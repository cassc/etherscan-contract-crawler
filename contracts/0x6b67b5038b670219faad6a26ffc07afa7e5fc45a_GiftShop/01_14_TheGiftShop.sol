// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract GiftShop is ERC1155,ERC1155Holder, Ownable {
    constructor() ERC1155("") {}

    uint256 public TOTAL_MINTED = 0;
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    string public name = "Gold Panda Club Gift Shop";
    mapping(uint256 => string) public _uris;
    string contractMetadata = "https://giftshop.goldpandaclub.com/gift_contractMetadata.json";
    mapping(uint256 => uint256) public prices;
    mapping(uint256 => uint256) public supply;
    address mmContract;
    uint256 itemsAddedCount;
    mapping(uint256=> uint256) tokensMinted;

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_uris[tokenId]);
    }

    function contractURI() public view returns (string memory) {
        return contractMetadata;
    }

    function setURI(uint256 tokenId,string memory uri) external onlyOwner{
        _uris[tokenId] = uri;
    }

    function setMMContract(address _contract) external onlyOwner {
        mmContract = _contract;
    }

    function setContractMetadataURI(string memory url) external onlyOwner {
        contractMetadata = url;
    }

    function getPrices(uint256 token_id) public view returns (uint256) {
        return prices[token_id];
    }

    function getSupply(uint256 token_id) public view returns (uint256) {
        return supply[token_id];
    }

    function getMintedQuantity(uint256 token_id) public view returns (uint256) {
        return tokensMinted[token_id];
    }
  
    function getRemainingBalance(uint256 token_id) public view  returns (uint256) {
        return balanceOf(address(this), token_id);
    }


    function mint(
        uint256[] memory token_ids,
        uint256[] memory quantities,
        address sender
    ) public {
        require(msg.sender == mmContract, "Please use the website to mint");

        for(uint256 i =0; i < token_ids.length; i++){
            uint256 token_id = token_ids[i];
            uint256 quantity = quantities[i];
            _mint(sender, token_id, quantity, "");
            
            if(tokensMinted[token_id] == 0){
                TOTAL_MINTED = TOTAL_MINTED + 1; //for OS. newly minted item
            }

            tokensMinted[token_id] += quantity;
        }
    }


    function addItemToShopBulk(
        string[] memory uris,
        uint256[] memory costs,
        uint256[] memory quantities
    ) public onlyOwner {

        for(uint256 i = 0; i < uris.length; i++){

            uint256 quantity = quantities[i];
            uint256 cost = costs[i];
            string memory uri = uris[i];

            uint256 token_id = itemsAddedCount +1;

            _uris[token_id] = uri;
            prices[token_id] = cost;
            supply[token_id] = quantity;
            itemsAddedCount++;

        }
      
    }

  

    function updateItemPrice(uint256 token_id, uint256 cost) public onlyOwner {
        prices[token_id] = cost;
    }

    function updateItemSupply(uint256 token_id, uint256 quantityToAdd)
        public
        onlyOwner
    {
        supply[token_id] += quantityToAdd;
    }

    function withdrawEth() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}