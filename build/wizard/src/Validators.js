import React from "react";
import axios from "axios";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faSatelliteDish, faTrash } from "@fortawesome/free-solid-svg-icons";
import { confirmAlert } from 'react-confirm-alert';
import 'react-confirm-alert/src/react-confirm-alert.css'; // Import css

const Validators = ({ network, apiToken }) => {
    const [validators, setValidators] = React.useState("");

    const beaconchainUrl = (validatorPubkey, text) => {
        const beaconChainBaseUrl = ({
            "prater": "https://prater.beaconcha.in",
            "mainnet": "https://beaconcha.in",
        })[network] || "https://beaconcha.in"
        return <a href={beaconChainBaseUrl + validatorPubkey}>{text ? text : validatorPubkey}</a>;
    }

    const updateValidators = async () => {
        if (apiToken) {            
            return await axios.get("http://eth2validator.my.ava.do:80/eth/v1/keystores", {
                headers: {
                    Accept: "application/json",
                    Authorization: `Bearer ${apiToken}`
                }
            }).then((res) => {
                if (res.status === 200) {
                    setValidators(res.data.keystores.map(d => d.validating_pubkey))
                }
            }).catch((e) => {
                console.log(e)
                console.dir(e)
            });;

        }
    }

    React.useEffect(() => {
        if (apiToken)
            updateValidators();
    }, [apiToken]) // eslint-disable-line



    function askConfirmationRemoveValidator(pubKey) {
        confirmAlert({
            message: `Are you sure you want to remove validator "${pubKey}"?`,
            buttons: [
                {
                    label: 'Remove',
                    onClick: () => removeValidator(pubKey)
                },
                {
                    label: 'Cancel',
                    onClick: () => { }
                }
            ]
        });
    }

    const downloadSlashingData = (data) => {
        const element = document.createElement("a");
        const file = new Blob([data], { type: 'text/json' });
        element.href = URL.createObjectURL(file);
        element.download = "slashing_protection.json";
        document.body.appendChild(element); // Required for this to work in FireFox
        element.click();
    }

    const removeValidator = (pubKey) => {
        //https://ethereum.github.io/keymanager-APIs/#/Local%20Key%20Manager/DeleteKeys
        const apiCall = async (pubKey) => {
            return await axios.delete("http://eth2validator.my.ava.do:80/eth/v1/keystores", {
                headers: { Authorization: `Bearer ${apiToken}` },
                data: { pubkeys: [pubKey] }
            }).then((res) => {
                console.dir(res)
                console.log(res)
                downloadSlashingData(res.data.slashing_protection)
                if (res.status === 200) {
                    updateValidators();
                }
            }).catch((e) => {
                console.log(e)
                console.dir(e)
            });
        }
        console.log("Deleting " + pubKey + " with token " + apiToken);
        apiCall(pubKey);
    }

    return (
        <>
            {validators && (
                <>
                    <div className="card">
                        <div class="card-content">
                            <h2 className="subtitle is-4">Validators</h2>
                            <table className="table">
                                <thead>
                                    <tr>
                                        <th></th>
                                        <th>Public key</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {validators.map(validator =>
                                        <tr key={validator}>
                                            <td>{beaconchainUrl("/validator/" + validator, <FontAwesomeIcon className="icon" icon={faSatelliteDish} />)}</td>
                                            <th>{beaconchainUrl("/validator/" + validator, <abbr title={validator}>{validator.substring(0, 10) + "…"}</abbr>)}</th>
                                            <td><button className="button is-text has-text-grey-light" onClick={() => askConfirmationRemoveValidator(validator)}><FontAwesomeIcon className="icon" icon={faTrash} /></button></td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </>
            )
            }
        </>
    );
};

export default Validators