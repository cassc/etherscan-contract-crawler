// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./libs/BondInit.sol";
import "./interfaces/IBondPriceCheck.sol";
import "./libs/DateTime.sol";

contract BondSwapBonds is
	Initializable,
	ERC721Upgradeable,
	ERC721BurnableUpgradeable,
	OwnableUpgradeable,
	ReentrancyGuardUpgradeable,
	PausableUpgradeable
{
	using SafeERC20 for IERC20;

	event NewBondClass(
		uint256 indexed id,
		uint256 minBondPrice,
		uint256 pricePerToken,
		uint256 premiumPercent, // 5 digits percentage so 5000 is 50%, 700 is 7% etc
		uint256 period,
		bool enabled,
		address bondPriceChecker,
		address bondPayToken
	);
	event BondCreated(
		uint256 indexed bondTypeID,
		uint256 indexed tokenID,
		uint256 paid,
		uint256 payout,
		uint256 vestEndTime,
		address owner
	);
	event BondClassStatusChanged(uint256 indexed id, bool enabled);
	event BondsClaimed(uint256[] tokenID, uint256[] amounts, bool[] fullyClaimed);
	event Withdrawal(address token, uint256 amount);

	BondInit.BondContractConfig public settings;
	string public URI;

	uint256 public totalDebt; // remaining tokens to issue from all bonds
	uint256 bondIDcounter;

	mapping(uint256 => BondTerms) public bondClasses;
	uint256 public bondClassesNum;
	mapping(uint256 => Bond) public bonds; // key is ERC721 token ID

	struct BondTerms {
		uint256 id; // id of bond starting with 0
		uint256 minBondPrice; // minimum price for this type of bond in ETH (not per token, this is floor for whole bond)
		uint256 pricePerToken; // fixed price per token, required if bondPriceChecker not set, if bondPriceChecker is set then it should be 0
		uint256 premiumPercent; // percent of tokens (5 digit representation) over current LP token value to be added to payout 5000 = 50%, 50 = 0.5% etc
		uint8 bondPayTokenDecimals;
		uint256 period; // bond maturing time in seconds
		bool enabled; // if bond is enabled or not
		address bondPriceChecker; // optional, if set price is determined by this contract
		address bondPayToken; // if set (different than 0 address) it means that this bond can be only bought using ERC20 token
	}

	struct Bond {
		uint256 bondTermsID; // bond ID
		uint256 payout; //  all tokens to be paid (this value is NOT updated when claimed)
		uint256 left; // how many tokes left to be claimed
		uint256 vestingEnd; // vest ending timestamp
		uint256 lastClaimed; // last claim timestamp
	}

	struct BondRedeemLog {
		uint256 tokenID;
		uint256 amount;
		bool fullyClaimed;
	}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize(BondInit.BondContractConfig memory _conf) external initializer {
		URI = _conf.uri;
		settings = _conf;

		__Ownable_init();
		transferOwnership(_conf.bondCreator);
		__ReentrancyGuard_init();
		__Pausable_init();
		__ERC721_init("", "");
	}

	function buyBondETH(
		uint256 _bondClassID,
		uint256 amountOutMin,
		uint256 _slippage // in percent max 5 digits, 10000 = 100%
	) external payable nonReentrant whenNotPaused {
		BondTerms memory currentBondTerms = bondClasses[_bondClassID];
		require(currentBondTerms.bondPayToken == address(0), "Bond: NOT_ETH_BOND");
		require(msg.value > 0, "Bond: NOT_ENOUGH_ETHER");

		_buyBond(_bondClassID, true, currentBondTerms, amountOutMin, msg.value, _slippage);
	}

	function buyBondToken(
		uint256 _bondClassID,
		uint256 amountOutMin,
		uint256 amountPaid,
		uint256 _slippage // in percent max 5 digits, 10000 = 100%
	) external nonReentrant whenNotPaused {
		BondTerms memory currentBondTerms = bondClasses[_bondClassID];
		require(currentBondTerms.bondPayToken != address(0), "Bond: NOT_TOKEN_BOND");
		require(amountOutMin > 0 && amountPaid > 0, "Bond: INVALID_AMOUNTS");

		_buyBond(_bondClassID, false, currentBondTerms, amountOutMin, amountPaid, _slippage);
	}

	function _buyBond(
		uint256 _bondClassID,
		bool _ethUsed, // if it's false then it's ERC20 token used for buying
		BondTerms memory _terms,
		uint256 _amountOutMin,
		uint256 _amountPaid,
		uint256 _slippage // in percent max 5 digits, 10000 = 100%
	) private {
		require(_slippage < 10000, "Bond: INVALID_SLIPPAGE");
		require(_amountPaid >= _terms.minBondPrice, "Bond: BELOW_FLOOR");
		require(_bondClassID < bondClassesNum, "Bond: INVALID_BOND_ID");
		require(_terms.period > 0, "Bond: INVALID_BOND_TYPE");
		require(_terms.enabled, "Bond: BOND_DISABLED");

		uint256 feeValue = 0;
		if (settings.protocolFee > 0) {
			feeValue = getProtocolFee(_amountPaid);
			if (_ethUsed) {
				(bool success, ) = payable(settings.protocolFeeAddress).call{ value: feeValue }("");
				require(success, "Bond: FEE_TRANSFER_FAILED");
			} else {
				IERC20(_terms.bondPayToken).safeTransferFrom(msg.sender, settings.protocolFeeAddress, feeValue);
			}
		}

		uint256 amountToSpend = _amountPaid - feeValue;
		uint256 finalReward = _calculateAmountOut(_terms, amountToSpend, _ethUsed);

		// final reward must be higher than min amoumt out minus slippage amount
		require(
			finalReward > 0 && finalReward >= _amountOutMin - ((_amountOutMin * _slippage) / 10000),
			"Bond: REWARD_LOWER_THAN_OUT_MIN"
		);

		require(
			IERC20(settings.bondToken).balanceOf(address(this)) >= totalDebt + finalReward,
			"Bond: NOT_ENOUGH_BOND_TOKENS"
		);

		if (!_ethUsed) {
			SafeERC20.safeTransferFrom(IERC20(_terms.bondPayToken), msg.sender, address(this), amountToSpend);
		}

		totalDebt += finalReward;

		uint256 bondID = bondIDcounter;
		bondIDcounter++;

		bonds[bondID] = Bond({
			bondTermsID: _terms.id,
			payout: finalReward,
			left: finalReward,
			vestingEnd: block.timestamp + _terms.period,
			lastClaimed: block.timestamp
		});

		// order here is important (subgraph), do NOT emit BondCreated after _safeMint
		emit BondCreated(_terms.id, bondID, _amountPaid, finalReward, block.timestamp + _terms.period, msg.sender);

		_safeMint(msg.sender, bondID);
	}

	function redeem(uint256[] memory tokenIDs) external nonReentrant {
		require(tokenIDs.length > 0, "Bond: NO_TOKENS");

		uint256 totalToClaim;

		BondRedeemLog[] memory claimedBonds = new BondRedeemLog[](tokenIDs.length);
		uint256 claimsNum = 0;

		for (uint256 i = 0; i < tokenIDs.length; i++) {
			require(ownerOf(tokenIDs[i]) == msg.sender, "Bond: NOT_TOKEN_OWNER");
			Bond storage bond = bonds[tokenIDs[i]];
			if (bond.left == 0) {
				continue;
			}

			if (block.timestamp >= bond.vestingEnd) {
				// fully mature, send what's left
				claimedBonds[claimsNum] = BondRedeemLog({
					tokenID: tokenIDs[i],
					amount: bond.left,
					fullyClaimed: true
				});
				totalToClaim += bond.left;
				bond.left = 0;
			} else {
				uint256 rewardRatePerSec = bond.payout / bondClasses[bond.bondTermsID].period;

				uint256 toClaim = (block.timestamp - bond.lastClaimed) * rewardRatePerSec;
				if (toClaim == 0) {
					continue;
				}

				bool fullyClaimed = false;
				if (toClaim >= bond.left) {
					toClaim = bond.left;
					fullyClaimed = true;
				}

				claimedBonds[claimsNum] = BondRedeemLog({
					tokenID: tokenIDs[i],
					amount: toClaim,
					fullyClaimed: fullyClaimed
				});

				totalToClaim += toClaim;
				bond.left -= toClaim;
			}

			bond.lastClaimed = block.timestamp;
			claimsNum += 1;
		}

		require(totalToClaim > 0, "Bond: NOTHING_TO_CLAIM");

		totalDebt -= totalToClaim;
		IERC20(settings.bondToken).safeTransfer(msg.sender, totalToClaim);

		uint256[] memory logsTokenID = new uint256[](claimsNum);
		uint256[] memory logsAmounts = new uint256[](claimsNum);
		bool[] memory logsFullyClaimed = new bool[](claimsNum);

		for (uint256 i = 0; i < claimsNum; i++) {
			logsTokenID[i] = claimedBonds[i].tokenID;
			logsAmounts[i] = claimedBonds[i].amount;
			logsFullyClaimed[i] = claimedBonds[i].fullyClaimed;
		}

		emit BondsClaimed(logsTokenID, logsAmounts, logsFullyClaimed);
	}

	function getAmountOut(uint256 _bondClassID, uint256 _amountIn) public view returns (uint256) {
		BondTerms memory terms = bondClasses[_bondClassID];
		bool ethUsed;
		if (terms.bondPayToken == address(0)) {
			ethUsed = true;
		}
		uint256 feeValue;
		if (settings.protocolFee > 0) {
			feeValue = getProtocolFee(_amountIn);
		}

		_amountIn = _amountIn - feeValue;

		return _calculateAmountOut(terms, _amountIn, ethUsed);
	}

	function _calculateAmountOut(
		BondTerms memory _terms,
		uint256 _amountIn,
		bool _ethUsed
	) internal view returns (uint256) {
		uint256 reward;
		if (_terms.bondPriceChecker != address(0)) {
			// dynamic price check
			if (_ethUsed) {
				reward = IBondPriceCheck(_terms.bondPriceChecker).getRewardAmountForETH(settings.bondToken, _amountIn);
			} else {
				reward = IBondPriceCheck(_terms.bondPriceChecker).getRewardAmountForToken(
					settings.bondToken,
					_terms.bondPayToken,
					_amountIn
				);
			}
		} else {
			reward = (_amountIn * 10**settings.bondTokenDecimals) / _terms.pricePerToken;
		}

		// if premium is 0 then it's discarded in this calculation anyway so we don't need to branch with if
		uint256 finalReward = reward + ((reward * _terms.premiumPercent) / 10000);
		return finalReward;
	}

	function getProtocolFee(uint256 _amountPaid) public view returns (uint256) {
		return (_amountPaid * settings.protocolFee) / 10000;
	}

	function name() public view override returns (string memory) {
		return string.concat("Bonds for ", Strings.toHexString(uint160(settings.bondToken), 20));
	}

	function symbol() public view override returns (string memory) {
		return string.concat("BondS", Strings.toString(settings.bondSymbolNumber));
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "TOKEN_DOESNT_EXIST");
		Bond memory b = bonds[tokenId];

		bytes memory dataURI = abi.encodePacked(
			"{",
			'"name": "',
			name(),
			'",',
			'"description": "BondSwap Bond",',
			'"external_url": "',
			string.concat(
				URI,
				Strings.toString(block.chainid),
				"/",
				Strings.toHexString(uint160(address(this)), 20),
				"/",
				Strings.toString(tokenId)
			),
			'",',
			'"image": "',
			generateSvgImage(tokenId, b, settings.bondTokenDecimals),
			'",',
			'"attributes": [',
			_createAttribute("bond class", b.bondTermsID),
			",",
			_createAttribute("left", b.left),
			",",
			_createAttribute("last claimed", b.lastClaimed),
			",",
			_createAttribute("maturity date", b.vestingEnd),
			"]",
			"}"
		);
		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
	}

	function _createAttribute(string memory _traitType, uint256 _value) internal pure returns (string memory) {
		return string.concat('{"trait_type": "', _traitType, '", "value": "', Strings.toString(_value), '"}');
	}

	function generateSvgImage(
		uint256 _tokenId,
		Bond memory _b,
		uint8 decimals
	) internal view returns (string memory) {
		bytes memory svg = abi.encodePacked(
			'<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
			"<style>.base { fill: white; font-family: serif; font-size: 20px; } .header { fill: white; font-weight: bold; font-size: 24px; }</style>",
			'<rect width="100%" height="100%" fill="black" />',
			'<text x="50%" y="10%" class="header" dominant-baseline="middle" text-anchor="middle">',
			"BondSwap",
			"</text>",
			'<text x="50%" y="30%" class="base" dominant-baseline="middle" text-anchor="middle">',
			"TokenID: ",
			Strings.toString(_tokenId),
			"</text>",
			'<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">',
			"BondClass: ",
			Strings.toString(_b.bondTermsID),
			"</text>",
			'<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
			"LeftToClaim: ",
			convertValueToHumanReadable(_b.left, decimals),
			"</text>",
			'<text x="50%" y="60%" class="base" dominant-baseline="middle" text-anchor="middle">',
			"MaturityDate: ",
			DateTime.dateTimeToText(_b.vestingEnd),
			"</text>",
			'<text x="50%" y="70%" class="base" dominant-baseline="middle" text-anchor="middle">',
			"DataFreshness: ",
			DateTime.dateTimeToText(block.timestamp),
			"</text>",
			"</svg>"
		);
		return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
	}

	function totalMinted() public view returns (uint256) {
		return bondIDcounter;
	}

	function convertValueToHumanReadable(uint256 value, uint8 decimal) internal pure returns (string memory) {
		if (decimal == 0) {
			return string.concat("(raw_value/no_decimals) ", Strings.toString(value));
		}
		uint256 multiplier = 10**decimal;
		return string.concat(Strings.toString(value / multiplier), ".", Strings.toString(value % multiplier));
	}

	// ONLY OWNER SECTION

	function changeBondClassStatus(uint256 _bondTypeID, bool _enabled) external onlyOwner {
		require(_bondTypeID < bondClassesNum, "INVALID_BOND_CLASS");
		bondClasses[_bondTypeID].enabled = _enabled;

		emit BondClassStatusChanged(_bondTypeID, _enabled);
	}

	function addNewBondClass(BondTerms memory _terms) external onlyOwner {
		require(_terms.period > 0 && _terms.period < 630720000, "INVALID_PERIOD"); // max 20 years
		require(_terms.id == bondClassesNum, "INVALID_TERMS_ID");

		// price can only be set if there is no price checker
		// it must be set if there is no price checker
		if (_terms.pricePerToken > 0) {
			require(_terms.bondPriceChecker == address(0), "PRICE_CHECK_SET_WITH_PER_TOKEN_PRICE");
		} else {
			require(_terms.bondPriceChecker != address(0), "PRICE_CHECK_NOT_SET");
		}

		uint8 decimals;
		if (_terms.bondPayToken != address(0)) {
			try IERC20Metadata(_terms.bondPayToken).decimals() returns (uint8 v) {
				if (v > 64) {
					revert("Factory:DECIMALS_TOO_HIGH");
				}
				decimals = v;
			} catch {
				revert("Factory:DECIMALS_ERROR");
			}
		} else {
			// ETH
			decimals = 18;
		}

		_terms.bondPayTokenDecimals = decimals;

		bondClasses[bondClassesNum] = _terms;
		bondClassesNum++;

		emit NewBondClass(
			_terms.id,
			_terms.minBondPrice,
			_terms.pricePerToken,
			_terms.premiumPercent,
			_terms.period,
			_terms.enabled,
			_terms.bondPriceChecker,
			_terms.bondPayToken
		);
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}

	function withdrawERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		if (tokenAddress == settings.bondToken) {
			uint256 balance = IERC20(settings.bondToken).balanceOf(address(this));
			require(balance >= tokenAmount && tokenAmount > 0, "TOKEN_AMOUNT_TOO_HIGH");
			require(balance >= totalDebt && balance - totalDebt >= tokenAmount, "DEBT_BALANCE_RATIO_TOO_HIGH");
		}
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);

		emit Withdrawal(tokenAddress, tokenAmount);
	}

	function withdraw() external onlyOwner {
		uint256 amount = address(this).balance;
		(bool success, ) = payable(msg.sender).call{ value: amount }("");
		require(success);

		emit Withdrawal(address(0), amount);
	}
}