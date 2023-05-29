// SPDX-License-Identifier: MIT
/*
                        _              __ _          _ _               __ _____
  /\/\   ___  _ __  ___| |_ ___ _ __  / _\ |__   ___| | |_ ___ _ __   / // __\ \
 /    \ / _ \| '_ \/ __| __/ _ \ '__| \ \| '_ \ / _ \ | __/ _ \ '__| | |/ /   | |
/ /\/\ \ (_) | | | \__ \ ||  __/ |    _\ \ | | |  __/ | ||  __/ |    | / /___ | |
\/    \/\___/|_| |_|___/\__\___|_|    \__/_| |_|\___|_|\__\___|_|    | \____/ | |
                                                                      \_\    /_/
*/


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonsterShelter is ERC721, Ownable {
    using Strings for uint256;

    //metadata
    string baseURI;

    //sales
    uint256 public cost = 0.04 ether;
    uint256 public preSaleCost = 0.035 ether;
    uint256 public allowListCost = 0.03 ether;

    uint256 public presaleSupply = 300;
    uint256 public reservedSupply = 155;
    uint256 public maxSupply = 5555;
    uint256 public totalSupply;
    uint256 public maxMintsPerTransaction = 10;

    uint256 public saleStartTimestamp;
    uint256 public preSaleStartTimestamp = 1637791200;
    uint256 public earlyAccess = 900;

    mapping(address => bool) public allowList;

    constructor(string memory _initBaseURI) ERC721("MonsterShelter", "MNSTRS") {
        setBaseURI(_initBaseURI);
    }

    // metadata region
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    //endregion


    //setters and getters for sales region
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPreSaleCost(uint256 _newPreSaleCost) public onlyOwner {
        preSaleCost = _newPreSaleCost;
    }

    function setAllowListCost(uint256 _newAllowListCost) public onlyOwner {
        allowListCost = _newAllowListCost;
    }

    function getCurrentCost(address sender) public view returns (uint256) {
        uint256 currentCost = cost;
        if (allowList[sender]) {
            currentCost = allowListCost;
        } else if (getSaleState(sender) == 1) {
            currentCost = preSaleCost;
        }
        return currentCost;
    }

    function configurePresale(uint256 _presaleSupply, uint256 _reservedSupply, uint256 _preSaleStartTimestamp) public onlyOwner {
        presaleSupply = _presaleSupply;
        reservedSupply = _reservedSupply;
        preSaleStartTimestamp = _preSaleStartTimestamp;
    }

    function configureSale(uint256 _maxMintsPerTransaction, uint256 _saleStartTimestamp) external onlyOwner {
        maxMintsPerTransaction = _maxMintsPerTransaction;
        saleStartTimestamp = _saleStartTimestamp;
    }

    function getSaleState(address sender) public view returns (uint256) {
        // returns 2 for main sale and 1 for pre-sale, 0 if sale is not started yet
        bool _isAllowListed = allowList[sender];
        uint256 currentTimestamp = block.timestamp;
        if (_isAllowListed) {
            currentTimestamp = block.timestamp + earlyAccess;
        }
        bool _isSaleActive = saleStartTimestamp > 0 && currentTimestamp >= saleStartTimestamp;
        if (_isSaleActive) {
            return 2;
        } else if (preSaleStartTimestamp > 0 && currentTimestamp >= preSaleStartTimestamp) {
            return 1;
        } else {
            return 0;
        }
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMaxMintsPerTransaction(uint256 _newmaxMintsPerTransaction) public onlyOwner {
        maxMintsPerTransaction = _newmaxMintsPerTransaction;
    }

    function setPreSaleStartTimestamp(uint256 _preSaleStartTimestamp) external onlyOwner {
        preSaleStartTimestamp = _preSaleStartTimestamp;
    }

    function setSaleStartTimestamp(uint256 _saleStartTimestamp) external onlyOwner {
        saleStartTimestamp = _saleStartTimestamp;
    }

    function setEarlyAccess(uint _newEarlyAccess) public onlyOwner {
        earlyAccess = _newEarlyAccess;
    }

    function setAllowList(address[] memory _allowList) external onlyOwner {
        for (uint256 i = 0; i < _allowList.length; i++) {
            allowList[_allowList[i]] = true;
        }
    }
    //endregion


    //mint and airdrop region
    function mint(uint256 _mintAmount) public payable {
        uint256 saleState = getSaleState(msg.sender);
        uint256 currentCost = getCurrentCost(msg.sender);

        require(saleState == 1 || saleState == 2, "Minting is not available.");
        require(_mintAmount > 0, "Can't mint less than 1.");
        require(_mintAmount <= maxMintsPerTransaction, "Can't mint more than maxMintsPerTransaction.");
        require(currentCost * _mintAmount == msg.value, "Incorrect Ether value.");

        if (saleState == 1) {
            require(_mintAmount <= presaleSupply, "Presale supply is out.");
            presaleSupply -= _mintAmount;
        }

        mintNFTs(msg.sender, _mintAmount);
    }

    modifier maxSupplyCheck(uint256 amount)  {
        require(totalSupply + reservedSupply + amount <= maxSupply, "Tokens supply reached limit.");
        _;
    }

    function mintNFTs(address to, uint256 amount) internal maxSupplyCheck(amount) {
        uint256 fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint256 i = 0; i < amount; i++) {
            _mint(to, fromToken + i);
        }
    }

    function airdrop(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            mintNFTs(addresses[i], amounts[i]);
        }
    }
    //endregion

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(0xc542c59Ea7744750A6E766615274FEf304A2f6E1).transfer(balance * 25 / 100); 
        payable(0xa6fdAd3634bcA54Bb7EAB0195fD158C6e7530d54).transfer(balance * 25 / 100); 
        payable(0xaB0D10bb4A32ccccdEdf1978060BA755249881cE).transfer(balance * 25 / 100);
        payable(0x2E8D42eeC83E5e9dFC3DF007F8CE890197a1d461).transfer(balance * 8 / 100); 
        payable(0xBbe165910bEBc144B8Ca754321aB44e910d1d771).transfer(balance * 17 / 100);
    }
}