// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "./OnChainStaking.Library.sol";
import "../common/OnChOwnableWithWhitelist.sol";

contract OnChainStakingPool is OnChOwnableWithWhitelist {
    mapping(address => uint256) internal _stakes;

    string _name;
    address public tokenAddress;
    uint public stakingStarts;
    uint public stakingEnds;
    uint public withdrawStarts;
    uint public withdrawEnds;
    uint public stakingCap;
    OnChainStakingLib.OnChainStakingState public stakeState;
    uint constant LIB_VERSION = 1002;

    /**
     * Fixed periods. For an open ended contract use end dates from very distant future.
     */
    constructor (
        string memory name_,
        address tokenAddress_,
        uint stakingStarts_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint withdrawEnds_,
        uint256 stakingCap_
    ) {

        require(OnChainStakingLib.VERSION() == LIB_VERSION, "Bad linked library version");

        _name = name_;

        require(tokenAddress_ != address(0), "OnChainStakingPool: Missing token address");
        tokenAddress = tokenAddress_;

        require(stakingStarts_ > 0, "OnChainStakingPool: zero staking start time");
        if (stakingStarts_ < block.timestamp) {
            stakingStarts = block.timestamp;
        } else {
            stakingStarts = stakingStarts_;
        }

        require(stakingEnds_ >= stakingStarts, "OnChainStakingPool: staking end must be after staking starts");
        stakingEnds = stakingEnds_;

        require(withdrawStarts_ >= stakingEnds, "OnChainStakingPool: withdrawStarts must be after staking ends");
        withdrawStarts = withdrawStarts_;

        require(withdrawEnds_ >= withdrawStarts, "OnChainStakingPool: withdrawEnds must be after withdraw starts");
        withdrawEnds = withdrawEnds_;

        require(stakingCap_ >= 0, "OnChainStakingPool: stakingCap cannot be negative");
        stakingCap = stakingCap_;
    }

    function setStakingStarts(uint stakingStarts_)
    internal {
        stakingStarts = stakingStarts_;
    }

    function setStakingEnds(uint stakingEnds_)
    internal whitelistedOnly {
        stakingEnds = stakingEnds_;
    }

    function setWithdrawStarts(uint withdrawStarts_)
    internal whitelistedOnly {
        withdrawStarts = withdrawStarts_;
    }

    function setWithdrawEnds(uint withdrawEnds_)
    internal whitelistedOnly {
        withdrawEnds = withdrawEnds_;
    }

    function setStakingCap(uint stakingCap_)
    internal whitelistedOnly {
        stakingCap = stakingCap_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function stakedTotal() external view returns (uint256) {
        return stakeState.stakedTotal;
    }

    function stakedBalance() public view returns (uint256) {
        return stakeState.stakedBalance;
    }

    function stakeOf(address account) external view returns (uint256) {
        return stakeState._stakes[account];
    }

    function stakeFor(address staker, uint256 amount)
    external
    returns (bool) {
        return _stake(msg.sender, staker, amount);
    }

    function stakeForMultiple(address[] calldata stakers, uint256[] calldata amounts)
    external
    returns (bool) {
        for (uint256 i = 0; i < stakers.length; i++)
            _stake(msg.sender, stakers[i], amounts[i]);
        return true;
    }

    /**
    * Requirements:
    * - `amount` Amount to be staked
    */
    function stake(uint256 amount)
    external
    returns (bool) {
        address from = msg.sender;
        return _stake(from, from, amount);
    }

    function _stake(address payer, address staker, uint256 amount) internal virtual returns (bool) {
        return OnChainStakingLib.stake(payer, staker, amount,
            stakingStarts, stakingEnds, stakingCap, tokenAddress,
            stakeState);
    }
}