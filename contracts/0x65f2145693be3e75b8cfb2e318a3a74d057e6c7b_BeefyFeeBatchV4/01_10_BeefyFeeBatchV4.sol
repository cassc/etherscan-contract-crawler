// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { IBeefySwapper } from "../interfaces/beefy/IBeefySwapper.sol";
import { IBeefyRewardPool } from "../interfaces/beefy/IBeefyRewardPool.sol";

/// @title Beefy fee batch
/// @author kexley, Beefy
/// @notice All Beefy fees will flow through to the treasury and the reward pool
/// @dev Wrapped ETH will build up on this contract and will be swapped via the Beefy Swapper to
/// the pre-specified tokens and distributed to the treasury and reward pool
contract BeefyFeeBatchV4 is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Bundled token information
    /// @param tokens Token addresses to swap to
    /// @param index Location of a token in the tokens array
    /// @param allocPoint Allocation points for this token
    /// @param totalAllocPoint Total amount of allocation points assigned to tokens in the array
    struct TokenInfo {
        address[] tokens;
        mapping(address => uint256) index;
        mapping(address => uint256) allocPoint;
        uint256 totalAllocPoint;
    }

    /// @notice Treasury address
    address public treasury;

    /// @notice Reward pool address
    address public rewardPool;

    /// @notice Swapper address to swap all tokens at
    address public swapper;

    /// @notice Treasury fee of the total native received on the contract (1 = 0.1%)
    uint256 public treasuryFee;

    /// @notice Duration of reward distributions
    uint256 public duration;

    /// @notice Tokens sent to this contract as fees
    address[] public feeTokens;

    /// @dev Tokens to be sent to the treasury
    TokenInfo private _treasuryTokens;

    /// @dev Tokens to be sent to the reward pool
    TokenInfo private _rewardTokens;

    /// @dev Denominator constant
    uint256 constant private DIVISOR = 1000;

    /// @notice Fees have been harvested
    /// @param feeToken Address of the fee token
    /// @param totalHarvested Total fee amount that has been processed
    event Harvest(address feeToken, uint256 totalHarvested);
    /// @notice Treasury fee that has been sent
    /// @param token Token that has been sent
    /// @param amount Amount of the token sent
    event DistributeTreasuryFee(address indexed token, uint256 amount);
    /// @notice Reward pool has been notified
    /// @param token Token used as a reward
    /// @param amount Amount of the token used
    /// @param duration Duration of the distribution
    event NotifyRewardPool(address indexed token, uint256 amount, uint256 duration);
    /// @notice Set fee tokens
    /// @param tokens Addresses of tokens to be received as fees
    event SetFeeTokens(address[] tokens);
    /// @notice Reward pool set
    /// @param rewardPool New reward pool address
    event SetRewardPool(address rewardPool);
    /// @notice Treasury set
    /// @param treasury New treasury address
    event SetTreasury(address treasury);
    /// @notice Swapper set
    /// @param swapper New swapper address
    event SetSwapper(address swapper);
    /// @notice Treasury fee set
    /// @param fee New fee split for the treasury
    event SetTreasuryFee(uint256 fee);
    /// @notice Reward pool duration set
    /// @param duration New duration of the reward distribution
    event SetDuration(uint256 duration);
    /// @notice Rescue an unsupported token
    /// @param token Address of the token
    /// @param recipient Address to send the token to
    event RescueTokens(address token, address recipient);

    /// @notice Initialize the contract, callable only once
    /// @param _rewardPool Reward pool address
    /// @param _treasury Treasury address
    /// @param _swapper Swapper address
    /// @param _treasuryFee Treasury fee split
    function initialize(
        address _rewardPool,
        address _treasury,
        address _swapper,
        uint256 _treasuryFee 
    ) external initializer {
        __Ownable_init();

        treasury = _treasury;
        rewardPool = _rewardPool;
        treasuryFee = _treasuryFee;
        swapper = _swapper;
        duration = 7 days;
    }

    /// @notice Distribute the fees to the treasury and reward pool
    function harvest() external {
        uint256 feeTokenLength = feeTokens.length;
        for (uint i; i < feeTokenLength;) {
            address feeToken = feeTokens[i];
            uint256 fees = IERC20Upgradeable(feeToken).balanceOf(address(this));
            emit Harvest(feeToken, fees);
            unchecked { ++i; }
        }

        _distribute(true);
        _distribute(false);
    }

    /// @dev Distribute the fees to the treasury or the reward pool
    /// @param _isTreasury Whether the fees are being distributed to the treasury or the reward pool
    function _distribute(bool _isTreasury) private {
        TokenInfo storage tokenInfo = _isTreasury ? _treasuryTokens : _rewardTokens;
        uint256 tokenLength = tokenInfo.tokens.length;
        for (uint i; i < tokenLength;) {
            address token = tokenInfo.tokens[i];
            uint256 amount;

            uint256 feeTokenLength = feeTokens.length;
            for (uint j; j < feeTokenLength;) {
                address feeToken = feeTokens[j];
                uint256 feeTokenTotal = IERC20Upgradeable(feeToken).balanceOf(address(this));
                if (feeToken == token) feeTokenTotal -= amount;

                uint256 feeAmount = feeTokenTotal
                    * tokenInfo.allocPoint[token]
                    / tokenInfo.totalAllocPoint;

                if (_isTreasury) feeAmount = feeAmount * treasuryFee / DIVISOR;

                if (feeAmount > 0) {
                    amount += feeToken == token
                        ? feeAmount
                        : IBeefySwapper(swapper).swap(feeToken, token, feeAmount);
                }

                unchecked { ++j; }
            }

            if (amount > 0) {
                if (_isTreasury) {
                    IERC20Upgradeable(token).safeTransfer(treasury, amount);
                    emit DistributeTreasuryFee(token, amount);
                } else {
                    IBeefyRewardPool(rewardPool).notifyRewardAmount(token, amount, duration);
                    emit NotifyRewardPool(token, amount, duration);
                }
            }

            unchecked { ++i; }
        }
    }

    /// @notice Information for the tokens to be sent to the treasury
    /// @param _id Index of the treasury token array
    /// @return token Address of the token
    /// @return allocPoint Allocation of the treasury fee to be sent in this token
    function treasuryTokens(uint256 _id) external view returns (address token, uint256 allocPoint) {
        token = _treasuryTokens.tokens[_id];
        allocPoint = _treasuryTokens.allocPoint[token];
    }

    /// @notice Total allocation points for the treasury tokens
    /// @return totalAllocPoint Total allocation points
    function treasuryTotalAllocPoint() external view returns (uint256 totalAllocPoint) {
        totalAllocPoint = _treasuryTokens.totalAllocPoint;
    }

    /// @notice Information for the tokens to be sent to the reward pool
    /// @param _id Index of the reward token array
    /// @return token Address of the token
    /// @return allocPoint Allocation of the rewards to be sent in this token
    function rewardTokens(uint256 _id) external view returns (address token, uint256 allocPoint) {
        token = _rewardTokens.tokens[_id];
        allocPoint = _rewardTokens.allocPoint[token];
    }

    /// @notice Total allocation points for the reward tokens
    /// @return totalAllocPoint Total allocation points
    function rewardTotalAllocPoint() external view returns (uint256 totalAllocPoint) {
        totalAllocPoint = _rewardTokens.totalAllocPoint;
    }

    /* ----------------------------------- VARIABLE SETTERS ----------------------------------- */

    /// @notice Set which tokens are sent to this contract as fees
    /// @param _feeTokens Array of fee token addresses
    function setFeeTokens(address[] calldata _feeTokens) external onlyOwner {
        for (uint i; i < feeTokens.length; ++i) {
            IERC20Upgradeable(feeTokens[i]).forceApprove(swapper, 0);
        }
        feeTokens = _feeTokens;
        for (uint i; i < _feeTokens.length; ++i) {
            IERC20Upgradeable(_feeTokens[i]).forceApprove(swapper, type(uint).max);
        }
        emit SetFeeTokens(_feeTokens);
    }

    /// @notice Adjust which tokens and how much the harvest should swap the treasury fee to
    /// @param _token Address of the token to send to the treasury
    /// @param _allocPoint How much to swap into the particular token from the treasury fee
    function setTreasuryAllocPoint(address _token, uint256 _allocPoint) external onlyOwner {
        _setAllocPoint(_treasuryTokens, _token, _allocPoint);
    }

    /// @notice Adjust which tokens and how much the harvest should swap the reward pool fee to
    /// @param _token Address of the token to send to the reward pool
    /// @param _allocPoint How much to swap into the particular token from the reward pool fee 
    function setRewardAllocPoint(address _token, uint256 _allocPoint) external onlyOwner {
        _setAllocPoint(_rewardTokens, _token, _allocPoint);
        if (_allocPoint > 0) {
            IERC20Upgradeable(_token).forceApprove(rewardPool, type(uint).max);
        } else {
            IERC20Upgradeable(_token).forceApprove(rewardPool, 0);
        }
    }

    /// @dev Adjust the allocation for treasury or rewards
    /// @param _tokenInfo Token basket to make changes to
    /// @param _token Token to change allocation for
    /// @param _allocPoint New allocation amount
    function _setAllocPoint(
        TokenInfo storage _tokenInfo,
        address _token,
        uint256 _allocPoint
    ) internal {
        if (_tokenInfo.allocPoint[_token] > 0 && _allocPoint == 0) {
            address endToken = _tokenInfo.tokens[_tokenInfo.tokens.length - 1];
            _tokenInfo.index[endToken] = _tokenInfo.index[_token];
            _tokenInfo.tokens[_tokenInfo.index[endToken]] = endToken;
            _tokenInfo.tokens.pop();
        } else if (_tokenInfo.allocPoint[_token] == 0 && _allocPoint > 0) {
            _tokenInfo.index[_token] = _tokenInfo.tokens.length;
            _tokenInfo.tokens.push(_token);
        }

        _tokenInfo.totalAllocPoint -= _tokenInfo.allocPoint[_token];
        _tokenInfo.totalAllocPoint += _allocPoint;
        _tokenInfo.allocPoint[_token] = _allocPoint;
    }

    /// @notice Set the reward pool
    /// @param _rewardPool New reward pool address
    function setRewardPool(address _rewardPool) external onlyOwner {
        address oldRewardPool = rewardPool;
        rewardPool = _rewardPool;
        for (uint i; i < _rewardTokens.tokens.length; ++i) {
            address token = _rewardTokens.tokens[i];
            IERC20Upgradeable(token).forceApprove(oldRewardPool, 0);
            IERC20Upgradeable(token).forceApprove(_rewardPool, type(uint).max);
        }
        emit SetRewardPool(_rewardPool);
    }

    /// @notice Set the treasury
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /// @notice Set the swapper
    /// @param _swapper New swapper address
    function setSwapper(address _swapper) external onlyOwner {
        address oldSwapper = swapper;
        for (uint i; i < feeTokens.length; ++i) {
            address feeToken = feeTokens[i];
            IERC20Upgradeable(feeToken).forceApprove(oldSwapper, 0);
            IERC20Upgradeable(feeToken).forceApprove(_swapper, type(uint).max);
        }
        swapper = _swapper;
        emit SetSwapper(_swapper);
    }

    /// @notice Set the treasury fee
    /// @param _treasuryFee New treasury fee split
    function setTreasuryFee(uint256 _treasuryFee) external onlyOwner {
        if (_treasuryFee > DIVISOR) _treasuryFee = DIVISOR;
        treasuryFee = _treasuryFee;
        emit SetTreasuryFee(_treasuryFee);
    }

    /// @notice Set the duration of the reward distribution
    /// @param _duration New duration of the reward distribution
    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
        emit SetDuration(_duration);
    }

    /* ------------------------------------- SWEEP TOKENS ------------------------------------- */

    /// @notice Rescue an unsupported token
    /// @param _token Address of the token
    /// @param _recipient Address to send the token to
    function rescueTokens(address _token, address _recipient) external onlyOwner {
        uint256 amount = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(_recipient, amount);
        emit RescueTokens(_token, _recipient);
    }
}