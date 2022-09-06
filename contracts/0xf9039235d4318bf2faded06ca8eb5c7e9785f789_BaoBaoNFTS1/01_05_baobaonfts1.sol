// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import './ERC721A.sol';
import './Ownable.sol';


    // its free Mint  and ERC721A contract (low GAS Fee)
    // 2929 Supply and Max 2 NFT per wallet & per tx
    // REVEAL: After Sold Out 


contract BaoBaoNFTS1 is ERC721A, Ownable {

    string _baseTokenURI;
    mapping(address => uint256) _minted;
    uint public maxSupply = 3000;
    uint public constant RESERVED = 70;
    uint public RESERVED_Minted = 0;
    uint public maxPerTx = 2;
    uint public maxPerWallet = 2;
    bool public isSaleActive = false;

    constructor() ERC721A("BaoBaoNFT S1", "BBNS1") {
    }

    function mint(uint256 quantity) public {
        require(isSaleActive, "Sale is not open");
        require(totalSupply() + quantity <= maxSupply - RESERVED, "All BaoBaoNFT S1 minted");
        require(quantity <= maxPerTx, "Cant mint more than 2 BaoBaoNFT S1 in one tx");
        require(quantity > 0, "Must mint at least one BaoBaoNFT S1");
        require(_minted[msg.sender] < maxPerWallet, "Cant mint more than 2 BaoBaoNFT S1 per wallet");
        _minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function mintReserved(address toaddress, uint256 quantity) external onlyOwner 
    {
        require(RESERVED_Minted + quantity <= RESERVED, "Cant mint more than RESERVED");
        RESERVED_Minted = RESERVED_Minted + quantity;
        _mint(toaddress, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setIsSaleActive(bool _isSaleActive) external onlyOwner{
      isSaleActive = _isSaleActive;
    }
	
	function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    } 
}