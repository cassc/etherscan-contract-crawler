// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interface IVotingEscrow {

//     struct Point {
//         int128 bias;
//         int128 slope; // # -dweight / dt
//         uint256 ts;
//         uint256 blk; // block
//     }

//     function token() external view returns (address);
//     function team() external returns (address);
//     function epoch() external view returns (uint);
//     function point_history(uint loc) external view returns (Point memory);
//     function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
//     function user_point_epoch(uint tokenId) external view returns (uint);

//     function ownerOf(uint) external view returns (address);
//     function isApprovedOrOwner(address, uint) external view returns (bool);
//     function transferFrom(address, address, uint) external;

//     function voting(uint tokenId) external;
//     function abstain(uint tokenId) external;
//     function attach(uint tokenId) external;
//     function detach(uint tokenId) external;

//     function checkpoint() external;
//     function deposit_for(uint tokenId, uint value) external;
//     function create_lock_for(uint, uint, address) external returns (uint);

//     function balanceOfNFT(uint) external view returns (uint);
//     function totalSupply() external view returns (uint);
// }

// interface IVoter {
//     function _ve() external view returns (address);
//     function governor() external view returns (address);
//     function emergencyCouncil() external view returns (address);
//     function attachTokenToGauge(uint _tokenId, address account) external;
//     function detachTokenFromGauge(uint _tokenId, address account) external;
//     function emitDeposit(uint _tokenId, address account, uint amount) external;
//     function emitWithdraw(uint _tokenId, address account, uint amount) external;
//     function isWhitelisted(address token) external view returns (bool);
//     function notifyRewardAmount(uint amount) external;
//     function distribute(address _gauge) external;
// }

// interface IPair {
//     function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
//     function claimFees() external returns (uint, uint);
//     function tokens() external returns (address, address);
//     function transferFrom(address src, address dst, uint amount) external returns (bool);
//     function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
//     function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
//     function burn(address to) external returns (uint amount0, uint amount1);
//     function mint(address to) external returns (uint liquidity);
//     function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
//     function getAmountOut(uint, address) external view returns (uint);
// }

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function claimFees() external returns (uint claimed0, uint claimed1);
    function left(address token) external view returns (uint);
    function isForPair() external view returns (bool);
}
// interface IERC20 {
//     function totalSupply() external view returns (uint256);
//     function transfer(address recipient, uint amount) external returns (bool);
//     function decimals() external view returns (uint8);
//     function symbol() external view returns (string memory);
//     function balanceOf(address) external view returns (uint);
//     function transferFrom(address sender, address recipient, uint amount) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint);
//     function approve(address spender, uint value) external returns (bool);

//     event Transfer(address indexed from, address indexed to, uint value);
//     event Approval(address indexed owner, address indexed spender, uint value);
// }

// interface IBribe {
//     function _deposit(uint amount, uint tokenId) external;
//     function _withdraw(uint amount, uint tokenId) external;
//     function getRewardForOwner(uint tokenId, address[] memory tokens) external;
//     function notifyRewardAmount(address token, uint amount) external;
//     function left(address token) external view returns (uint);
// }

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
interface ITHEGauge is IGauge{

    /// STATE VARIABLES ///

    // the LP token that needs to be staked for rewards
    function TOKEN() external view returns (address);
    // the ve token used for gauges
    function _ve() external view returns (address);
    function internal_bribe() external view returns (address);
    function external_bribe() external view returns (address);
    function voter() external view returns (address);
    function derivedSupply() external view returns (uint256);
    function derivedBalances(address) external view returns (uint256);
    function isForPair() external view returns (bool);
    // default snx staking contract implementation
    function rewardRate(address) external view returns (uint256);
    function periodFinish(address) external view returns (uint256);
    function lastUpdateTime(address) external view returns (uint256);
    function rewardPerTokenStored(address) external view returns (uint256);
    function lastEarn(address, address) external view returns (uint256);
    function userRewardPerTokenStored(address, address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function rewards(uint256) external view returns (address);
    function isReward(address) external view returns (bool);
    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint256 timestamp;
        uint256 balanceOf;
    }
    /// @notice A checkpoint for marking reward rate
    struct RewardPerTokenCheckpoint {
        uint256 timestamp;
        uint256 rewardPerToken;
    }
    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint256 timestamp;
        uint256 supply;
    }
    function checkpoints(address, uint256) external view returns (Checkpoint memory);
    function numCheckpoints(address) external view returns (uint256);
    function supplyCheckpoints(uint256) external view returns (SupplyCheckpoint memory);
    function supplyNumCheckpoints() external view returns (uint256);
    function rewardPerTokenCheckpoints(address, uint256) external view returns (RewardPerTokenCheckpoint memory);
    function rewardPerTokenNumCheckpoints(address) external view returns (uint256);
    function fees0() external view returns (uint256);
    function fees1() external view returns (uint256);

    /// FUNCTIONS ///
    function claimFees() external returns (uint256 claimed0, uint256 claimed1);
    /**
    * @notice Determine the prior balance for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param timestamp The timestamp to get the balance at
    * @return The balance the account had as of the given block
    */
    function getPriorBalanceIndex(address account, uint256 timestamp) external view returns (uint256);
    function getPriorSupplyIndex(uint256 timestamp) external view returns (uint256);
    function getPriorRewardPerToken(address token, uint256 timestamp) external view returns (uint256, uint256);
    function rewardsListLength() external view returns (uint256);
    // returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable(address token) external view returns (uint256);
    function getReward() external;
    function rewardPerToken(address token) external view returns (uint256);
    function derivedBalance(address account) external view returns (uint256);
    function batchRewardPerToken(address token, uint256 maxRuns) external;
    /// @dev Update stored rewardPerToken values without the last one snapshot
    ///      If the contract will get "out of gas" error on users actions this will be helpful
    function batchUpdateRewardPerToken(address token, uint256 maxRuns) external;
    // earned is an estimation, it won't be exact till the supply > rewardPerToken calculations have run
    function earned(address token, address account) external view returns (uint256);
    function depositAll() external;
    function deposit(uint256 amount) external;
    function withdrawAll() external;
    function withdraw(uint256 amount) external;
    function left(address token) external view returns (uint256);
    function notifyRewardAmount(address token, uint256 amount) external;
    function swapOutRewardToken(uint256 i, address oldToken, address newToken) external;
}