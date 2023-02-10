// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";
import { IBooster } from "../../integrations/convex/IBooster.sol";
import { IConvexV1BaseRewardPoolAdapter } from "../../interfaces/convex/IConvexV1BaseRewardPoolAdapter.sol";

import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";

import { IPoolService } from "@gearbox-protocol/core-v2/contracts/interfaces/IPoolService.sol";

import { ACLTrait } from "@gearbox-protocol/core-v2/contracts/core/ACLTrait.sol";
import { ICreditManagerV2 } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditManagerV2.sol";
import { ICreditConfigurator } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditConfigurator.sol";

/// @title ConvexV1BoosterAdapter adapter
/// @dev Implements logic for for interacting with the Convex Booster contract
contract ConvexV1BoosterAdapter is
    AbstractAdapter,
    IBooster,
    ACLTrait,
    ReentrancyGuard
{
    /// @dev CRV token
    address public immutable crv;

    /// @dev CVX token
    address public immutable minter;

    /// @dev Maps pid to a pseudo-ERC20 token that represents the staked position
    mapping(uint256 => address) public pidToPhantomToken;

    AdapterType public constant _gearboxAdapterType =
        AdapterType.CONVEX_V1_BOOSTER;
    uint16 public constant _gearboxAdapterVersion = 1;

    /// @dev Constructor
    /// @param _creditManager Address Credit manager
    /// @param _booster Address of Booster contract
    constructor(address _creditManager, address _booster)
        ACLTrait(
            address(
                IPoolService(ICreditManagerV2(_creditManager).poolService())
                    .addressProvider()
            )
        )
        AbstractAdapter(_creditManager, _booster)
    {
        crv = IBooster(_booster).crv(); // F: [ACVX1_B_01]
        minter = IBooster(_booster).minter(); // F: [ACVX1_B_01]
    }

    /// @dev Sends an order to deposit Curve LP tokens into Booster
    /// @param _pid The pid of the pool being deposited to
    /// @param _stake Whether to immediately stake resulting Convex LP tokens in the pool
    /// @notice '_amount' is ignored since the calldata is routed directly to the target
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function deposit(
        uint256 _pid,
        uint256,
        bool _stake
    ) external returns (bool) {
        return _deposit(_pid, _stake, msg.data, false);
    }

    /// @dev Sends an order to deposit all available Curve LP tokens into Booster
    /// @param _pid The ID of the pool being deposited to
    /// @param _stake Whether to immediately stake resulting Convex LP tokens in the pool
    /// The input token does need to be disabled, because this spends the entire balance
    function depositAll(uint256 _pid, bool _stake) external returns (bool) {
        return _deposit(_pid, _stake, msg.data, true);
    }

    /// @dev Internal implementation for deposit functions
    /// - Invokes a safe allowance fast check call to target, with passed calldata
    /// @param _pid The ID of the pool being deposited to
    /// @param _stake Whether to immediately stake resulting Convex LP tokens in the pool
    /// @param callData Data that the target contract will be called with
    /// @notice Fast check parameters:
    /// Input token: Curve LP Token
    /// Output token: Phantom token if _stake == true, otherwise Convex LP Token
    /// Input token is allowed, since the target does a transferFrom of Curve LP tokens
    function _deposit(
        uint256 _pid,
        bool _stake,
        bytes memory callData,
        bool disableTokenIn
    ) internal returns (bool) {
        PoolInfo memory pool = IBooster(targetContract).poolInfo(_pid);

        address tokenIn = pool.lptoken; // F: [ACVX1_B_02-05]
        address tokenOut = _stake ? pidToPhantomToken[_pid] : pool.token; // F: [ACVX1_B_02-05]

        _safeExecuteFastCheck(
            tokenIn,
            tokenOut,
            callData,
            true,
            disableTokenIn
        );

        return true;
    }

    /// @dev Sends an order to burn Convex LP tokens and retrieve Curve LP tokens
    /// @param _pid The ID of the pool
    /// @notice '_amount' is ignored since the unchanged calldata is routed directly to the target
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function withdraw(uint256 _pid, uint256) external returns (bool) {
        return _withdraw(_pid, msg.data, false);
    }

    /// @dev Sends an order to burn all Convex LP tokens and retrieve Curve LP tokens
    /// @param _pid The ID of the pool
    /// The input token does need to be disabled, because this spends the entire balance
    function withdrawAll(uint256 _pid) external returns (bool) {
        return _withdraw(_pid, msg.data, true);
    }

    /// @dev Internal implementation for withdraw functions
    /// - Invokes a safe allowance fast check call to target, with passed calldata
    /// @param _pid The ID of the pool for which Convex LP tokens are withdrawn
    /// @param callData Data that the target contract will be called with
    /// @notice Fast check parameters:
    /// Input token: Convex LP token
    /// Output token: Curve LP token
    /// Input token is not allowed, since the target directly burns Convex LP tokens
    function _withdraw(
        uint256 _pid,
        bytes memory callData,
        bool disableTokenIn
    ) internal returns (bool) {
        PoolInfo memory pool = IBooster(targetContract).poolInfo(_pid);

        address tokenIn = pool.token; // F: [ACVX1_B_06-07]
        address tokenOut = pool.lptoken; // F: [ACVX1_B_06-07]

        _safeExecuteFastCheck(
            tokenIn,
            tokenOut,
            callData,
            false,
            disableTokenIn
        );

        return true;
    }

    //
    // GETTERS
    //

    /// @dev Returns a struct with parameters of a particular pool
    /// @param i The ID of the pool
    function poolInfo(uint256 i) external view returns (PoolInfo memory) {
        return IBooster(targetContract).poolInfo(i); // F: [ACVX1_B_08]
    }

    /// @dev Returns the total number of pools
    function poolLength() external view returns (uint256) {
        return IBooster(targetContract).poolLength(); // F: [ACVX1_B_08]
    }

    /// @dev Returns the Convex helper contract that facilitates staking into Curve
    function staker() external view returns (address) {
        return IBooster(targetContract).staker(); // F: [ACVX1_B_08]
    }

    /// @dev Returns the Curve registry
    function registry() external view returns (address) {
        return IBooster(targetContract).registry();
    }

    /// @dev Returns the CVX staking pool
    function stakerRewards() external view returns (address) {
        return IBooster(targetContract).stakerRewards();
    }

    /// @dev Returns the cvxCRV staking pool
    function lockRewards() external view returns (address) {
        return IBooster(targetContract).lockRewards();
    }

    /// @dev Retrusn the cvxCRV extra reward pool (3CRV)
    function lockFees() external view returns (address) {
        return IBooster(targetContract).lockFees();
    }

    ///
    /// CONFIGURATION
    ///

    /// @dev Updates the mapping of pool IDs to phantom tokens
    /// - Iterates through all known adapters
    /// - If an adapter is a BaseRewardPool adapter, gets the pid and the phantom token address,
    /// and adds them to the mapping
    /// @notice This is needed in order to determine the tokenOut when
    /// the user deposits with staking
    function updateStakedPhantomTokensMap() external configuratorOnly {
        ICreditConfigurator cc = ICreditConfigurator(
            creditManager.creditConfigurator()
        );

        address[] memory allowedContracts = cc.allowedContracts();
        uint256 len = allowedContracts.length;

        for (uint256 i = 0; i < len; ) {
            address allowedContract = allowedContracts[i];

            address adapter = creditManager.contractToAdapter(allowedContract);
            AdapterType aType = IAdapter(adapter)._gearboxAdapterType();

            if (aType == AdapterType.CONVEX_V1_BASE_REWARD_POOL) {
                uint256 pid = IConvexV1BaseRewardPoolAdapter(adapter).pid();
                pidToPhantomToken[pid] = IConvexV1BaseRewardPoolAdapter(adapter)
                    .stakedPhantomToken();
            }

            unchecked {
                ++i;
            }
        }
    }
}