// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * Dolce&Gabbana Disco Drip Collection. Exclusive for DGFamily Collection Holders.
 * https://drops.unxd.com/dgfamily
 */
contract DGDiscoDrip is
	ERC1155,
	AccessControl,
	Pausable,
	ERC1155Burnable,
	ERC1155Supply,
	Ownable
{

	// access roles.
	bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	// royalty percentage for secondary sales in UNXD marketplace.
	uint256 public royaltyPercentage;

	// status flag for when minting is allowed. once the required amount of tokens are minted, this will be stopped.
	bool public mintingAllowed = true;

	// name
	string public constant name = "Dolce&Gabbana Disco Drip";

	// symbol
	string public constant symbol = "DGDD";

	// royalty % change event.
	event RoyaltyPercentageChanged(uint256 indexed newPercentage);

	// minting status change event.
	event MintingStatusChanged(bool indexed status);

	constructor(
		uint256 _royaltyPercentage,
		string memory _baseUri
	) ERC1155(_baseUri) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(URI_SETTER_ROLE, msg.sender);
		_grantRole(PAUSER_ROLE, msg.sender);
		_grantRole(MINTER_ROLE, msg.sender);
		royaltyPercentage = _royaltyPercentage;
	}

	/**
	* Set base URI
	* @param newuri: new uri
	*/
	function setURI(string memory newuri)
		public
		onlyRole(URI_SETTER_ROLE) {
		_setURI(newuri);
	}


	/**
	* Pause minting & transfers.
	*/
	function pause()
		public
		onlyRole(PAUSER_ROLE) {
		_pause();
	}

	/**
	* UnPause minting & transfers.
	*/
	function unpause()
		public
		onlyRole(PAUSER_ROLE) {
		_unpause();
	}

	/**
	* Mint NFT
	* @param account: address of recipient
	* @param id: id of token
	* @param amount: amount of tokens
	* @param data: any additional data
	*/
	function mint(address account, uint256 id, uint256 amount, bytes memory data)
		public
		onlyRole(MINTER_ROLE)
	{
		require(mintingAllowed, "MINTING_IS_STOPPED");
		_mint(account, id, amount, data);
	}

	/**
	* Mint Batch of NFTs
	* @param to: address of recipient
	* @param ids: array of token ids
	* @param amounts: array of amount of tokens
	* @param data: any additional data
	*/
	function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
		public
		onlyRole(MINTER_ROLE)
	{
		require(mintingAllowed, "MINTING_IS_STOPPED");
		_mintBatch(to, ids, amounts, data);
	}

	/**
	* Airdrop Batch of NFTs
	* @param to: array of recipients
	* @param ids: array of token ids
	* @param amounts: array of amount of tokens
	* @param data: any additional data
	*/
	function batchAirdrop(address[] memory to, uint256[][] memory ids, uint256[][] memory amounts, bytes memory data)
		public
		onlyRole(MINTER_ROLE)
	{
		require(mintingAllowed, "MINTING_IS_STOPPED");
		for (uint256 i = 0; i < to.length; i = i + 1) {
			_mintBatch(to[i], ids[i], amounts[i], data);
		}
	}

	/**
	 * @notice Stops minting. Once required amount of tokens are minted, minting will be stopped forever.
     * @dev Emits "MintingStatusChanged"
     */
	function endMinting()
		external
		onlyRole(MINTER_ROLE)
	{
		require(mintingAllowed, "MINTING_IS_ALREADY_STOPPED");
		mintingAllowed = false;
		emit MintingStatusChanged(false);
	}

	/**
	 * @notice Sets royalty percentage for secondary sale
     * @dev Emits "RoyaltyPercentageChanged"
     * @param percentage The percentage of royalty to be deducted
     */
	function setRoyaltyPercentage(uint256 percentage)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		royaltyPercentage = percentage;
		emit RoyaltyPercentageChanged(royaltyPercentage);
	}

	/**
	 * Get royalty amount at any specific price.
	 * @param price: price for sale.
     */
	function getRoyaltyInfo(uint256 price)
		external
		view
		returns (uint256 royaltyAmount, address royaltyReceiver)
	{
		require(price > 0, "PRICE_CAN_NOT_BE_ZERO");
		uint256 royalty = (price * royaltyPercentage)/100;
		return (royalty, owner());
	}

	// Before Transfer Hook
	function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
		internal
		whenNotPaused
		override(ERC1155, ERC1155Supply)
	{
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}

	// The following functions are overrides required by Solidity.
	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC1155, AccessControl)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

}