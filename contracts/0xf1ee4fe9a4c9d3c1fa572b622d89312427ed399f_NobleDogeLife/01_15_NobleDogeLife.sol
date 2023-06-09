//SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NobleDogeLife is ERC721, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Public Sell Mint
    event SellMint(uint indexed nums, address indexed minter);

    uint256 public tokenPrice = 30000000000000000;  //0.03 ETH

    uint256 public constant MAX_DOGES = 10000;//Max Size
    uint256 public constant PRE_DOGES = 1000;//For Dogecoin Mint
    uint256 public constant MAX_COMM_MINTS = 50;//AirDrop Community
    uint256 public constant MAX_SALE_MINTS = MAX_DOGES - MAX_COMM_MINTS - PRE_DOGES;

    uint256 public commMintedNum = 0;
    uint256 public saleMintedNum = 0;

    uint public maxBuy = 20;
    uint public totalBuy = 200;

    bool public publicSale = false;
    bool public preSale = false;

    //Nobel Doge
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    //withdraw this.blance to Owner
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    //Frozen public sale
    function flipPublicSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function flipPreSale() public onlyOwner {
        preSale = !preSale;
    }

    function setMaxBuy(uint nums) public onlyOwner {
        require(nums > 0, "nums should large then 0.");
        maxBuy = nums;
    }

    function setTotalBuy(uint nums) public onlyOwner {
        require(nums > 0, "nums should large then 0.");
        require(nums > maxBuy, "nums should large then maxBuy.");
        totalBuy = nums;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    //Eth go da the moon
    function changePrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    //Normal mint
    function mint(uint nums) external payable {
        require(publicSale, "Sale not started.");
        require(nums > 0, "nums should large then 0.");
        require(nums <= maxBuy, "reach max sell limit.");
        require(saleMintedNum.add(nums) <= MAX_SALE_MINTS, "Sale mint limit reached.");
        require(totalSupply() < MAX_DOGES, "DOGES sold out.");

        uint salePrice = getPrice().mul(nums);
        require(msg.value >= salePrice, "not enough funds to purchase.");

        for (uint i = 0; i < nums; i++) {
            uint id = nextIndex();
            if (id < MAX_DOGES) {
                _safeMint(msg.sender, id);
            }
        }
        saleMintedNum = saleMintedNum.add(nums);

        emit SellMint(nums, msg.sender);
    }

    //dogeMint
    function dogeMint(uint nums, address recipient) public onlyOwner {
        require(totalSupply().add(nums) <= MAX_DOGES, "not enough doge left.");

        for (uint i = 0; i < nums; i++) {
            uint id = nextIndex();
            if (id < MAX_DOGES) {
                _safeMint(recipient, id);
            }
        }
    }

    //Community Mint For airDrop
    function mintToGroup(uint nums, address commAddr) public onlyOwner {
        require(commMintedNum.add(nums) <= MAX_COMM_MINTS, "Community Mint limit reached.");
        require(totalSupply() < MAX_DOGES, "DOGES sold out.");

        for (uint i = 0; i < nums; i++) {
            uint id = nextIndex();
            if (id < MAX_DOGES) {
                _safeMint(commAddr, id);
                commMintedNum = commMintedNum.add(1);
            }
        }
    }
    //Presale  For ETH(Not Use)
    function presale(uint nums) external payable {
        require(preSale, "Sale not started.");
        require(msg.sender != address(0));
        require(nums > 0, "Nums should large then 0.");
        require(nums <= maxBuy, "Reach max sell limit.");
        require(saleMintedNum.add(nums) <= MAX_SALE_MINTS, "Sale mint limit reached.");
        require(totalSupply() < MAX_DOGES, "DOGES sold out.");

        uint256 hdwNums = balanceOf(msg.sender);
        require(hdwNums.add(nums) <= totalBuy, "Reach max totalBuy limit.");

        uint salePrice = getPrice().mul(nums);
        require(msg.value >= salePrice, "not enough funds to purchase.");

        for (uint i = 0; i < nums; i++) {
            uint id = nextIndex();
            if (id < MAX_DOGES) {
                _safeMint(msg.sender, id);
            }
        }
        saleMintedNum = saleMintedNum.add(nums);
    }

    //Get next number
    function nextIndex() internal view returns (uint) {
        return totalSupply();
    }
    //Get price
    function getPrice() public view returns (uint) {
        return tokenPrice;
    }
}