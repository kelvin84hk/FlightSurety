
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';

let map = new Map();
map.set(0, 'No flight event information yet.');
map.set(10, 'The flight is on time.');
map.set(20, 'The flight is late because of airline.');
map.set(30, 'The flight is late because of weather.');
map.set(40, 'The flight is late because of techinal reasons.');
map.set(50, 'The flight is late because of other reasons.');

class App {
    constructor() {
        this.contract = new Contract('localhost', () => {

            this.contract.isAuthorized()
                .then((result) => console.log('contract authorized'))
                .catch((err) => console.log(err));
            
            this.contract.fundContract()
                .then((result) => console.log('contract funded'))
                .catch((err) => console.log(err));

            this.contract.isOperational()
                .then((result) => {
                    display(
                        true,
                        'display-wrapper',
                        'oper',
                        'Operational Status',
                        'Checks if smart contract is operational',
                        [ { label: 'Status', value: result} ]
                    );
                })
                .catch((err) => {
                    display(
                        true,
                        'display-wrapper',
                        'Operational Status',
                        'Checks if smart contract is operational',
                        [ { label: 'Status', error: err} ]
                    );
                });
            this.listenForFlightStatusUpdate();
        });
    }

    async fetchFlightStatus(flight) {
        this.contract.fetchFlightStatus(flight)
            .then(() => {
                display(
                    true,
                    'result-wrapper',
                    'status',
                    'Oracles Report',
                    'Fetching flight status from oracles',
                    [
                        { label: String(flight), value: 'waiting for oracales response...if there is no reponse for a while, please click the button again!'}
                     ]
                );
            })
            .catch((error) => console.log(error));
    }

    async buyInsurance(flight,notional){
        this.contract.buyInsurance(flight,notional)
        .then(() => {
            display(
                false,
                'price-wrapper',
                'price',
                'Transaction summary',
                Date.now().toString(),
                [
                    { label: String(flight), value: 'Notional insured:' +String(notional)+ " ETH"}
                 ]
            );
        })
        .catch((error) => {
            console.log(error)
            display(
                false,
                'price-wrapper',
                'price',
                'Transaction summary',
                'No transaction',
                [
                    { label: "Reason", value: "Maximum total amount to be insured 1 Ether"}
                 ]
            );
        });
    }

    async fetchPassengerBalance(){
        this.contract.fetchPassengerBalance()
        .then((result) => {
            display(
                true,
                'balance-wrapper',
                'bal',
                'Current payout balance',
                Date.now().toString(),
                [
                    { label: "ETH", value:String(result)}
                 ]
            );
        });
    }

    async withdrawBalance(){
        this.contract.withdrawBalance()
        .then((result) => {
            display(
                true,
                'balance-wrapper',
                'bal',
                'Current payout balance',
                Date.now().toString(),
                [
                    { label: "ETH", value:String(0)}
                 ]
            );

            display(
                true,
                'withdraw-wrapper',
                'balw',
                'Withdarw status',
                Date.now().toString(),
                [
                    { label: "balance wthdraw", value:'success'}
                 ]
            );
        })
        .catch((error) => {
            console.log(error)
            display(
                true,
                'withdraw-wrapper',
                'balw',
                'Withdarw status',
                'No transaction',
                [
                    { label: "balance wthdraw", value: "Failed"}
                 ]
            );
        });
    }

    async listenForFlightStatusUpdate() {
        this.contract.flightSuretyApp.events.FlightStatusInfo({fromBlock: 0},
            (error, event) => {
                if (error) return console.log(error);
                if (!event.returnValues) return console.error("No returnValues");
                console.log( event.returnValues.status);
                display(
                    true,
                    'result-wrapper',
                    'status',
                    'Oracles Report',
                    'Fetching flight status from oracles',
                    [
                        { label: String(event.returnValues.flight), value: String(map.get( parseInt(event.returnValues.status)))+" " + String(event.returnValues.timestamp)}
                     ]
                );
            });
        
    }

}

const Application = new App();

document.addEventListener('click', (ev) => {
    if (!ev.target.dataset.action) return;

    const action = parseFloat(ev.target.dataset.action);

    switch(action) {
        case 0:
            let flight = DOM.elid('flight-number').value;
            Application.fetchFlightStatus(flight);
            break;
        case 1:
            let flight2 = DOM.elid('flight-number').value;
            let notional = DOM.elid('ether').value;
            Application.buyInsurance(flight2,notional);
            break;
        case 2:
            Application.fetchPassengerBalance();
            break;
        case 3:
            Application.withdrawBalance();
            break;
    }
});

function display(is_clear,display_id,result_id,title, description, results) {
    let displayDiv = DOM.elid(display_id);
    if (is_clear)
    {
        displayDiv.innerHTML="";
    }
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value',id:result_id}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);
}


