// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "solmate/tokens/ERC721.sol";
import "solmate/utils/MerkleProofLib.sol";
import "solmate/auth/Owned.sol";

error SoldOut();
error AlreadyMinted();
error InvalidProof();
error TokenNotFound();

contract uwu is ERC721, Owned {
    uint256 public constant MAX_SUPPLY = 69;

    string public baseURI;

    uint256 nextTokenId = 0;
    mapping(address => bool) public hasMinted;

    bytes32 public merkleRoot;

    constructor(string memory _baseURI) ERC721("kaw-ai", "kaw-ai") Owned(msg.sender) {
        baseURI = _baseURI;
    }

    function setRoot(bytes32 newRoot) public onlyOwner {
        merkleRoot = newRoot;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function mint(bytes32[] calldata proof) public {
        bytes32 leaf = bytes32(uint256(uint160(msg.sender)));
        if (!MerkleProofLib.verify(proof, merkleRoot, leaf)) revert InvalidProof();

        if (nextTokenId >= MAX_SUPPLY) revert SoldOut();

        if (hasMinted[msg.sender]) revert AlreadyMinted();
        hasMinted[msg.sender] = true;

        _mint(msg.sender, nextTokenId++);
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        ownerOf(id); // will revert if not minted
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(id))) : "";
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol#L254-L290
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15-L38
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
}