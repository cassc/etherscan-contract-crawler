/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";
import {IERC165} from "@openzeppelin/[email protected]/utils/introspection/IERC165.sol";
import {ENS} from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import {INameResolver} from "@ensdomains/ens-contracts/contracts/resolvers/profiles/INameResolver.sol";
import {IExtendedResolver} from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IExtendedResolver.sol";

interface ERC721Stub {
	function name() external view returns (string memory);
	function tokenURI(uint256 token) external view returns (string memory);
	function ownerOf(uint256 token) external view returns (address);
}

address constant CRYPTO_PUNKS  = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
interface CryptoPunksStub {
	function punkIndexToAddress(uint256 token) external view returns (address);
	function punkImageSvg(uint16 index) external view returns (string memory svg);
}

address constant ENS_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
bytes32 constant ENS_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
interface ReverseRegistrarStub {
	 function setName(string memory name) external returns (bytes32);
}

uint256 constant HYPHEN = 0x2D;
	
contract NFTResolver is Ownable, IExtendedResolver {

	event NFTRegistered(address indexed nft, string label);

	error NotAllowed();
	error NotContract();
	error BadPayment();
	error BadLabel();

	function supportsInterface(bytes4 x) external pure returns (bool) {
		return x == type(IERC165).interfaceId			// 0x01ffc9a7 
			|| x == type(IExtendedResolver).interfaceId; // 0x9061b923
	}

	mapping (bytes32 => address) _addrs;
	uint256 public publicPrice = 0.05 ether;
	bool public adminRegistrationLocked;

	function withdraw() external {
		payable(owner()).transfer(address(this).balance);
	}

	function setPrimary(string calldata name) onlyOwner external {
		ReverseRegistrarStub(ENS(ENS_REGISTRY).owner(ENS_REVERSE_NODE)).setName(name);
	}

	function setPublicPrice(uint256 price) onlyOwner external {
		publicPrice = price;
	}
	function lockAdminRegistration() onlyOwner external {
		adminRegistrationLocked = true;
	}

	function publicRegister(address nft, string calldata label) external payable {
		if (publicPrice == 0) revert NotAllowed();
		if (msg.value < publicPrice) revert BadPayment();
		if (contractFor(label) != address(0)) revert BadLabel(); // cannot overwrite
		_register(nft, label);
	}
	function adminRegister(address[] calldata nfts, string[] calldata labels) onlyOwner external {
		if (adminRegistrationLocked) revert NotAllowed();
		for (uint256 i; i < nfts.length; i++) {
			_register(nfts[i], labels[i]);
		}
	}
	function _register(address nft, string memory label) private {
		if (nft != address(0)) {
			if (nft.code.length == 0) revert NotContract();
			if (_digitQ(uint8(bytes(label)[0]))) revert BadLabel(); // leading digit
			uint256 last = uint8(bytes(label)[bytes(label).length-1]);
			if (_digitQ(last) || last == HYPHEN) revert BadLabel(); // trailing digit
		}
		_addrs[_labelhash(label)] = nft;
		emit NFTRegistered(nft, label);
	}

	// convenience getters
	function contractFor(string memory label) public view returns (address) {
		return _addrs[_labelhash(label)];
	}
	function holderFor(string memory label, uint256 token) external view returns (address target, address owner, string memory primary) {
		(target, owner) = holderOf(contractFor(label), token);
		primary = primaryOf(owner);
	}

	// primitive getters
	function primaryOf(address owner) public view returns (string memory ret) {
		string memory temp = new string(40);
		uint256 ptr;
		assembly {
			ptr := add(temp, 32)
		}
		_writeHex(ptr, uint160(owner), 40);
		bytes32 node = keccak256(abi.encodePacked(ENS_REVERSE_NODE, keccak256(bytes(temp))));
		address resolver = ENS(ENS_REGISTRY).resolver(node);
		if (resolver != address(0)) {
			try INameResolver(resolver).name(node) returns (string memory name) {
				ret = name;
			} catch {
			}
		}
	}
	function avatarOf(address nft, uint256 token) public view returns (string memory avatar) {
		(address target, ) = holderOf(nft, token);
		if (target == CRYPTO_PUNKS) {
			return CryptoPunksStub(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2).punkImageSvg(uint16(token));
		}
		avatar = new string(125); // 18 + 40 + 3 + 64
		uint256 ptr;
		assembly {
			ptr := add(avatar, 32)
			mstore(ptr,          0x6569703135353A312F6572633732313A30780000000000000000000000000000) // "eip155:1/erc1155:0x"
			mstore(add(ptr, 58), 0x2F30780000000000000000000000000000000000000000000000000000000000) // "/0x"
		}
		_writeHex(ptr + 18, uint160(target), 40);
		_writeHex(ptr + 61, token, 64);
	}
	function holderOf(address nft, uint256 token) public view returns (address target, address owner) {
		if (nft == CRYPTO_PUNKS) {
			try CryptoPunksStub(nft).punkIndexToAddress(token) returns (address ret) {
				owner = ret;
			} catch {
			}
		} else {
			try ERC721Stub(nft).ownerOf(token) returns (address ret) {
				owner = ret;
			} catch {
			}
		}
		target = nft;
		while (owner.code.length > 0) { // wrapped?
			try ERC721Stub(owner).ownerOf(token) returns (address ret) {
				target = owner;
				owner = ret;
			} catch {
				break;
			}
		}
	}

	// accepts:
	//   <name>.*
	//   <digit>.<name>.*
	//   <name>-?<digit>.*
	uint256 constant TY_LABEL = 0;
	uint256 constant TY_TOKEN = 1;
	function parseEncodedName(bytes memory encoded) public pure returns (uint256 ty, bytes32 labelhash, uint256 token) {
		unchecked {
			uint256 head;
			uint256 ptr;
			assembly {
				ptr := add(encoded, 32)
				head := mload(ptr)
			}
			uint256 len = head >> 248;
			if (_digitQ(uint8(head >> 240))) { // leading digit
				token = _readInteger(++ptr, len);
				ptr += len;
				ty = TY_TOKEN;
			}
			assembly {
				head := mload(ptr)
				ptr := add(ptr, 1)
			}
			len = head >> 248;
			if (ty == TY_LABEL) {
				uint256 end = ptr + len; // work backwards
				uint256 cut = end;
				uint256 off;
				do {
					off = cut - 32;
					assembly {
						head := mload(off)
					}
					while (_digitQ(uint8(head))) {
						head >>= 8;
						--cut;
					}
				} while (off == cut);
				if (cut < end) { // has digits
					ty = TY_TOKEN;
					token = _readInteger(cut, end - cut);
					if (uint8(head) == HYPHEN) --cut;
					len = cut - ptr; // truncate
				}
			}
			assembly {
				labelhash := keccak256(ptr, len)
			}
		}
	}

	// IExtendedResolver
	function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory res) {
		unchecked {
			(uint256 ty, bytes32 labelhash, uint256 token) = parseEncodedName(name);
			address addr = _addrs[labelhash];
			bytes4 method = bytes4(data[0:4]);
			if (method == 0x3b3b57de) { // addr(bytes32) => address
                bytes32 node = abi.decode(data[4:], (bytes32));
				if (ty == TY_TOKEN) {
					(, addr) = holderOf(addr, token);
				} else if (ENS(ENS_REGISTRY).resolver(node) == address(this)) {
                    addr = address(this);
                }
				res = abi.encode(addr);
			} else if (method == 0xf1cb7e06) { // addr(bytes32,coinType) => bytes
				(bytes32 node, uint256 coinType) = abi.decode(data[4:], (bytes32, uint256));
				if (coinType == 60) {
					if (ty == TY_TOKEN) {
						(, addr) = holderOf(addr, token);
					} else if (ENS(ENS_REGISTRY).resolver(node) == address(this)) {
                        addr = address(this);
                    }
					res = abi.encode(abi.encodePacked(addr));
				} else {
					res = abi.encode('');
				}
			} else if (method == 0xbc1c58d1) { // contenthash(bytes32) => bytes 
				return abi.encode('');
			} else if (method == 0x59d1d43c) { // text(bytes32,string) => string
				(, string memory key) = abi.decode(data[4:], (bytes32, string));
				bytes32 keyhash = keccak256(bytes(key));
				if (keyhash == 0xb68b5f5089998f2978a1dcc681e8ef27962b90d5c26c4c0b9c1945814ffa5ef0) { // url
					if (ty == TY_TOKEN) {
						try ERC721Stub(addr).tokenURI(token) returns (string memory url) {
							return abi.encode(url);
						} catch {
						}
					} 
				} else if (keyhash == 0x1596dc38e2ac5a6ddc5e019af4adcc1e017a04f510d57e69d6879d5d2996bb8e) { // description
					try ERC721Stub(addr).name() returns (string memory ret) {
						return abi.encode(ret);
					} catch {
					}
				} else if (keyhash == 0xd1f86c93d831119ad98fe983e643a7431e4ac992e3ead6e3007f4dd1adf66343) { // avatar
					if (ty == TY_TOKEN) {
						return abi.encode(avatarOf(addr, token));
					}
				} else if (keyhash == 0x32418106fd89af94305d9787acb608a501b749f5f1783cfca7b3f864595254ca) { // name
					if (ty == TY_TOKEN) {
						(, addr) = holderOf(addr, token);
					}
					return abi.encode(primaryOf(addr));
				}
				return abi.encode("");
			}
		}
	} 

	// utils
	function _labelhash(string memory label) private pure returns (bytes32) {
		return keccak256(bytes(label));
	}
	function _digitQ(uint256 ch) private pure returns (bool) {
		return ch >= 0x30 && ch <= 0x39;
	}
	function _readInteger(uint256 ptr, uint256 len) private pure returns (uint256 acc) {
		unchecked {
			uint256 end = ptr + len;
			while (true) {
				uint256 temp;
				assembly {
					temp := mload(ptr)
				}
				uint256 shift = 256;
				while (shift > 0) {
					shift -= 8;
					uint256 ch = uint8(temp >> shift);
					if (!_digitQ(ch)) return type(uint256).max; // error
					acc = acc * 10 + (ch - 0x30);
					if (++ptr == end) return acc;
				}
			}
		}
	}
	function _writeHex(uint256 ptr, uint256 value, uint256 len) private pure {
		unchecked {
			uint256 end = ptr + len;
			while (end > ptr) {
				assembly {
					end := sub(end, 1)
					mstore8(end, byte(and(value, 0xF), 0x3031323334353637383961626364656600000000000000000000000000000000))
					value := shr(4, value)
				}
			}
		}
	}

}