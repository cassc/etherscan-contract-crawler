// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IFestaked.sol";
import "./Festaked.Library.sol";

/**
 * A staking contract distributes rewards.
 * One can create several TraditionalFestaking over one
 * staking and give different rewards for a single
 * staking contract.
 */
contract FestakedOptimized is IFestaked {
    mapping (address => uint256) internal _stakes;

    string private _name;
    address  public override tokenAddress;
    uint public override stakingStarts;
    uint public override stakingEnds;
    uint public withdrawStarts;
    uint public withdrawEnds;
    uint public stakingCap;
    FestakedLib.FestakeState public stakeState;
    uint constant LIB_VERSION = 1001;

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
        uint256 stakingCap_) public {
        require(FestakedLib.VERSION() == LIB_VERSION, "Bad linked library version");
        _name = name_;
        require(tokenAddress_ != address(0), "Festaking: 0 address");
        tokenAddress = tokenAddress_;

        require(stakingStarts_ > 0, "Festaking: zero staking start time");
        if (stakingStarts_ < now) {
            stakingStarts = now;
        } else {
            stakingStarts = stakingStarts_;
        }

        require(stakingEnds_ >= stakingStarts, "Festaking: staking end must be after staking starts");
        stakingEnds = stakingEnds_;

        require(withdrawStarts_ >= stakingEnds, "Festaking: withdrawStarts must be after staking ends");
        withdrawStarts = withdrawStarts_;

        require(withdrawEnds_ >= withdrawStarts, "Festaking: withdrawEnds must be after withdraw starts");
        withdrawEnds = withdrawEnds_;

        require(stakingCap_ >= 0, "Festaking: stakingCap cannot be negative");
        stakingCap = stakingCap_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function stakedTotal() external override view returns (uint256) {
        return stakeState.stakedTotal;
    }

    function stakedBalance() public override view returns (uint256) {
        return stakeState.stakedBalance;
    }

    function stakeOf(address account) external override view returns (uint256) {
        return stakeState._stakes[account];
    }

    function stakeFor(address staker, uint256 amount)
    external
    override
    returns (bool) {
        return _stake(msg.sender, staker, amount);
    }

    /**
    * Requirements:
    * - `amount` Amount to be staked
    */
    function stake(uint256 amount)
    external
    override
    returns (bool) {
        address from = msg.sender;
        return _stake(from, from, amount);
    }

    function _stake(address payer, address staker, uint256 amount) internal virtual returns (bool) {
        return FestakedLib.stake(payer, staker, amount,
            stakingStarts, stakingEnds, stakingCap, tokenAddress,
            stakeState);
    }
}