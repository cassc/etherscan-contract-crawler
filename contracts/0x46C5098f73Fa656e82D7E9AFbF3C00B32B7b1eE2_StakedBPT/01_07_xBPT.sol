// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakedBPT is ERC20("Staked BPT", "xBPT"), Ownable {
    using SafeMath for uint256;
    IERC20 public bpt;
    address public rewardDistribution;

    event Stake(address indexed staker, uint256 xbptReceived);
    event Unstake(address indexed unstaker, uint256 bptReceived);
    event RewardDistributorSet(address indexed newRewardDistributor);
    event BptFeeReceived(address indexed from, uint256 bptAmount);

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }


    // Define the bpt token contract
    constructor(IERC20 _bpt) public {
        bpt = _bpt;
    }

    function enter(uint256 _amount) public {
        // Gets the amount of bpt locked in the contract
        uint256 totalbpt = bpt.balanceOf(address(this));
        // Gets the amount of xBPT in existence
        uint256 totalShares = totalSupply();
        // If no xBPT exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalbpt == 0) {
            _mint(_msgSender(), _amount);
            emit Stake(_msgSender(), _amount);
        } 
        // Calculate and mint the amount of xBPT the bpt is worth. The ratio will change overtime, as xBPT is burned/minted and bpt deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalbpt);
            _mint(_msgSender(), what);
            emit Stake(_msgSender(), what);
        }
        // Lock the bpt in the contract
        bpt.transferFrom(_msgSender(), address(this), _amount);
    }

    function leave(uint256 _share) public {
        // Gets the amount of xBPT in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of bpt the xBPT is worth
        uint256 what = _share.mul(bpt.balanceOf(address(this))).div(totalShares);
        _burn(_msgSender(), _share);
        bpt.transfer(_msgSender(), what);
        emit Unstake(_msgSender(), what);
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
        emit RewardDistributorSet(_rewardDistribution);
    }

    function notifyRewardAmount(uint256 _balance)
        external
        onlyRewardDistribution
    {
        bpt.transferFrom(_msgSender(), address(this), _balance);
        emit BptFeeReceived(_msgSender(), _balance);
    }
}