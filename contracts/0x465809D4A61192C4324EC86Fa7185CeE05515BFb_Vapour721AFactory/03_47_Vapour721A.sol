// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@beehiveinnovation/rain-protocol/contracts/vm/RainVM.sol";
import {AllStandardOps, ALL_STANDARD_OPS_START, ALL_STANDARD_OPS_LENGTH} from "@beehiveinnovation/rain-protocol/contracts/vm/ops/AllStandardOps.sol";
import {VMState, StateConfig} from "@beehiveinnovation/rain-protocol/contracts/vm/libraries/VMState.sol";

/**
 * config for deploying Vapour721A contract
 */
struct InitializeConfig {
	string name;
	string symbol;
	string baseURI;
	uint256 supplyLimit;
	address recipient;
	address owner;
	address admin;
	uint256 royaltyBPS;
	address currency;
	StateConfig vmStateConfig;
}

struct BuyConfig {
	uint256 maximumPrice;
	uint256 minimumUnits;
	uint256 desiredUnits;
}

// supply limit
uint256 constant LOCAL_OP_SUPPLYLIMIT = 0;
// amount withdrawn
uint256 constant LOCAL_OP_AMOUNT_WITHDRAWN = 1;
//amount payable
uint256 constant LOCAL_OP_AMOUNT_PAYABLE = 2;
//amount payable
uint256 constant LOCAL_OP_ACCOUNT = 3;
//amount payable
uint256 constant LOCAL_OP_TARGET_UNITS = 4;
// the total numbers of tokens
uint256 constant LOCAL_OP_TOTAL_SUPPLY = 5;
// the total unites minted
uint256 constant LOCAL_OP_TOTAL_MINTED = 6;
// number of tokens minted by `owner`.
uint256 constant LOCAL_OP_NUMBER_MINTED = 7;
// number of tokens burned by `owner`.
uint256 constant LOCAL_OP_NUMBER_BURNED = 8;

uint256 constant LOCAL_OPS_LENGTH = 9;

contract Vapour721A is ERC721AUpgradeable, RainVM, VMState, OwnableUpgradeable, AccessControlUpgradeable {
	using Strings for uint256;
	using Math for uint256;

	uint256 private immutable localOpsStart;

	uint256 private _supplyLimit;
	uint256 private _amountWithdrawn;
	uint256 private _amountPayable;

	address private _vmStateConfig;
	address private _currency;
	address payable private _recipient;

	// Royalty amount in bps
	uint256 private _royaltyBPS;

	string private baseURI;

	event Buy(address _receiver, uint256 _units, uint256 _cost);
	event Initialize(InitializeConfig config_);
	event RecipientChanged(address newRecipient);
	event Withdraw(
		address _withdrawer,
		uint256 _amountWithdrawn,
		uint256 _totalWithdrawn
	);

	/// Admin role for `DELEGATED_MINTER`.
	bytes32 private constant DELEGATED_MINTER_ADMIN =
		keccak256("DELEGATED_MINTER_ADMIN");
	/// Role for `DELEGATED_MINTER`.
	bytes32 private constant DELEGATED_MINTER = keccak256("DELEGATED_MINTER");

	constructor() {
		localOpsStart = ALL_STANDARD_OPS_START + ALL_STANDARD_OPS_LENGTH;
	}
	
	function initialize(InitializeConfig memory config_) initializerERC721A initializer external{
		__ERC721A_init(config_.name, config_.symbol);
		__Ownable_init();
		
		_supplyLimit = config_.supplyLimit;
		baseURI = config_.baseURI;

		_royaltyBPS = config_.royaltyBPS;
		require(_royaltyBPS < 10_000, "MAX_ROYALTY");

		setRecipient(config_.recipient);
		transferOwnership(config_.owner);

		require(config_.admin != address(0), "0_ADMIN");
		_setRoleAdmin(DELEGATED_MINTER, DELEGATED_MINTER_ADMIN);

		_grantRole(DELEGATED_MINTER_ADMIN, config_.admin);


		_currency = config_.currency;

		_vmStateConfig = _snapshot(_newState(config_.vmStateConfig));

		emit Initialize(config_);
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		return string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
	}

	function calculateBuy(address account_, uint256 targetUnits_)
		public
		view
		returns (uint256 maxUnits_, uint256 price_)
	{
		State memory state_ = _restore(_vmStateConfig);
		eval(abi.encode(account_, targetUnits_), state_, 0);

		(maxUnits_, price_) = (
			state_.stack[state_.stackIndex - 2],
			state_.stack[state_.stackIndex - 1]
		);
	}

	function _mintNFT(address receiver, BuyConfig memory config_) internal {
		require(0 < config_.minimumUnits, "0_MINIMUM");
		require(
			config_.minimumUnits <= config_.desiredUnits,
			"MINIMUM_OVER_DESIRED"
		);

		uint256 remainingUnits_ = _supplyLimit - _totalMinted();
		uint256 targetUnits_ = config_.desiredUnits.min(remainingUnits_);

		(uint256 maxUnits_, uint256 price_) = calculateBuy(receiver, targetUnits_);

		uint256 units_ = maxUnits_.min(targetUnits_);
		require(units_ >= config_.minimumUnits, "INSUFFICIENT_STOCK");

		require(price_ <= config_.maximumPrice, "MAXIMUM_PRICE");
		uint256 cost_ = price_ * units_;
		if (_currency == address(0)) {
			require(msg.value >= cost_, "INSUFFICIENT_FUND");
			Address.sendValue(payable(msg.sender), msg.value - cost_);
		} else IERC20(_currency).transferFrom(msg.sender, address(this), cost_);

		unchecked {
			_amountPayable = _amountPayable + cost_;
		}
		_mint(receiver, units_);
		emit Buy(receiver, units_, cost_);
	}

	function mintNFT(BuyConfig calldata config_) external payable {
		_mintNFT(msg.sender, config_);
	}

	/// A minting function that allows minting to an address other than the
	/// sender of the transaction/account that pays. This opens up the
	/// possibility of using 3rd party services that will mint on a user's
	/// behalf if they pay with some other form of payment. The BuyConfig for
	/// the mint is split out of its struct, also for easier integration.
	/// The downside is, this way of minting could be vulnerable to a phishing
	/// attack - an attacker could create a duplicate front end that makes the
	/// user think they are minting to themselves, when actually they are
	/// minting to someone else. To mitigate against this we restrict access to
	/// this function to only those accounts with the 'DELEGATED_MINTER' role.
	/// @param receiver the receiver of the NFTs
	/// @param maximumPrice maximum price, as per BuyConfig
	/// @param minimumUnits minimum units, as per BuyConfig
	/// @param desiredUnits desired units, as per BuyConfig
	function mintNFTFor(
		address receiver,
		uint256 maximumPrice,
		uint256 minimumUnits,
		uint256 desiredUnits
	) external payable onlyRole(DELEGATED_MINTER) {
		_mintNFT(receiver, BuyConfig(maximumPrice, minimumUnits, desiredUnits));
	}

	function setRecipient(address newRecipient) public {
		require(
			msg.sender == _recipient || _recipient == address(0),
			"RECIPIENT_ONLY"
		);
		require(
			newRecipient.code.length == 0 && newRecipient != address(0),
			"INVALID_ADDRESS."
		);
		_recipient = payable(newRecipient);
		emit RecipientChanged(newRecipient);
	}

	function burn(uint256 tokenId) external {
		_burn(tokenId, true);
	}

	function withdraw() external {
		require(_amountPayable > 0, "ZERO_FUND");
		unchecked {
			_amountWithdrawn = _amountWithdrawn + _amountPayable;
		}
		emit Withdraw(msg.sender, _amountPayable, _amountWithdrawn);

		if (_currency == address(0)) Address.sendValue(_recipient, _amountPayable);
		else IERC20(_currency).transfer(_recipient, _amountPayable);

		_amountPayable = 0;
	}

	//// @dev Get royalty information for token
	//// @param _salePrice Sale price for the token
	function royaltyInfo(uint256, uint256 _salePrice)
		external
		view
		returns (address receiver, uint256 royaltyAmount)
	{
		if (_recipient == address(0x0)) {
			return (_recipient, 0);
		}
		return (_recipient, (_salePrice * _royaltyBPS) / 10_000);
	}

	/// @inheritdoc RainVM
	function applyOp(
		bytes memory context_,
		State memory state_,
		uint256 opcode_,
		uint256 operand_
	) internal view override {
		unchecked {
			if (opcode_ < localOpsStart) {
				AllStandardOps.applyOp(
					state_,
					opcode_ - ALL_STANDARD_OPS_START,
					operand_
				);
			} else {
				(uint256 account_, uint256 units_) = abi.decode(
					context_,
					(uint256, uint256)
				);
				opcode_ -= localOpsStart;
				require(opcode_ < LOCAL_OPS_LENGTH, "MAX_OPCODE");
				if (opcode_ == LOCAL_OP_AMOUNT_PAYABLE) {
					state_.stack[state_.stackIndex] = _amountPayable;
				} else if (opcode_ == LOCAL_OP_AMOUNT_WITHDRAWN) {
					state_.stack[state_.stackIndex] = _amountWithdrawn;
				} else if (opcode_ == LOCAL_OP_SUPPLYLIMIT) {
					state_.stack[state_.stackIndex] = _supplyLimit;
				} else if (opcode_ == LOCAL_OP_ACCOUNT) {
					state_.stack[state_.stackIndex] = account_;
				} else if (opcode_ == LOCAL_OP_TARGET_UNITS) {
					state_.stack[state_.stackIndex] = units_;
				} else if (opcode_ == LOCAL_OP_TOTAL_SUPPLY) {
					state_.stack[state_.stackIndex] = totalSupply();
				} else if (opcode_ == LOCAL_OP_TOTAL_MINTED) {
					state_.stack[state_.stackIndex] = _totalMinted();
				} else if (opcode_ == LOCAL_OP_NUMBER_MINTED) {
					address account = address(
						uint160(state_.stack[state_.stackIndex - 1])
					);
					state_.stack[state_.stackIndex - 1] = _numberMinted(account);
					state_.stackIndex--;
				} else if (opcode_ == LOCAL_OP_NUMBER_BURNED) {
					address account = address(
						uint160(state_.stack[state_.stackIndex - 1])
					);
					state_.stack[state_.stackIndex - 1] = _numberBurned(account);
					state_.stackIndex--;
				}
				state_.stackIndex++;
			}
		}
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(AccessControlUpgradeable, ERC721AUpgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}