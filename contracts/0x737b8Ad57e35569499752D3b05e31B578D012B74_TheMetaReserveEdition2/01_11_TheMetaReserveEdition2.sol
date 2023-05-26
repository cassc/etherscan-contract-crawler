// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The Meta Reserve Edition 2
// WeMint.Cash

contract TheMetaReserveEdition2 is ERC721, Ownable {
    ERC721 Washies;
    using Strings for uint256;
    mapping(uint256 => bool) public claimed;
    bool public enabled;
    uint256 public maxSupply;
    uint256 public totalSupply;
    string internal baseURI;

    constructor()
    ERC721("WeMint Jefferson", "JEFFERSON")
    {
        enabled = false;
        maxSupply = 10000;
        totalSupply = 0;
        setWashie(0xA9cB55D05D3351dcD02dd5DC4614e764ce3E1D6e);
        baseURI = "ipfs://QmYstpM5tHC162SM2mVVUZSqYFpppP8wJHm2yrvW98chu9/";
    }

    function claimJeffies(uint256[] memory tokenIds) public returns (uint256[] memory){
        require(enabled, "Contract not enabled");
        require(tx.origin == msg.sender, "CANNOT MINT THROUGH A CUSTOM CONTRACT");
        uint256[] memory newTokenIds = new uint[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(claimed[tokenIds[i]] == false, "Token already claimed");
            require(Washies.ownerOf(tokenIds[i]) == msg.sender, "You dont own that Washie");
            claimed[tokenIds[i]] = true;
            uint256 newTokenId = lcg(maxSupply, tokenIds[i]);
            _safeMint(_msgSender(), newTokenId);
            newTokenIds[i] = newTokenId;
        }
        totalSupply += tokenIds.length;
        return newTokenIds;
    }

    // LCG w/ params satisfying Hull–Dobell Theorem
    function lcg(uint256 _m, uint256 seed) internal pure returns (uint256) {
        uint256 a = 421;
        uint256 c = 1663;
        uint256 m = _m;
        return (((a * seed) + c) % m) + 1;
    }

    function setWashie(address _washieAddress) public onlyOwner {
        Washies = ERC721(_washieAddress);
        return;
    }

    function enable(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}