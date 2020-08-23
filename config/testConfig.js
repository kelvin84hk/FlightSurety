
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    ///Available Accounts for ganache-cli -m "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat" -a 35 -l 9999999999
    ///==================
    // (0) 0x627306090abaB3A6e1400e9345bC60c78a8BEf57 (100 ETH)
    // (1) 0xf17f52151EbEF6C7334FAD080c5704D77216b732 (100 ETH)
    // (2) 0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef (100 ETH)
    // (3) 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544 (100 ETH)
    // (4) 0x0d1d4e623D10F9FBA5Db95830F7d3839406C6AF2 (100 ETH)
    // (5) 0x2932b7A2355D6fecc4b5c0B6BD44cC31df247a2e (100 ETH)
    // (6) 0x2191eF87E392377ec08E7c08Eb105Ef5448eCED5 (100 ETH)
    // (7) 0x0F4F2Ac550A1b4e2280d04c21cEa7EBD822934b5 (100 ETH)
    // (8) 0x6330A553Fc93768F612722BB8c2eC78aC90B3bbc (100 ETH)
    // (9) 0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE (100 ETH)
    //...

    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0x69e1CB5cFcA8A311586e3406ed0301C06fb839a2",
        "0xF014343BDFFbED8660A9d8721deC985126f189F3",
        "0x0E79EDbD6A727CfeE09A2b1d0A59F7752d5bf7C9",
        "0x9bC1169Ca09555bf2721A5C9eC6D69c8073bfeB4",
        "0xa23eAEf02F9E0338EEcDa8Fdd0A73aDD781b2A86",
        "0x6b85cc8f612d5457d49775439335f83e12b8cfde",
        "0xcbd22ff1ded1423fbc24a7af2148745878800024",
        "0xc257274276a4e539741ca11b590b9447b26a8051",
        "0x2f2899d6d35b1a48a4fbdc93a37a72f264a9fca7"
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new(firstAirline);
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);

    
    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};