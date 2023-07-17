// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WizardlyAnimalsSchool is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 100;
    uint256 private _price = 0.06 ether;
    bool public _paused = true;

    // withdraw addresses
    address t1 = 0x7f8b77218387b27B0AAe242Af459ac10739Ff0D4;
    address t2 = 0x0eeb38bd538E9ee454DdC768a6e499EeCae07D2D;
    address t3 = 0x5DF0fA50B44d183128085dfeAA563362dc8293b8;
    address t4 = 0x7226051bC27038DaA03D4Cd114cc73164EFeD1Ab;

    modifier onlyManager() {
        require(
            msg.sender == t1 ||
                msg.sender == t2 ||
                msg.sender == t3 ||
                msg.sender == t4 ||
                msg.sender == owner(),
            "Only manager can call this function."
        );
        _;
    }

    constructor(string memory baseURI)
        ERC721("Wizardly Animals School", "WAS")
    {
        setBaseURI(baseURI);

        // team gets the first 4
        _safeMint(t1, 0); // will be rinkel
        _safeMint(t2, 1); // will be feanor
        _safeMint(t3, 2); // will be galileo
        _safeMint(t4, 3); // will be henley
    }

    // TODO: implement modifier to return the excess of eth or all the eth if value is not enough
    function mintWizard(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(!_paused, "Sale paused");
        require(num < 21, "You can mint a maximum of 20 Wizards at a time");
        require(
            supply + num < 10001 - _reserved,
            "Exceeds maximum Wizard supply"
        );
        require(msg.value >= _price * num, "Ether sent is not correct");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function wizardsOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function ownerOfWizard(uint256 wizardId_) public view returns (address) {
        return ownerOf(wizardId_);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= _reserved, "Exceeds reserved Wizard supply");

        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner returns (bool) {
        _paused = val;
        return val;
    }

    function isMinted(uint256 wizardId_) public view returns (bool) {
        return _exists(wizardId_);
    }

    function withdrawAll() public payable onlyManager {
        uint256 _each = address(this).balance / 4;
        require(payable(t1).send(_each));
        require(payable(t2).send(_each));
        require(payable(t3).send(_each));
        require(payable(t4).send(_each));
    }
}