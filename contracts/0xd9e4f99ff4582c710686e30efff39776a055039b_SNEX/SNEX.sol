/**
 *Submitted for verification at Etherscan.io on 2023-06-28
*/

// SPDX-License-Identifier: CC-BY-4.0
/*
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
██░▄▄▄░██░▀██░██░▄▄▄█▄▀█▀▄██
██▄▄▄▀▀██░█░█░██░▄▄▄███░████
██░▀▀▀░██░██▄░██░▀▀▀█▀▄█▄▀██
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

v1.00 - 2023

written by Ariel Sebastián Becker

NOTICE
======

This is a custom contract, tailored and pruned to fit Spurious Dragon's limit of 24,576 bytes.
Because of that, you will see some modifications made to third-party libraries such as OpenZeppelin's.

THIS SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

*/
pragma solidity ^0.8.17;

string constant _strReverted = 'Unable to send value; recipient may have reverted!';
string constant _strLowCallFailed = 'Low-level call failed.';
string constant _strNonContract = 'Call to non-contract.';
string constant _strDelegateCallFailed = 'Low-level delegate call failed.';
string constant _strDelegateCallNonContract = 'Low-level delegate call to non-contract.';
string constant _strBalanceZeroAddy = 'Balance query for the zero address.';
string constant _strTransferZeroAddy = 'Cannot transfer to the zero address!';
string constant _strNotAuthorized = 'Not authorized!';
string constant _strTransferFailed = 'Transfer failed.';
string constant _strOutOfBounds = 'Out of bounds!';
string constant _strPaused = 'Contract is paused.';
string constant _strNotEnoughBalance = 'Insufficient balance!';
string constant _strTransferToNon721 = 'Attempted transfer to non ERC721Receiver implementer!';
string constant _strTokenName = 'SNEX';
string constant _strTokenTicker = 'SNEX';
string constant _strInvalidMultiproof = 'Invalid multiproof.';
string constant _strNotAllowlist = 'Not in allowlist!';
string constant _strPresaleFinished = 'Presale finished!';
string constant _strInPresale = 'Public sale not enabled yet!';
string constant _strJSONName = '"name": "';
string constant _strJSONDescription = '"description": "';

pragma solidity ^0.8.17;
interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

pragma solidity ^0.8.17;
interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function balanceOf(address owner) external view returns(uint256 balance);
	function ownerOf(uint256 tokenId) external view returns(address owner);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function transferFrom(address from, address to, uint256 tokenId) external;
	function approve(address to, uint256 tokenId) external;
	function getApproved(uint256 tokenId) external view returns(address operator);
	function setApprovalForAll(address operator, bool _approved) external;
	function isApprovedForAll(address owner, address operator) external view returns(bool);
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.17;
interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

pragma solidity ^0.8.17;
library Address {

	function isContract(address account) internal view returns(bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, _strNotEnoughBalance);
		(bool success, ) = recipient.call{value: amount}('');
		require(success, _strReverted);
	}

	function functionCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionCall(target, data, _strLowCallFailed);
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns(bytes memory) {
		return functionCallWithValue(target, data, value, _strLowCallFailed);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
		require(address(this).balance >= value, _strNotEnoughBalance);
		require(isContract(target), _strNonContract);
		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns(bytes memory) {
		return functionStaticCall(target, data, _strLowCallFailed);
	}

	function functionStaticCall( address target, bytes memory data, string memory errorMessage) internal view returns(bytes memory) {
		require(isContract(target), _strNonContract);
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionDelegateCall(target, data, _strDelegateCallFailed);
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		require(isContract(target), _strDelegateCallNonContract);
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns(bytes memory) {
		if(success) {
			return returndata;
		}
		else {
			if(returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			}
			else {
				revert(errorMessage);
			}
		}
	}
}

pragma solidity ^0.8.17;
abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}

pragma solidity ^0.8.17;
library Strings {
	bytes16 private constant _SYMBOLS = '0123456789abcdef';
	uint8 private constant _ADDRESS_LENGTH = 20;

	function toString(uint256 value) internal pure returns(string memory) {
		if(value == 0) {
			return '0';
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

	function toHexString(uint256 value, uint256 length) internal pure returns(string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = '0';
		buffer[1] = 'x';
		for(uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _SYMBOLS[value & 0xf];
			value >>= 4;
		}

		return string(buffer);
	}

	function toHexString(address addr) internal pure returns(string memory) {
		return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
	}

	function stringLength(string memory s) internal pure returns(uint256) {
		return bytes(s).length;
	}
}

pragma solidity ^0.8.17;
abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

pragma solidity ^0.8.17;
contract ERC721 is Context, ERC165, IERC721 {
	using Address for address;
	using Strings for uint256;

	mapping(uint256 => address) private _owners;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
		return
		interfaceId == type(IERC721).interfaceId ||
		super.supportsInterface(interfaceId);
	}

	function balanceOf(address owner) public view virtual override returns(uint256) {
		require(owner != address(0), _strBalanceZeroAddy);
		return _balances[owner];
	}

	function ownerOf(uint256 tokenId) public view virtual override returns(address) {
		address owner = _owners[tokenId];
		require(owner != address(0), _strOutOfBounds);
		return owner;
	}

	function approve(address to, uint256 tokenId) public virtual override {
		address owner = ERC721.ownerOf(tokenId);
		require(to != owner, _strNotAuthorized);
		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
				_strNotAuthorized
		);
		_approve(to, tokenId);
	}

	function getApproved(uint256 tokenId) public view virtual override returns(address) {
		require(_exists(tokenId), _strOutOfBounds);
		return _tokenApprovals[tokenId];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(operator != _msgSender(), _strNotAuthorized);
		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenId) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), _strNotAuthorized);
		_transfer(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
		safeTransferFrom(from, to, tokenId, '');
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), _strNotAuthorized);
		_safeTransfer(from, to, tokenId, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
		_transfer(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), _strTransferToNon721);
	}

	function _exists(uint256 tokenId) internal view virtual returns(bool) {
		return _owners[tokenId] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
		require(_exists(tokenId), _strOutOfBounds);
		address owner = ERC721.ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}

	function _safeMint(address to, uint256 tokenId) internal virtual {
		_safeMint(to, tokenId, '');
	}

	function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
		_mint(to, tokenId);
		require(
			_checkOnERC721Received(address(0), to, tokenId, _data),
				_strTransferToNon721
		);
	}

	function _mint(address to, uint256 tokenId) internal virtual {
		require(!_exists(tokenId), _strOutOfBounds);
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(address(0), to, tokenId);
	}

	function _transfer(address from, address to, uint256 tokenId) internal virtual {
		require(ERC721.ownerOf(tokenId) == from, _strNotAuthorized);
		require(to != address(0), _strTransferZeroAddy);
		require(_exists(tokenId), _strOutOfBounds);
		_approve(address(0), tokenId);
		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(from, to, tokenId);
	}

	function _approve(address to, uint256 tokenId) internal virtual {
		_tokenApprovals[tokenId] = to;
		emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
		if(to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if(reason.length == 0) {
					revert(_strTransferToNon721);
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		}
		else {
			return true;
		}
	}
}

pragma solidity ^0.8.17;
interface IERC4906 is IERC165, IERC721 {
	/// @dev This event emits when the metadata of a token is changed.
	/// So that the third-party platforms such as NFT market could
	/// timely update the images and related attributes of the NFT.
	event MetadataUpdate(uint256 _tokenId);

	/// @dev This event emits when the metadata of a range of tokens is changed.
	/// So that the third-party platforms such as NFT market could
	/// timely update the images and related attributes of the NFTs.
	event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

pragma solidity ^0.8.17;
contract Ownable {
	string public constant NOT_CURRENT_OWNER = '018001';
	string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = '018002';
	address public owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, NOT_CURRENT_OWNER);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}

pragma solidity ^0.8.17;
library Base64 {
	string internal constant _TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	function encode(bytes memory data) internal pure returns(string memory) {
		if(data.length == 0) return '';
		string memory table = _TABLE;
		string memory result = new string(4 * ((data.length + 2) / 3));

		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)
			for {
				let dataPtr := data
				let endPtr := add(data, mload(data))
			} lt(dataPtr, endPtr) {

			} {
				dataPtr := add(dataPtr, 3)
				let input := mload(dataPtr)
				mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
				mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
				mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
				mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
			}

			switch mod(mload(data), 3)
			case 1 {
				mstore8(sub(resultPtr, 1), 0x3d)
				mstore8(sub(resultPtr, 2), 0x3d)
			}
			case 2 {
				mstore8(sub(resultPtr, 1), 0x3d)
			}
		}

		return result;
	}
}

pragma solidity ^0.8.17;

/**
 * @dev Tailored and pruned.
 */
library MerkleProof {
	function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
		return processProof(proof, leaf) == root;
	}

	function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
		bytes32 computedHash = leaf;
		for(uint256 i = 0; i < proof.length; i++) {
			computedHash = _hashPair(computedHash, proof[i]);
		}
		return computedHash;
	}

	function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
		bytes32 computedHash = leaf;
		for(uint256 i = 0; i < proof.length; i++) {
			computedHash = _hashPair(computedHash, proof[i]);
		}
		return computedHash;
	}

	function processMultiProof(bytes32[] memory proof, bool[] memory proofFlags, bytes32[] memory leaves) internal pure returns (bytes32 merkleRoot) {
		uint256 leavesLen = leaves.length;
		uint256 totalHashes = proofFlags.length;

		require(leavesLen + proof.length - 1 == totalHashes, _strInvalidMultiproof);

		bytes32[] memory hashes = new bytes32[](totalHashes);
		uint256 leafPos = 0;
		uint256 hashPos = 0;
		uint256 proofPos = 0;

		for(uint256 i = 0; i < totalHashes; i++) {
			bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
			bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
			hashes[i] = _hashPair(a, b);
		}

		if(totalHashes > 0) {
			return hashes[totalHashes - 1];
		}
		else if(leavesLen > 0) {
			return leaves[0];
		}
		else {
			return proof[0];
		}
	}

	function processMultiProofCalldata(bytes32[] calldata proof, bool[] calldata proofFlags, bytes32[] memory leaves) internal pure returns (bytes32 merkleRoot) {
		uint256 leavesLen = leaves.length;
		uint256 totalHashes = proofFlags.length;

		require(leavesLen + proof.length - 1 == totalHashes, _strInvalidMultiproof);

		bytes32[] memory hashes = new bytes32[](totalHashes);
		uint256 leafPos = 0;
		uint256 hashPos = 0;
		uint256 proofPos = 0;

		for(uint256 i = 0; i < totalHashes; i++) {
			bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
			bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
			hashes[i] = _hashPair(a, b);
		}

		if(totalHashes > 0) {
			return hashes[totalHashes - 1];
		}
		else if(leavesLen > 0) {
			return leaves[0];
		}
		else {
			return proof[0];
		}
	}

	function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
		return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
	}

	function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
		/// @solidity memory-safe-assembly
		assembly {
			mstore(0x00, a)
			mstore(0x20, b)
			value := keccak256(0x00, 0x40)
		}
	}
}

pragma solidity ^0.8.17;
contract SNEX is Context, ERC721, IERC4906 {
	using MerkleProof for bytes32[];

	bool private _boolPaused = false;
	bool private _boolAllowList = true;

	bytes32 _allowlistMerkleRoot;

	uint256 private _presaleMintFee = 10000000000000000; //10000000000000000, 0.01 ETH
	uint256 private _publicMintFee = 50000000000000000; //50000000000000000, 0.05 ETH
	uint256 private _mintedTokens = 0;
	uint256 private _maxCap = 5000;
	uint256 private _presaleMaxSales = 1000;
	uint256 private _sellerFeePoints = 750; // 7.5%

	address private _addrContractOwner = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;

	string private _strDescription = 'Proof of rich';
	string private _strBaseURI = 'https://proofofrich.com/';
	string private _strExternalURLPrefix = string(abi.encodePacked(_strBaseURI, 'token/'));
	string private _strScript = '';
	string private _strCommonBlack = 'common-black';
	string private _strCommonWhite = 'common-white';
	string private _strCommonBlack2 = 'common-black-common-black';
	string private _strCommonWhite2 = 'common-white-common-white';
	string private _strCommonCommon = 'common-common';
	string private _strCommonCommon2 = 'common-common-common-common';

	string[27] private _strPalette = ['#00a5e3','#8dd7bf','#ff96c5','#ff5768','#ffbf65','#fc6238','#ffd872','#f2d4cc','#e77577','#6c88c4','#c05780','#ff828b','#e7c582','#00b0ba','#0065a2','#00cdac','#ff6f68','#ffdacc','#ff60a8','#cff800','#ff5c77','#4dd091','#ffec59','#ffa23a','#74737a','#ffffff','#292929'];

	string private _strSVGContract = '';
	string private _strSVGPrefix = '';
	string private _strSVGUnrevealed = '';

	string private _strContractJSON = string(abi.encodePacked(
		'{',
			_strJSONName, _strTokenName, '",',
			_strJSONDescription, _strDescription, '",',
			'"symbol": "', _strTokenTicker, '",',
			'"image": "', _strSVGContract, '",',
			'"external_link": "', _strBaseURI, '",',
			'"total_supply": "', Strings.toString(_maxCap),'",',
			'"seller_fee_basis_points": "', Strings.toString(_sellerFeePoints),'",',
			'"fee_recipient": "', Strings.toHexString(_addrContractOwner), '"'
		'}'
	));

	struct TokenProperties {
		bool revealed;
		uint256 rarity;
		uint256[] tokenColors;
	}

	mapping(uint => TokenProperties) private tokenData;

// ==================================================================
//                              MODIFIERS
// ==================================================================

	modifier insideBounds(uint256 tokenId) {
		require(tokenId > 0, _strOutOfBounds);
		require(tokenId <= _mintedTokens, _strOutOfBounds);
		_;
	}

	modifier onlyAdmin {
		require(_msgSender() == _addrContractOwner, _strNotAuthorized);
		_;
	}

	constructor() ERC721() {}
// ==================================================================
//                       AUX INTERNAL FUNCTIONS
// ==================================================================

	function _buildArrayColors(uint256 tokenId) internal view returns(string memory) {
		string memory _retValue = "[";

		for(uint i = 0; i < 4; i++) {
			_retValue = string(abi.encodePacked(_retValue, Strings.toString(tokenData[tokenId].tokenColors[i])));
			if(i < 3) {
				_retValue = string(abi.encodePacked(_retValue, ","));
			}
		}
		_retValue = string(abi.encodePacked(_retValue, "]"));

		return _retValue;
	}

	function _buildHexColor(uint256 _tokenId, uint256 _colorIndex) internal view returns(string memory) {
		return _strPalette[tokenData[_tokenId].tokenColors[_colorIndex]];
	}

	function _buildSVG(uint256 _tokenId) internal view returns(string memory) {
		return string(abi.encodePacked(
			_strSVGPrefix, _buildHexColor(_tokenId, 0), ";fill-opacity:1;stroke-width:2.64583;stroke-linecap:round;stroke-linejoin:round' id='segment1' cx='65.458244' cy='10.460792' r='13.229167' transform='rotate(36.46956)' /><circle style='fill:", _buildHexColor(_tokenId, 1), ";fill-opacity:1;stroke-width:2.64583;stroke-linecap:round;stroke-linejoin:round' id='segment2' cx='69.997108' cy='8.2027063' r='13.229167' transform='rotate(36.46956)' /><circle style='fill:", _buildHexColor(_tokenId, 2), ";fill-opacity:1;stroke-width:2.64583;stroke-linecap:round;stroke-linejoin:round' id='segment3' cx='76.831429' cy='8.6074381' r='13.229167' transform='rotate(36.46956)' /><circle style='fill:", _buildHexColor(_tokenId, 3), ";fill-opacity:1;stroke-width:2.64583;stroke-linecap:round;stroke-linejoin:round' id='segment4' cx='82.556908' cy='11.740624' r='13.229167' transform='rotate(36.46956)' /></svg>"));
	}

	function _ownerBalance(uint256 tokenId) internal view returns(uint256) {
		address owner = ownerOf(tokenId);
		return owner.balance;
	}

	function _getTokenRarity(uint256 _rarity) internal view returns(string memory) {
		string memory retValue = '';
		if(_rarity == 1) {
			retValue = _strCommonBlack;
		}
		else if(_rarity == 2) {
			retValue = _strCommonWhite;
		}
		else if(_rarity == 3) {
			retValue = _strCommonBlack2;
		}
		else if(_rarity == 4) {
			retValue = _strCommonWhite2;
		}
		else if(_rarity == 5) {
			retValue = _strCommonCommon;
		}
		else if(_rarity == 6) {
			retValue = _strCommonCommon2;
		}
		else {
			retValue = 'Unrevealed';
		}

		return retValue;
	}

// ==================================================================
//                       MAIN PUBLIC FUNCTIONS
// ==================================================================

// ------------------------------------------------------------------
//                               GETTERS
// ------------------------------------------------------------------
	/// @dev Returns the URI to the contract's JSON.
	///	 Note: can be a URL or a base64-encoded JSON.
	function contractURI() public view returns(string memory) {
		string memory _retValue = string(
			abi.encodePacked(
				'data:application/json;base64,',
				Base64.encode(abi.encodePacked(_strContractJSON))
			)
		);

		return _retValue;
	}

	/// @dev Generates the token HTML.
	/// @param tokenId Token ID.
	function generateHTML(uint256 tokenId) insideBounds(tokenId) public view returns(string memory) {
		bytes memory html = abi.encodePacked(
			"<!DOCTYPE html><html><head><meta charset='UTF-8' /><style>body{margin: 0;}canvas{background:#000;display:block;}</style></head><body><canvas id='snex'></canvas><script>const tokenId=", Strings.toString(tokenId), ";let minimum=5;let balance=", Strings.toString(_ownerBalance(tokenId)),";if(balance==0){minimum=0}let snakeLength=Math.floor(balance/1000000000000000000)+minimum;if(snakeLength>9995){snakeLength=9995}const tokenColors=", _buildArrayColors(tokenId),";</script><script>", _strScript, "</script></body></html>"
		);

		return string(
			abi.encodePacked(
				'data:text/html;base64,',
				Base64.encode(html)
			)
		);
	}

	/// @dev Returns contract's total minted tokens.
	function mintedTokens() public view returns(uint256) {
		return _mintedTokens;
	}

	/// @dev Returns the contract's name.
	function name() public view returns(string memory) {
		return _strTokenName;
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
		return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
	}

	/// @dev Returns the contract's symbol, or ticker.
	function symbol() public view returns(string memory) {
		return _strTokenTicker;
	}

	/// @dev Returns a base64-encoded JSON that describes the given tokenID
	/// @param tokenId Token ID.
	function tokenURI(uint256 tokenId) insideBounds(tokenId) public view returns(string memory) {
		string memory _strSuffix = '';
		if(tokenData[tokenId].revealed == true) {
			_strSuffix = string(abi.encodePacked(
				'"image": "', _buildSVG(tokenId), '",',
				'"animation_url": "', generateHTML(tokenId), '"'
			));
		}
		else {
			_strSuffix = string(abi.encodePacked(
				'"image": "', _strSVGUnrevealed, '"'
			));
		}
		return string(
			abi.encodePacked(
				'data:application/json;base64,',
				Base64.encode(abi.encodePacked(
					'{',
						_strJSONName, 'SNEX #', Strings.toString(tokenId), '",',
						_strJSONDescription, _strDescription, '",',
						'"external_url": "', _strExternalURLPrefix, Strings.toString(tokenId), '",',
						'"attributes": [',
							'{',
								'"trait_type": "Rarity", ',
								'"value": "', _getTokenRarity(tokenData[tokenId].rarity), '"',
							'}',
						'],',
						_strSuffix,
					'}'
				))
			)
		);
	}

	/// @dev Returns contract's max supply.
	function totalSupply() public view returns(uint256) {
		return _maxCap;
	}

// ------------------------------------------------------------------
//                               SETTERS
// ------------------------------------------------------------------
	/// @dev Changes the contract's owner.
	///	 Note: Only current contract's owner can change this.
	/// @param _newOwner Address of the new owner.
	function changeContractOwner(address _newOwner) onlyAdmin public {
		_addrContractOwner = _newOwner;
	}

	/// @dev Changes mint fee.
	///	 Note: Only contract's owner can change this.
	/// @param _newValue New value in wei.
	/// @param _isPresale true for presale fee, false for public fee.
	function changeMintFee(uint256 _newValue, bool _isPresale) onlyAdmin public {
		if(_isPresale) {
			_presaleMintFee = _newValue;
		}
		else {
			_publicMintFee = _newValue;
		}
	}

	/// @dev Changes onchain contents.
	///	 Note: Only contract's owner can change this.
	/// @param _string New content, minified.
	/// @param _index 1 for contract-level SVG, 2 for unrevealed SVG, 3 for revealed SVG prefix, 4 for JS script, 5 for description, 6 for base URI.
	function changeOnchainData(string memory _string, uint8 _index) onlyAdmin public {
		if(_index == 1) {
			_strSVGContract = _string;
		}
		else if(_index == 2) {
			_strSVGUnrevealed = _string;
		}
		else if(_index == 3) {
			_strSVGPrefix = _string;
		}
		else if(_index == 4) {
			_strScript = _string;
		}
		else if(_index == 5) {
			_strDescription = _string;
		}
		else if(_index == 6) {
			_strBaseURI = _string;
		}
		if(_mintedTokens > 0) {
			emit BatchMetadataUpdate(1, (_mintedTokens + 1));
		}
	}

	/// @dev Mints a new token during public sale.
	function mint() public payable {
		uint256 _newTokenId = _mintedTokens + 1;
		require(!_boolPaused, _strPaused);
		require(_newTokenId > 0, _strOutOfBounds);
		require(_newTokenId <= _maxCap, _strOutOfBounds);
		require(!_boolAllowList, _strInPresale);

		if(_msgSender() != _addrContractOwner) {
			require(msg.value >= _publicMintFee, _strNotEnoughBalance);
		}

		_mintedTokens++;
		_mint(_msgSender(), _newTokenId);
		tokenData[_newTokenId].revealed = false;
		tokenData[_newTokenId].rarity = 0;
	}

	/// @dev Mints a new token during presale.
	function presaleMint(bytes32[] memory _proof) public payable {
		uint256 _newTokenId = _mintedTokens + 1;
		bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender(), 1))));
		require(!_boolPaused, _strPaused);
		require(_newTokenId > 0, _strOutOfBounds);
		require(_newTokenId <= _maxCap, _strOutOfBounds);
		require(_boolAllowList, _strPresaleFinished);
		require(MerkleProof.verify(_proof, _allowlistMerkleRoot, _leaf), _strNotAllowlist);

		if(_msgSender() != _addrContractOwner) {
			require(msg.value >= _presaleMintFee, _strNotEnoughBalance);
		}

		if(_newTokenId == _presaleMaxSales) {
			// Pauses the contract automatically to avoid overmint.
			// Also changes to public mint mode.
			_boolPaused = true;
			_boolAllowList = false;
		}

		_mintedTokens++;
		_mint(_msgSender(), _newTokenId);
		tokenData[_newTokenId].revealed = false;
		tokenData[_newTokenId].rarity = 0;
	}

	/// @dev Reveals the traits of the given tokens.
	///	 Note: Only contract's owner can use this function.
	/// @param _tokenRarity Rarity expressed as an index, array.
	/// @param _colorList List containing array of colors for each token.
	/// @param _initialToken First token number to be revealed.
	/// @param _finalToken Last token number to be revealed.
	function reveal(uint256[] memory _tokenRarity, uint256[][] memory _colorList, uint256 _initialToken, uint256 _finalToken) onlyAdmin public {
		uint256 _paramCounter = 0;
		require(_initialToken > 0, _strOutOfBounds);
		require(_finalToken <= _mintedTokens, _strOutOfBounds);
		for(uint i = _initialToken; i <= _finalToken ; i++) {
			tokenData[i].revealed = true;
			tokenData[i].rarity = _tokenRarity[_paramCounter];
			tokenData[i].tokenColors = _colorList[_paramCounter];
			_paramCounter++;
		}

		emit BatchMetadataUpdate(_initialToken, _finalToken);
	}

	/// @dev Ends the presale stage. Optionally pauses the contract.
	///	 Note: Only contract's owner can use this function.
	/// @param _boolAlsoPause set this to true to pause the contract.
	function finishPreSale(bool _boolAlsoPause) public onlyAdmin {
		_boolAllowList = false;
		if(_boolAlsoPause) {
			_boolPaused = true;
		}
	}

	/// @dev Sets the merkle root.
	///	 Note: Only contract's owner can use this function.
	/// @param _merkleRoot merkle root.
	function setAllowlistMerkleRoot(bytes32 _merkleRoot) public onlyAdmin {
		_allowlistMerkleRoot = _merkleRoot;
	}

	/// @dev Pauses or unpauses the contract
	///	 Note: Only contract's owner can change this.
	/// @param _state boolean, true to pause, false to unpause
	function setPauseStatus(bool _state) onlyAdmin public {
		_boolPaused = _state;
	}

	/// @dev Allows to withdraw any ETH available on this contract.
	///	 Note: Only contract's owner can withdraw.
	function withdraw() public onlyAdmin payable {
		uint balance = address(this).balance;
		require(!_boolPaused, _strPaused);
		require(balance > 0, _strNotEnoughBalance);
		(bool success, ) = (_msgSender()).call{value: balance}('');
		require(success, _strTransferFailed);
	}
}