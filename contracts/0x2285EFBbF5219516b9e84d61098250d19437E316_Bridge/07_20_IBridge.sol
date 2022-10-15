// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {ILendingPool} from "./ILendingPool.sol";

interface IBridge {
    struct ATokenData {
        uint256 l2TokenAddress;
        IERC20 underlyingAsset;
        ILendingPool lendingPool;
        uint256 ceiling;
    }

    event Deposit(
        address indexed sender,
        address indexed token,
        uint256 indexed amount,
        uint256 l2Recipient,
        uint256 blockNumber,
        uint256 rewardsIndex,
        uint256 l2MsgNonce
    );
    event Withdrawal(
        address indexed token,
        uint256 l2sender,
        address indexed recipient,
        uint256 indexed amount
    );
    event RewardsTransferred(
        uint256 l2sender,
        address recipient,
        uint256 amount
    );
    event ApprovedBridge(address l1Token, uint256 l2Token, uint256 ceiling);
    event L2StateUpdated(address indexed l1Token, uint256 rewardsIndex);

    event StartedDepositCancellation(
        uint256 indexed l2Recipient,
        uint256 rewardsIndex,
        uint256 blockNumber,
        uint256 amount,
        uint256 nonce
    );
    event CancelledDeposit(
        uint256 indexed l2Recipient,
        address l1Recipient,
        uint256 rewardsIndex,
        uint256 blockNumber,
        uint256 amount,
        uint256 nonce
    );

    /**
     * @notice allows deposits of aTokens or their underlying assets on L2
     * @param l1AToken aToken address
     * @param l2Recipient recipient address
     * @param amount to be minted on l2
     * @param referralCode of asset
     * @param fromUnderlyingAsset if set to true will accept deposit from underlying assets
     **/
    function deposit(
        address l1AToken,
        uint256 l2Recipient,
        uint256 amount,
        uint16 referralCode,
        bool fromUnderlyingAsset
    ) external returns (uint256);

    /**
     * @notice allows withdraw of aTokens or their underlying assets from L2
     * @param l1AToken aToken address
     * @param l2sender sender address
     * @param recipient on l1
     * @param staticAmount amount to be withdraw
     * @param toUnderlyingAsset if set to 1 will withdraw underlying asset tokens from pool and transfer them to recipient
     **/
    function withdraw(
        address l1AToken,
        uint256 l2sender,
        address recipient,
        uint256 staticAmount,
        uint256 l2RewardsIndex,
        bool toUnderlyingAsset
    ) external;

    /**
     * @notice Returns bridge's available rewards
     * @dev Function is invoked before consuming L2->L1 message to ensure bridge has enough rewards
     * @return Rewards currently available on the bridge: claimed rewards + pending rewards
     **/
    function getAvailableRewards() external returns (uint256);

    /**
     * @notice allows l1 user to receive the bridged rewards tokens from l2
     * @param l2sender sender on l2
     * @param recipient on l1
     * @param amount of tokens to be claimed to user on l1
     **/
    function receiveRewards(
        uint256 l2sender,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice updates the rewards index of tokens on l2
     * @param l1AToken aToken address
     **/
    function updateL2State(address l1AToken) external;
}