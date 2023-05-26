// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// This contract was built on top of inspiration from @HodlCaulfield
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import './RandomlyAssigned.sol';

/*

  /$$$$$$ /$$   /$$/$$$$$$$$/$$      /$$$$$$$$/$$$$$$$$/$$$$$$ /$$              /$$$$$$  /$$$$$$ /$$$$$$$$/$$$$$$ 
 /$$__  $| $$  /$$| $$_____| $$     | $$_____|__  $$__/$$__  $| $$             /$$__  $$/$$__  $|__  $$__/$$__  $$
| $$  \__| $$ /$$/| $$     | $$     | $$        | $$ | $$  \ $| $$            | $$  \__| $$  \ $$  | $$ | $$  \__/
|  $$$$$$| $$$$$/ | $$$$$  | $$     | $$$$$     | $$ | $$$$$$$| $$            | $$     | $$$$$$$$  | $$ |  $$$$$$ 
 \____  $| $$  $$ | $$__/  | $$     | $$__/     | $$ | $$__  $| $$            | $$     | $$__  $$  | $$  \____  $$
 /$$  \ $| $$\  $$| $$     | $$     | $$        | $$ | $$  | $| $$            | $$    $| $$  | $$  | $$  /$$  \ $$
|  $$$$$$| $$ \  $| $$$$$$$| $$$$$$$| $$$$$$$$  | $$ | $$  | $| $$$$$$$$      |  $$$$$$| $$  | $$  | $$ |  $$$$$$/
 \______/|__/  \__|________|________|________/  |__/ |__/  |__|________/       \______/|__/  |__/  |__/  \______/                                                                                                                                                                                                                                                                                      

									███╗   ██████████╗██████╗██╗    ██╗
									████╗ ██████╔════██╔═══████║    ██║
									██╔████╔███████╗ ██║   ████║ █╗ ██║
									██║╚██╔╝████╔══╝ ██║   ████║███╗██║
									██║ ╚═╝ █████████╚██████╔╚███╔███╔╝
									╚═╝     ╚═╚══════╝╚═════╝ ╚══╝╚══╝ 
                                   
										.         .   .                 .               
							o           |         |   |                 |               
						;-. . ,-. ,-.   |-  ,-.   |-  |-. ,-.   ;-. ,-. |-. ,-. ;-. ;-. 
						|   | `-. |-'   |   | |   |   | | |-'   |   |-' | | | | |   | | 
						'   ' `-' `-'   `-' `-'   `-' ' ' `-'   '   `-' `-' `-' '   ' ' 
																						


*/

contract SkeletalCats is ERC721, ERC1155Holder, Ownable, RandomlyAssigned {
	using Strings for uint256;

	/*
	 * Private Variables
	 */
	uint256 private constant NUMBER_OF_NFTS = 3333;
	uint256 private constant MAX_ALLOWLIST_MINTS_PER_ADDRESS = 3;
	uint256 private constant MAX_WAITLIST_MINTS_PER_ADDRESS = 5;

	struct MintTypes {
		uint256 _numberOfMintsByAddress;
	}

	bytes32 public allowlistMerkleRoot;
	bytes32 public waitlistMerkleRoot;


	enum SalePhase {
		Locked,
		AllowList,
		WaitList,
		PublicSale
	}

	string private _defaultUri;

	string private _tokenBaseURI;

	/*
	 * Public Variables
	 */

	bool public metadataIsFrozen = false;

	SalePhase public phase = SalePhase.Locked;

	uint256 public allowlistMintPrice = 0.07 ether;
	uint256 public mintPrice = 0.09 ether;

	mapping(SalePhase => mapping(address => MintTypes)) public addressToMints;


	event RaffleWinner(uint256 winner);  
	/*
	 * Constructor
	 */
	constructor(
		string memory uri
    )
		ERC721('Skeletal Cats', 'SKTLCAT')
		RandomlyAssigned(
			NUMBER_OF_NFTS,
			0
		)
	{
		_defaultUri = uri;


	}

	// ======================================================== Owner Functions

	/// Set the base URI for the metadata
	/// @dev modifies the state of the `_tokenBaseURI` variable
	/// @param URI the URI to set as the base token URI
	function setBaseURI(string memory URI) external onlyOwner {
		require(!metadataIsFrozen, 'Metadata is permanently frozen');
		_tokenBaseURI = URI;
	}

	/// Freezes the metadata
	/// @dev sets the state of `metadataIsFrozen` to true
	/// @notice permamently freezes the metadata so that no more changes are possible
	function freezeMetadata() external onlyOwner {
		require(!metadataIsFrozen, 'Metadata is already frozen');
		metadataIsFrozen = true;
	}

	/// Adjust the mint price
	/// @dev modifies the state of the `mintPrice` variable
	/// @notice sets the price for minting a token
	/// @param newPrice_ The new price for minting
	function adjustMintPrice(uint256 allowlistNewPrice_, uint256 newPrice_) external onlyOwner {
		mintPrice = newPrice_;
		allowlistMintPrice = allowlistNewPrice_;
	}

	/// Advance Phase
	/// @dev Advance the sale phase state
	/// @notice Advances sale phase state incrementally
	function enterPhase(SalePhase phase_) external onlyOwner {
		phase = phase_;
	}

	/// Disburse payments
	/// @dev transfers amounts that correspond to addresses passeed in as args
	/// @param payees_ recipient addresses
	/// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
	function disbursePayments(
		address[] memory payees_,
		uint256[] memory amounts_
	) external onlyOwner {
		require(
			payees_.length == amounts_.length,
			'Payees and amounts length mismatch'
		);
		for (uint256 i; i < payees_.length; i++) {
			makePaymentTo(payees_[i], amounts_[i]);
		}
	}

	/// Make a payment
	/// @dev internal fn called by `disbursePayments` to send Ether to an address
	function makePaymentTo(address address_, uint256 amt_) private {
		(bool success, ) = address_.call{value: amt_}('');
		require(success, 'Transfer failed.');
	}

	/// Mint during allowlist
	/// @dev mints by addresses validated using verified coupons signed by an admin signer
	/// @notice mints tokens with randomized token IDs to addresses eligible for presale
	/// @param count number of tokens to mint in transaction
	/// @param merkleProof proof to verify whitelisted
	function mintAllowlist(uint256 count, bytes32[] calldata merkleProof)
		external
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count,true)
	{
		require(phase == SalePhase.AllowList, 'Allowlist event is not active');
		require(
			count + addressToMints[phase][msg.sender]._numberOfMintsByAddress <=
				MAX_ALLOWLIST_MINTS_PER_ADDRESS,
			'Exceeds number of allowlist mints allowed'
		);
        require(isOnAllowList(merkleProof, _msgSender()), "Address not on allowlist");


		addressToMints[phase][msg.sender]._numberOfMintsByAddress += count;

		for (uint256 i; i < count; i++) {
			_mintRandomId(msg.sender);
		}
	}

	/// Mint during Waitlist
	/// @dev mints by addresses validated using verified coupons signed by an admin signer
	/// @notice mints tokens with randomized token IDs to addresses eligible for presale
	/// @param count number of tokens to mint in transaction
	/// @param merkleProof proof to verify whitelisted
	function mintWaitlist(uint256 count, bytes32[] calldata merkleProof)
		external
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count,true)
	{
		require(phase == SalePhase.WaitList, 'Waitlist event is not active');
		require(
			count + addressToMints[phase][msg.sender]._numberOfMintsByAddress <=
				MAX_WAITLIST_MINTS_PER_ADDRESS,
			'Exceeds number of waitlist mints allowed'
		);
        require(isOnWaitlist(merkleProof, _msgSender()), "Address not on waitlist");


		addressToMints[phase][msg.sender]._numberOfMintsByAddress += count;

		for (uint256 i; i < count; i++) {
			_mintRandomId(msg.sender);
		}
	}

	/// Public minting open to all
	/// @dev mints tokens during public sale, limited by `MAX_MINTS_PER_ADDRESS`
	/// @notice mints tokens with randomized IDs to the sender's address
	/// @param count number of tokens to mint in transaction
	function mint(uint256 count)
		external
		payable
		validateEthPayment(count, false)
		ensureAvailabilityFor(count)
	{
		require(phase == SalePhase.PublicSale, 'Public sale is not active');

		addressToMints[phase][msg.sender]._numberOfMintsByAddress += count;
		for (uint256 i; i < count; i++) {
			_mintRandomId(msg.sender);
		}
	}

	// ======================================================== Overrides

	/// Return the tokenURI for a given ID
	/// @dev overrides ERC721's `tokenURI` function and returns either the `_tokenBaseURI` or a custom URI
	/// @notice reutrns the tokenURI using the `_tokenBase` URI if the token ID hasn't been suppleid with a unique custom URI
	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721)
		returns (string memory)
	{
		require(_exists(tokenId), 'Cannot query non-existent token');

		return
			bytes(_tokenBaseURI).length > 0
				? string(
					abi.encodePacked(_tokenBaseURI, '/', tokenId.toString())
				)
				: string(
					abi.encodePacked(_defaultUri, '/', tokenId.toString())
				);
	}

	/// override supportsInterface because two base classes define it
	/// @dev See {IERC165-supportsInterface}.
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721, ERC1155Receiver)
		returns (bool)
	{
		return
			ERC721.supportsInterface(interfaceId) ||
			ERC1155Receiver.supportsInterface(interfaceId);
	}

	 function updateAllowlistRoot(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        allowlistMerkleRoot = _merkleRoot;
    }

	function updateWaitlistRoot(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        waitlistMerkleRoot = _merkleRoot;
    }

	function ownerMint(address[] memory payees_, uint256[] memory counts)
		external onlyOwner
	{
		require(
			payees_.length == counts.length,
			'Payees and counts length mismatch'
		);
		for (uint256 i; i < payees_.length; i++) {
			for (uint256 k; k < counts[i]; k++) {
				_mintRandomId(payees_[i]);
			}
		}
		
	}

	function drawRaffle()
		external onlyOwner
	{
		emit RaffleWinner(random());
	}

	// ======================================================== Internal Functions


	function toBytes32(address addr) pure internal returns (bytes32) {
    	return bytes32(uint256(uint160(addr)));
  	}

	/// @dev internal check to ensure a genesis token ID, or ID outside of the collection, doesn't get minted
	function _mintRandomId(address to) private {
		uint256 id = nextToken();
		assert(id <= NUMBER_OF_NFTS);
		_safeMint(to, id);
	}

	function isOnAllowList(bytes32[] calldata merkleProof, address sender) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(merkleProof, allowlistMerkleRoot, leaf);
    }

	function isOnWaitlist(bytes32[] calldata merkleProof, address sender) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(merkleProof, waitlistMerkleRoot, leaf);
    }

	function withdraw() public onlyOwner {
        payable(address(_msgSender())).transfer(address(this).balance);
    }

	function random() private view returns (uint) {
    	uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    	return (randomHash % (NUMBER_OF_NFTS + 1)) + 1;
	} 

	// ======================================================== Modifiers

	/// Modifier to validate Eth payments on payable functions
	/// @dev compares the product of the state variable `_mintPrice` and supplied `count` to msg.value
	/// @param count factor to multiply by
	modifier validateEthPayment(uint256 count, bool allowlist) {
		require(
			allowlist ? allowlistMintPrice * count <= msg.value : mintPrice * count <= msg.value,
			'Ether value sent is not correct'
		);
		_;
	}
} // End of Contract