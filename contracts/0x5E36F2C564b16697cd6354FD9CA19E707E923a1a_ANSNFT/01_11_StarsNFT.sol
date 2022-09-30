// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// implements the ERC721 standard
import 'tiny-erc721/contracts/TinyERC721.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ANSNFT is TinyERC721 {
    using SafeMath for uint256;
    
    string private baseURI = "https://api.artnstars.com/token/";
    
    uint256 private MAX_STARS = 10000;
    uint256 starPrice = 0.01 ether;
    bool private saleActive = true;

    address payable private _owner;
    address payable private _manager;

    constructor(address manager) TinyERC721("ANS", "ANS", MAX_STARS) {
        _owner = payable(msg.sender);
        _manager =  payable(manager);
    }

    function buy(uint256 starsQty) external payable {
        require(saleActive == true, "Sales are currently close");
        require(totalSupply() < MAX_STARS, "Sold Out");
        require(starsQty > 0, "Qty cannot be 0");
        require(starsQty <= 100, "You may not buy more than 100 items at once");
        require(totalSupply().add(starsQty) <= MAX_STARS, "Sale exceeds available items");
        uint256 salePrice = starPrice.mul(starsQty);
        require(msg.value >= salePrice, "Insufficient Amount");

       _mint(msg.sender, starsQty);
       
        _manager.transfer(msg.value);

    }

    function initialMint(address receiver, uint256 starsQty) external {
        require(msg.sender == _owner, "Only the owner can mint");
        _mint(receiver, starsQty);
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external {
        require(msg.sender == _owner, "Only the owner can set the base URI");
        baseURI = baseURI_;
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function toogleSale() public {
        require(msg.sender == _owner, "Only the owner can toggle the sale");

        saleActive = !saleActive;
    }

    function statusSale() public view returns (bool status){
       return (saleActive);
    }

}