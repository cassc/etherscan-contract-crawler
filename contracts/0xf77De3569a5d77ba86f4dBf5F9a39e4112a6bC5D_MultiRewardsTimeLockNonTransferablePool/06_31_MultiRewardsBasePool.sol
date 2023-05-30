// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IMultiRewardsBasePool.sol";
import "../interfaces/ITimeLockPool.sol";

import "./AbstractMultiRewards.sol";
import "./TokenSaver.sol";

abstract contract MultiRewardsBasePool is ERC20Votes, AbstractMultiRewards, IMultiRewardsBasePool, TokenSaver, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC20 public immutable depositToken;
    
    address[] public rewardTokens;
    mapping(address => bool) public rewardTokensList;
    mapping(address => address) public escrowPools;
    mapping(address => uint256) public escrowPortions; // how much is escrowed 1e18 == 100%
    mapping(address => uint256) public escrowDurations; // escrow duration in seconds

    event RewardsClaimed(address indexed _reward, address indexed _from, address indexed _receiver, uint256 _escrowedAmount, uint256 _nonEscrowedAmount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address[] memory _rewardTokens,
        address[] memory _escrowPools,
        uint256[] memory _escrowPortions,
        uint256[] memory _escrowDurations
    ) ERC20Permit(_name) ERC20(_name, _symbol) AbstractMultiRewards(balanceOf, totalSupply) {
        require(_depositToken != address(0), "MultiRewardsBasePool.constructor: Deposit token must be set");
        require(_rewardTokens.length == _escrowPools.length, "MultiRewardsBasePool.constructor: reward tokens and escrow pools length mismatch");
        require(_rewardTokens.length == _escrowPortions.length, "MultiRewardsBasePool.constructor: reward tokens and escrow portions length mismatch");
        require(_rewardTokens.length == _escrowDurations.length, "MultiRewardsBasePool.constructor: reward tokens and escrow durations length mismatch");

        depositToken = IERC20(_depositToken);

        for (uint i=0; i<_rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            require(rewardToken != address(0), "MultiRewardsBasePool.constructor: reward token cannot be zero address");

            address escrowPool = _escrowPools[i];

            uint256 escrowPortion = _escrowPortions[i];
            require(escrowPortion <= 1e18, "MultiRewardsBasePool.constructor: Cannot escrow more than 100%");

            uint256 escrowDuration = _escrowDurations[i];

            if (!rewardTokensList[rewardToken]) {
                rewardTokensList[rewardToken] = true;
                rewardTokens.push(rewardToken);
                escrowPools[rewardToken] = escrowPool;
                escrowPortions[rewardToken] = escrowPortion;
                escrowDurations[rewardToken] = escrowDuration;

                if(rewardToken != address(0) && escrowPool != address(0)) {
                    IERC20(rewardToken).safeApprove(escrowPool, type(uint256).max);
                }
            }
        }

        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    /// @dev A modifier which checks that the caller has the admin role.
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "MultiRewardsBasePool: only admin");
        _;
    }

    function _mint(address _account, uint256 _amount) internal virtual override {
		super._mint(_account, _amount);
        for (uint i=0; i<rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            _correctPoints(reward, _account, -(_amount.toInt256()));
        }
        
	}
	
	function _burn(address _account, uint256 _amount) internal virtual override {
		super._burn(_account, _amount);
        for (uint i=0; i<rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            _correctPoints(reward, _account, _amount.toInt256());
        }
	}

    function _transfer(address _from, address _to, uint256 _value) internal virtual override {
		super._transfer(_from, _to, _value);
        for (uint i=0; i<rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            _correctPointsForTransfer(reward, _from, _to, _value);
        }
	}

    function rewardTokensLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    function addRewardToken(
        address _reward, 
        address _escrowPool, 
        uint256 _escrowPortion, 
        uint256 _escrowDuration) 
        external onlyAdmin 
    {
        require(_reward != address(0), "MultiRewardsBasePool.addRewardToken: reward token cannot be zero address");
        require(_escrowPortion <= 1e18, "MultiRewardsBasePool.addRewardToken: Cannot escrow more than 100%");

        if (!rewardTokensList[_reward]) {
            rewardTokensList[_reward] = true;
            rewardTokens.push(_reward);
            escrowPools[_reward] = _escrowPool;
            escrowPortions[_reward] = _escrowPortion;
            escrowDurations[_reward] = _escrowDuration;

            if(_reward != address(0) && _escrowPool != address(0)) {
                IERC20(_reward).safeApprove(_escrowPool, type(uint256).max);
            }
        }
    }

    function distributeRewards(address _reward, uint256 _amount) external override nonReentrant {
        IERC20(_reward).safeTransferFrom(_msgSender(), address(this), _amount);
        _distributeRewards(_reward, _amount);
    }

    function claimRewards(address _reward, address _receiver) public {
        uint256 rewardAmount = _prepareCollect(_reward, _msgSender());
        uint256 escrowedRewardAmount = rewardAmount * escrowPortions[_reward] / 1e18;
        uint256 nonEscrowedRewardAmount = rewardAmount - escrowedRewardAmount;

        ITimeLockPool escrowPool = ITimeLockPool(escrowPools[_reward]);
        if(escrowedRewardAmount != 0 && address(escrowPool) != address(0)) {
            escrowPool.deposit(escrowedRewardAmount, escrowDurations[_reward], _receiver);
        }

        // ignore dust
        if(nonEscrowedRewardAmount > 1) {
            IERC20(_reward).safeTransfer(_receiver, nonEscrowedRewardAmount);
        }

        emit RewardsClaimed(_reward, _msgSender(), _receiver, escrowedRewardAmount, nonEscrowedRewardAmount);
    }
    
    function claimAll(address _receiver) external {
        for (uint i=0; i<rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            claimRewards(reward, _receiver);
        }
    }
}