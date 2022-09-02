/*                   _________-----_____ */
/*        _____------           __      ----_ */
/* ___----             ___------              \ */
/*    ----________        ----                 \ */
/*                -----__    |             _____) */
/*                     __-                /     \ */
/*         _______-----    ___--          \    /)\ */
/*   ------_______      ---____            \__/  / */
/*                -----__    \ --    _          /\ */
/*                       --__--__     \_____/   \_/\ */
/*                               ----|   /          | */
/*                                   |  |___________| */
/*                                   |  | ((_(_)| )_) */
/*                                   |  \_((_(_)|/(_) */
/*                                   \             ( */
/*                                    \_____________) */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ERC721A } from "erc721a/ERC721A.sol";

contract WAGTH is Ownable, ERC721A {
    /* ===== Collection Details ===== */
    string public baseURI;
    uint256 public maxSupply;

    /* ===== Mint Details ===== */
    bool public isOpened;
    uint256 public price;
    uint256 public maxTokenPerWallet;

    constructor(
        string memory uri,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxTokenPerWallet
    ) ERC721A("WE ARE GOING TO HELL", "WAGTH") {
        baseURI = uri;
        maxSupply = _maxSupply;
        price = _price;
        maxTokenPerWallet = _maxTokenPerWallet;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setSalesStatus(bool _status) external onlyOwner {
        isOpened = _status;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxTokenPerWallet(uint256 _maxTokenPerWallet) external onlyOwner {
        maxTokenPerWallet = _maxTokenPerWallet;
    }

    function mint(uint256 _quantity) external payable {
        require(isOpened, "NotStarted");
        require(msg.sender == tx.origin, "NotAllowed");
        require(totalSupply() + _quantity <= maxSupply, "MaxSupply");
        require(_numberMinted(msg.sender) + _quantity <= maxTokenPerWallet, "ExceedLimit");
        require(msg.value >= _quantity * price, "InvalidPrice");
        _mint(msg.sender, _quantity);
    }

    function withdraw(address payable _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _receiver.call{ value: balance }("");
        require(success, "WithdrawFailed");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length != 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}