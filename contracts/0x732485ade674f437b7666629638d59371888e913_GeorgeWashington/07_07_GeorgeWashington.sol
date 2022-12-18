// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";

contract GeorgeWashington is ERC721A, Ownable {
    string baseURI;
    string baseExtension = ".json";
    string notRevealedUri;
    bool saleLive;
    bool isRevealed;

    uint256 public constant maxSupply = 4444;
    uint256 constant price = 0.001 ether;
    uint256 constant freeSupply = 500;
    mapping(address => uint256) public Minted;

    constructor(string memory _BaseURI, string memory _NotRevealedUri)
        ERC721A("Washington Digital Trading Cards", "WDTC")
    {
        setBaseURI(_BaseURI);
        setNotRevealedURI(_NotRevealedUri);
        _mint(msg.sender, 1);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string calldata _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        if (isRevealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
            : "";
    }

    function setSaleState(bool _state) public onlyOwner {
        saleLive = _state;
    }

    function reveal(bool _state) public onlyOwner {
        isRevealed = _state;
    }

    function mint(uint256 _mintAmount) public payable {
        if (!saleLive) revert SaleNotLive();
        if (_mintAmount == 0) revert NoZeroValue();
        if (totalSupply() < freeSupply) {
            _mint(msg.sender, _mintAmount);
        } else {
            if (totalSupply() + _mintAmount > maxSupply) revert OverMintLimit();
            if (msg.value < _mintAmount * price) revert InvalidMsgValue();
            _mint(msg.sender, _mintAmount);
        }
    }

    function withdraw() external payable onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }
}

error TransferFailed();
error OverMintLimit();
error InvalidMsgValue();
error SaleNotLive();
error NoZeroValue();