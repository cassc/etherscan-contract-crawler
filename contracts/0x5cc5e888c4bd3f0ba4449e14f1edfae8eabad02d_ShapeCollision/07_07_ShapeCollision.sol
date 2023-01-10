// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";

contract ShapeCollision is ERC721A, Ownable {
    string baseURI;
    string baseExtension = ".json";
    bool saleLive;

    uint256 public constant maxSupply = 501;
    uint256 constant price = 0.0018 ether;
    uint256 constant freeSupply = 100;
    mapping(address => uint256) public Minted;

    constructor(string memory _BaseURI) ERC721A("Shapes Collision", "SCOLI") {
        setBaseURI(_BaseURI);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string calldata _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
            : "";
    }

    function setSaleState(bool _state) public onlyOwner {
        saleLive = _state;
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