// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";

/// @author tempest-sol<[email protected]>
contract Curiosities is Ownable, ERC721AQueryable {

    enum SaleType { STAGING, PUBLIC, CONCLUDED }

    SaleType public currentSale;

    uint256 public immutable maxSupply;
    uint256 public immutable reserveCount;
    uint256 public reservesMinted;

    uint256 public cost;
    uint256 public maxMintTx;

      ///////////////////
     ////   Events   ///
    ///////////////////
    event SaleTypeChanged(SaleType indexed saleType);
    event MintCostChanged(uint256 indexed cost);

    //!!!!!!!!!!!!!!!!!!!!!!!!! 
    // SET URI
    //!!!!!!!!!!!!!!!!!!!!!!!!!

    string public uri;

    constructor() ERC721A("Curiosities", "CURIOUS") {
        maxSupply = 5000;
        reserveCount = 150;
        cost = 0.04 ether;
        maxMintTx = 5;
    }

    function updateUri(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    function setSaleType(SaleType sale) external onlyOwner {
        require(currentSale != sale, "sale_already_set");
        currentSale = sale;
        emit SaleTypeChanged(sale);
    }

    function updateSalePrice(uint256 amount) external onlyOwner {
        require(cost != amount, "amount_already_set");
        cost = amount;
        emit MintCostChanged(amount);
    }

    function mint(uint256 amount) external canMint(amount) payable {
        uint256 totalCost = cost * amount;
        require(msg.value == totalCost, "invalid_eth_value");
        uint256 total = totalSupply() + amount;
        if(total == maxSupply || total == maxSupply - reserveCount) {
            currentSale = SaleType.CONCLUDED;
            emit SaleTypeChanged(currentSale);
        }
        _safeMint(msg.sender, amount);
    }

    function mintFreeFor(address[] calldata addresses, uint256 amount) external onlyOwner {
        require(totalSupply() + (addresses.length * amount) <= maxSupply - reserveCount, "max_mint_exceeded");
        address nullAddr = address(0x0);
        address addr;
        for(uint256 i=0;i<addresses.length;++i) {
            addr = addresses[i];
            require(addr != nullAddr, "address_invalid");
            _safeMint(addr, amount);
        }
        uint256 total = totalSupply();
        if(total == maxSupply || total == maxSupply - reserveCount) {
            currentSale = SaleType.CONCLUDED;
            emit SaleTypeChanged(currentSale);
        }
    }

    function mintReservedFor(address to, uint256 quantity) external onlyOwner {
        require(reservesMinted + quantity <= reserveCount, "exceeds_reserves");
        reservesMinted += quantity;
        _safeMint(to, quantity);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

     function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier canMint(uint256 amount) {
        require(amount <= maxMintTx, "exceeds_mint_allowance");
        require(currentSale > SaleType.STAGING, "sale_inactive");
        require(currentSale != SaleType.CONCLUDED, "sale_concluded");
        require(totalSupply() + amount <= maxSupply - reserveCount, "exceeds_max_supply");
        _;  
    }

    receive() external payable {}

}