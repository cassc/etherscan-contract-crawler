// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error MaxTotalSupplyReached();
error InvalidSignatureOrAlreadyMinted();

contract DeQuestXIlluviumSummerChallenge is ERC721, ERC721Burnable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    uint96 public immutable maxTotalSupply;
    address public backend;

    mapping(address => bool) public nftMintedToAddress;

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory _name,
        string memory symbol,
        address _backend,
        uint96 _maxTotalSupply
    ) ERC721(_name, symbol) {
        maxTotalSupply = _maxTotalSupply;
        backend = _backend;
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://scarlet-adjacent-orangutan-882.mypinata.cloud/ipfs/QmaDPew8why7RKzcCmBujsBmx72QrMCxqCf92tbUviciWw?_gl=1*1ew78oj*rs_ga*OTE2NDA1NjgtNzYyMy00ZWZmLTljNTctZjk3MDhhOTVjMTU3*rs_ga_5RMPXG14TE*MTY4NjA1MzY2NC40LjEuMTY4NjA1NDA3Ny42MC4wLjA";
    }

    function safeMint(uint8 v, bytes32 r, bytes32 s, address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        if (tokenId >= maxTotalSupply) {
            revert MaxTotalSupplyReached();
        }

        bytes32 signedDataHash = keccak256(abi.encodePacked(to));
        bytes32 message = signedDataHash.toEthSignedMessageHash();
        if (message.recover(v, r, s) != backend || nftMintedToAddress[to]) {
            revert InvalidSignatureOrAlreadyMinted();
        }

        _tokenIdCounter.increment();
        nftMintedToAddress[to] = true;
        _safeMint(to, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return _baseURI();
    }

    function isMaxTotalSupplyReached() external view returns (bool) {
        if (_tokenIdCounter.current() >= maxTotalSupply) {
            return true;
        }
        return false;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}