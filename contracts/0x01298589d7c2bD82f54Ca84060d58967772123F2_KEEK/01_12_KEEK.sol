/*                 cHONKNMgmoo                                                                                  
				   NNM   "3NMNMggy                            gNMNNMg_     ggMp     moo         qMMp   cHONkggy 
				  -NNE       j2MMNNgggjj_                     NNNMNMMM_    MNNMp    NMM&        gMMP   gNMMNNNNy
				   MMg,jqqgMMMMMMNNMMNMMMNMggqyj              MNM  NNM:   jNN lML   "NNM  gNgy jNNM    MNNl MNN"
				   gNNNNMM9?:            '?9NNMMMgq_          NMNNNNM"    gNN lNM,   MNMgMNMNMggNM&    MNNNNNNy 
	_chONKMMNMMNNNNNMPl                        '9NNNMg_       MMMNNMMg    NMNMMMNg   9MMNMM&NMNMMNl    NMNP9MMM;
   gMMN99?""""qNNMR.                               ?MNNgy    -MMN  MNN)  jMMN33MMNy   NNNM&  NMMM&    (NNM  3NNM
   NNM      jgMNO                                     MMMMj  :MMN  dMNM  dNM&  JMM&   3MN&    3MN"    7NM&   3NM
   7NMg    gMNP                                        'MMNg  ?0l   ?9l  """"  '"""                              
	?NNgj gMN"                                           9NNp             ,                                     
	  9MMNNN"                                             3MNy          jNM&                                    
		gNN"                                               NMN         qMNNF                                    
   mooMMNN&                                                :NN&      gMMMN"                                     
jMMMMNMNNN                                           jggy   MOO      '23                                        
NNM    MM&               cgqg            qg&        gMMMNM  9MM                                                 
NMgy  _NME              MOONMM          gNNMNg      MKEEKM  7MN~                                                
 9NMggJMM\              NNNMMM          ""  '"       "?3"   :MN)                                                
   9MMNNM:               """"                               :MMC                                                
	  3NMC                                                   MNp                          https://www.gmcafe.io/
	   MOO                                                   N*/
/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";
import {IERC165} from "@openzeppelin/[email protected]/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol";
import {IERC2981} from "@openzeppelin/[email protected]/interfaces/IERC2981.sol";
import {DefaultOperatorFilterer} from "[email protected]/src/DefaultOperatorFilterer.sol";

interface KEEKURI {
	function render(uint256 td, uint256 od) external view returns (string memory uri);
}

contract KEEK is Ownable, IERC165, IERC721, IERC721Metadata, IERC2981, DefaultOperatorFilterer {

	function supportsInterface(bytes4 x) external pure returns (bool) {
		return x == type(IERC165).interfaceId         // 0x01ffc9a7 
		    || x == type(IERC721).interfaceId         // 0x80ac58cd
		    || x == type(IERC721Metadata).interfaceId // 0x5b5e139f
		    || x == type(IERC2981).interfaceId        // 0x2a55205a
			|| x == 0x7f5828d0  // https://eips.ethereum.org/EIPS/eip-173  (Ownable)
		    || x == 0x49064906; // https://eips.ethereum.org/EIPS/eip-4906 (Metadata Update Extension)
	}

	event MetadataUpdate(uint256 token);

	// pref packing:
	// 0000000FFF 12 token
	// 000000F000  4 pref
	// 0000FF0000  8 mint
	// FFFF000000 16 index
	event SetPref(uint256 packed);
	event Locked(uint256 token);
	event Unlocked(uint256 token);
	event UnlockAttempt(uint256 token);
	event MerkleRootChanged();

	error InvalidInput();
	error InvalidReceiver();
	error InvalidLockState();
	error NotAllowed();

	// token allocation:
	// 001-300  moo direct     300
	// 301-333  moo custom      33
	// 334-337  FND (4)          4
	// 338-345  team(4) x2       8
	// 346-353  barista(4) x2    8
	// 354-386  treasury        33
	// 387      audit            1
	// 388-XXX  mintable      2946
	// Total[{300, 33, 4, 8, 8, 33, 1, 2946}] = 3333
	uint256 constant DROPPED_SUPPLY = 387;

	// mint data packing:
	uint256 constant MD_PREFABLE_BIT    =        0x0000000000000000000000000000000000000000000000000000000000000001; // 1
	uint256 constant MD_MINTABLE_SHIFT  = 1;  // 0x0000000000000000000000000000000000000000000000000000000000011110     4
	uint256 constant MD_INDEX_SHIFT		= 5;  // 0x0000000000000000000000000000000011111111111111111111111111100000     X
	uint256 constant MD_MINTABLE_MASK   = 0xF;

	// owner balance packing:
	//               OB_OWNED_SHIFT     =  0; // 0x0000000000000000000000000000000000000000000000000000000000000FFF    12
	uint256 constant OB_MINTED_SHIFT    = 12; // 0x0000000000000000000000000000000000000000000000000000000000FFF000    12
	uint256 constant OB_RESERVATION_BIT =        0x0000000000000000000000000000000000000000000000000000000001000000; // 1
	uint256 constant OB_PUBLIC_BIT      =        0x0000000000000000000000000000000000000000000000000000000002000000; // 1
	uint256 constant OB_ACQUIRE_SHIFT   = 26; // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000     X
	uint256 constant OB_OWNED_MASK      = 0xFFF;
	uint256 constant OB_MINTED_MASK     = 0xFFF;
	uint256 constant OB_ACQUIRE_1       = (1 << OB_ACQUIRE_SHIFT) | 1;
	uint256 constant OB_MINT_1          = (1 << OB_MINTED_SHIFT) | 1;

	// token data packing:
	// FoldList[Plus, 0, {160, 32, 32, 15, 1, 4, 12}] = {0, 160, 192, 224, 239, 240, 244, 256}
	//               TD_OWNER_SHIFT    =   0; // 0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF   160
	uint256 constant TD_BLOCK_SHIFT    = 160; // 0x0000000000000000FFFFFFFF0000000000000000000000000000000000000000    32
	uint256 constant TD_TRANSFER_SHIFT = 192; // 0x00000000FFFFFFFF000000000000000000000000000000000000000000000000    32
	uint256 constant TD_TAG_SHIFT      = 224; // 0x00007FFF00000000000000000000000000000000000000000000000000000000    15
	uint256 constant TD_LOCK_BIT       =         0x0000800000000000000000000000000000000000000000000000000000000000; // 1
	uint256 constant TD_PREF_SHIFT     = 240; // 0x000F000000000000000000000000000000000000000000000000000000000000     4
	uint256 constant TD_TOKEN_SHIFT    = 244; // 0xFFF0000000000000000000000000000000000000000000000000000000000000    12

	uint256 constant TD_TAG_MASK       = 0x7FFF; // 15
	uint256 constant TD_PREF_PICK      = 0x8;    // 1000 (influence bit)
	uint256 constant TD_PREF_MASK      = 0xF;    // 1111 (+3 choices)
	uint256 constant TD_TOKEN_MASK     = 0xFFF;  // 12
	uint256 constant TD_COPY_MASK      = (TD_TOKEN_MASK << TD_TOKEN_SHIFT) | (TD_PREF_MASK << TD_PREF_SHIFT);
	
	struct Unlock {
		bytes32 hash;  // hash of your password
		uint256 price; // recovery price you set
	}

	mapping (address => uint256) _ownerBalance;
	mapping (uint256 => uint256) _tokenData;
	mapping (uint256 => Unlock)  _tokenUnlock;
	mapping (uint256 => address) _tokenApproval;
	mapping (address => mapping(address => bool)) _operatorApprovals;

	address constant TEAM_MULTISIG = 0xa050F07d0a880B7C9389A782250d6848bA433854;
	function withdraw() external {
		uint256 b = address(this).balance;
		if (b == 0) revert InvalidInput();
		uint256 p = b / 20; // 5%
		payable(0xf29c7Db01873Db03D7dE5d0F238b1E08d0c7EDD8).transfer(p);      // eoa: raffy
		payable(0x6A1e88B4ef7098347F078ebC4D8fBFc064dEfb8A).transfer(p);      // eoa: loop 
		payable(0xDb513d3d4bd419A7c3AD24e363B3B6E8CCACB67E).transfer(p << 1); // eoa: jane 
		payable(0xb23Db186161bA869C06fAED618d0a0263bDB75C3).transfer(p << 2); // eoa: ben
		payable(TEAM_MULTISIG).transfer(b - (p << 3));
	}

	string public name = "Good Morning Cafe: Keekusaurs";
	string public symbol = "KEEK";

	bool _prefsLocked;
	bytes32 _merkleRoot;
	uint256 _mintPrice = 0.06 ether;
	uint256 _supply;
	uint256 _maxSupply = 3333;
	uint256 _lastToken = DROPPED_SUPPLY;
	uint256 _publicMax;

	address public _tokenURIContract;
	string public _tokenURIPrefix = "https://api.gmcafe.io/metadata/keek/";
	string public _tokenURISuffix = ".json";
	address _royaltyReceiver = TEAM_MULTISIG;
	uint256 _royaltyNumer = 50_000; // 5%
	uint256 constant ROYALTY_DENOM = 1_000_000;

	function totalSupply() public view returns (uint256) {
		return _supply;
	}
	
	// metadata
	function setTokenURIContract(address addr) onlyOwner public {
		_tokenURIContract = addr;
	}
	function setTokenURIPrefix(string calldata prefix) onlyOwner public {
		_tokenURIPrefix = prefix;
	}
	function setTokenURISuffix(string calldata suffix) onlyOwner public {
		_tokenURISuffix = suffix;
	}
	function tokenURI(uint256 token) public view returns (string memory uri) {
		uint256 td = _tokenData[token];
		if (td == 0) revert InvalidInput(); // ERC721
		if (_tokenURIContract != address(0)) {
			address owner = address(uint160(td));
			uri = KEEKURI(_tokenURIContract).render(td, _ownerBalance[owner]);
		}
		if (bytes(uri).length == 0) {
			bytes memory prefix = bytes(_tokenURIPrefix);
			bytes memory suffix = bytes(_tokenURISuffix);
			unchecked {
				uri = new string(prefix.length + 4 + suffix.length); // "3333"
			}
			uint256 ptr;
			assembly {
				ptr := uri
			}
			ptr = _appendBytes(ptr, prefix);
			uint256 len = token >= 100 ? token >= 1000 ? 4 : 3 : token >= 10 ? 2 : 1;
			ptr = _appendInt(ptr, token, len);
			ptr = _appendBytes(ptr, suffix);
			assembly {
				mstore(uri, sub(ptr, uri)) // truncate
			}	
		}
	}
	function _appendBytes(uint256 ptr, bytes memory data) private pure returns (uint256 dst) {
		uint256 src;
		assembly {
			src := data
			dst := add(ptr, mload(data)) // truncate
		}
		while (ptr < dst) {
			assembly {
				ptr := add(ptr, 32)
				src := add(src, 32)
				mstore(ptr, mload(src))
			}
		}
	}
	function _appendInt(uint256 ptr, uint256 value, uint256 len) private pure returns (uint256 dst) {
		uint256 bits = len << 3;
		uint256 buf;
		unchecked {
			for (uint256 i; i < bits; i += 8) {
				uint256 x = value % 10;
				buf |= (48 + x) << i;
				value /= 10;
			}
		}
		assembly {
			dst := add(ptr, len)
			mstore(dst, or(shl(bits, mload(ptr)), buf)) 
		}
	}

	// royalties
	function setRoyaltyInfo(address receiver, uint256 numer) onlyOwner external {
		if (numer > (receiver == address(0) ? 0 : ROYALTY_DENOM)) revert InvalidInput();
		_royaltyReceiver = receiver;
		_royaltyNumer = numer;
	}
	function getRoyaltyInfo() external view returns (address receiver, uint256 numer, uint256 denom) {
		receiver = _royaltyReceiver;
		numer = _royaltyNumer;
		denom = ROYALTY_DENOM;
	}
	function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
		receiver = _royaltyReceiver;
		royaltyAmount = (salePrice * _royaltyNumer) / ROYALTY_DENOM;
	}

	// tagging
	function setTag(uint256 token, uint256 tag) external {
		if (tag > TD_TAG_MASK) revert InvalidInput(); // too large
		uint256 td = _tokenData[token];
		_requireApprovedSender(address(uint160(td)), token);
		uint256 tag0 = (td >> TD_TAG_SHIFT) & TD_TAG_MASK;
		if (tag0 == tag) revert InvalidInput(); // no change
		_tokenData[token] = td ^ ((tag ^ tag0) << TD_TAG_SHIFT);
	}

	// locking
	function isKeekLocked(uint256 token) external view returns (bool) {
		return _isLocked(_tokenData[token]);
	}
	function _isLocked(uint256 td) private pure returns (bool) {
		return (td & TD_LOCK_BIT) > 0;
	}
	function makePasswordHash(uint256 token, string memory password) pure public returns (bytes32) {
		return keccak256(abi.encodePacked(token, password));
	}
	function lockKeek(uint256 token, uint256 price, bytes32 hash) external {
		uint256 td = _tokenData[token];
		if (_isLocked(td)) revert InvalidLockState(); // already locked
		_requireApprovedSender(address(uint160(td)), token); 
		if (price > 0) { // password only applies when non-zero
			_tokenUnlock[token] = Unlock({hash: hash, price: price});
		}
		_tokenData[token] = td | TD_LOCK_BIT;
		emit Locked(token);
		emit MetadataUpdate(token);
	}
	function unlockKeek(uint256 token, string memory password, address transfer) payable public {
		uint256 td = _tokenData[token];
		if (!_isLocked(td)) revert InvalidLockState(); // not locked
		address owner = address(uint160(td));
		_requireApprovedSender(owner, token); 
		Unlock storage unlock = _tokenUnlock[token];
		uint256 price = unlock.price;
		if (price > 0) { // must satisfy one of the following:
			if (msg.value == 0) { // check password
				if (unlock.hash != makePasswordHash(token, password)) { // wrong password
					emit UnlockAttempt(token);
					return;
				}
			} else if (msg.value < price) { // check price
				revert InvalidLockState(); // not enough
			}
			delete _tokenUnlock[token]; // clear storage
		}
		_tokenData[token] = td ^ TD_LOCK_BIT; // clear lock
		emit Unlocked(token);
		emit MetadataUpdate(token);
		if (transfer != address(0)) {
			safeTransferFrom(owner, transfer, token, ''); // could be a contract
		}
	}
	function rescueKeek(uint256 token) onlyOwner public {
		// if the keek was locked and the owner gave this contract approval,
		// admin can break the lock and obtain the keek
		uint256 td = _tokenData[token];
		if (!_isLocked(td)) revert InvalidLockState(); // not locked
		address owner = address(uint160(td));
		if (!isApprovedForAll(owner, address(this)) && _tokenApproval[token] != address(this)) revert NotAllowed();
		delete _tokenUnlock[token]; // clear storage
		_tokenData[token] = td ^ TD_LOCK_BIT; // clear lock
		emit Unlocked(token);
		emit MetadataUpdate(token);
		if (owner != msg.sender) { 
			_approvedTransfer(owner, msg.sender, token); 
		}
	}

	// minting
	function reduceSupply(uint256 supply) onlyOwner external {
		if (supply >= _maxSupply) revert InvalidInput(); // must decrease
		if (supply < _lastToken) revert InvalidInput(); // too low
		_maxSupply = supply;
	}
	function setMintPrice(uint256 priceWei) onlyOwner external {
		_mintPrice = priceWei;
	}
	function setMerkleRoot(bytes32 hash) onlyOwner external {
		_merkleRoot = hash;
		emit MerkleRootChanged();
	}
	function setPublicMax(uint256 max) onlyOwner external {
		_publicMax = max;
	}
	function getMintInfo() external view returns (
		uint256 price, uint256 supply, uint256 dropped, 
		uint256 minted, uint256 publicMax, bool prefsLocked
	) {
		price = _mintPrice;
		supply = _maxSupply;
		minted = _lastToken - DROPPED_SUPPLY;
		dropped = _supply - minted;
		publicMax = _publicMax;
		prefsLocked = _prefsLocked;
	}
	function hasMinted(uint256 md, address minter) external view returns (bool) {
		uint256 index = md >> MD_INDEX_SHIFT;
		return (_ownerBalance[minter] & (index > 0 ? OB_RESERVATION_BIT : OB_PUBLIC_BIT)) > 0;
	}
	function mintKeeks(bytes32[] calldata proof, uint256 md, uint256[] calldata prefs) external payable {
		unchecked {
			require(msg.sender == tx.origin, "only eoa"); 
			uint256 index = md >> MD_INDEX_SHIFT;			
			bool prefable;
			uint256 ob = _ownerBalance[msg.sender];
			uint256 bit;
			if (index > 0) {
				bit = OB_RESERVATION_BIT;
				prefable = (md & MD_PREFABLE_BIT) > 0; // only reservations can have prefs 
			} else { 
				bit = OB_PUBLIC_BIT;
			}
			require((ob & bit) == 0, "already minted");
			ob |= bit; // mark minted
			uint256 mintable; // mint limit
			if (md == 0) { // proof = <ignored>, index = 0, prefable = false
				mintable = _publicMax;
			} else {
				mintable = (md >> MD_MINTABLE_SHIFT) & MD_MINTABLE_MASK; 
				bytes32 node = keccak256(abi.encodePacked(msg.sender, md));
				for (uint256 i; i < proof.length; i++) {
					bytes32 b = proof[i];
					node = b < node ? keccak256(abi.encodePacked(b, node)) : keccak256(abi.encodePacked(node, b));
				}
				require(node == _merkleRoot, "bad proof");
			}
			require(prefs.length <= mintable, "bad quantity");
			uint256 token = _lastToken;
			uint256 avail = min(_maxSupply - token, prefs.length); // prevent overmint
			require(avail > 0, "max supply");
			uint256 value = _mintPrice * avail;
			require(msg.value >= value, "bad value");
			_supply += avail; // update supply
			_lastToken = token + avail; // update mint index
			_ownerBalance[msg.sender] = ob + OB_MINT_1 * avail; // +owned/minted
			for (uint256 i; i < avail; i++) {
				++token;
				uint256 pref;
				if (prefable) {
					pref = prefs[i] & TD_PREF_MASK;
					if (pref >= TD_PREF_PICK) {
						emit SetPref((index << 24) | (i << 16) | (pref << 12) | token);
					}
				}
				_mint(token, msg.sender, pref);	
			}
			uint256 refund = msg.value - value;
			if (refund > 0) {
				payable(msg.sender).transfer(refund);
			}
		}
	}
	function airdropKeeks(uint256[] calldata recs) onlyOwner external {
		unchecked {
			for (uint256 i; i < recs.length; i++) {
				uint256 rec = recs[i];
				address owner = address(uint160(rec));
				if (owner == address(0)) revert InvalidInput();
				uint256 token = rec >> 160;
				if (token == 0 || token > DROPPED_SUPPLY) revert InvalidInput();
				if (_tokenData[token] > 0) revert NotAllowed();
				_mint(token, owner, 0);		
				_ownerBalance[owner] += OB_MINT_1; // +owned/minted
			}
		}
		_supply += recs.length;
	}
	function _mint(uint256 token, address owner, uint256 pref) private {
		_tokenData[token] = (token << TD_TOKEN_SHIFT)
			| (pref << TD_PREF_SHIFT)
			| (block.number << TD_BLOCK_SHIFT) 
			| uint160(owner);
		emit Transfer(address(0), owner, token);
	}

	// airdrop preferences
	function lockPrefs() onlyOwner external {
		if (_prefsLocked) revert InvalidInput(); // already locked
		_prefsLocked = true;
	}
	function setPref(uint256 token, uint256 pref) external {
		if (_prefsLocked) revert NotAllowed();
		if (token > DROPPED_SUPPLY) revert NotAllowed();
		if (pref < TD_PREF_PICK || pref > TD_PREF_MASK) revert InvalidInput();
		_requireApprovedSender(msg.sender, token);
		uint256 td = _tokenData[token];
		uint256 pref0 = (td >> TD_PREF_SHIFT) & TD_PREF_MASK;
		if (pref0 > 0) revert NotAllowed();		
		_tokenData[token] = td | (pref << TD_PREF_SHIFT);
		emit SetPref((pref << 12) | token);
	}

	// transfer
	function safeTransferFrom(address from, address to, uint256 token) external {
		safeTransferFrom(from, to, token, '');
	}
	function safeTransferFrom(address from, address to, uint256 token, bytes memory data) public {
		transferFrom(from, to, token);
		if (to.code.length > 0) {
			try IERC721Receiver(to).onERC721Received(msg.sender, from, token, data) returns (bytes4 ret) {
				require(ret == IERC721Receiver.onERC721Received.selector);
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert InvalidReceiver();
				} else {
					assembly {
						revert(add(reason, 32), mload(reason))
					}
				}
			}
		}
	}
	function transferFrom(address from, address to, uint256 token) onlyAllowedOperator(from) public {
		if (to == address(0)) revert InvalidReceiver(); // ERC721
		_requireApprovedSender(from, token); // from is owner
		_approvedTransfer(from, to, token);
	}
	function _approvedTransfer(address from, address to, uint256 token) private {
		if (to == from) revert InvalidReceiver(); // block transfer to self
		uint256 td = _tokenData[token];
		if (address(uint160(td)) != from) revert NotAllowed(); // not owned by from
		require(!_isLocked(td), "Keek is Locked"); // use string because user-facing error
		delete _tokenApproval[token]; // clear token approval
		unchecked {
			uint256 transfers = uint32((td >> TD_TRANSFER_SHIFT) + 1);
			_tokenData[token] = td & TD_COPY_MASK  // keep token and pref
				| (block.number << TD_BLOCK_SHIFT) // current block
				| (transfers << TD_TRANSFER_SHIFT) // updated transfer count
				| uint160(to);                     // new owner
			_ownerBalance[from]--;                 // -owned 
			_ownerBalance[to] += OB_ACQUIRE_1;     // +owned/acquire
		}
		emit Transfer(from, to, token);
	}

	// getters
	function balanceOf(address owner) external view returns (uint256) {
		if (owner == address(0)) revert InvalidInput(); // ERC721
		return _ownerBalance[owner] & OB_OWNED_MASK;
	}
	function ownerOf(uint256 token) public view returns (address) {
		return address(uint160(_tokenData[token]));
	}
	function getOwnerInfo(address owner) external view returns (
		uint16 owned, uint16 minted, uint256 acquired, 
		bool mintedReservation, bool mintedPublic
	) {
		uint256 ob = _ownerBalance[owner];
		owned = uint16(ob & OB_OWNED_MASK);
		minted = uint16((ob >> OB_MINTED_SHIFT) & OB_MINTED_MASK);
		acquired = ob >> OB_ACQUIRE_SHIFT;
		mintedReservation = (ob & OB_RESERVATION_BIT) > 0;
		mintedPublic = (ob & OB_PUBLIC_BIT) > 0;
	}
	function getKeekInfo(uint256 token) external view returns (
		address owner, uint32 transfers, uint32 block0, uint32 blocksHeld, 
		bool isLocked, uint16 tag, uint8 pref, uint256 unlockPrice
	) {
		unchecked {
			uint256 td = _tokenData[token];
			if (td == 0) revert InvalidInput();
			owner = address(uint160(td));
			transfers = uint32(td >> TD_TRANSFER_SHIFT);
			block0 = uint32(td >> TD_BLOCK_SHIFT);
			blocksHeld = uint32(block.number - block0);
			tag = uint16((td >> TD_TAG_SHIFT) & TD_TAG_MASK);
			pref = uint8((td >> TD_PREF_SHIFT) & TD_PREF_MASK);
			isLocked = _isLocked(td);
			if (isLocked) {
				unlockPrice = _tokenUnlock[token].price;
			}
		}
	}
	// note: this is 0-based
	function keeksFromSlice(uint256 offset, uint256 size) external view returns (bytes32[] memory keeks) {
		unchecked {
			uint256 max = _maxSupply;
			if (offset < max) { // require valid index
				size = min(offset + size, max) - offset; // truncate
			} else {
				size = 0; // invalid
			}
			keeks = new bytes32[](size);
			for (uint256 i; i < size; ) { // just dumb memcpy
				keeks[i++] = bytes32(_tokenData[++offset]); 
			}
		}
	}

	// approvals
	function _requireApprovedSender(address owner, uint256 token) private view {
		if (owner != msg.sender && !isApprovedForAll(owner, msg.sender) && _tokenApproval[token] != msg.sender) {
			revert NotAllowed();
		}
	}
	function isApprovedForAll(address owner, address operator) public view returns (bool) {
		return _operatorApprovals[owner][operator];
	}
	function setApprovalForAll(address operator, bool approved) onlyAllowedOperatorApproval(operator) external {
		if (operator == msg.sender) revert NotAllowed(); // owner is always approved
		_operatorApprovals[msg.sender][operator] = approved;
		emit ApprovalForAll(msg.sender, operator, approved);
	}
	function getApproved(uint256 token) external view returns (address) {
		if (_tokenData[token] == 0) revert InvalidInput(); // ERC721
		return _tokenApproval[token];
	}
	function approve(address operator, uint256 token) onlyAllowedOperatorApproval(operator) external {
		address owner = address(uint160(_tokenData[token]));
		if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) revert NotAllowed();
		_tokenApproval[token] = operator;
		emit Approval(owner, operator, token);
	}

	// helper
	function min(uint256 a, uint256 b) private pure returns (uint256) {
		return a < b ? a : b;
	}

}