//SPDX-License-Identifier: MIT
// @title LarvaNuts contract
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LarvaNuts is ERC721A, Ownable {
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 newTokenId;
    bool public isPublicMintEnabled;
    string public baseURI;
    address payable public withdrawWallet;
    uint256 ownerMintedCount;
    mapping(address => uint256) public walletMints;

    constructor(string memory initBaseURI) payable ERC721A("LarvaNuts", "LN") {
        mintPrice = 0.00 ether;
        maxSupply = 5555;
        maxPerWallet = 5;
        setBaseURI(initBaseURI);
        // set withdraw wallet address
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function setBaseURI(string memory newBaseURI_) public onlyOwner {
        baseURI = newBaseURI_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "Token does not exists!");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId_)));
    }


    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

modifier mintCompliance(uint256 quantity_) {
    require(quantity_ > 0 && quantity_ <= maxPerWallet, 'Invalid mint amount!');
    require(totalSupply() + quantity_ <= maxSupply, 'Max supply exceeded!');
    _;
  }

modifier mintPriceCompliance(uint256 quantity_) {
        require(msg.value >= mintPrice * quantity_, 'Insufficient funds!');
     _;
    }

function mint(uint256 quantity_) public payable mintCompliance(quantity_) mintPriceCompliance(quantity_) {
        require(isPublicMintEnabled, "minting not enabled");
        ownerMintedCount = walletMints[msg.sender];

            _safeMint(msg.sender, quantity_);
        }

function premint(uint256 quantity_) public payable onlyOwner {

            _safeMint(msg.sender, quantity_);
        }

function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }


  //only owner

    function setMaxPerWallet(uint256 _limit) public onlyOwner {
        maxPerWallet = _limit;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
    mintPrice = _newMintPrice;
  }

  function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    maxSupply = _newMaxSupply;
  }

}