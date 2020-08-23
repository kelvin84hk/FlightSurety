pragma solidity ^0.5.15;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    struct Airline {
        bool isRegistered;
        bool isFunded;
        address[] support_from_ra ;
        uint256 vote_count;
    }
    struct Passenger{
        uint256 balance;
    }
    struct Insurance{
        address[] insured_passengers;
        mapping(address => uint256)insured_amount;
        bool isProccessed;
    }
    uint256 private M;                                                      // number of airline registered
    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping (address => Airline) airlines;
    mapping (address => bool) authorizeCallers;
    mapping (address => Passenger) passengers;
    mapping (bytes => Insurance) insurance;
    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address _firstAirLine
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        // register 1st airline when deploy
        airlines[_firstAirLine].isRegistered =true;
        airlines[_firstAirLine].isFunded =false;
        M=1;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier differentModeRequest(bool status) {
        require(status != operational, "Contract already in the state requested");
        _;
    }
    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier isAuthorizeCaller()
    {   
        require(authorizeCallers[msg.sender],"caller is not authorized");
        _;
    }

    modifier isRegistered(address _address)
    {
        require(airlines[_address].isRegistered, "Caller is not registered");
        _;
    }

     modifier isFunded(address _address)
    {
        require(airlines[_address].isFunded, "Caller is not funded");
        _;
    }

    
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function authorizeCaller(address _address)
    external
    requireContractOwner
    requireIsOperational
    {
        authorizeCallers[_address] = true;
    }
    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner
                            differentModeRequest(mode) 
    {
        operational = mode;
    }
    
    function testing_mode()
    public
    requireIsOperational
    {
        bool t;
        t = true;
    }

    
    function getAirlineInfo(
        address _address
        )
    public
    view
    returns(bool,bool)
    {        
        return (
           airlines[_address].isRegistered,
           airlines[_address].isFunded
        );
    }

    function getRegisteredAirlineNum(
        )
    public
    view
    returns (uint256)
    {
        return M;
    }

    function getInsuranceAmount(
        string memory flight,
        address passenger
    )
    public
    view
    returns (uint256)
    {   
        bytes memory flight_id = bytes(flight);
        return insurance[flight_id].insured_amount[passenger];
    }

    function getPassengerBalance(
        address _passenger
    )
    public
    view
    returns (uint256)
    {
        return passengers[_passenger].balance;
    }

    function get_vote_count(address _address_of_new_airline)
    public
    view
    returns (uint256)
    {
        return airlines[_address_of_new_airline].vote_count;
    }
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    // function to authorize addresses (especially the App contract!) to call functions from flighSuretyData contract
    
   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address _address_new,
                                address _address_exit
                            )
                            external
                            isAuthorizeCaller
                            requireIsOperational
                            isRegistered(_address_exit)
                            isFunded(_address_exit)
    {
        airlines[_address_new].isRegistered=true;
        airlines[_address_new].isFunded =false;
        M=M.add(1);  // update number of registered airlines
    }
    
    // registered airlines support new airline to register
    function vote(address _address_of_new_airline, address _sender)
    external
    isAuthorizeCaller
    requireIsOperational
    isRegistered(_sender)
    isFunded(_sender)
    {
        bool isDuplicate = false;
        for(uint c=0; c<airlines[_address_of_new_airline].support_from_ra.length; c++) {
            if (airlines[_address_of_new_airline].support_from_ra[c] == _sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "each registered airline can only vote once");
        airlines[_address_of_new_airline].support_from_ra.push(_sender);
        airlines[_address_of_new_airline].vote_count=airlines[_address_of_new_airline].vote_count.add(1);
        
    }
    

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (
                                string memory _flight,
                                address passenger,
                                uint256 amount                             
                            )
                            public
                            payable
                            isAuthorizeCaller
                            requireIsOperational
    {
        bytes memory flight_id = bytes(_flight);
        bool isDuplicate = false;
        for(uint c=0; c<insurance[flight_id].insured_passengers.length; c++) {
            if (insurance[flight_id].insured_passengers[c] == passenger) {
                isDuplicate = true;
                break;
            }
        }
        if (!isDuplicate)
        {
            insurance[flight_id].insured_passengers.push(passenger);
        }
        insurance[flight_id].insured_amount[passenger] = insurance[flight_id].insured_amount[passenger].add(amount); 
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    string memory _flight,
                                    uint payoutFactor
                                )
                                public
                                isAuthorizeCaller
                                requireIsOperational
    {
        bytes memory flight_id = bytes(_flight);
        address temp_address;
        uint256 temp_payout;
        if (!insurance[flight_id].isProccessed)
        {
            for (uint i=0;i<insurance[flight_id].insured_passengers.length;i++)
            {
                temp_address = insurance[flight_id].insured_passengers[i];
                temp_payout = insurance[flight_id].insured_amount[temp_address].mul(payoutFactor).div(100);
                passengers[temp_address].balance = passengers[temp_address].balance.add(temp_payout);
            }
            insurance[flight_id].isProccessed =true;
        }
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address payable _address
                            )
                            public
                            isAuthorizeCaller
                            requireIsOperational
    {
        require (passengers[_address].balance>0, "invalid withdarw amount");
        uint256 _amount = passengers[_address].balance;
        passengers[_address].balance = 0;
        _address.transfer(_amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (
                                address _address_of_new_airline
                            )
    public
    payable
    isAuthorizeCaller
    requireIsOperational
    isRegistered(_address_of_new_airline)
    {   
        airlines[_address_of_new_airline].isFunded =true;
    
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function () 
    external 
    payable 
    isAuthorizeCaller 
    {
        require(msg.data.length == 0);
        fund (msg.sender);
    }


}

