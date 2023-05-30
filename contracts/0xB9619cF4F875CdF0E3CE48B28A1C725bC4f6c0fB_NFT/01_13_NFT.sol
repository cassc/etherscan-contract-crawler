// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFT is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;


    string _baseTokenURI;
    Counters.Counter _tokenIds;

    mapping(address => bool) public hasMinted;
    uint256 public MAX_SUPPLY = 2048;

    address private _signer = 0x9d2f3C9AF13CAA9109498f4703881a6135c2aA51;

    constructor(
    ) ERC721("RSS3 Whitepaper", "RWP") {
        _baseTokenURI = "ipfs://QmTMD6sLA7M4iegKDhbdMPBZ4HLi5fjW27w2J16gqc5Cb7/";
    }

    function mint(uint256 salt, bytes memory sig) public {
        require(_verify(_hash(msg.sender, salt), sig), "Invalid token");
        require(!hasMinted[msg.sender], "Already minted");

        uint256 tokenId = totalSupply() + 1;
        require(tokenId <= MAX_SUPPLY, "Max supply exceeded");
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();

        hasMinted[msg.sender] = true;
    }

    function _hash(address _address, uint256 salt) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_address, salt, address(this)));
    }

    function _verify(bytes32 hash, bytes memory sig) internal view returns (bool) {
        return (_recover(hash, sig) == _signer);
    }

    function _recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(sig);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setSigner(address account) public onlyOwner {
        _signer = account;
    }
}