// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {RecoverERC20} from "../libraries/RecoverERC20.sol";
import {IMFDPlus} from "../../interfaces/IMultiFeeDistribution.sol";
import {IChefIncentivesController} from "../../interfaces/IChefIncentivesController.sol";
import {IPriceProvider} from "../../interfaces/IPriceProvider.sol";
import {IEligibilityDataProvider} from "../../interfaces/IEligibilityDataProvider.sol";
import {ICompounder} from "../../interfaces/ICompounder.sol";
import {IBountyManager} from "../../interfaces/IBountyManager.sol";

/// @title BountyManager Contract
/// @author Radiant Devs
contract BountyManager is Initializable, OwnableUpgradeable, PausableUpgradeable, RecoverERC20 {
	using SafeERC20 for IERC20;

	address public rdnt;
	address public weth;
	address public mfd;
	address public chef;
	address public priceProvider;
	address public eligibilityDataProvider;
	address public compounder;
	uint256 public hunterShare;
	uint256 public baseBountyUsdTarget; // decimals 18
	uint256 public maxBaseBounty;
	uint256 public bountyCount;
	uint256 public minStakeAmount;

	/// @notice Ratio Divisor
	uint256 public constant RATIO_DIVISOR = 10000;

	/// @notice The users specified slippage value for auto-compounding will be used
	uint256 internal constant DEFAULT_USERS_SLIPPAGE = 0;

	// Array of available Bounty functions to run. See _getMfdBounty, _getChefBounty, etc.
	mapping(uint256 => function(address, bool) returns (address, uint256, bool)) private bounties;

	mapping(address => bool) public whitelist;
	bool public whitelistActive;

	modifier isWhitelisted() {
		if (whitelistActive) {
			if (!whitelist[msg.sender] && msg.sender != address(this)) revert NotWhitelisted();
		}
		_;
	}

	event MinStakeAmountUpdated(uint256 indexed _minStakeAmount);
	event BaseBountyUsdTargetUpdated(uint256 indexed _newVal);
	event HunterShareUpdated(uint256 indexed _newVal);
	event MaxBaseBountyUpdated(uint256 indexed _newVal);
	event BountiesSet();
	event BountyReserveEmpty(uint256 indexed _bal);
	event WhitelistUpdated(address indexed _user, bool indexed _isActive);
	event WhitelistActiveChanged(bool indexed isActive);

	error AddressZero();
	error InvalidNumber();
	error QuoteFail();
	error Ineligible();
	error InvalidSlippage();
	error ActionTypeIndexOutOfBounds();
	error NotWhitelisted();

	constructor() {
		_disableInitializers();
	}

	/**
	 * @notice Initialize
	 * @param _rdnt RDNT address
	 * @param _weth WETH address
	 * @param _mfd MFD, to send bounties as vesting RDNT to Hunter (user calling bounty)
	 * @param _chef CIC, to query bounties for ineligible emissions
	 * @param _priceProvider PriceProvider service, to get RDNT price for bounty quotes
	 * @param _eligibilityDataProvider Eligibility data provider
	 * @param _compounder Compounder address
	 * @param _hunterShare % of reclaimed rewards to send to Hunter
	 * @param _baseBountyUsdTarget Base Bounty is paid in RDNT, will scale to match this USD target value
	 * @param _maxBaseBounty cap the scaling above
	 */
	function initialize(
		address _rdnt,
		address _weth,
		address _mfd,
		address _chef,
		address _priceProvider,
		address _eligibilityDataProvider,
		address _compounder,
		uint256 _hunterShare,
		uint256 _baseBountyUsdTarget,
		uint256 _maxBaseBounty
	) external initializer {
		if (_rdnt == address(0)) revert AddressZero();
		if (_weth == address(0)) revert AddressZero();
		if (_mfd == address(0)) revert AddressZero();
		if (_chef == address(0)) revert AddressZero();
		if (_priceProvider == address(0)) revert AddressZero();
		if (_eligibilityDataProvider == address(0)) revert AddressZero();
		if (_compounder == address(0)) revert AddressZero();
		if (_hunterShare > RATIO_DIVISOR) revert InvalidNumber();
		if (_baseBountyUsdTarget == 0) revert InvalidNumber();
		if (_maxBaseBounty == 0) revert InvalidNumber();

		rdnt = _rdnt;
		weth = _weth;
		mfd = _mfd;
		chef = _chef;
		priceProvider = _priceProvider;
		eligibilityDataProvider = _eligibilityDataProvider;
		compounder = _compounder;

		hunterShare = _hunterShare;
		baseBountyUsdTarget = _baseBountyUsdTarget;
		maxBaseBounty = _maxBaseBounty;

		bounties[1] = _getMfdBounty;
		bounties[2] = _getChefBounty;
		bounties[3] = _getAutoCompoundBounty;
		bountyCount = 3;

		__Ownable_init();
		__Pausable_init();
	}

	/**
	 * @notice Given a user, return their bounty amount. uses staticcall to run same bounty aglo, but without execution
	 * @param _user address
	 * @return bounty amount of RDNT Hunter will recieve.
	 * can be a fixed amt (Base Bounty) or dynamic amt based on rewards removed from target user during execution (ineligible revenue, autocompound fee)
	 * @return actionType which of the 3 bounty types (above) to run.
	 * _getAvailableBounty returns this based on priority (expired locks first, then inelig emissions, then autocompound)
	 */
	function quote(address _user) public view returns (uint256 bounty, uint256 actionType) {
		(bool success, bytes memory data) = address(this).staticcall(
			abi.encodeCall(IBountyManager.executeBounty, (_user, false, 0))
		);
		if (!success) revert QuoteFail();

		(bounty, actionType) = abi.decode(data, (uint256, uint256));
	}

	/**
	 * @notice Execute a bounty.
	 * @param _user address
	 * can be a fixed amt (Base Bounty) or dynamic amt based on rewards removed from target user during execution (ineligible revenue, autocompound fee)
	 * @param _actionType which of the 3 bounty types (above) to run.
	 * @return bounty in RDNT to be paid to Hunter (via vesting)
	 * @return actionType which bounty ran
	 */
	function claim(address _user, uint256 _actionType) public returns (uint256, uint256) {
		return executeBounty(_user, true, _actionType);
	}

	/**
	 * @notice Execute the most appropriate bounty on a user, check returned amount for slippage, calc amount going to Hunter, send to vesting.
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * can be a fixed amt (Base Bounty) or dynamic amt based on rewards removed from target user during execution (ineligible revenue, autocompound fee)
	 * @param _actionType which of the 3 bounty types (above) to run.
	 * @return bounty in RDNT to be paid to Hunter (via vesting)
	 * @return actionType which bounty ran
	 */
	function executeBounty(
		address _user,
		bool _execute,
		uint256 _actionType
	) public whenNotPaused isWhitelisted returns (uint256 bounty, uint256 actionType) {
		if (_execute && msg.sender != address(this)) {
			if (!_canBountyHunt(msg.sender)) revert Ineligible();
		}
		uint256 totalBounty;
		bool issueBaseBounty;
		address incentivizer;

		(incentivizer, totalBounty, issueBaseBounty, actionType) = _getAvailableBounty(_user, _execute, _actionType);
		if (issueBaseBounty) {
			bounty = getBaseBounty();
		} else {
			if (totalBounty != 0) {
				bounty = (totalBounty * hunterShare) / RATIO_DIVISOR;
			}
		}

		if (_execute && bounty != 0) {
			if (!issueBaseBounty) {
				IERC20(rdnt).safeTransferFrom(incentivizer, address(this), totalBounty);
			}
			bounty = _sendBounty(msg.sender, bounty);
		}
	}

	function _canBountyHunt(address _user) internal view returns (bool) {
		(, , uint256 lockedLP, , ) = IMFDPlus(mfd).lockedBalances(_user);
		bool isEmissionsEligible = IEligibilityDataProvider(eligibilityDataProvider).isEligibleForRewards(_user);
		return lockedLP >= minDLPBalance() && isEmissionsEligible;
	}

	/**
	 * @notice Given a user and actionType, execute that bounty on either CIC or MFD or Compounder.
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * @param _actionTypeIndex, which of the 3 bounty types (above) to run.
	 * @return incentivizer the contract that had a bounty operation performed for it.
	 * Either CIC (to remove ineligible user from emission pool, or MFD to remove expired locks)
	 * @return totalBounty raw amount of RDNT returned from Incentivizer. Hunter % will be deducted from this.
	 * @return issueBaseBounty whether Incentivizer will pay bounty from its own RDNT reserve, or from this contracts RDNT reserve
	 * @return actionType the action type index executed
	 */
	function _getAvailableBounty(
		address _user,
		bool _execute,
		uint256 _actionTypeIndex
	) internal returns (address incentivizer, uint256 totalBounty, bool issueBaseBounty, uint256 actionType) {
		if (_actionTypeIndex > bountyCount) revert ActionTypeIndexOutOfBounds();
		if (_actionTypeIndex != 0) {
			// execute bounty w/ given params
			(incentivizer, totalBounty, issueBaseBounty) = bounties[_actionTypeIndex](_user, _execute);
			actionType = _actionTypeIndex;
		} else {
			for (uint256 i = 1; i <= bountyCount; ) {
				(incentivizer, totalBounty, issueBaseBounty) = bounties[i](_user, _execute);
				if (totalBounty != 0 || issueBaseBounty) {
					actionType = i;
					break;
				}
				unchecked {
					i++;
				}
			}
		}
	}

	/**
	 * @notice call MFDPlus.claimBounty()
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * @return incentivizer in this case MFD
	 * @return totalBounty RDNT to pay for this _user's bounty execution
	 * @return issueBaseBounty false when !autorelock because they will have rewards removed from their ineligible time after locks expired
	 */
	function _getMfdBounty(
		address _user,
		bool _execute
	) internal returns (address incentivizer, uint256, bool issueBaseBounty) {
		try IMFDPlus(mfd).claimBounty(_user, _execute) returns (bool issueBaseBounty_) {
			issueBaseBounty = issueBaseBounty_;
		} catch {
			issueBaseBounty = false;
		}
		incentivizer = mfd;
		return (incentivizer, 0, issueBaseBounty);
	}

	/**
	 * @notice call CIC.claimBounty()
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * @return incentivizer in this case CIC
	 * @return totalBounty RDNT to pay for this _user's bounty execution
	 * @return issueBaseBounty will be true
	 */
	function _getChefBounty(
		address _user,
		bool _execute
	) internal returns (address incentivizer, uint256, bool issueBaseBounty) {
		issueBaseBounty = IChefIncentivesController(chef).claimBounty(_user, _execute);
		incentivizer = chef;
		return (incentivizer, 0, issueBaseBounty);
	}

	/**
	 * @notice call Compounder.claimCompound(). compound pending rewards for _user into locked LP
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * @return incentivizer is the Compounder
	 * @return totalBounty RDNT to pay for this _user's bounty execution. paid from Autocompound fee
	 * @return issueBaseBounty will be false, will vary based on autocompound fee
	 */
	function _getAutoCompoundBounty(
		address _user,
		bool _execute
	) internal returns (address incentivizer, uint256 totalBounty, bool issueBaseBounty) {
		(totalBounty) = ICompounder(compounder).claimCompound(_user, _execute, DEFAULT_USERS_SLIPPAGE);
		issueBaseBounty = false;
		incentivizer = compounder;
	}

	/**
	 * @notice Vest a bounty in MFD for successful bounty by Hunter
	 * @param _to Hunter address
	 * @param _amount of RDNT
	 * @return amt added to vesting
	 */
	function _sendBounty(address _to, uint256 _amount) internal returns (uint256) {
		uint256 bountyReserve = IERC20(rdnt).balanceOf(address(this));
		if (_amount > bountyReserve) {
			IERC20(rdnt).safeTransfer(address(mfd), bountyReserve);
			IMFDPlus(mfd).vestTokens(_to, bountyReserve, true);
			emit BountyReserveEmpty(bountyReserve);
			_pause();
			return bountyReserve;
		} else {
			IERC20(rdnt).safeTransfer(address(mfd), _amount);
			IMFDPlus(mfd).vestTokens(_to, _amount, true);
			return _amount;
		}
	}

	/**
	 * @notice Return RDNT amount for Base Bounty.
	 * Base Bounty used to incentivize operations that don't generate their own reward to pay to Hunter.
	 * @return bounty in RDNT
	 */
	function getBaseBounty() public view whenNotPaused returns (uint256) {
		uint256 rdntPrice = IPriceProvider(priceProvider).getTokenPriceUsd();
		uint256 bounty = (baseBountyUsdTarget * 1e8) / rdntPrice;
		return bounty > maxBaseBounty ? maxBaseBounty : bounty;
	}

	/**
	 * @notice Minimum locked lp balance
	 */
	function minDLPBalance() public view returns (uint256 min) {
		uint256 lpTokenPrice = IPriceProvider(priceProvider).getLpTokenPriceUsd();
		min = (minStakeAmount * 1e8) / lpTokenPrice;
	}

	/**
	 * @notice Sets minimum stake amount.
	 * @dev Only owner can call this function.
	 * @param _minStakeAmount Minimum stake amount
	 */
	function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
		minStakeAmount = _minStakeAmount;
		emit MinStakeAmountUpdated(_minStakeAmount);
	}

	/**
	 * @notice Sets target price of base bounty.
	 * @dev Only owner can call this function.
	 * @param _newVal New USD value
	 */
	function setBaseBountyUsdTarget(uint256 _newVal) external onlyOwner {
		baseBountyUsdTarget = _newVal;
		emit BaseBountyUsdTargetUpdated(_newVal);
	}

	/**
	 * @notice Sets hunter's share ratio.
	 * @dev Only owner can call this function.
	 * @param _newVal New hunter share ratio
	 */
	function setHunterShare(uint256 _newVal) external onlyOwner {
		if (_newVal > RATIO_DIVISOR) revert InvalidNumber();
		hunterShare = _newVal;
		emit HunterShareUpdated(_newVal);
	}

	/**
	 * @notice Updates maximum base bounty.
	 * @dev Only owner can call this function.
	 * @param _newVal Maximum base bounty
	 */
	function setMaxBaseBounty(uint256 _newVal) external onlyOwner {
		maxBaseBounty = _newVal;
		emit MaxBaseBountyUpdated(_newVal);
	}

	/**
	 * @notice Set bounty operations.
	 * @dev Only owner can call this function.
	 */
	function setBounties() external onlyOwner {
		bounties[1] = _getMfdBounty;
		bounties[2] = _getChefBounty;
		bounties[3] = _getAutoCompoundBounty;
		emit BountiesSet();
	}

	/**
	 * @notice Recover ERC20 tokens from the contract.
	 * @param tokenAddress Token address to recover
	 * @param tokenAmount Amount to recover
	 */
	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		_recoverERC20(tokenAddress, tokenAmount);
	}

	/**
	 * @notice Add new address to whitelist.
	 * @param user address
	 * @param status for whitelist
	 */
	function addAddressToWL(address user, bool status) external onlyOwner {
		whitelist[user] = status;
		emit WhitelistUpdated(user, status);
	}

	/**
	 * @notice Update whitelist active status.
	 * @param status New whitelist status
	 */
	function changeWL(bool status) external onlyOwner {
		whitelistActive = status;
		emit WhitelistActiveChanged(status);
	}

	/**
	 * @notice Pause the bounty operations.
	 */
	function pause() public onlyOwner {
		_pause();
	}

	/**
	 * @notice Unpause the bounty operations.
	 */
	function unpause() public onlyOwner {
		_unpause();
	}
}