import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
var BigNumber = require('bignumber.js');

export default class Contract {
    constructor(network, callback) {

        this.config = Config[network];
        //this.web3 = new Web3(new Web3.providers.HttpProvider(config.url)); //config.url.replace('http', 'ws') // config.url 
        this.web3 = new Web3();
        const eventProvider = new Web3.providers.WebsocketProvider(this.config.url.replace('http', 'ws'));
        this.web3.setProvider(eventProvider);
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, this.config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, this.config.dataAddress);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.weiMultiple= (new BigNumber(10)).pow(18)
        this.initialize(callback);
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 4) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }
            
            callback();
        });
    

    }

    isAuthorized(){
        return new Promise((resolve, reject) => {
            this.flightSuretyData.methods
                .authorizeCaller(this.config.appAddress)
                .send({ from: this.owner}), (err, res) => {
                    if (err) reject(err);
                    resolve(res);
                }
        });        
    }
    
    isOperational() {
        return new Promise((resolve, reject) => {
            this.flightSuretyApp.methods
                .isOperational()
                .call({ from: this.owner}, (err, res) => {
                    if (err) reject(err);
                    resolve(res);
                });
        });
    }

    fundContract(){
        return new Promise((resolve, reject) => {
            this.flightSuretyApp.methods
            .fundAccount()
            .send({from:this.airlines[0],value:10*this.weiMultiple,gas: 9999999},
            (err, res) => {
                if (err) reject(err);
                resolve(res);
            
            });

        });
    }

    fetchFlightStatus(flight) {
        return new Promise((resolve, reject) => {
            this.flightSuretyApp.methods
                .fetchFlightStatus(this.airlines[0], flight, Math.floor(Date.now() / 1000))
                .send(
                    { from: this.owner },
                    (err, res) => {
                        if (err) reject(err);
                        resolve(res);
                    }
                );
        });
    }

    buyInsurance(flight,notional){
        return new Promise((resolve, reject) => {
            this.flightSuretyApp.methods
            .buyInsurance(flight)
            .send(
                {from:this.passengers[0],value:notional*this.weiMultiple,gas: 9999999},
                (err, res) => {
                    if (err) reject(err);
                    resolve(res);
                }
            );

        });
    }

    fetchPassengerBalance() {
        return new Promise((resolve, reject) => {
            this.flightSuretyData.methods
            .getPassengerBalance(this.passengers[0])
            .call(
                { from: this.owner },
                (err, res) => {
                    if (err) reject(err);
                    resolve(res/this.weiMultiple);
                }
            );
        });
    }

    withdrawBalance() {
        return new Promise((resolve, reject) => {
            this.flightSuretyApp.methods
            .pay(this.passengers[0])
            .send(
                { from: this.owner,gas: 9999999 },
                (err, res) => {
                    if (err) reject(err);
                    resolve(res);
                }
            );
        });
    }
}