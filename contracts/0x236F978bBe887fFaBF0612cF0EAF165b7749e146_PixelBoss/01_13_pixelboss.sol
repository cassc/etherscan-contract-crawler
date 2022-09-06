// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

contract PixelBoss is ERC1155, Ownable, ERC1155Burnable {
    using Strings for uint256;

    mapping(address => bool) public _minted;
    bool public mintEnabled = false;
    mapping (address => bool) public whitelisted;
    bool public whitelistOnly = true;

    uint256 public mintStartDate;
    uint256 public mintDayPeriod = 91;

    uint8 public goldSupply = 0;
    uint8 public platinumSupply = 0;
    uint8 public diamondSupply = 0;
    uint8 public tripleaSupply = 0;

    uint8 public goldMax = 250;
    uint8 public platinumMax = 250;
    uint8 public diamondMax = 250;
    uint8 public tripleaMax = 250;

    uint8 public goldAvailable = 0;
    uint8 public platinumAvailable = 0;
    uint8 public diamondAvailable = 0;
    uint8 public tripleaAvailable = 0;

    uint256 public goldPrice = 0.22 ether;
    uint256 public platinumPrice = 0.33 ether;
    uint256 public diamondPrice = 0.44 ether;
    uint256 public tripleaPrice = 100 ether;

    constructor(string memory uri_) ERC1155("") {
        _setURI(uri_);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC1155.uri(tokenId), tokenId.toString(), ".json"));
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function isMember() public view returns (bool){
        return _minted[msg.sender];
    }

    function addWhitelist(address addr, bool val) public onlyOwner {
        whitelisted[addr] = val;
    }

    function setWhitelistOnly(bool val) public onlyOwner {
        whitelistOnly = val;
    }


    function mint(uint8 tier) public payable
    {
        require(mintEnabled, "Mint not started");
        require(!whitelistOnly, "Whitelist only");
        require(!_minted[msg.sender], "Already minted");
        require(tier <= 3, "Invalid tier");
        _minted[msg.sender] = true;

        if (tier == 0) {
            require(goldSupply < goldAvailable, "None available");
            require(msg.value >= goldPrice, "Value too low");
            goldSupply++;
            _mint(msg.sender, 0, 1, "");
        } else if (tier == 1) {
            require(platinumSupply < platinumAvailable, "None available");
            require(msg.value >= platinumPrice, "Value too low");
            platinumSupply++;
            _mint(msg.sender, 1, 1, "");
        } else if (tier == 2) {
            require(diamondSupply < diamondAvailable, "None available");
            require(msg.value >= diamondPrice, "Value too low");
            diamondSupply++;
            _mint(msg.sender, 2, 1, "");
        } else if (tier == 3) {
            require(tripleaSupply < tripleaAvailable, "None available");
            require(msg.value >= tripleaPrice, "Value too low");
            tripleaSupply++;
            _mint(msg.sender, 3, 1, "");
        }
    }

    function setPrice(uint8 tier, uint256 newPrice) public onlyOwner {
        require(newPrice > 0, "Invalid value");
        if (tier == 0) {
            goldPrice = newPrice;
        } else if (tier == 1) {
            platinumPrice = newPrice;
        } else if (tier == 2) {
            diamondPrice = newPrice;
        } else if (tier == 3) {
            tripleaPrice = newPrice;
        }
    }

    function setAvailable(uint8 tier, uint8 newAvailable) public onlyOwner {
        if (tier == 0) {
            require(goldAvailable <= goldMax, "Exceeds max supply");
            goldAvailable = newAvailable;
        } else if (tier == 1) {
            require(platinumAvailable <= platinumMax, "Exceeds max supply");
            platinumAvailable = newAvailable;
        } else if (tier == 2) {
            require(diamondAvailable <= diamondMax, "Exceeds max supply");
            diamondAvailable = newAvailable;
        } else if (tier == 3) {
            require(tripleaAvailable <= tripleaMax, "Exceeds max supply");
            tripleaAvailable = newAvailable;
        }
    }

    function airdrop(uint8 tier, address recieveAddress) public onlyOwner {
        if (tier == 0) {
            goldAvailable++;
            goldSupply++;
            _mint(recieveAddress, 0, 1, "");
        } else if (tier == 1) {
            platinumAvailable++;
            platinumSupply++;
            _mint(recieveAddress, 1, 1, "");
        } else if (tier == 2) {
            diamondAvailable++;
            diamondSupply++;
            _mint(recieveAddress, 2, 1, "");
        } else if (tier == 3) {
            tripleaAvailable++;
            tripleaSupply++;
            _mint(recieveAddress, 3, 1, "");
        }
    }

    function setMintEnabled(bool value) public onlyOwner {
        mintEnabled = value;
        if (value) {
            mintStartDate = block.timestamp + (mintDayPeriod * 1 days);
        }
    }

    function setRefundPeriod(uint256 newDayPeriod) public onlyOwner {
        mintDayPeriod = newDayPeriod;
    }

    function refund(uint8 tier) public payable {
        require(checkBalance(tier) > 0, "Must hold NFT");
        require(block.timestamp < mintStartDate + (mintDayPeriod * 1 days), "Refund period closed");

        if (tier == 0) {
            _burn(msg.sender, tier, 1);
            (bool sent, ) = msg.sender.call{value: (goldPrice * 5) / 10}("");
            require(sent, "Refund error");
        } else if (tier == 1) {
            _burn(msg.sender, tier, 1);
            (bool sent, ) = msg.sender.call{value: (platinumPrice * 5) / 10}("");
            require(sent, "Refund error");
        } else if (tier == 2) {
            _burn(msg.sender, tier, 1);
            (bool sent, ) = msg.sender.call{value: (diamondPrice * 5) / 10}("");
            require(sent, "Refund error");
        } else if (tier == 3) {
            _burn(msg.sender, tier, 1);
            (bool sent, ) = msg.sender.call{value: (tripleaPrice * 5) / 10}("");
            require(sent, "Refund error");
        }
    }

    function externalBurn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }

    function checkBalance(uint8 tier) public view returns (uint256) {
        return IERC1155(address(this)).balanceOf(msg.sender, tier);
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether!");
    }

}