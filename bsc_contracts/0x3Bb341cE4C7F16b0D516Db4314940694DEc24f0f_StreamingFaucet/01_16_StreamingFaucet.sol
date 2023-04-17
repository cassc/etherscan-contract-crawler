// SPDX-License-Identifier: AGPLv3
pragma solidity 0.7.6;
pragma abicoder v2;

import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {
    ISuperfluid,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IERC1820Registry } from "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import { IERC777Recipient } from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

/*
* Faucet opening a stream of a configured SuperToken to the transaction sender.
* Only a single "sponsor" (the first account to provide tokens) can fund the faucet.
* Whoever invokes the ERC777 hook first by transferring the right SuperTokens, becomes the sponsor.
* This hook is also triggered by a simple ERC20 transfer, no need for the sponsor to look for an ERC777 aware wallet.
*/
contract StreamingFaucet is IERC777Recipient {
    address public sponsor;
    ISuperToken public token;
    int96 public flowRate;
    ISuperfluid internal _sfHost;
    IConstantFlowAgreementV1 internal _cfa;
    IERC1820Registry constant internal _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    constructor(ISuperfluid sfHost, ISuperToken token_, int96 flowRate_) {
        require(token_.getHost() == address(sfHost), "StreamingFaucet: not a SuperToken with given host");
        require(flowRate_ > 0, "StreamingFaucet: invalid flowRate");

        _sfHost = ISuperfluid(sfHost);
        address cfaAddr = address(
            _sfHost.getAgreementClass(keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1"))
        );
        _cfa = IConstantFlowAgreementV1(cfaAddr);

        token = token_;
        flowRate = flowRate_;

        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    // the first invocation of this ERC-777 hook registers the sender as exclusive sponsor
    function tokensReceived(
        address /*operator*/,
        address from,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) override external {
        require(msg.sender == address(token), "StreamingFaucet: wrong token");
        if (from != sponsor) {
            // allowing just one sponsor prevents frontrunning attacks of the first funding action
            require(sponsor == address(0x0), "StreamingFaucet: faucet already has a sponsor");
            sponsor = from;
        }
    }

    // can be called by any account currently not receiving a stream from this faucet
    // opens a stream with the configured stream to the message sender
    function startStreamToSender() public {
        address receiver = msg.sender;

        (,int96 curFlowRate,,) = _cfa.getFlow(token, address(this), receiver);
        require(curFlowRate == 0, "StreamingFaucet: stream already open");

        _sfHost.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.createFlow.selector,
                token,
                receiver,
                flowRate,
                new bytes(0)
            ),
            "0x"
        );
    }

    // alternative way to trigger the faucet action in order to make it accessible from any wallet without Dapp
    receive() external payable {
        require(msg.value == 0, "StreamingFaucet: amount must be 0, no bribes accepted");
        startStreamToSender();
    }

    // lets the sponsor withdraw remaining tokens. This may trigger a mass liquidation of open streams
    function withdrawTokens() external {
        require(msg.sender == sponsor, "only the sponsor can withdraw");
        token.send(msg.sender, token.balanceOf(address(this)), new bytes(0));
    }

    // stops the stream to the message sender if open (useful for testing, otherwise not needed)
    function stopStream() external {
        address receiver = msg.sender;
        _sfHost.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.deleteFlow.selector,
                token,
                address(this),
                receiver,
                new bytes(0)
            ),
            "0x"
        );
    }
}