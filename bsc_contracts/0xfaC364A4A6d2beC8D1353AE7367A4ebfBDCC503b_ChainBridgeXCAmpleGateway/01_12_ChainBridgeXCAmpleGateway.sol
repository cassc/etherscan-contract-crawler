// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.3;

import {Ownable} from "oz-contracts/contracts/access/Ownable.sol";
import {SafeMath} from "oz-contracts/contracts/math/SafeMath.sol";

import {ChainBridgeRebaseGateway} from "../../base-bridge-gateways/ChainBridgeRebaseGateway.sol";
import {
    ChainBridgeTransferGateway
} from "../../base-bridge-gateways/ChainBridgeTransferGateway.sol";

import {IXCAmpleController} from "../../_interfaces/IXCAmpleController.sol";
import {IXCAmpleControllerGateway} from "../../_interfaces/IXCAmpleControllerGateway.sol";
import {IXCAmple} from "../../_interfaces/IXCAmple.sol";

/**
 * @title ChainBridgeXCAmpleGateway
 * @dev This contract is deployed on the satellite EVM chains eg). tron, acala, near etc.
 *
 *      It's a pass-through contract between the ChainBridge handler contract and
 *      the xc-ample controller contract.
 *
 *      When rebase is transmitted across the bridge,
 *      It forwards the next rebase report to the xc-ample controller.
 *
 *      When a sender initiates a cross-chain AMPL transfer from a
 *      source chain to a recipient on the current chain (target chain)
 *      the xc-amples are mint into the recipient's wallet.
 *      The amount of tokens to be mint is calculated based on the globalAMPLSupply
 *      on a source chain at the time of transfer and the,
 *      globalAMPLSupply recorded on the current chain at the time of minting.
 *
 *      When a sender initiates a cross-chain AMPL transfer from the current chain (source chain)
 *      to a recipient on a target chain, chain-bridge executes the `validateAndBurn`.
 *      It validates if the total supply reported is consistent with the recorded on-chain value
 *      and burns xc-amples from the sender's wallet.
 *
 */
contract ChainBridgeXCAmpleGateway is
    ChainBridgeRebaseGateway,
    ChainBridgeTransferGateway,
    Ownable
{
    using SafeMath for uint256;

    address public immutable xcAmple;
    address public immutable xcController;

    /**
     * @dev Forwards the most recent rebase information from the bridge handler to the xc-ample controller.
     * @param globalAmpleforthEpoch Ampleforth monetary policy epoch from the base chain.
     * @param globalAMPLSupply AMPL ERC-20 total supply from the base chain.
     */
    function reportRebase(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply)
        external
        override
        onlyOwner
    {
        uint256 recordedGlobalAmpleforthEpoch = IXCAmpleController(xcController)
            .globalAmpleforthEpoch();

        uint256 recordedGlobalAMPLSupply = IXCAmple(xcAmple).globalAMPLSupply();

        emit XCRebaseReportIn(
            globalAmpleforthEpoch,
            globalAMPLSupply,
            recordedGlobalAmpleforthEpoch,
            recordedGlobalAMPLSupply
        );

        IXCAmpleControllerGateway(xcController).reportRebase(
            globalAmpleforthEpoch,
            globalAMPLSupply
        );
    }

    /**
     * @dev Calculates the amount of xc-amples to be mint based on the amount and the total supply
     *      on the base chain when the transaction was initiated
     *      and mints xc-amples to the recipient.
     * @param senderAddressInSourceChain Address of the sender wallet in the transaction originating chain.
     * @param recipient Address of the recipient wallet in the current chain (target chain).
     * @param amount Amount of tokens that were {locked/burnt} on the source chain.
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer.
     */
    function mint(
        address senderAddressInSourceChain,
        address recipient,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external override onlyOwner {
        uint256 recordedGlobalAMPLSupply = IXCAmple(xcAmple).globalAMPLSupply();
        uint256 mintAmount = amount.mul(recordedGlobalAMPLSupply).div(globalAMPLSupply);

        emit XCTransferIn(
            address(0),
            recipient,
            globalAMPLSupply,
            mintAmount,
            recordedGlobalAMPLSupply
        );

        IXCAmpleControllerGateway(xcController).mint(recipient, mintAmount);
    }

    /**
     * @dev Validates the data from the handler and burns specified amount from the sender's wallet.
     * @param sender Address of the sender wallet on the source chain.
     * @param recipientAddressInTargetChain Address of the recipient wallet in the target chain.
     * @param amount Amount of tokens to be burnt on the current chain (source chain).
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer burning.
     */
    function validateAndBurn(
        address sender,
        address recipientAddressInTargetChain,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external override onlyOwner {
        uint256 recordedGlobalAMPLSupply = IXCAmple(xcAmple).globalAMPLSupply();
        require(
            globalAMPLSupply == recordedGlobalAMPLSupply,
            "ChainBridgeXCAmpleGateway: total supply not consistent"
        );

        IXCAmpleControllerGateway(xcController).burn(sender, amount);

        emit XCTransferOut(sender, address(0), amount, recordedGlobalAMPLSupply);
    }

    constructor(
        address bridgeHandler,
        address xcAmple_,
        address xcController_
    ) {
        xcAmple = xcAmple_;
        xcController = xcController_;

        transferOwnership(bridgeHandler);
    }
}