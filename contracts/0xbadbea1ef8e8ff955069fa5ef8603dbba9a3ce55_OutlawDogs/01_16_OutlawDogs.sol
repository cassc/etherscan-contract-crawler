// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "hardhat/console.sol";

/**
 * @title OutlawDogs
 * OutlawDogs - The DODGE CITY OUTLAW DOGS are an NFT, members only outlaw gang..
 */
contract OutlawDogs is ERC721, Ownable {
    using SafeMath for uint256;

    string public OGD_PROVENANCE = "";

    uint256 public constant MAX_DOGS = 10000;

    uint256 public dogPrice = 70000000000000000; //0.07 ETH

    uint256 public maxBreeding = 50;

    bool public saleIsActive = false;

    // Dogs reserved for team and community / giveaways / awards
    uint public dogReserveCount = 400;

    bool public whitelistOnly = true;

    mapping(address => bool) whitelist;

    constructor(string memory baseURI)
        ERC721("Outlaw Dogs", "OGD")
    {
      _setBaseURI(baseURI);
    }

    /*
    * Set NFT Base URI
    */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * send ETH from contract to owner
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        _msgSender().transfer(balance);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Flip between whitelisting only sale
    */
    function flipWhitelistOnlyState() public onlyOwner {
        whitelistOnly = !whitelistOnly;
    }

    /**
    * Breeds Dogs
    */
    function breed(uint dogs) public payable {
        uint256 supply = totalSupply();

        require(saleIsActive,                     "Sale paused");

        if(whitelistOnly) {
          require(isWhitelisted(),                "Wallet is not on the whitelist ");
          require(_maxDogCountReached(msg.sender, dogs),"Max dogs per wallet during whitelist phase reached");
        }

        require(dogs <= maxBreeding,              "Max 50 dogs at a time");
        require(supply.add(dogs) <= MAX_DOGS,     "Sold out");
        require(dogPrice.mul(dogs) <= msg.value,  "Not enough Ether sent");

        for(uint256 i = 0; i < dogs; i++) {
          _safeMint(msg.sender, supply + i);
        }
    }

    function reserveDogs(address to, uint256 nrOfDogs) public onlyOwner {
        uint supply = totalSupply();

        require(nrOfDogs > 0 && nrOfDogs <= dogReserveCount, "Not enough reserve left");

        for (uint i = 0; i < nrOfDogs; i++) {
            _safeMint(to, supply + i);
        }
        dogReserveCount = dogReserveCount.sub(nrOfDogs);
    }

    /**
    * Whitelist an address
    */
    function whitelistAddress(address participant) public onlyOwner {
        whitelist[participant] = true;
    }

    /**
    * Whitelist multiple addresses
    */
    function whitelistAddresses(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
          whitelist[addresses[i]] = true;
        }
    }

    /**
    * Check if whitelisted
    */
    function isWhitelisted() public view returns (bool) {
        return whitelist[msg.sender];
    }

    /**
    * Check if whitelisted
    */
    function addressWhitelisted(address addr) public view onlyOwner returns (bool) {
        return whitelist[addr];
    }

    /**
    * Check max dog reached for address
    */
    function _maxDogCountReached(address addr, uint256 dogs) internal virtual view returns (bool) {
        uint256 balance = balanceOf(addr);
        return (balance.add(dogs) <= maxBreeding);
    }

    /**
    * Set price in eth
    */
    function updatePrice(uint256 price) public onlyOwner {
        dogPrice = price;
    }
}