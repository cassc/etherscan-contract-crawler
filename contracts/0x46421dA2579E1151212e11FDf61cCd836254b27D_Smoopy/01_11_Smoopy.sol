// SPDX-License-Identifier: MIT
/*                
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%&@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%#((%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%@@@@@@@((((((((((%@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@(  ((((((((((@@(%%%%%%%%@@           @@(((((((%%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@     ((((((((((((((%%%%@.      @@@       @&(((((%%[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@    ((((((((((((((%%@..    @&&&&&&@      @(((%%%[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@    ((((((((((((((@...   @&**&&&%,@.     @((%%....&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@ @*(((((((((((((@...     @@**   &@      @%%......,@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@   ((((((((((((@....      [email protected]*  &&@     @&[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@     ((((((((((#@....    @ ,,,,,&@     @*.........#@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@      ((((((((((%@....    @@@@@       @*@[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@(     (((((((((((((@@[email protected]@@@@@%............,%%@@@@@@@@@@@@@@@
@@@@@@@@@@@@@((((((((((((((((((@@#(((((((&@@ /@@@............%%%%&@@@@@@@@@@@@@@
@@@@@@@@@@@@@((((((((((((((((((((((((((((@  ****@@..........%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@(((((((((((((((((((((((((((@&   ***@........%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@#(((((((((((((((((((((((((((@  ****@((/...%%%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((((((((((((#(((((((((((((@  ****@((((((((%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((%%%......(((((((((((@   .**@(((((((((((((%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%%%%.............(((((((((@  ***@((((((((((((((((%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%%....%%............((((((((@@&(((((((((((((@@((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%[email protected]@...............(((((((((((((((((((((@@((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@[email protected]@...................(((((((((((((((((@(((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%[email protected]@................         /((((((((((@((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@%%%#[email protected]@...........                        @@((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@%%%%%%%@@...                                @((((@@@@@@@@@@@@@@@@                
*/
/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 * @edited: Moopy 0xlunes				*
 ****************************************
 * Blimpie-ERC721 implementation      	*
 * Mint by ID and transfer lock 	 	*
 ****************************************/

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

abstract contract ERC721Custom is Context, ERC165, IERC721, IERC721Metadata {
	using Address for address;

	struct Token {
		address owner;
	}

	mapping(address => uint256) balances;
	uint256 public constant MAX_SUPPLY = 5000;
	Token[MAX_SUPPLY] public tokens;
	string private _name;
	string private _symbol;

	mapping(uint256 => address) internal _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	//public view
	function balanceOf(address owner)
		public
		view
		override
		returns (uint256 balance)
	{
		return balances[owner];
	}

	function name() external view override returns (string memory name_) {
		return _name;
	}

	function ownerOf(uint256 tokenId)
		public
		view
		override
		returns (address owner)
	{
		require(_exists(tokenId), "ERC721Custom: query for nonexistent token");
		return tokens[tokenId].owner;
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC165, IERC165)
		returns (bool isSupported)
	{
		return
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	function symbol() external view override returns (string memory symbol_) {
		return _symbol;
	}

	//approvals
	function approve(address to, uint256 tokenId) external override {
		address owner = ownerOf(tokenId);
		require(to != owner, "ERC721Custom: approval to current owner");

		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
			"ERC721Custom: caller is not owner nor approved for all"
		);

		_approve(to, tokenId);
	}

	function getApproved(uint256 tokenId)
		public
		view
		override
		returns (address approver)
	{
		require(_exists(tokenId), "ERC721Custom: query for nonexistent token");
		return _tokenApprovals[tokenId];
	}

	function isApprovedForAll(address owner, address operator)
		public
		view
		override
		returns (bool isApproved)
	{
		return _operatorApprovals[owner][operator];
	}

	function setApprovalForAll(address operator, bool approved)
		external
		override
	{
		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	//transfers
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external override {
		safeTransferFrom(from, to, tokenId, "");
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public override {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			"ERC721Custom: caller is not owner nor approved"
		);
		_safeTransfer(from, to, tokenId, _data);
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external override {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			"ERC721Custom: caller is not owner nor approved"
		);
		_transfer(from, to, tokenId);
	}

	//internal
	function _approve(address to, uint256 tokenId) internal {
		_tokenApprovals[tokenId] = to;
		emit Approval(ownerOf(tokenId), to, tokenId);
	}

	function _exists(uint256 tokenId) internal view returns (bool) {
		return tokenId < tokens.length && tokens[tokenId].owner != address(0);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {
		require(from == address(0) || to == address(0), "transfer not permitted");

		if (from != address(0)) --balances[from];

		if (to != address(0)) ++balances[to];

	}

	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) private returns (bool) {
		if (to.isContract()) {
			try
				IERC721Receiver(to).onERC721Received(
					_msgSender(),
					from,
					tokenId,
					_data
				)
			returns (bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert("ERC721Custom: transfer to non ERC721Receiver implementer");
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId)
		internal
		view
		returns (bool)
	{
		require(_exists(tokenId), "ERC721Custom: query for nonexistent token");
		address owner = ownerOf(tokenId);
		return (spender == owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(owner, spender));
	}

	function _safeTransfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		_transfer(from, to, tokenId);
		require(
			_checkOnERC721Received(from, to, tokenId, _data),
			"ERC721Custom: transfer to non ERC721Receiver implementer"
		);
	}

	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		require(
			ownerOf(tokenId) == from,
			"ERC721Custom: transfer of token that is not own"
		);
		_beforeTokenTransfer(from, to, tokenId);

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);
		tokens[tokenId].owner = to;

		emit Transfer(from, to, tokenId);
	}
}

pragma solidity ^0.8.0;

abstract contract ERC721CustomEnumerable is ERC721Custom, IERC721Enumerable {
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(IERC165, ERC721Custom)
		returns (bool isSupported)
	{
		return
			interfaceId == type(IERC721Enumerable).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index)
		external
		view
		override
		returns (uint256 tokenId)
	{
		uint256 count;
		for (uint256 i; i < tokens.length; ++i) {
			if (owner == tokens[i].owner) {
				if (count == index) return i;
				else ++count;
			}
		}

		revert("ERC721CustomEnumerable: owner index out of bounds");
	}

	function tokenByIndex(uint256 index)
		external
		view
		override
		returns (uint256 tokenId)
	{
		require(
			index < tokens.length,
			"ERC721CustomEnumerable: query for nonexistent token"
		);
		return index;
	}
}

pragma solidity ^0.8.0;

interface IERC721CustomBatch {
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view returns( bool );
  function transferBatch( address from, address to, uint[] calldata tokenIds, bytes calldata data ) external;
  function walletOfOwner( address account ) external view returns( uint[] memory );
}

pragma solidity ^0.8.0;

abstract contract ERC721CustomBatch is ERC721CustomEnumerable, IERC721CustomBatch {
	function isOwnerOf(address account, uint256[] calldata tokenIds)
		external
		view
		override
		returns (bool)
	{
		for (uint256 i; i < tokenIds.length; ++i) {
			if (account != tokens[tokenIds[i]].owner) return false;
		}

		return true;
	}

	function transferBatch(
		address from,
		address to,
		uint256[] calldata tokenIds,
		bytes calldata data
	) external override {
		for (uint256 i; i < tokenIds.length; ++i) {
			safeTransferFrom(from, to, tokenIds[i], data);
		}
	}

	function walletOfOwner(address account)
		public
		view
		override
		returns (uint256[] memory wallet_)
	{
		uint256 count;
		uint256 quantity = balanceOf(account);
		uint256[] memory wallet = new uint256[](quantity);
		for (uint256 i; i < tokens.length; ++i) {
			if (account == tokens[i].owner) {
				wallet[count++] = i;
				if (count == quantity) break;
			}
		}
		return wallet;
	}
}

pragma solidity ^0.8.0;

contract Smoopy is ERC721CustomBatch, Ownable {
	using Strings for uint256;

	mapping (address => bool) public approvedMinters;

	string private _baseURI;
	string private constant TOKENURISUFFIX = ".json";

	constructor() ERC721Custom("sMoopy", "SMOOPY") {}

	//view: IERC721Metadata
	function tokenURI(uint256 tokenId)
		external
		view
		override
		returns (string memory)
	{
		require(_exists(tokenId), "SMOOPY: query for nonexistent token");
		return
			string(
				abi.encodePacked(_baseURI, tokenId.toString(), TOKENURISUFFIX)
			);
	}

	//view: IERC721Enumerable
	function totalSupply() public view override returns (uint256 totalSupply_) {
		return tokens.length;
	}

	//only approved minters
	function mint(address to, uint256 tokenId) external {
		require(approvedMinters[msg.sender], "address not approved");
		require(!_exists(tokenId), "token already minted");

		_beforeTokenTransfer(address(0), to, tokenId);

		tokens[tokenId].owner = to;
		
		emit Transfer(address(0), to, tokenId);
	}

	//only approved minters
	function burn(address from, uint256 tokenId) external {
		require(approvedMinters[msg.sender], "address not approved");
		require(_exists(tokenId), "token not minted");

		_beforeTokenTransfer(from, address(0), tokenId);

		tokens[tokenId].owner = address(0);

		emit Transfer(from, address(0), tokenId);
	}

	//onlyOwner
	function setBaseURI(string calldata _newBaseURI) external onlyOwner {
		_baseURI = _newBaseURI;
	}

	function addApprovedMinter(address[] memory addresses) external onlyOwner {
		for (uint256 i; i < addresses.length; i++) {
			approvedMinters[addresses[i]] = true;
		}
	}

	function removeApprovedMinter(address[] memory addresses) external onlyOwner {
		for (uint256 i; i < addresses.length; i++) {
			approvedMinters[addresses[i]] = false;
		}
	}
}