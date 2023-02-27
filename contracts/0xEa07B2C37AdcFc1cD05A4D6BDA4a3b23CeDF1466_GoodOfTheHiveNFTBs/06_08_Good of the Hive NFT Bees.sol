// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GoodOfTheHiveNFTBs is ERC721A, Ownable, ReentrancyGuard {

    uint256 public price = 50000000000000000;
    uint256 public maxSupply = 1000;
    string public baseURI = "ipfs://Qmb7UL1FhdBvKNKKGsCknLYQpvr6eB3LufcVTgxcgj6FFU/";
    bool public saleActive = false;

    mapping(uint256 => string) private _URIS;



    constructor() ERC721A("Good of the Hive NFT Bees", "NFTB") {
    }

    //Public Functions

    function publicMint(uint256 quantity) external payable nonReentrant {
        uint256 _maxSupply = maxSupply;

        require (saleActive, "Sale is not active");
        require(totalSupply() + quantity <= _maxSupply, "Sold Out");
        require(msg.value >= (price * quantity), "Not Enough Ether Sent");

        _safeMint(msg.sender, quantity);
        

    }

    //Only Owner Functions

    function batchGiftMint(address[] memory _addresses, uint256 quantity) external onlyOwner {
        uint256 _maxSupply = maxSupply;
        uint256 totalQuantity = quantity * _addresses.length;
        uint256 totalSupply = totalSupply();

        require(totalQuantity + totalSupply <= _maxSupply, "Not Enough Bees Left :(");
        for(uint256 i = 0; i < _addresses.length; i++){
            _safeMint(_addresses[i], quantity);
        }
    }

    function isSaleActive(bool isActive) external onlyOwner {
        saleActive = isActive;
    }

    function editSalePrice(uint256 _newPriceInWei) external onlyOwner{
        price = _newPriceInWei;
    }

    function setTokenURI(string memory _newURI) external onlyOwner {
         baseURI = _newURI;
    }

    function withdraw(address payable _to) public onlyOwner {
        require(_to != address(0), "Token cannot be zero address.");
        _to.transfer(address(this).balance);
    }


    // // metadata URI

    function uri(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        if (bytes(_URIS[_tokenId]).length != 0) {
            return string(_URIS[_tokenId]);
        }
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }


    function contractURI() public pure returns (string memory) {
        return "ipfs://QmTz443G5BMT9wSgSZJFG8bVkp4VUQVXXbSyP7cgsN5YSM";
    }

    function _startTokenId() internal view override returns (uint256) {
   return 1;
    }



    fallback() external payable {}

    receive() external payable {}

}