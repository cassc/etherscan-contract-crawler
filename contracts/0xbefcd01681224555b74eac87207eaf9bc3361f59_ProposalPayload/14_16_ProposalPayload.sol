// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {AaveV2CollectorContractConsolidation} from "./AaveV2CollectorContractConsolidation.sol";
import {AMMWithdrawer} from "./AMMWithdrawer.sol";
import {TokenAddresses} from "./TokenAddresses.sol";
import {AaveMisc} from "@aave-address-book/AaveMisc.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

/**
 * @title Payload to redeem set of AMM tokens and to deploy a contract for V2Collector consolidation
 * @author Llama
 * @notice Provides an execute function for Aave governance to execute
 * Governance Forum Post: https://governance.aave.com/t/arfc-ethereum-v2-collector-contract-consolidation/10909
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xe1e72012b87ead90a7be671cd4adba4b5d7c543be5c2c876d14337e6e22d3cec
 */
contract ProposalPayload {
    address public immutable consolidationContract;
    AMMWithdrawer public immutable withdrawContract;

    constructor(address _consolidationContract, AMMWithdrawer _withdrawContract) {
        consolidationContract = _consolidationContract;
        withdrawContract = _withdrawContract;
    }

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Transfer to withdraw contract to spend pre-defined amount of tokens and then redeem AMM Tokens
        address[5] memory aAMMTokens = TokenAddresses.getaAMMTokens();
        for (uint256 i = 0; i < 5; ++i) {
            AaveMisc.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.transfer(
                AaveV2Ethereum.COLLECTOR,
                aAMMTokens[i],
                address(withdrawContract),
                IERC20(aAMMTokens[i]).balanceOf(AaveV2Ethereum.COLLECTOR)
            );
        }

        withdrawContract.redeem();

        // Approve the Consolidation Contract to spend pre-defined amount of tokens from AAVE V2 Collector
        address[17] memory purchasableTokens = TokenAddresses.getPurchasableTokens();
        for (uint256 i = 0; i < 17; ++i) {
            AaveMisc.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.approve(
                AaveV2Ethereum.COLLECTOR,
                purchasableTokens[i],
                consolidationContract,
                IERC20(purchasableTokens[i]).balanceOf(AaveV2Ethereum.COLLECTOR)
            );
        }
    }
}