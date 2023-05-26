// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@beskay/erc721b/contracts/ERC721B.sol";

contract MuscleBrainMonsters is Ownable, ERC721B {
    using Strings for uint256;

    string public _baseUri;
    address public minter;
    uint256 public purchaseLimit;

    constructor() ERC721B("Muscle Brain Monsters", "MBM") {
    }

    function setMinter(address _minter, string memory __baseUri, uint256 _purchaseLimit) public onlyOwner {
        minter = _minter;
        _baseUri = __baseUri;
        purchaseLimit = _purchaseLimit;
    }

    function updateBaseTokenURI(string memory __baseUri) public onlyOwner {
        _baseUri = __baseUri;
    }
    
    function mint(address to, uint256 quantity) public {
        require(msg.sender == minter && quantity <= purchaseLimit, "params error");

        _safeMint(to, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, tokenId.toString())) : "";
    }
}