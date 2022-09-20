// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Zenga is ERC721A, ReentrancyGuard, Ownable  {

    constructor() ERC721A("ZENGA", "ZNG"){}

    bytes32 internal root;
    bool public mintingIsEnabled;
    bool public claimingIsEnabled;
    uint256 public maxSupply = 1000;
    mapping(address => bool) internal walletClaimed;
    mapping(address => bool) internal walletMinted;

    function toggleSale(bool _saleActive) external onlyOwner {
        mintingIsEnabled = _saleActive;
    }

    function toggleClaim(bool _claimActive) external onlyOwner {
        claimingIsEnabled = _claimActive;
    }

    function editAllowList(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function claim(bytes32[] calldata _proof) public nonReentrant {
        require(MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender))), "Not on allow list.");
        require(claimingIsEnabled, "Claim is not live.");
        require(!walletClaimed[msg.sender], "Wallet has already claimed 1.");
        require(_totalMinted() + 1 <= maxSupply, "Max supply reached.");
        require(msg.sender == tx.origin, "Only EOAs can mint.");
        walletClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

   function mint() public nonReentrant {
        require(mintingIsEnabled, "Public minting is not live.");
        require(!walletMinted[msg.sender], "Wallet has already minted 1.");
        require(_totalMinted() + 1 <= maxSupply, "Max supply reached.");
        require(msg.sender == tx.origin, "Only EOAs can mint.");
        walletMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory uri = _baseURI();
        return bytes(uri).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json")) : '';
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function hasWalletClaimed(address _addr) public view returns (bool) {
        return walletClaimed[_addr];
    }
            
    function hasWalletMinted(address _addr) public view returns (bool) {
        return walletMinted[_addr];
    }
  
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}