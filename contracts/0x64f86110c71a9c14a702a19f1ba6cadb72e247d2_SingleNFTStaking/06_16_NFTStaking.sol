// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./StructDeclaration.sol";
interface INFTStakingFactory {
    function owner() external view returns (address);
    function getAdminFeePercent() external view returns (uint256);
    function getAdminFeeAddress() external view returns (address);
}

contract NFTStaking is ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public factory;

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant YEAR_TIMESTAMP = 31536000;

    /** Staking NFT address */
    InitializeParam public stakingParams;

    /** apr reward per timestamp */
    uint256 public _rewardPerTimestamp;
    /** total staked NFTs*/
    uint256 public _totalStakedNfts;

    

    event StartTimeUpdated(uint256 _timestamp);
    event EndTimeUpdated(uint256 _timestamp);
    event RewardTokenUpdated(address newTokenAddress);
    event StakeNftPriceUpdated(uint256 newValue);
    event AprUpdated(uint256 newValue);
    event MaxStakedNftsUpdated(uint256 newValue);
    event MaxNftsPerUserUpdated(uint256 newValue);
    event DepositFeePerNftUpdated(uint256 newValue);
    event WithdrawFeePerNftUpdated(uint256 newValue);

    event Staked(address indexed account, uint256 tokenId, uint256 amount);
    event Withdrawn(address indexed account, uint256 tokenId, uint256 amount);
    event Harvested(address indexed account, uint256 amount);

    function getDepositTokenAmount(
        uint256 stakeNftPrice_,
        uint256 maxStakedNfts_,
        uint256 apr_,
        uint256 period_
    ) internal pure returns (uint256) {
        uint256 depositTokenAmount = stakeNftPrice_
            .mul(maxStakedNfts_)
            .mul(apr_)
            .mul(period_)
            .div(YEAR_TIMESTAMP)
            .div(PERCENTS_DIVIDER);
        return depositTokenAmount;
    }

    function initialize(
        InitializeParam memory _param
    ) public initializer {
        factory = msg.sender;
        stakingParams = _param;

        _rewardPerTimestamp = _param.apr
            .mul(_param.stakeNftPrice)
            .div(PERCENTS_DIVIDER)
            .div(YEAR_TIMESTAMP);
    }

    /**
     * @dev Update start block timestamp
     * Only factory owner has privilege to call this function
     */
    function updateStartTimestamp(uint256 startTimestamp_)
        external        
        onlyFactoryOwner
    {
        require(
            startTimestamp_ <= stakingParams.endTime,
            "Start block must be before end time"
        );
        require(
            startTimestamp_ > block.timestamp,
            "Start block must be after current block"
        );
        require(stakingParams.startTime > block.timestamp, "Staking started already");
        require(stakingParams.startTime != startTimestamp_, "same timestamp");

        stakingParams.startTime = startTimestamp_;
        emit StartTimeUpdated(startTimestamp_);
    }

    /**
     * @dev Update end block timestamp
     * Only factory owner has privilege to call this function
     */
    function updateEndTimestamp(uint256 endTimestamp_)
        external        
        onlyFactoryOwner
    {
        require(
            endTimestamp_ >= stakingParams.startTime,
            "End block must be after start block"
        );
        require(
            endTimestamp_ > block.timestamp,
            "End block must be after current block"
        );
        require(endTimestamp_ != stakingParams.endTime, "same timestamp");

        stakingParams.endTime = endTimestamp_;
        emit EndTimeUpdated(endTimestamp_);
    }

    /**
     * @dev Update reward token address
     * Only factory owner has privilege to call this function
     */
    function updateRewardTokenAddress(address rewardTokenAddress_)
        external        
        onlyFactoryOwner
    {
        require(
            stakingParams.rewardTokenAddress != rewardTokenAddress_,
            "same token address"
        );
        require(stakingParams.startTime > block.timestamp, "Staking started already");
        
        stakingParams.rewardTokenAddress = rewardTokenAddress_;
        emit RewardTokenUpdated(rewardTokenAddress_);
    }

    /**
     * @dev Update nft price
     * Only factory owner has privilege to call this function
     */
    function updateStakeNftPrice(uint256 stakeNftPrice_)
        external        
        onlyFactoryOwner
    {
        require(stakingParams.stakeNftPrice != stakeNftPrice_, "same nft price");
        require(stakingParams.startTime > block.timestamp, "Staking started already");

        stakingParams.stakeNftPrice = stakeNftPrice_;
        _rewardPerTimestamp = stakingParams.apr
            .mul(stakeNftPrice_)
            .div(PERCENTS_DIVIDER)
            .div(YEAR_TIMESTAMP);
        emit StakeNftPriceUpdated(stakeNftPrice_);
    }

    /**
     * @dev Update apr value
     * Only factory owner has privilege to call this function
     */
    function updateApr(uint256 apr_) external onlyFactoryOwner {
        require(stakingParams.apr != apr_, "same apr");
        require(stakingParams.startTime > block.timestamp, "Staking started already");

        stakingParams.apr = apr_;
        _rewardPerTimestamp = apr_
            .mul(stakingParams.stakeNftPrice)
            .div(PERCENTS_DIVIDER)
            .div(YEAR_TIMESTAMP);
        emit AprUpdated(apr_);
    }

    /**
     * @dev Update maxStakedNfts value
     * Only factory owner has privilege to call this function
     */
    function updateMaxStakedNfts(uint256 maxStakedNfts_)
        external        
        onlyFactoryOwner
    {
        require(stakingParams.maxStakedNfts != maxStakedNfts_, "same maxStakedNfts");
        require(stakingParams.startTime > block.timestamp, "Staking started already");

        emit MaxStakedNftsUpdated(maxStakedNfts_);
    }

    /**
     * @dev Update maxNftsPerUser value
     * Only factory owner has privilege to call this function
     */
    function updateMaxNftsPerUser(uint256 maxNftsPerUser_)
        external        
        onlyFactoryOwner
    {
        stakingParams.maxNftsPerUser = maxNftsPerUser_;
        emit MaxNftsPerUserUpdated(maxNftsPerUser_);
    }

    /**
     * @dev Update depositFeePerNft value
     * Only factory owner has privilege to call this function
     */
    function updateDepositFeePerNft(uint256 depositFeePerNft_)
        external        
        onlyFactoryOwner
    {
        stakingParams.depositFeePerNft = depositFeePerNft_;
        emit DepositFeePerNftUpdated(depositFeePerNft_);
    }

    /**
     * @dev Update withdrawFeePerNft value
     * Only factory owner has privilege to call this function
     */
    function updateWithdrawFeePerNft(uint256 withdrawFeePerNft_)
        external        
        onlyFactoryOwner
    {
        stakingParams.withdrawFeePerNft = withdrawFeePerNft_;
        emit WithdrawFeePerNftUpdated(withdrawFeePerNft_);
    }

    /**
     * @dev Safe transfer reward to the receiver
     */
    function safeRewardTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        require(_to != address(0), "Invalid null address");
        if (stakingParams.rewardTokenAddress == address(0x0)) {
            uint256 balance = address(this).balance;
            if (_amount == 0 || balance == 0) {
                return 0;
            }
            if (_amount > balance) {
                _amount = balance;
            }
            (bool result, ) = payable(_to).call{value: _amount}("");
        	require(result, "Failed to transfer coin");

            return _amount;
        } else {
            uint256 tokenBalance = IERC20Upgradeable(stakingParams.rewardTokenAddress).balanceOf(
                address(this)
            );
            if (_amount == 0 || tokenBalance == 0) {
                return 0;
            }
            if (_amount > tokenBalance) {
                _amount = tokenBalance;
            }
            IERC20Upgradeable(stakingParams.rewardTokenAddress).safeTransfer(_to, _amount);
            return _amount;
        }
    }

    /**
     * @notice Pause / Unpause staking
     */
    function pause(bool flag_) public onlyFactoryOwner {
        if (flag_) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address token_, uint256 amount_)
        external
        onlyFactoryOwner
    {
        if (token_ == address(0x0)) {
            (bool result, ) = payable(stakingParams.creatorAddress).call{value: amount_}("");
        	require(result, "Failed to recover coin");
        } else {
            IERC20Upgradeable(token_).safeTransfer(stakingParams.creatorAddress, amount_);
        }
    }

    function withdrawBNB() external onlyFactoryOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "insufficient balance");  
        (bool result, ) = payable(msg.sender).call{value: balance}("");
        require(result, "Failed to withdraw balance");     
    }

    /**
     * @dev Require _msgSender() to be the creator of the token id
     */
    modifier onlyFactoryOwner() {
        address factoryOwner = INFTStakingFactory(factory).owner();
        require(
            factoryOwner == _msgSender(),
            "caller is not the factory owner"
        );
        _;
    }

    /**
     * @dev To receive ETH
     */
    receive() external payable {}
}