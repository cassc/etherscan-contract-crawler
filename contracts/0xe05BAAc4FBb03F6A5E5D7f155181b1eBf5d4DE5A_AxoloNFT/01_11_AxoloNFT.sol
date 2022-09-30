// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// implements the ERC721 standard
import "tiny-erc721/contracts/TinyERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AxoloNFT is TinyERC721{
    using SafeMath for uint256;
    
    string private baseURI = "https://api.axolo.art/token/";

    uint256 private MAX_AXOLOS = 10000;
    uint256 axoloPrice = 0.01 ether;
    bool private saleActive = true;

    address payable private _owner;
    address payable private _manager;

    constructor(address manager) TinyERC721("AXL", "AXL", MAX_AXOLOS) {
        _owner = payable(msg.sender);
        _manager =  payable(manager);
    }

    function buy(uint256 axolosQty) external payable {
        require(saleActive == true, "Sales are currently close");
        require(totalSupply() < MAX_AXOLOS, "Sold Out");
        require(axolosQty > 0, "Qty cannot be 0");
        require(axolosQty <= 100, "You may not buy more than 100 items at once");
        require(totalSupply().add(axolosQty) <= MAX_AXOLOS, "Sale exceeds available items");
        uint256 salePrice = axoloPrice.mul(axolosQty);
        require(msg.value >= salePrice, "Insufficient Amount");

        _mint(msg.sender, axolosQty);
       
        _manager.transfer(msg.value);

    }

   function initialMint(address receiver, uint256 axolosQty) external {
        require(msg.sender == _owner, "Only the owner can mint");
        _mint(receiver, axolosQty);
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