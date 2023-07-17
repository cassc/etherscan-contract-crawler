// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IGold {
    function burn(address account, uint amount) external;
    function balanceOf(address owner) external view returns (uint);
}

contract GHGHouse is ERC721, Ownable, Pausable, ReentrancyGuard {
    uint16 public maxTokens = 500;
    uint16 public maxGiveAway = 150;

    uint16 public tokensMinted = 0;
    uint16 public giveAwayMinted = 0;

    uint public goldPrice = 0 ether;
    uint public woodPrice = 300000 ether;

    IGold public gold;
    IGold public wood;

    mapping(address => bool) public approvedManagers;

    string private _apiURI = "https://gold-hunt-house.herokuapp.com/token/";

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }
    function setBaseURI(string memory uri) external {
        _apiURI = uri;
    }
    function setGold(address _address) external onlyOwner {
        gold = IGold(_address);
    }
    function setWood(address _address) external onlyOwner {
        wood = IGold(_address);
    }

    constructor() ERC721("GHGHouse", "GHGHOUSE") {
        _pause();
        _mint(msg.sender, 0);

        approvedManagers[msg.sender] = true;
    }
    function totalSupply() external view returns (uint) {
        return tokensMinted + giveAwayMinted;
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    function pause() external onlyOwner {
        _pause();
    }
    function addManager(address _address) external onlyOwner {
        approvedManagers[_address] = true;
    }
    function removeManager(address _address) external onlyOwner {
        approvedManagers[_address] = false;
    }
    function changeGoldPrice(uint _wei) external onlyOwner {
        goldPrice = _wei;
    }
    function changeWoodPrice(uint _wei) external onlyOwner {
        woodPrice = _wei;
    }
    function changeTotalSupply(uint16 _maxSupply) external onlyOwner {
        maxTokens = _maxSupply;
    }
    function changeGiveAwaySupply(uint16 _maxSupply) external onlyOwner {
        maxGiveAway = _maxSupply;
    }

    function mintPrice(uint16 _amount, bool inWood) public view returns(uint) {
        return inWood ? _amount * woodPrice : _amount * goldPrice;
    }

    function giveAway(address _wallet, uint16 _amount) public {
        require(approvedManagers[msg.sender] == true);
        require(giveAwayMinted + _amount <= maxGiveAway, "Out of limit");

        uint16 fromToken = tokensMinted + giveAwayMinted + 1;
        giveAwayMinted += _amount;

        for (uint16 i = 0; i < _amount; i++) {
            _mint(_wallet, fromToken + i);
        }
    }

    function mint(uint16 _amount) public whenNotPaused nonReentrant {
        require(tokensMinted + _amount <= maxTokens, "Out of limit");
        uint goldTotalPrice = mintPrice(_amount, false);
        uint woodTotalPrice = mintPrice(_amount, true);

        require(gold.balanceOf(msg.sender) >= goldTotalPrice, "Not enough gold");
        require(wood.balanceOf(msg.sender) >= woodTotalPrice, "Not enough wood");

        uint16 fromToken = tokensMinted + giveAwayMinted + 1;
        tokensMinted += _amount;

        if (goldTotalPrice > 0) {
            gold.burn(msg.sender, goldTotalPrice);
        }
        if (woodTotalPrice > 0) {
            wood.burn(msg.sender, woodTotalPrice);
        }

        for (uint16 i = 0; i < _amount; i++) {
            _mint(msg.sender, fromToken + i);
        }
    }
}