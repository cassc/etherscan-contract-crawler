// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error SoldOut();
error InvalidValue();
error CannotSetZeroAddress();

contract FuckLifeStyle is ERC721A, ERC2981, Ownable {

    uint256 public constant maxSupply = 9996;
    uint256 public constant price = 0.003 ether;
    string public baseTokenURI;

    // Sets Treasury Address for withdraw() and ERC2981 royaltyInfo
    address public treasuryAddress;

    constructor(
        address treasuryAddress_,
        string memory baseTokenURI_
    ) ERC721A("Fuck Lifestyle Gang Club DAO", "FLGC") {
        baseTokenURI = baseTokenURI_;
        setTreasureAddress(treasuryAddress_);
    }

    function mint(
        uint256 quantity
    ) external payable {
        if (totalSupply() + quantity > maxSupply) revert SoldOut();
        if (price * quantity > msg.value) revert InvalidValue();
        _mint(msg.sender, quantity);
    }

    function withdraw(

    ) external onlyOwner {
        payable(treasuryAddress).transfer(address(this).balance);
    }

    function setTreasureAddress(
        address treasuryAddress_
    ) public onlyOwner {
        treasuryAddress = treasuryAddress_;
        _setDefaultRoyalty(treasuryAddress_, 100); // 1%
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool){
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _baseURI(
    ) internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId(
    ) internal pure override returns (uint256) {
        return 1;
    }
}