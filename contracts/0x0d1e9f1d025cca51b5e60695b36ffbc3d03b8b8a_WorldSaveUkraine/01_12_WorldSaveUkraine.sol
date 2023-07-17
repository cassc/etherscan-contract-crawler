// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WorldSaveUkraine is ERC1155, Ownable, ReentrancyGuard {
    // Русский корабль иди нахуй.

    using Strings for uint256;
    bool public isActive = false;
    string private name_ = "World Save Ukraine by Holy Water";
    string private symbol_ = "WSU";
    string public _uri = "";

    uint256 public artworks = 80;
    uint256 public editions = 120;
    uint256 public supply = artworks * editions;

    uint256 public maxPerTransaction = 10;

    uint256 public price = 0.08 ether;

    // https://twitter.com/Ukraine/status/1497594592438497282
    address public saveUkraineCharityAddress =
        0x165CD37b4C644C2921454429E7F9358d18A45e14;

    uint256 private counter = 0;
    uint256 public minted = 0;
    uint256 public donated = 0;

    constructor() ERC1155(_uri) {}

    function mint(uint256 _amount) public payable nonReentrant {
        require(isActive, "Minting is closed");
        require(minted < supply, "Sold out");
        require(
            msg.sender == tx.origin,
            "You cannot mint from a smart contract"
        );
        require(msg.value >= price * _amount, "Not enough eth");
        require(
            _amount > 0 && _amount <= maxPerTransaction,
            "The amount must be between 1 and 10"
        );
        require(_amount + minted <= supply, "Not enough NFTs");

        minted += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = (counter % artworks) + 1;
            _mint(msg.sender, tokenId, 1, "");
            counter++;
        }

        uint256 currentBalance = address(this).balance;

        if (currentBalance >= 5 ether) {
            payable(saveUkraineCharityAddress).transfer(currentBalance);
            donated += currentBalance;
        }
    }

    function uri(uint256 _id)
        public
        view
        override(ERC1155)
        returns (string memory)
    {
        return string(abi.encodePacked(_uri, _id.toString()));
    }

    function toggleActive() public onlyOwner {
        isActive = !isActive;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        _uri = newuri;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function withdraw() external payable nonReentrant onlyOwner {
        uint256 currentBalance = address(this).balance;
        require(currentBalance >= 0, "Not enough eth");
        payable(saveUkraineCharityAddress).transfer(currentBalance);
        donated += currentBalance;
    }
}