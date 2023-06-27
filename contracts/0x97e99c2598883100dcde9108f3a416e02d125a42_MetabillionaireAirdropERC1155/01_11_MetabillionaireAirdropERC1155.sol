// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Misterjuiice https://instagram.com/misterjuiice
/// @title METABILLIONAIRE MERCH PASS

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetabillionaireAirdropERC1155 is Ownable, ERC1155 {
    uint256 public constant Platinum = 1;
    uint256 public constant Gold = 2;
    uint256 public constant Silver = 3;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmcdbzLCAMdmVBh7n4ho762XAhRb49gBiV3XywPzGqkyJj/";

    constructor(
        address[] memory platinumAddress,
        address[] memory goldAddress
    ) ERC1155("{baseURI}{id}.json") {
        for(uint i = 0 ; i < platinumAddress.length ; i++) {
            _mint(platinumAddress[i], Platinum, 1, "");
        }
        for(uint i = 0 ; i < goldAddress.length ; i++) {
            _mint(goldAddress[i], Gold, 1, "");
        }
    }

    function uri(uint256 _tokenid) override public view virtual returns (string memory) {
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenid),".json"
            )
        );
    }

     function burn(address ownerAddress, uint256 tokenId) public {
        require(ownerAddress == msg.sender, "You are not the owner");
        _burn(ownerAddress, tokenId, 1);
    }

    function ownerBurn(address ownerAddress, uint256 tokenId) external onlyOwner {
      _burn(ownerAddress, tokenId, 1);
    }

    function giftPlatinum(address[] calldata _to) external onlyOwner {
        for(uint i = 0 ; i < _to.length ; i++) {
            _mint(_to[i], Platinum, 1, "");
        }
    }

     function giftGold(address[] calldata _to) external onlyOwner {
        for(uint i = 0 ; i < _to.length ; i++) {
            _mint(_to[i], Gold, 1, "");
        }
    }

     function giftSilver(address[] calldata _to) external onlyOwner {
        for(uint i = 0 ; i < _to.length ; i++) {
            _mint(_to[i], Silver, 1, "");
        }
    }

    function setURI(string memory baseUri) public onlyOwner {
        _setURI(baseUri);
        baseURI = baseUri;
    }
}