// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract CryptoFish is ERC1155, Ownable, ERC1155Burnable {
    
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri = "https://www.muratsayginer.com/nfts/cryptofish/";
    
    uint256 public nftPrice = 500000000000000000 wei; // 0.5 Eth
    uint256 public amountMinted = 0;
	uint256 public amountMintable = 0;
	
    // Mapping from token ID to max mint
    mapping(uint256 => uint256) private _mintedMint;
    mapping(uint256 => uint256) private _maxMint;
    uint256 private maxToken = 29;
    
    constructor()
        ERC1155(_uri)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        _uri = newuri;
    }

    function mint()
        public payable
    {
      require(nftPrice == msg.value, "Ether value sent is incorrect");
      
      uint256[] memory _available = new uint256[](maxToken);
      uint256 len = 0;
      for (uint256 i=0; i < maxToken; i++) {  //for loop example
         if(_mintedMint[i] < _maxMint[i]) {
             _available[len] = i;
             len++;
         }
      }
    
      require(len > 0, "ERC1155: No fish available to mint.");
      
      uint256 id = _available[_getRandom() % len];
      _mint(msg.sender, id, 1, "");
      _mintedMint[id] += 1;
	  amountMinted += 1;
    }

    function mintOwner(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
        _mintedMint[id] += amount;
        amountMinted += amount;
        
        if(_mintedMint[id] > _maxMint[id]) {
            amountMintable += _mintedMint[id] - _maxMint[id];
            _maxMint[id] = _mintedMint[id];
        }
    }

    function mintOwnerBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            mintOwner(to, ids[i], amounts[i], data);
        }
    }
    
    function getPrice() public view returns (uint256 price) {
        return nftPrice;
    }
    
    function getAmountMinted(uint256 id) public view returns (uint256 amount) {
        return _mintedMint[id];
    }
    
    function setTokenSettingsOwner(uint256 minid, uint256 maxid, uint256 maxAmount)
        public
        onlyOwner
    {
        for (uint256 id = minid; id <= maxid; id++) {
            amountMintable += maxAmount; 
            amountMintable -= _maxMint[id];
            _maxMint[id] = maxAmount;
        }
    }
    
    function setSettingsOwner(uint256 max, uint256 price)
        public
        onlyOwner
    {
        maxToken = max;
        nftPrice = price;
    }
    
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), "{id}/metadata.json"));
    }
    
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, 'Insufficient balance');
        payable(msg.sender).transfer(amount);
    }
    
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_uri, "metadata.json"));
    }
    
    /* Internal functions */
    function _getRandom() internal view returns (uint256) {
       return uint256(blockhash(block.number - 1));
    }
}