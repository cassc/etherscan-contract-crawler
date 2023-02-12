// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
pragma abicoder v1;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";

import { IClaimZap } from "../../integrations/convex/IClaimZap.sol";
import { IRewards, IBasicRewards } from "../../integrations/convex/IRewards.sol";
import { IBaseRewardPool } from "../../integrations/convex/IBaseRewardPool.sol";
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";

/// @title ConvexV1ClaimZapAdapter adapter
/// @dev Implements logic for interacting with the Convex ClaimZap contract
contract ConvexV1ClaimZapAdapter is
    AbstractAdapter,
    IClaimZap,
    ReentrancyGuard
{
    AdapterType public constant _gearboxAdapterType =
        AdapterType.CONVEX_V1_CLAIM_ZAP;
    uint16 public constant _gearboxAdapterVersion = 1;

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _claimZap Address of the ClaimZap contract
    constructor(address _creditManager, address _claimZap)
        AbstractAdapter(_creditManager, _claimZap)
    {}

    /// @dev Claims rewards from multiple sources for a Credit Account
    /// @param rewardContracts Base reward pools to claim from
    /// @param extraRewardContracts Base reward pools to claim from
    /// @param tokenRewardContracts Special reward pools to claim from
    /// @param tokenRewardTokens Tokens to claim from special reward pools
    /// @notice Additional parameters for claimZap are ignored, since they deal
    /// with pools and contracts that are currently not supported.
    function claimRewards(
        address[] calldata rewardContracts,
        address[] calldata extraRewardContracts,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        _claimAndEnableRewards(creditAccount, rewardContracts); // F: [ACVX1_Z-1]

        _claimAndEnableExtraRewards(creditAccount, extraRewardContracts); // F: [ACVX1_Z-1,2]

        _claimAndEnableTokenRewards( // F: [ACVX1_Z-1,4]
            creditAccount,
            tokenRewardContracts,
            tokenRewardTokens
        );

        _enableTokenIfHasBalance(creditAccount, crv()); // F: [ACVX1_Z-1]
        _enableTokenIfHasBalance(creditAccount, cvx()); // F: [ACVX1_Z-1]

        _checkAndOptimizeEnabledTokens(creditAccount);
    }

    /// @dev Calls getReward on base reward contracts and enables extra reward tokens, if available
    /// @param creditAccount Credit account to claim for
    /// @param rewardContracts BaseRewardPool contracts to claim from
    /// @notice The reward token itself is not enabled, since it is always CRV,
    /// which is enabled at the end of the main function
    function _claimAndEnableRewards(
        address creditAccount,
        address[] calldata rewardContracts
    ) internal {
        address token;
        uint256 len = rewardContracts.length;

        for (uint256 i; i < len; ) {
            address rewardContract = rewardContracts[i];

            IBaseRewardPool(rewardContract).getReward(creditAccount, true); // F: [ACVX1_Z-1]
            token = IRewards(rewardContract).rewardToken();

            try IBaseRewardPool(rewardContract).extraRewards(0) returns (
                address extraRewardContract1
            ) {
                // F: [ACVX1_Z-5]
                token = IRewards(extraRewardContract1).rewardToken();
                _enableTokenIfHasBalance(creditAccount, token); // F: [ACVX1_Z-1]

                try IBaseRewardPool(rewardContract).extraRewards(1) returns (
                    address extraRewardContract2
                ) {
                    token = IRewards(extraRewardContract2).rewardToken();
                    _enableTokenIfHasBalance(creditAccount, token); // F: [ACVX1_Z-1]
                } catch {}
            } catch {}

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Calls getReward on extra reward contracts and enables extra reward tokens
    /// @param creditAccount Credit account to claim for
    /// @param extraRewardContracts VirtualBalanceRewardPool contracts to claim from
    function _claimAndEnableExtraRewards(
        address creditAccount,
        address[] calldata extraRewardContracts
    ) internal {
        address token;

        uint256 len = extraRewardContracts.length;

        for (uint256 i = 0; i < len; ) {
            token = IRewards(extraRewardContracts[i]).rewardToken();
            IRewards(extraRewardContracts[i]).getReward(creditAccount); // F: [ACVX1_Z-1,2]

            _enableTokenIfHasBalance(creditAccount, token); // F: [ACVX1_Z-1,2]

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Calls getReward on special reward contracts and enables designated reward tokens
    /// @param creditAccount Credit account to claim for
    /// @param tokenRewardContracts Contracts to claim from
    /// @param tokenRewardTokens Tokens to claim
    /// @notice If the sizes of two arrays don't match, then any tokens that
    /// don't have a corresponding contract will be ignored
    function _claimAndEnableTokenRewards(
        address creditAccount,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens
    ) internal {
        address token;
        uint256 len = tokenRewardContracts.length; // F: [ACVX1_Z-4]
        //claim from multi reward token contract
        for (uint256 i; i < len; ) {
            token = tokenRewardTokens[i];
            IBasicRewards(tokenRewardContracts[i]).getReward( // F: [ACVX1_Z-1,4]
                creditAccount,
                token
            );

            _enableTokenIfHasBalance(creditAccount, token); // F: [ACVX1_Z-1,4]

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Enables token for a credit account if it has balance > 1
    /// @param creditAccount The CA to enable the token for
    /// @param token The token to enable
    function _enableTokenIfHasBalance(address creditAccount, address token)
        internal
    {
        if (IERC20(token).balanceOf(creditAccount) > 1) {
            creditManager.checkAndEnableToken(creditAccount, token);
        }
    }

    /// @dev Returns the CRV token address
    function crv() public view returns (address) {
        return IClaimZap(targetContract).crv();
    }

    /// @dev Returns the CVX token address
    function cvx() public view returns (address) {
        return IClaimZap(targetContract).cvx();
    }
}