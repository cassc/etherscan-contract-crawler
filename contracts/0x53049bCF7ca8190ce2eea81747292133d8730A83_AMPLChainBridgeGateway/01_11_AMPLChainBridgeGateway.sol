// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.3;

import {Ownable} from "oz-contracts/contracts/access/Ownable.sol";
import {SafeMath} from "oz-contracts/contracts/math/SafeMath.sol";

import {ChainBridgeRebaseGateway} from "../../base-bridge-gateways/ChainBridgeRebaseGateway.sol";
import {
    ChainBridgeTransferGateway
} from "../../base-bridge-gateways/ChainBridgeTransferGateway.sol";

import {IERC20} from "oz-contracts/contracts/token/ERC20/IERC20.sol";
import {IAmpleforth} from "uFragments/contracts/interfaces/IAmpleforth.sol";
import {ITokenVault} from "../../_interfaces/ITokenVault.sol";

/**
 * @title AMPLChainBridgeGateway: AMPL-ChainBridge Gateway Contract
 * @dev This contract is deployed on the base chain (Ethereum).
 *
 *      It's a pass-through contract between the ChainBridge handler contract and
 *      the Ampleforth policy and the Token vault.
 *
 *      The contract is owned by the ChainBridge handler contract.
 *
 *      When rebase is transmitted across the bridge, It checks the consistency of rebase data
 *      from the ChainBridge handler contract with the recorded on-chain value.
 *
 *      When a sender initiates a cross-chain AMPL transfer from the
 *      current chain (source chain) to a target chain through chain-bridge,
 *      `validateAndLock` is executed.
 *      It validates if total supply reported is consistent with the
 *      recorded on-chain value and locks AMPLS in a token vault.
 *
 *      When a sender has initiated a cross-chain AMPL transfer from a source chain
 *      to a recipient on the current chain (target chain),
 *      chain-bridge executes the `unlock` function.
 *      The amount of tokens to be unlocked to the recipient is calculated based on
 *      the globalAMPLSupply on the source chain, at the time of transfer initiation
 *      and the total ERC-20 AMPL supply on the current chain, at the time of unlock.
 *
 */
contract AMPLChainBridgeGateway is ChainBridgeRebaseGateway, ChainBridgeTransferGateway, Ownable {
    using SafeMath for uint256;

    address public immutable ampl;
    address public immutable policy;
    address public immutable vault;

    /**
     * @dev Validates if the data from the handler is consistent with the
     *      recorded value on the current chain.
     * @param globalAmpleforthEpoch Ampleforth monetary policy epoch.
     * @param globalAMPLSupply AMPL ERC-20 total supply.
     */
    function validateRebaseReport(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply)
        external
        override
        onlyOwner
    {
        uint256 recordedGlobalAmpleforthEpoch = IAmpleforth(policy).epoch();
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

        require(
            globalAmpleforthEpoch == recordedGlobalAmpleforthEpoch,
            "AMPLChainBridgeGateway: epoch not consistent"
        );
        require(
            globalAMPLSupply == recordedGlobalAMPLSupply,
            "AMPLChainBridgeGateway: total supply not consistent"
        );

        emit XCRebaseReportOut(globalAmpleforthEpoch, globalAMPLSupply);
    }

    /**
     * @dev Validates the data from the handler and transfers specified amount from
     *      the sender's wallet and locks it in the vault contract.
     * @param sender Address of the sender wallet on the base chain.
     * @param recipientAddressInTargetChain Address of the recipient wallet in the target chain.
     * @param amount Amount of tokens to be locked on the current chain (source chain).
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer locking.
     */
    function validateAndLock(
        address sender,
        address recipientAddressInTargetChain,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external override onlyOwner {
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

        require(
            globalAMPLSupply == recordedGlobalAMPLSupply,
            "AMPLChainBridgeGateway: total supply not consistent"
        );

        ITokenVault(vault).lock(ampl, sender, amount);

        emit XCTransferOut(sender, address(0), amount, recordedGlobalAMPLSupply);
    }

    /**
     * @dev Calculates the amount of amples to be unlocked based on the share of total supply and
     *      transfers it to the recipient.
     * @param senderAddressInSourceChain Address of the sender wallet in the transaction originating chain.
     * @param recipient Address of the recipient wallet in the current chain (target chain).
     * @param amount Amount of tokens that were {locked/burnt} on the base chain.
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer.
     */
    function unlock(
        address senderAddressInSourceChain,
        address recipient,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external override onlyOwner {
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();
        uint256 unlockAmount = amount.mul(recordedGlobalAMPLSupply).div(globalAMPLSupply);

        emit XCTransferIn(
            address(0),
            recipient,
            globalAMPLSupply,
            unlockAmount,
            recordedGlobalAMPLSupply
        );

        ITokenVault(vault).unlock(ampl, recipient, unlockAmount);
    }

    constructor(
        address bridgeHandler,
        address ampl_,
        address policy_,
        address vault_
    ) {
        ampl = ampl_;
        policy = policy_;
        vault = vault_;

        transferOwnership(bridgeHandler);
    }
}