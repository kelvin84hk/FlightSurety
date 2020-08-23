pragma solidity ^0.5.15;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

// interface contract 
contract FlightSuretyData {
    function getRegisteredAirlineNum() public view returns (uint256);
    function vote(address _address_of_new_airline,address _sender) external;
    function registerAirline(address _address,address _address_exit) external;
    function fund(address _address_of_new_airline) public payable;
    function get_vote_count(address _address_of_new_airline) public view returns (uint256);
    function buy(string memory _flight,address passenger,uint256 amount) public payable;
    function getAirlineInfo(address _address) public view returns(bool,bool);
    function creditInsurees(string memory _flight,uint payoutFactor) public;
    function getInsuranceAmount(string memory flight,address passenger)public view returns (uint256);
    function pay(address payable _address)public;
}


/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract
    FlightSuretyData flightSuretyData;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;
    uint private fundingAmount = 10 ether;
    uint private maxBuyAmount = 1 ether;
    uint private payoutFactor = 150;
    uint private mc_threshold = 4; 
    bool private operational = true;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event Funded(address airline);
    event Voted (address new_airline,address original_airline);
    event Registered(address airline);           
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
         // Modify to call data contract's status
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


    modifier fundEnough()
    {
        require(msg.value>=fundingAmount,"min funding 10 ether");
        _;
    }

    modifier payEnough()
    {
        require(msg.value>0,"not paying enough");
        require(msg.value<=maxBuyAmount,"maximum to buy 1 ether");
        _;
    }


    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address _address_data
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(_address_data);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational
                            (

                            ) 
                            public 
                            returns(bool) 
    {
        return operational;  // Modify to call data contract's status
    }

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

    function isRegisteredFunded
                                (
                                    address airline
                                )
                                private
                                returns(bool)
    {
        bool result1;
        bool result2; 
        (result1,result2) = flightSuretyData.getAirlineInfo(airline);
        if (result1 == true && result2 == true)
        {
            return true;
        }else{
            return false;
        }
    }

    function testing_mode()
    public
    requireIsOperational
    {
        bool t = true;
    }

    function stringToBytes32
                            (
                                string memory source
                                ) 
    internal
    pure 
    returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            (
                                address _address   
                            )
                            external
                            requireIsOperational
    {
        uint256 M = flightSuretyData.getRegisteredAirlineNum();
        if (M<mc_threshold)
        {
            flightSuretyData.registerAirline(_address,msg.sender);
        }else{
            require(flightSuretyData.get_vote_count(_address).mul(100).div(M)>=50,"multi-party consensus of 50% is required");
            flightSuretyData.registerAirline(_address,msg.sender);
        }
        emit Registered(_address);
    }

    function vote
                (
                    address _address_of_new_airline
                )
    external
    {
        flightSuretyData.vote(_address_of_new_airline,msg.sender);
        emit Voted(_address_of_new_airline,msg.sender);
    }

    function fundAccount
                            (
                            )
    public
    payable
    requireIsOperational
    fundEnough()
    {
        flightSuretyData.fund.value(msg.value)(msg.sender);
        emit Funded(msg.sender);
    }

    function buyInsurance
                            (
                                string memory _flight
                            )
    public
    payable
    requireIsOperational
     payEnough()
     {   
         require(flightSuretyData.getInsuranceAmount(_flight,msg.sender)+msg.value<= 1 ether,"Max 1 ether in total");
         flightSuretyData.buy.value(msg.value)(_flight,msg.sender,msg.value);
     }

    function pay
                (
                    address payable _passenger
                )
    public
    payable
    requireIsOperational
    {
        flightSuretyData.pay(_passenger);
    }

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    string memory flight
                                )
                                public
                                requireIsOperational
    {
       require(isRegisteredFunded(msg.sender),"airline not eligible to register flights");
       bytes32 flight_id = stringToBytes32(flight);
       flights[flight_id].isRegistered = true;
       flights[flight_id].updatedTimestamp = now;
       flights[flight_id].airline = msg.sender;
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
    {
        bytes32 flight_id = stringToBytes32(flight);
        flights[flight_id].airline = airline;
        flights[flight_id].statusCode = statusCode;
        flights[flight_id].updatedTimestamp = timestamp;
        if (statusCode == STATUS_CODE_LATE_AIRLINE)
        {
            flightSuretyData.creditInsurees(flight, payoutFactor);
        }
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp                            
                        )
                        public 
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            public
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string memory flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        public
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
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

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8 )
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   
