/*                       ..:::::::::::::.. */
/*                 .:::::''              ``:::. */
/*               .:;'                        `::. */
/*            ..::'                            `::. */
/*           ::'                                  ::.:' */
/*       `::.::                                    ::. */
/*     .::::::::'                                `:.:::.    .:':' */
/* :::::::::::::.          .:.                .:. ` :::::::::'::: */
/* :::.::::::::::::'       :::                :::    :::::::::':::' */
/* ..::::::::::::'          ' `                ' `   .::::::' :::' */
/* ::::::::::::'  `:.   .:::::::.          .:::::::.:: .:' :'.::' */
/* ::::::::::::    `::.::'     `::.      .::'     `::.::':'.:::' */
/* ::::::::::::      .::'        `:;  . .::'        `:;:'.::'' */
/* :::::::::::'.     ::'    .    .:: :  ::'    .    .:::::'' */
/* :`::::::::::::.:  `::.  :O: .::;' :  `::.  :O: .::;'::' */
/*    `::::::`::`:.    `:::::::::'   :.   `:::::::::':''' */
/*        `````:`::.     , .         `:.        , . `::. */
/*             :: `::.   :::      ..::::::::..  :::  `:: */
/*       .::::'::. `::.  `:'     :::::::::::::; `:'   :; */
/*             ::'    ::.   .::'  ``:::::::;'' :.   .:' */
/*             `::    `::  ::'        ::       .::  :' */
/*              ::.    :'.::::::.    :  :   .::::. .:::. */
/* :.           `::.     :::'  ``::::. .::::'' `::::' `::. */
/* `::.          `::.    `:::. ::.  `::::' .:: ::::;    `:: */
/* :.`:.          `::.     `::. `:::.    .::'  ::;'     .:;. */
/*  ::`::.          `::.     `::.  `::. .::' .:;':'     :;':. */
/* ::':``:::::.       `::.     `::. `::::'  .:;':'     .;':': */
/* : .:`:::':`:::::.   `::.      `:::.   .::;'.:'  .::;'' ';: */
/* ..::': :. ::::. `::::::`::..      `:::::'  .:':::'::.:: :': */
/* :' :'.:::. `:: :: ::. .::`::.   .     . .:;':' ::'`:: :::' */
/* : ::.:. `:  `::'  `:: ::'::`::::::::::::;' :: .:' .::: ;:' */
/* ::.::.:::: .:: :.  `:':'  ::.:'`::. .::':.::' :: .::''::' */
/* `:::`::.`:.::' ::  .: ::  `::'  `:: :' .::' ::.:.::' :; */
/*    `::::::.`:. .:. :: `::.:: ::  `::. .:: ::.`:::':.:;' */
/*          `::::::::::...:::'  `::.:'`:.::'.:.:;' .:;' */
/*                     `::::::::::::::::::::'.::;:;' */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";

error NotStarted();
error NotAllowed();
error InsufficientValue();
error LimitReached(uint256 minted, uint256 quantity);
error MaxSupplyReached();
error NonExistentTokenURI();
error WithdrawFailed();

contract MentalClown is Ownable, ERC721A {
    string public baseURI;
    string public uriSuffix = ".json";
    bool public saleStatus;
    uint256 public price;
    uint256 public maxMintAmount;
    uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri,
        uint256 _price,
        uint256 _maxMintAmount,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol) {
        baseURI = uri;
        price = _price;
        maxMintAmount = _maxMintAmount;
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory uri, string memory _suffix) external onlyOwner {
        baseURI = uri;
        uriSuffix = _suffix;
    }

    function setSalesStatus(bool _status) external onlyOwner {
        saleStatus = _status;
    }

    function setMintDetails(uint256 _price, uint256 _maxMintAmount) external onlyOwner {
        price = _price;
        maxMintAmount = _maxMintAmount;
    }

    function mint(uint256 _quantity) external payable {
        if (!saleStatus) revert NotStarted();
        if (msg.sender != tx.origin) revert NotAllowed();
        if (totalSupply() + _quantity > maxSupply) revert MaxSupplyReached();
        uint256 _minted = _numberMinted(msg.sender);
        if (_minted + _quantity > maxMintAmount) revert LimitReached(_minted, _quantity);
        if (msg.value < _quantity * price) revert InsufficientValue();
        _mint(msg.sender, _quantity);
    }

    function devMint(uint256 _quantity) external onlyOwner {
        if (totalSupply() + _quantity > maxSupply) revert MaxSupplyReached();
        _mint(msg.sender, _quantity);
    }

    function numberMinted(address _address) external view returns (uint256 result) {
        result = _numberMinted(_address);
    }

    function withdraw(address payable _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _receiver.call{ value: balance }("");
        if (!success) revert WithdrawFailed();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length != 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), uriSuffix))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}