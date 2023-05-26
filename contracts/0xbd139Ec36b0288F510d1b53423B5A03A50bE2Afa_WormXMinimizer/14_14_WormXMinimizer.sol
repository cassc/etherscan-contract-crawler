// SPDX-License-Identifier: CC0
pragma solidity ^0.8.9;

import './Worm1000/IWorm1000Artwork.sol';
import './IERC721Payable.sol';

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721Receiver.sol';
import '@openzeppelin/contracts/interfaces/IERC721Enumerable.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract WormXMinimizer is IERC721Payable, Ownable {
	using Address for address;

	// ============================================================
	// STORAGE
	// ============================================================

	// Address of the Original Worm contract
	IERC721Enumerable edwormContract;
	// Address of the Resurrected Worm contract
	IERC721Enumerable edwoneContract;
	// Address of the Worm Vigils contract
	IWormVigils vigilsContract;
	// Address of the Worm 1000 Artwork contract
	IWorm1000Artwork artContract;

	// The next token ID to be minted
	uint private _currentIndex;

	// Mapping from token ID to frozen lights
	mapping(uint => uint[4]) private _lights;

	// Mapping from token ID to owner address
	mapping(uint => address) private _owners;

	// Mapping owner address to token count
	mapping(address => uint) private _balances;

	// Mapping from token ID to approved address
	mapping(uint => address) private _tokenApprovals;

	// Mapping from owner to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	// ============================================================
	// CONSTRUCTOR
	// ============================================================

	constructor(
		IERC721Enumerable _edwormContract,
		IERC721Enumerable _edwoneContract,
		IWormVigils _vigilsContract,
		IWorm1000Artwork _artContract
	) {
		edwormContract = _edwormContract;
		edwoneContract = _edwoneContract;
		vigilsContract = _vigilsContract;
		artContract = _artContract;
	}

	// ============================================================
	// ERC721 - NFT
	// ============================================================

	// In the interest of saving gas and being responsible stewards
	// of the Ethereum environment, we have chosen not to duplicate
	// data stored in other contracts. Because the Blessing is only
	// being sent to Disciples, we can reference those contracts to
	// get the addresses of Disciples and skip storing balances and
	// owners. Only when a token is transferred is the data stored.
	// This reduces the cost of minting by ~93% and further enables
	// all 1000 Blessings to be airdropped in a single transaction.
	function bless(uint quantity) external onlyOwner {
		require(
			_currentIndex + quantity <= 1000,
			'All 1000 blessings have been minted.'
		);

		unchecked {
			for (uint i = 0; i < quantity; i++) {
				// Increment FIRST so it starts at 1
				_currentIndex++;

				// Get the address to mint to (from Edworm or Edwone contracts)
				address to = discipleAddress(_currentIndex);

				// NOTE: we are NOT storing balances OR owners to save gas
				// _balances[to] += 1;
				// _owners[_currentIndex] = to;

				emit Transfer(address(0), to, _currentIndex);
			}
		}
	}

	function totalSupply() public view returns (uint) {
		return _currentIndex;
	}

	// This function is different because of the optimizations
	function balanceOf(address owner) public view returns (uint) {
		// If they're a disciple under 1000, then we add 1 to their balance
		// because we're not storing their balance when we mint to save gas
		bool isSubKilo = isSubKiloDisciple(owner);
		uint balance = _balances[owner];

		// Unchecked to allow overflows to offset the balance
		unchecked {
			if (isSubKilo) {
				balance += 1;
			}
		}

		return balance;
	}

	function isSubKiloDisciple(address owner) public view returns (bool) {
		// First we check to see if they're an Edworm disciple
		bool isEdwormDisciple = IERC721Enumerable(edwormContract).balanceOf(
			owner
		) == 1;

		// If they are, then they're under a 1000
		if (isEdwormDisciple) {
			return true;
		}

		// If not, we check to see if they're an Edwone disciple
		bool isEdwoneDisciple = IERC721Enumerable(edwoneContract).balanceOf(
			owner
		) == 1;

		// If they are, then we check to see if they're under 1000
		if (isEdwoneDisciple) {
			uint discipleId = IERC721Enumerable(edwoneContract).tokenOfOwnerByIndex(
				owner,
				0
			);

			return discipleId < 1001;
		}

		// Otherwise, they're not
		return false;
	}

	// This function is different because of the optimizations
	function ownerOf(uint tokenId) public view returns (address) {
		_requireMinted(tokenId);

		address owner = _owners[tokenId];

		// If the owner is 0 that means the disciple still owns the
		// the blessing so then we return the disciple as the owner
		if (owner == address(0)) {
			return discipleAddress(tokenId);
		}
		// However, if the owner is NOT 0- meaning the owner has been
		// stored on transfer then return the owner as normal
		else {
			return owner;
		}
	}

	// Given a token ID, returns the address of the disciple
	function discipleAddress(uint tokenId) public view returns (address) {
		// If the token ID is less than 273 then we lookup using Edworm
		if (tokenId < 273) {
			return IERC721Enumerable(edwormContract).ownerOf(tokenId);
		}
		// Otherwise we lookup using Edwone
		else {
			return IERC721Enumerable(edwoneContract).ownerOf(tokenId);
		}
	}

	// Given a token ID, returns the lights owned by the disciple
	function discipleLights(
		uint tokenId
	) public view returns (uint[4] memory lightsByLumenLevel) {
		// Check to see if the lights are frozen
		// (They are frozen if there is an owner)
		if (_owners[tokenId] != address(0)) {
			return _lights[tokenId];
		}

		// Prepare the array to return
		uint[4] memory lights;

		// Get the disciple address
		address disciple = discipleAddress(tokenId);

		// Get the disciple light balance
		uint lightsOwned = vigilsContract.balanceOf(disciple);

		// Return early if no lights are owned
		if (lightsOwned == 0) {
			return lights;
		}

		// Loop through the lights
		for (uint i; i < lightsOwned; i++) {
			// Get the light ID
			uint lightId = vigilsContract.tokenOfOwnerByIndex(disciple, i);

			// Get the light data
			(, uint64 lumenLevel, ) = vigilsContract.getCandleData(lightId);

			// Tabulate the light according to brightness
			if (lumenLevel == 3) {
				lights[3] += 1;
			} else if (lumenLevel == 2) {
				lights[2] += 1;
			} else if (lumenLevel == 1) {
				lights[1] += 1;
			} else {
				lights[0] += 1;
			}
		}

		return lights;
	}

	// ============================================================
	// ERC721 - Metadata
	// ============================================================

	function name() public pure returns (string memory) {
		return 'The Worm x minimizer';
	}

	function symbol() public pure returns (string memory) {
		return 'WxM';
	}

	// Get the JSON & SVG from minimizer's brilliant contract
	function tokenURI(uint discipleId) public view returns (string memory) {
		uint[4] memory lightsByLumenLevel = discipleLights(discipleId);

		return artContract.tokenURI(discipleId, lightsByLumenLevel, false);
	}

	// ============================================================
	// ERC721 - Management
	// ============================================================

	// Split all revenue between theworm.eth & minimizer.eth
	receive() external payable {
		uint half = msg.value / 2;

		payable(owner()).transfer(half);
		payable(IWorm1000Artwork(artContract).royaltyRecipient()).transfer(
			msg.value - half
		);
	}

	// Split all revenue between theworm.eth & minimizer.eth
	function withdrawTokens(IERC20 token) external {
		uint balance = token.balanceOf(address(this));
		uint half = balance / 2;

		token.transfer(owner(), half);
		token.transfer(
			IWorm1000Artwork(artContract).royaltyRecipient(),
			balance - half
		);
	}

	// ============================================================
	// ERC721 - Approvals
	// ============================================================

	function approve(address to, uint tokenId) external {
		address owner = ownerOf(tokenId);
		require(to != owner, 'ERC721: approval to current owner');

		require(
			msg.sender == owner || isApprovedForAll(owner, msg.sender),
			'ERC721: approve caller is not token owner or approved for all'
		);

		_tokenApprovals[tokenId] = to;
		emit Approval(owner, to, tokenId);
	}

	function getApproved(uint tokenId) public view returns (address operator) {
		_requireMinted(tokenId);

		return _tokenApprovals[tokenId];
	}

	function isApprovedForAll(
		address owner,
		address operator
	) public view returns (bool) {
		return _operatorApprovals[owner][operator];
	}

	function setApprovalForAll(address operator, bool approved) external {
		require(msg.sender != operator, 'ERC721: approve to caller');
		_operatorApprovals[msg.sender][operator] = approved;
		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function _requireMinted(uint tokenId) internal view virtual {
		require(
			tokenId > 0 && tokenId <= _currentIndex,
			'ERC721: invalid token ID'
		);
	}

	// ============================================================
	// ERC721 - Transfers
	// ============================================================

	function safeTransferFrom(
		address from,
		address to,
		uint tokenId
	) public payable override {
		safeTransferFrom(from, to, tokenId, '');
	}

	function safeTransferFrom(
		address from,
		address to,
		uint tokenId,
		bytes memory data
	) public payable override {
		transferFrom(from, to, tokenId);

		require(
			_checkOnERC721Received(from, to, tokenId, data),
			'ERC721: transfer to non ERC721Receiver implementer'
		);
	}

	function transferFrom(
		address from,
		address to,
		uint tokenId
	) public payable override {
		require(to != address(0), 'ERC721: transfer to the zero address');
		require(ownerOf(tokenId) == from, 'ERC721: transfer from incorrect owner');
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			'ERC721: caller is not token owner or approved'
		);

		// Check if transferring away from disciple
		// If so, freeze the lights, store the owner
		if (to != discipleAddress(tokenId)) {
			_lights[tokenId] = discipleLights(tokenId);
			_owners[tokenId] = to;
		}
		// Otherwise returning back to the disciple
		// So delete the lights and owner
		else {
			delete _lights[tokenId];
			delete _owners[tokenId];
		}

		// Clear approvals from the previous owner
		delete _tokenApprovals[tokenId];

		unchecked {
			// `_balances[from]` WILL underflow for disciples
			// but then we add 1 when checking their balance
			_balances[from] -= 1;
			// `_balances[to]` won't overflow since we're limiting supply to 1000
			_balances[to] += 1;
		}

		emit Transfer(from, to, tokenId);
	}

	function _isApprovedOrOwner(
		address spender,
		uint tokenId
	) internal view virtual returns (bool) {
		address owner = ownerOf(tokenId);
		return (spender == owner ||
			isApprovedForAll(owner, spender) ||
			getApproved(tokenId) == spender);
	}

	// Copied from OpenZeppelin ERC721.sol
	function _checkOnERC721Received(
		address from,
		address to,
		uint tokenId,
		bytes memory data
	) private returns (bool) {
		if (to.isContract()) {
			try
				IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data)
			returns (bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert('ERC721: transfer to non ERC721Receiver implementer');
				} else {
					/// @solidity memory-safe-assembly
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}

	// ============================================================
	// ERC2981 - Royalty
	// ============================================================

	function royaltyInfo(
		uint,
		uint _salePrice
	) external view returns (address receiver, uint royaltyAmount) {
		// It's 10%
		uint royalty = (_salePrice * 1000) / 10000;
		return (address(this), royalty);
	}

	// ============================================================
	// ERC165 - Interfaces
	// ============================================================

	function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
		return
			// ERC165 interface ID for ERC165.
			interfaceId == 0x01ffc9a7 ||
			// ERC165 interface ID for ERC721.
			interfaceId == 0x80ac58cd ||
			// ERC165 interface ID for ERC721Metadata.
			interfaceId == 0x5b5e139f ||
			// ERC2981 interface ID for royalties.
			interfaceId == 0x2a55205a;
	}
}

interface IWormVigils is IERC721Enumerable {
	function getCandleData(
		uint _tokenId
	) external view returns (uint128 _discipleId, uint64 _level, uint64 _vigil);
}