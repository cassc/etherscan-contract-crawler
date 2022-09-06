/*                              gweMBMEBBBMBMEBMBwg_.                                                           
                           aeMMEPP"  ' '. .  ..""^BMMBMe_'                             )BE   zEE .ZEEBL  JBBMg. 
                      __eEMPP .                     .`?RBEe,.                          $BM$_JMMBLJMEOEBL BEPEEE 
                    _BMMK'                              ''ME$L.                        $EEMEMBMB'5EE MMK$BE.]ME 
                  _BMB'                                    .$EE,   [email protected]@BBBEEB.          5MB$EBEEE'MMK'MBKEME BEf 
  [email protected],,.zB$"                                         EBMMBBF``' .'EEk         MM('".]B$.EMKJBB BBL,EEP 
 JB$`. .. `?PKEMBEMBMEBg_                           _,we_      SBB.        ]ME        .BBP   $EE EMMME`.BBMMEK  
 $MP           .  . ``FBMe                          EEFEEE     .BEL       .$MK        .^^    1M   "F^.  .APP.   
 1BE'                   ^B$.                       JBB .BMK     JME      .BEK                                   
  1MB,                   [EE                        BB, 5B[     )E$    ,gBB`            .EEk                    
    BEB                 .BMP                        ?BEgME.    _BEBgLeMMBC_'          ,e$EM^                    
    .`MBMg,            gEBE'  ',,        eEBe,,,  . [email protected][email protected]         $MEP`                     
      ,BMBEMEew_L,_-wMBBR`    'RBMBewwBEBE"?PBBMEBMEER^`?RRMBM^`.  @e.    'BB.                                  
  __eBBP`''''^RRRBRRP`..        ..""YY`                     '.wgwL.'MBE  _wEE                                   
[email protected]`.                      Lgg_              _eMg.        JEBEMMe  3MMME$K                                    
$BP.                       JBBEBEB.           yBBBMBy       $EBMEBE   $ME.                                      
&EK_         .,            \MBEBBE.           "^   `.        '^R^ '   .BM'                                      
 `[email protected]@@BEMBK           ' RRK".                                     MB                                       
     BE$^YY"` .                                                       JM$                 https://www.gmcafe.io/
     ^".                                                              .*/
/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";
import {IERC165} from "@openzeppelin/[email protected]/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/[email protected]/token/ERC1155/IERC1155.sol";
import {IERC721Metadata} from "@openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol";

contract GMOO is Ownable, IERC165, IERC721, IERC721Metadata {

	function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
		return interfaceId == type(IERC165).interfaceId // 0x01ffc9a7 
			|| interfaceId == type(IERC721).interfaceId // 0x80ac58cd
			|| interfaceId == type(IERC721Metadata).interfaceId; // 0x5b5e139f
	}

	error InvalidInput();
	error NotOpenSeaOwner(uint256 token); 
	error AlreadyMigrated(uint256 moo);
	error InvalidMoo(uint256 moo);
	error NotMooOperator(uint256 moo);
	error InvalidReceiver();
	error InvalidLockState();
	error NotAllowed();

	event MooLocked(uint256 moo);
	event MooUnlocked(uint256 moo);
	event MooUnlockAttempt(uint256 moo);

	uint256 constant HERD_SIZE = 333;
	address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
	address constant OPENSEA_CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;
	IERC1155 constant OPENSEA_NFT = IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e); 
	uint256 constant CLAIM_DELAY = 33 days;

	//               OWNER_SHIFT    =   0; // 0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 
	uint256 constant BLOCK_SHIFT    = 160; // 0x0000000000000000FFFFFFFF0000000000000000000000000000000000000000
	uint256 constant TRANSFER_SHIFT = 192; // 0x00000000FFFFFFFF000000000000000000000000000000000000000000000000
	uint256 constant TAG_SHIFT      = 224; // 0x0000FFFF00000000000000000000000000000000000000000000000000000000
	uint256 constant MOO_SHIFT      = 240; // 0xFFFF000000000000000000000000000000000000000000000000000000000000
	uint256 constant LOCK_BIT       = 1 << 255;
	uint256 constant TAG_CLEAR      = ~(uint256(type(uint16).max) << TAG_SHIFT); 

	struct Unlock {
		bytes32 hash;  // hash of your password
		uint256 price; // recovery price you set
	}

	string public _provenance;
	string public _tokenURIPrefix = "https://api.gmcafe.io/metadata/gmoo/";
	string public _tokenURISuffix = ".json";
	uint256 public _claimableTime;

	uint256 _migrated;
	mapping (address => uint256) _balances; // owner -> owned
	mapping (uint256 => uint256) _moos;     //   moo -> packed data
	mapping (uint256 => Unlock)  _unlocks;  //   moo -> Unlock

	mapping (uint256 => address) _tokenApprovals;
	mapping (address => mapping(address => bool)) _operatorApprovals;

	function _requireValidMoo(uint256 moo) private pure {
		if (moo == 0 || moo > HERD_SIZE) revert InvalidMoo(moo);
	}

	function _requireApproval(address owner, uint256 moo) private view {
		if (owner != msg.sender && !isApprovedForAll(owner, msg.sender) && getApproved(moo) != msg.sender) {
			revert NotMooOperator(moo);
		}
	}

	constructor() {
		_claimableTime = block.timestamp + CLAIM_DELAY;
	}

	function name() public pure returns (string memory) {
		return "Good Morning Cafe";
	}
	function symbol() public pure returns (string memory) {
		return "GMOO";
	}
	function totalSupply() public view returns (uint256) {
		return _migrated;
	}

	// admin
	function withdraw() onlyOwner public {
		if (address(this).balance == 0) revert InvalidReceiver();
		payable(msg.sender).transfer(address(this).balance);
	}

	// metadata
	function setProvenance(string calldata s) onlyOwner public {
		_provenance = s;
	}
	function setTokenURIPrefix(string calldata s) onlyOwner public {
		_tokenURIPrefix = s;
	}
	function setTokenURISuffix(string calldata s) onlyOwner public {
		_tokenURISuffix = s;
	}
	function tokenURI(uint256 moo) public view returns (string memory uri) {
		_requireValidMoo(moo);
		bytes memory prefix = bytes(_tokenURIPrefix);
		bytes memory suffix = bytes(_tokenURISuffix);
		unchecked {
			uri = new string(prefix.length + suffix.length + 68); // 3 + 1 + 32 + 32
		}
		uint256 ptr;
		assembly {
			ptr := uri
		}
		ptr = _appendBytes(ptr, prefix);
		ptr = _appendInt(ptr, moo, 3, 10); // +3
		ptr = _appendBytes(ptr, suffix);
		uint256 data = _moos[moo];
		if (data != 0) {
			ptr = _appendBytes(ptr, "?"); // +1
			ptr = _appendInt(ptr, data >> 128, 32, 16); // +32
			ptr = _appendInt(ptr, data,        32, 16); // +32
		}
		assembly {
			mstore(uri, sub(ptr, uri)) // truncate
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
	function _appendInt(uint256 ptr, uint256 value, uint256 len, uint256 base) private pure returns (uint256 dst) {
		uint256 bits =  len << 3;
		uint256 buf;
		unchecked {
			for (uint256 i; i < bits; i += 8) {
				uint256 x = value % base;
				buf |= (x < 10 ? 48 + x : 87 + x) << i; // "0" => 48, ("a" - 10) => 87
				value /= base;
			}
		}
		assembly {
			dst := add(ptr, len)
			mstore(dst, or(shl(bits, mload(ptr)), buf)) 
		}
	}

	// getters
	function getHerd() public view returns (bytes32[] memory ret) {
		ret = new bytes32[](HERD_SIZE);
		uint256 ptr;
		assembly {
			ptr := ret
		}
		uint256 moo;
		while (moo < HERD_SIZE) {
			unchecked { 
				uint256 data = _moos[++moo];
				if (data == 0) continue;
				assembly {
					ptr := add(ptr, 32)
					mstore(ptr, data)
				}
			}
		}
		assembly {
			mstore(ret, shr(5, sub(ptr, ret))) // truncate
		}
	}
	function getMoo(uint256 moo) public view returns (
			address owner, uint32 transfers, uint32 block0, uint32 blocksHeld, 
			uint16 tag, bool isLocked, uint256 unlockPrice
	) {
		uint256 data = _moos[moo];
		owner = address(uint160(data));
		if (owner != address(0)) {
			transfers = uint32(data >> TRANSFER_SHIFT);
			block0 = uint32(data >> BLOCK_SHIFT);
			unchecked {
				blocksHeld = uint32(block.number - block0);
			}
			tag = uint16(data >> TAG_SHIFT);
			isLocked = _isLocked(data);
			if (isLocked) {
				unlockPrice = _unlocks[moo].price;
			}
		}
	}
	function getWallet(address owner) public view returns (uint256[] memory moos) {
		uint256 n = _balances[owner];
		if (n != 0) {
			moos = new uint256[](n);
			uint256 moo = HERD_SIZE; // go backwards so output sorted
			while (true) {
				unchecked {
					if (address(uint160(_moos[moo])) == owner) {
						moos[--n] = moo;
						if (n == 0) break;
					}
					moo--;
				}
			}
		}
	}
	function balanceOf(address owner) public view returns (uint256) {
		if (owner == address(0)) revert InvalidInput(); // ERC721
		return _balances[owner];
	}
	function ownerOf(uint256 moo) public view returns (address) {
		return address(uint160(_moos[moo]));
	}

	// locking
	function isMooLocked(uint256 moo) public view returns (bool) {
		return _isLocked(_moos[moo]);
	}
	function _isLocked(uint256 data) private pure returns (bool) {
		return (data & LOCK_BIT) != 0;
	}
	function makePasswordHash(uint256 moo, string memory password) pure public returns (bytes32) {
		return keccak256(abi.encodePacked(moo, password));
	}
	function lockMoo(uint256 moo, uint256 price, bytes32 hash) public {
		uint256 data = _moos[moo];
		if (_isLocked(data)) revert InvalidLockState(); // already locked
		_requireApproval(address(uint160(data)), moo);
		if (price != 0) { // password only applies when non-zero
			_unlocks[moo] = Unlock({hash: hash, price: price});
		}
		_moos[moo] = data | LOCK_BIT;
		emit MooLocked(moo);
	}
	function unlockMoo(uint256 moo, string memory password, address transfer) payable public {
		uint256 data = _moos[moo];
		if (!_isLocked(data)) revert InvalidLockState(); // not locked
		address owner = address(uint160(data));
		_requireApproval(owner, moo); 
		Unlock storage unlock = _unlocks[moo];
		if (unlock.price != 0) { // must satisfy one of the following:
			if (msg.value == 0) { // check password
				if (unlock.hash != makePasswordHash(moo, password)) { // wrong password
					emit MooUnlockAttempt(moo);
					return;
				}
			} else if (msg.value < unlock.price) { // check price
				revert InvalidLockState(); // not enough
			}
			delete unlock.price; // zero storage
			delete unlock.hash;
		}
		_moos[moo] = data ^ LOCK_BIT; // clear lock
		emit MooUnlocked(moo);
		if (transfer != address(0)) {
			safeTransferFrom(owner, transfer, moo, ''); // could be a contract
		}
	}
	function rescueMoo(uint256 moo) onlyOwner public {
		// if the moo was locked and the owner gave this contract approval,
		// admin can break the lock and obtain the moo
		uint256 data = _moos[moo];
		if (!_isLocked(data)) revert InvalidLockState(); // not locked
		address owner = address(uint160(data));
		if (!isApprovedForAll(owner, address(this)) && getApproved(moo) != address(this)) revert NotMooOperator(moo);
		delete _unlocks[moo]; // zero storage
		_moos[moo] = data ^ LOCK_BIT; // clear lock
		emit MooUnlocked(moo);
		if (owner != msg.sender) { 
			_approvedTransfer(owner, msg.sender, moo); 
		}
	}
	
	// tagging
	function setTag(uint256 moo, uint16 tag) public {
		uint256 data = _moos[moo];
		_requireApproval(address(uint160(data)), moo);
		_moos[moo] = (data & TAG_CLEAR) | (uint256(tag) << TAG_SHIFT);
	}

	// minting
	function _mint(uint256 moo) private {
		_moos[moo] = (moo << MOO_SHIFT) | (block.number << BLOCK_SHIFT) | uint160(msg.sender);
		emit Transfer(address(0), msg.sender, moo); 
	}
	function _addMinted(uint256 n) private {
		uint256 prior = _balances[msg.sender];
		unchecked {
			_balances[msg.sender] = prior + n;
			_migrated += n;
		}
		if (prior == 0) { // first moo migrated
			setApprovalForAll(OPENSEA_CONDUIT, true);
		}
	}

	// migration	
	function isMigrationApproved(address sender) public view returns (bool) {
		return OPENSEA_NFT.isApprovedForAll(sender, address(this));
	}
	function getMigratableTokens(address sender) public view returns (uint256[] memory tokens, uint256[] memory moos) {		
		tokens = new uint256[](HERD_SIZE);
		address[] memory owners = new address[](HERD_SIZE);
		unchecked {
			for (uint256 i; i < HERD_SIZE; i++) {
				owners[i] = sender;
				tokens[i] = _tokenFromCollectionIndex(i + 1);
			}
		}
		uint256[] memory balances = OPENSEA_NFT.balanceOfBatch(owners, tokens);
		uint256 n;
		unchecked {
			for (uint256 i; i < HERD_SIZE; i++) {
				if (balances[i] != 0) {
					tokens[n++] = tokens[i];
				}
			}
		}
		assembly {
			mstore(tokens, n) // truncate
		}
		moos = new uint256[](n);
		for (uint256 i; i < n; i++) {
			moos[i] = mooFromToken(tokens[i]);
		}
	}
	function migrateMoos(uint256[] calldata tokens) public {
		uint256 n = tokens.length;
		if (n == 0) revert InvalidInput();
		uint256[] memory balances = new uint256[](n);
		unchecked { 
			for (uint256 i; i < n; i++) {
				balances[i] = 1;
			}
		}
		OPENSEA_NFT.safeBatchTransferFrom(msg.sender, BURN_ADDRESS, tokens, balances, ''); 
		unchecked { 
			for (uint256 i; i < n; i++) {
				uint256 moo = mooFromToken(tokens[i]);
				if (_moos[moo] != 0) revert AlreadyMigrated(moo); 
				_mint(moo); 
			}
		}
		_addMinted(n);
	}

	function secondsUntilClaimable() public view returns (uint256) {
		unchecked {
			return block.timestamp >= _claimableTime ? 0 : _claimableTime - block.timestamp;
		}
	}	
	function claimUnmigratedMoos(uint256 limit) onlyOwner public {	
		if (secondsUntilClaimable() != 0) revert NotAllowed(); // time lock
		unchecked {
			uint256 max = HERD_SIZE - _migrated; // claimable
			if (max == 0) revert InvalidInput(); // nothing to claim
			if (limit == 0) limit = max; // claim all
			uint256 moo;
			uint256 n;
			while (moo < HERD_SIZE) {
				moo++;
				if (_moos[moo] != 0) continue;
				_mint(moo);
				if (++n == limit) break;
			}
			_addMinted(n);
		}
	}

	// transfer
	function safeTransferFrom(address from, address to, uint256 moo) public {
		safeTransferFrom(from, to, moo, '');
	}
	function safeTransferFrom(address from, address to, uint256 moo, bytes memory data) public {
		transferFrom(from, to, moo);
		if (to.code.length != 0) {
			try IERC721Receiver(to).onERC721Received(msg.sender, from, moo, data) returns (bytes4 ret) {
				if (ret != IERC721Receiver.onERC721Received.selector) {
					revert InvalidReceiver();
				}
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
	function transferFrom(address from, address to, uint256 moo) public {
		if (to == address(0)) revert InvalidReceiver(); // ERC721
		_requireApproval(from, moo);
		_approvedTransfer(from, to, moo);
	}
	function _approvedTransfer(address from, address to, uint256 moo) private {
		if (to == from) revert InvalidReceiver(); // block transfer to self
		uint256 data = _moos[moo];
		if (address(uint160(data)) != from) revert NotAllowed(); // moo is not owned by from
		require(!_isLocked(data), "Moo is Locked"); // use string because user-facing error
		delete _tokenApprovals[moo]; // clear token approval
		unchecked {
			uint256 transfers = uint32((data >> TRANSFER_SHIFT) + 1);
			_moos[moo] = (moo << MOO_SHIFT)     // moo number
				| (block.number << BLOCK_SHIFT) // current block height
				| (transfers << TRANSFER_SHIFT) // updated transfer count
				| uint160(to);                  // new owner
			_balances[from]--;
			_balances[to]++;
		}
		emit Transfer(from, to, moo);
	}

	// operator approvals
	function isApprovedForAll(address owner, address operator) public view returns (bool) {
		return _operatorApprovals[owner][operator];
	}
	function setApprovalForAll(address operator, bool approved) public {
		if (operator == msg.sender) revert NotAllowed(); // owner is always approved
		_operatorApprovals[msg.sender][operator] = approved;
		emit ApprovalForAll(msg.sender, operator, approved);
	}

	// token approvals
	function getApproved(uint256 moo) public view returns (address) {
		_requireValidMoo(moo); // ERC721
		return _tokenApprovals[moo];
	}
	function approve(address to, uint256 moo) public {
		address owner = address(uint160(_moos[moo]));
		if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) revert NotMooOperator(moo);
		_tokenApprovals[moo] = to;
		emit Approval(owner, to, moo);
	}

	// old token => new token
	function _tokenFromCollectionIndex(uint256 i) private pure returns (uint256) {
		//       |-------------------------------creator||-------index||--------|
		return 0xB3457C2065FD1F384E9F05495251F2894D1659B6000000000000000000000001 | (i << 40);
	}
	function mooFromToken(uint256 token) public pure returns (uint256) {
		uint256 index = uint16(token >> 40); // see above
		if (_tokenFromCollectionIndex(index) != token) revert InvalidInput(); // not a moo
		uint256 moo = _mooFromCollectionIndex(index);
		_requireValidMoo(moo); // weird shit bro
		return moo;
	}
	function _mooFromCollectionIndex(uint256 i) private pure returns (uint256) {
		unchecked {
			if (i <= 180) {
				if (i <= 99) {
					if (i <= 52) {
						if (i <= 29) {
							if (i <= 21) return i;
							if (i == 22) return 301;
							return i - 1;
						} else {
							if (i == 30) return 302;
							return i - 2;
						}
					} else {
						if (i <= 68) {
							if (i <= 54) return i + 1;
							if (i <= 57) return i - 4;
							return i - 2;
						} else {
							if (i == 69) return 303;
							return i - 3;
						}
					}
				} else {
					if (i <= 156) {
						if (i == 100) return 296;
						if (i == 136) return 133;
						if (i == 137) return 132;
						return i - 4;
					} else {
						if (i == 157) return 162;
						if (i == 167) return 248;
						return i - 5;
					}
				}
			} else {
				if (i <= 278) {
					if (i <= 253) {
						if (i <= 245) {
							if (i == 181) return 304;
							if (i == 245) return 305;
							return i - 6;
						} else {
							if (i == 253) return 306;
							return i - 7;
						}
					} else {
						if (i <= 255) return i - 8;
						if (i <= 274) return i - 7;
						if (i == 275) return 307;
						return i - 8;
					}
				} else {
					if (i <= 297) {
						if (i == 279) return 309;
						if (i == 286) return 288;
						if (i == 297) return 277;
						return i - 9;
					} else {
						if (i <= 304) return i - 9;
						if (i <= 308) return i - 8;
						if (i == 309) return 308;
						return i;
					}
				}
			}
		}
	}

}