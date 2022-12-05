// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "hardhat/console.sol";

interface IRewardAnimal is IERC721 {
    function mintAnimals(
        address to,
        uint256 stake_amount,
        uint256 age
    ) external;
}

contract NoahArk is Ownable, ERC721Holder {
    IERC20 public stakeToken;
    IRewardAnimal public nft;

    uint256 constant stakingTime = 180 seconds;
    uint256 constant token = 10e18;

    struct Staker {
        uint256 balance;
        uint256 lastAction;
        uint256 age;
    }

    constructor(IERC20 _stakeToken, IRewardAnimal _nft) {
        stakeToken = _stakeToken;
        nft = _nft;
    }

    /// @notice mapping of a staker to its wallet
    mapping(address => Staker) public stakers;

    /// @notice event emitted when a user has staked

    event Staked(address owner, uint256 amount);

    /// @notice event emitted when a user has unstaked
    event Unstaked(address owner);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user);

    function getStakedTokens(
        address _user
    ) public view returns (uint256 balance) {
        return stakers[_user].balance;
    }

    function stake(uint256 _amount) public {
        _stake(msg.sender, _amount);
    }

    function _stake(address _user, uint256 _amount) internal {
        require(stakers[_user].balance == 0, "already staked");
        Staker storage staker = stakers[_user];

        stakeToken.transferFrom(_user, address(this), _amount);
        staker.lastAction = block.timestamp;
        staker.balance += _amount;

        emit Staked(_user, _amount);
    }

    /**
     * Claim reward and unstake.
     */
    function unstake() public {
        _claimReward(msg.sender);
        _unstake(msg.sender);
    }

    /**
     * Emergency unstake without claiming reward.
     */
    function emergencyUnstake() public {
        _unstake(msg.sender);
    }

    function _claimReward(address _user) internal {
        require(stakers[_user].balance > 0, "0 rewards yet");

        Staker storage staker = stakers[_user];

        nft.mintAnimals(
            _user,
            stakers[_user].balance,
            block.timestamp - staker.lastAction
        );
        staker.lastAction = block.timestamp;

        emit RewardPaid(_user);
    }

    function _unstake(address _user) internal {
        Staker storage staker = stakers[_user];
        delete stakers[_user];
        stakeToken.transferFrom(address(this), _user, staker.balance);

        emit Unstaked(_user);
    }
}