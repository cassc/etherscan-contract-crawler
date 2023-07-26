// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract KaraApe is ERC721A, Ownable {
    string  public baseURI;
    uint256 public supplyKaraApe;
    uint256 public freeKaraApe;
    uint256 public maxPerTxn = 101;
    uint256 public price   = 0.03 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("KaraApe", "KaraAPE", 100) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
        require(totalSupply() + count < supplyKaraApe, "Excedes max supply.");
        require(totalSupply() + 1  > freeKaraApe, "Public sale is not live yet.");
        require(count < maxPerTxn, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price == msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
    }

    function freeMint() public payable {
        require(totalSupply() + 1 <= freeKaraApe, "Not in free mint state");
        require(!walletCount[msg.sender], " 1 free mint per wallet");
         _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
    }

    function airdrop() external onlyOwner {
            _safeMint(_msgSender(), 10);
    }
      
    function setSupply(uint256 _newSupplyKaraApe) public onlyOwner {
        supplyKaraApe = _newSupplyKaraApe;
    }

    function setfreeKaraApe(uint256 _newfreeKaraApe) public onlyOwner {
        freeKaraApe = _newfreeKaraApe;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMax(uint256 _newMax) public onlyOwner {
        maxPerTxn = _newMax;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}