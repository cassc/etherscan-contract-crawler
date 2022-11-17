// SPDX-License-Identifier: MIT   
pragma solidity ^0.8.17; 

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WhathappenedDickButtClub is ERC721A, Ownable {

    using Strings for uint256;

    string public baseURI = "ipfs://bafybeiftlmavwwctiqgkxyirv2alfpnjykxhghzeudtj75kloi4qidpkmq/";

    uint256 public price = 0.002 ether;
    uint256 public maxPerTx = 20;
    uint256 public maxSupply = 2222;
    uint256 public maxFreePerWallet = 1;
    uint256 public totalFreeMinted = 0;
    uint256 public maxFreeSupply = 1000;
    bool public reserved;

    mapping(address => uint256) public _mintedFreeAmount;

    constructor() ERC721A("What H A P P E N E D Dick Butt Club", "WHDBC") {}

    function mint(uint256 _amount) public payable {
        require(msg.value >= _amount * price, "Incorrect amount of ETH.");
        require(totalSupply() + _amount <= maxSupply, "Sold out.");
        require(_amount <= maxPerTx, "You may only mint a max of 20 per transaction");
        _mint(msg.sender, _amount);
    }

    function mintFree(uint256 _amount) public payable {
        require(_mintedFreeAmount[msg.sender] + _amount <= maxFreePerWallet, "You have minted max free amount allowed per wallet");
        require(totalFreeMinted + _amount <= maxFreeSupply, "Free supply exceeded." );
        require(totalSupply() + _amount <= maxSupply, "Sold out.");

        _mintedFreeAmount[msg.sender]++;
        totalFreeMinted++;
        _safeMint(msg.sender, _amount);
    }

 function  Airdrop(uint8 _amountPerAddress, address[] calldata addresses) external onlyOwner {
     uint16 totalSupply = uint16(totalSupply());
     uint totalAmount =   _amountPerAddress * addresses.length;
    require(totalSupply + totalAmount <= maxSupply, "Exceeds max supply.");
     for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], _amountPerAddress);
        }

     delete _amountPerAddress;
     delete totalSupply;
  }

    function tokenURI(uint256 tokenId)
        public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTx = _amount;
    }

    function setmaxFreeSupply(uint256 _newMaxFreeSupply) public onlyOwner {
        require(_newMaxFreeSupply <= maxSupply);
        maxFreeSupply = _newMaxFreeSupply;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}