// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author FOMOLOL (fomolol.com)

import "./libs/BetterBoolean.sol";
import "./libs/SafeAddress.sol";
import "./libs/ABDKMath64x64.sol";
import "./security/ContractGuardian.sol";
import "./finance/LockedPaymentSplitter.sol";

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @dev Errors
/**
 * @notice Token is not free. Needed `amount` to be more than zero.
 * @param amount total mint price.
 */
error NotFree(uint256 amount);
/**
 * @notice Insufficient balance for transfer. Needed `required` but only `available` available.
 * @param available balance available.
 * @param required requested amount to transfer.
 */
error InsufficientBalance(uint256 available, uint256 required);
/**
 * @notice Maximum mints exceeded. Allowed `allowed` but trying to mint `trying`.
 * @param trying total trying to mint.
 * @param allowed allowed amount to mint per wallet.
 */
error MaxPerWalletCap(uint256 trying, uint256 allowed);
/**
 * @notice Maximum supply exceeded. Allowed `allowed` but trying to mint `trying`.
 * @param trying total trying to mint.
 * @param allowed allowed amount to mint per wallet.
 */
error MaxSupplyExceeded(uint256 trying, uint256 allowed);
/**
 * @notice Not allowed. Address is not allowed.
 * @param _address wallet address checked.
 */
error NotAllowed(address _address);
/**
 * @notice Token does not exist.
 * @param tokenId token id checked.
 */
error DoesNotExist(uint256 tokenId);

/**
 * @title FOMOPASS
 * @author FOMOLOL (fomolol.com)
 * @dev Standard ERC1155 implementation
 *
 * ERC1155 NFT contract, with reserves, payment splitting and paid token features.
 *
 * In addition to using ERC1155, gas is optimized via boolean packing
 * and use of constants where possible.
 */
/// @custom:security-contact [email protected]
abstract contract FOMOPASS is
	ERC1155,
	IERC2981,
	Ownable,
	Pausable,
	ERC1155Supply,
	ContractGuardian,
	ReentrancyGuard,
	LockedPaymentSplitter
{
	enum Status {
		Pending,
		PublicSale,
		Finished
	}

	using SafeAddress for address;
	using ABDKMath64x64 for uint;
	using BetterBoolean for uint256;
	using Strings for uint256;
	using ECDSA for bytes32;

	Status public status;

	string private name_;
	string private symbol_;
	address private _recipient;

	uint256 public constant MAX_PER_WALLET_LIMIT = 50;
	uint256 public constant PASS_ALL_ACCESS_ID = 0;
	uint256 public constant PASS_EVENTS_ONLY_ID = 1;
	uint256 public tokensReserved;

	bool public metadataRevealed;
	bool public metadataFinalised;

	mapping(uint256 => string) private _uris;
	mapping(uint256 => uint256) private _costs;
	mapping(uint256 => uint256) private _maxSupplies;
	mapping(uint256 => uint256) private _maxBatchSizes;

	/// @dev Events
	event PermanentURI(string _value, uint256 indexed _id);
	event TokensMinted(
		address indexed mintedBy,
		uint256 indexed id,
		uint256 indexed quantity
	);
	event BaseUriUpdated(string oldBaseUri, string newBaseUri);
	event CostUpdated(uint256 oldCost, uint256 newCost);
	event ReservedToken(address minter, address recipient, uint256 amount);
	event StatusChanged(Status status);

	constructor(
		string memory _symbol,
		string memory _name,
		string memory __uri,
		address[] memory __addresses,
		uint256[] memory __splits
	) ERC1155(__uri) SlimPaymentSplitter(__addresses, __splits) {
		name_ = _name;
		symbol_ = _symbol;

		// Set royalty recipient
		_recipient = owner();

		// All Access Pass
		_costs[PASS_ALL_ACCESS_ID] = 0.1 ether;
		_uris[
			PASS_ALL_ACCESS_ID
		] = "ipfs://QmUvDi6gUZ8HLazUuuzij4bi3GoJWoLEg2bL95AH3r7qih/0.json";
		_maxSupplies[PASS_ALL_ACCESS_ID] = 200;
		_maxBatchSizes[PASS_ALL_ACCESS_ID] = 25;

		// Events Only Pass
		_costs[PASS_EVENTS_ONLY_ID] = 0.05 ether;
		_uris[
			PASS_EVENTS_ONLY_ID
		] = "ipfs://QmUvDi6gUZ8HLazUuuzij4bi3GoJWoLEg2bL95AH3r7qih/1.json";
		_maxSupplies[PASS_EVENTS_ONLY_ID] = 300;
		_maxBatchSizes[PASS_EVENTS_ONLY_ID] = 25;
	}

	/**
	 * @dev Throws if amount if less than zero.
	 */
	function _isNotFree(uint256 amount) internal pure {
		if (amount <= 0) {
			revert NotFree(amount);
		}
	}

	/**
	 * @dev Throws if public sale is NOT active.
	 */
	function _isPublicSaleActive() internal view {
		if (_msgSender() != owner()) {
			require(status == Status.PublicSale, "Public sale is not active.");
		}
	}

	/**
	 * @dev Throws if max tokens per wallet
	 * @param id token id to check
	 * @param quantity quantity to check
	 */
	function _isMaxTokensPerWallet(uint256 id, uint256 quantity) internal view {
		if (_msgSender() != owner()) {
			uint256 mintedBalance = balanceOf(_msgSender(), id);
			uint256 currentMintingAmount = mintedBalance + quantity;
			if (currentMintingAmount > MAX_PER_WALLET_LIMIT) {
				revert MaxPerWalletCap(
					currentMintingAmount,
					MAX_PER_WALLET_LIMIT
				);
			}
		}
	}

	/**
	 * @dev Throws if the amount sent is not equal to the total cost.
	 * @param id token id to check
	 * @param quantity quantity to check
	 */
	function _isCorrectAmountProvided(uint256 id, uint256 quantity)
		internal
		view
	{
		uint256 mintCost = _costs[id];
		uint256 totalCost = quantity * mintCost;
		if (msg.value < totalCost && _msgSender() != owner()) {
			revert InsufficientBalance(msg.value, totalCost);
		}
	}

	/**
	 * @dev Throws if the claim size is not valid
	 * @param id token id to check
	 * @param count total to check
	 */
	function _isValidBatchSize(uint256 id, uint256 count) internal view {
		require(
			0 < count && count <= _maxBatchSizes[id],
			"Max tokens per batch exceeded"
		);
	}

	/**
	 * @dev Throws if the total token number being minted is zero
	 */
	function _isMintingOne(uint256 quantity) internal pure {
		require(quantity > 0, "Must mint at least 1 token");
	}

	/**
	 * @dev Throws if the total being minted is greater than the max supply
	 */
	function _isLessThanMaxSupply(uint256 id, uint256 quantity) internal view {
		uint256 _maxSupply = _maxSupplies[id];
		if (totalSupply(id) + quantity > _maxSupply) {
			revert MaxSupplyExceeded(totalSupply(id) + quantity, _maxSupply);
		}
	}

	/**
	 * @dev Mint function for reserved tokens.
	 * @param minter is the address minting the token(s).
	 * @param quantity is total tokens to mint.
	 */
	function _internalMintTokens(
		address minter,
		uint256 id,
		uint256 quantity
	) internal {
		_isLessThanMaxSupply(id, quantity);
		_mint(minter, id, quantity, "");
	}

	/**
	 * @dev Allows us to specify the collection name.
	 */
	function name() public view returns (string memory) {
		return name_;
	}

	/**
	 * @dev Allows us to specify the token symbol.
	 */
	function symbol() public view returns (string memory) {
		return symbol_;
	}

	/**
	 * @dev Pause the contract
	 */
	function pause() public onlyOwner {
		_pause();
	}

	/**
	 * @dev Unpause the contract
	 */
	function unpause() public onlyOwner {
		_unpause();
	}

	/**
	 * @notice Reserve token(s) to multiple team members.
	 *
	 * @param frens addresses to send tokens to
	 * @param quantity the number of tokens to mint.
	 */
	function reserve(
		address[] memory frens,
		uint256 id,
		uint256 quantity
	) external onlyOwner {
		_isMintingOne(quantity);
		_isValidBatchSize(id, quantity);
		_isLessThanMaxSupply(id, quantity);

		uint256 idx;
		for (idx = 0; idx < frens.length; idx++) {
			require(frens[idx] != address(0), "Zero address");
			_internalMintTokens(frens[idx], id, quantity);
			tokensReserved += quantity;
			emit ReservedToken(_msgSender(), frens[idx], quantity);
		}
	}

	/**
	 * @notice Reserve multiple tokens to a single team member.
	 *
	 * @param fren Address to send tokens to
	 * @param id Token id to mint
	 * @param quantity Number of tokens to mint
	 */
	function reserveSingle(
		address fren,
		uint256 id,
		uint256 quantity
	) external onlyOwner {
		_isMintingOne(quantity);
		_isValidBatchSize(id, quantity);
		_isLessThanMaxSupply(id, quantity);

		uint256 _maxBatchSize = _maxBatchSizes[id];
		uint256 multiple = quantity / _maxBatchSize;
		for (uint256 i = 0; i < multiple; i++) {
			_internalMintTokens(fren, id, _maxBatchSize);
		}
		uint256 remainder = quantity % _maxBatchSize;
		if (remainder != 0) {
			_internalMintTokens(fren, id, remainder);
		}
		tokensReserved += quantity;
		emit ReservedToken(_msgSender(), fren, quantity);
	}

	/**
	 * @dev The public mint function.
	 * @param id Token id to mint.
	 * @param quantity Total number of tokens to mint.
	 */
	function mint(uint256 id, uint256 quantity)
		public
		payable
		nonReentrant
		onlyUsers
	{
		_isPublicSaleActive();
		_isMaxTokensPerWallet(id, quantity);
		_isCorrectAmountProvided(id, quantity);
		_isMintingOne(quantity);
		_isLessThanMaxSupply(id, quantity);

		_mint(_msgSender(), id, quantity, "");
		emit TokensMinted(_msgSender(), id, quantity);
	}

	/**
	 * @notice This is a mint cost override (must be in wei)
	 * @dev Handles setting the mint cost
	 * @param id token id to set the cost for
	 * @param _cost new cost to associate with minting tokens (in wei)
	 */
	function setMintCost(uint256 id, uint256 _cost) public onlyOwner {
		_isNotFree(_cost);
		uint256 currentCost = _costs[id];
		_costs[id] = _cost; // in wei
		emit CostUpdated(currentCost, _cost);
	}

	/**
	 * @dev Handles updating the status
	 */
	function setStatus(Status _status) external onlyOwner {
		status = _status;
		emit StatusChanged(_status);
	}

	/**
	 * @dev override for before token transfer method
	 */
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override(ERC1155, ERC1155Supply) whenNotPaused {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
		require(!paused(), "token transfer while paused");
	}

	/**
	 * @dev override for the uri that allows IPFS to be used
	 * @param id token id to update uri for
	 */
	function uri(uint256 id) public view override returns (string memory) {
		return (_uris[id]);
	}

	/**
	 * @dev handles returning the cost for a token
	 * @param id token id to update uri for
	 */
	function cost(uint256 id) public view returns (uint256) {
		return (_costs[id]);
	}

	/**
	 * @dev override for the uri that allows IPFS to be used
	 * @param id token id to update uri for
	 * @param _uri uri for token id
	 */
	function setTokenUri(uint256 id, string memory _uri) public onlyOwner {
		_uris[id] = _uri;
	}

	/**
	 * @dev handles returning the max supply for a token
	 * @param id token id to update uri for
	 */
	function maxSupply(uint256 id) public view returns (uint256) {
		return (_maxSupplies[id]);
	}

	/**
	 * @dev handles returning the max batch size for a token
	 * @param id token id to update uri for
	 */
	function maxBatchSize(uint256 id) public view returns (uint256) {
		return (_maxBatchSizes[id]);
	}

	/**
	 * @dev handles adjusting the max supply
	 * @param id token id to update uri for
	 * @param quantity to change the max supply to
	 */
	function setMaxSupply(uint256 id, uint256 quantity) public onlyOwner {
		_maxSupplies[id] = quantity;
	}

	/**
	 * @dev handles adjusting the max batch size
	 * @param id token id to update uri for
	 * @param quantity to change the max supply to
	 */
	function setMaxBatchSize(uint256 id, uint256 quantity) public onlyOwner {
		_maxBatchSizes[id] = quantity;
	}

	/** @dev EIP2981 royalties implementation. */

	// Maintain flexibility to modify royalties recipient (could also add basis points).
	function _setRoyalties(address newRecipient) internal {
		require(newRecipient != address(0), "royalty recipient zero address");
		_recipient = newRecipient;
	}

	function setRoyalties(address newRecipient) external onlyOwner {
		_setRoyalties(newRecipient);
	}

	// EIP2981 standard royalties return.
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
		external
		view
		override
		returns (address receiver, uint256 royaltyAmount)
	{
		return (_recipient, (_salePrice * 500) / 10000); // 5% (500 basis points)
	}

	// EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC1155, IERC165)
		returns (bool)
	{
		return (interfaceId == type(IERC2981).interfaceId ||
			super.supportsInterface(interfaceId));
	}
}