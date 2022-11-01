// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GACCToysV1 is ERC721A, Ownable {

    /*
        ───────────╔════╗
        ───────────║╔╗╔╗║
        ╔══╦══╦══╦═╩╣║║╠╩═╦╗─╔╦══╗
        ║╔╗║╔╗║╔═╣╔═╝║║║╔╗║║─║║══╣
        ║╚╝║╔╗║╚═╣╚═╗║║║╚╝║╚═╝╠══║
        ╚═╗╠╝╚╩══╩══╝╚╝╚══╩═╗╔╩══╝
        ╔═╝║──────────────╔═╝║
        ╚══╝──────────────╚══╝
    */

    using SafeMath for uint256;

    address payable private _PaymentAddress;

    uint256 public MAX_TOYS = 100;
    string private baseURI;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        _PaymentAddress = payable(msg.sender);
    }

    function setPaymentAddress(address paymentAddress) external onlyOwner {
        _PaymentAddress = payable(paymentAddress);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function mintToys(uint numberOfTokens) public onlyOwner payable {
        require(totalSupply().add(numberOfTokens) < MAX_TOYS + 1, "Purchase would exceed max supply of GACC Toys");
        _safeMint(msg.sender, numberOfTokens);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "Operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function burn(uint256 tokenId) public virtual {
        require(isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner or approved");
        _burn(tokenId);
    }

}