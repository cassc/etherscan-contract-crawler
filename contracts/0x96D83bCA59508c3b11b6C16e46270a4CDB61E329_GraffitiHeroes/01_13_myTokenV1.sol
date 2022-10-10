// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract GraffitiHeroes is Ownable, ERC721A, ReentrancyGuard {
    using Address for address;
    uint256 startSale;
    uint256 constant whiteListFee = 0.05 ether;
    uint256 publicFee = 0.069 ether;
    mapping(address => bool) public whitelisted;
    
    bool saleEnabled;

    mapping(address => uint256) nftCounter;

    event enabled(bool saleEnabled);
    

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  
  ) ERC721A("Graffiti Heroes", "GH", maxBatchSize_, collectionSize_) {
    // maxMint = maxBatchSize_;
  }
    function enableSale() external onlyOwner {
        require(!saleEnabled, "Sale is already enabled");
        startSale = block.timestamp;
        saleEnabled = true;
        emit enabled(saleEnabled);
    }

    /**
     * Add contract addresses to the whitelist
     */

    function addToWhitelist(address _user) public onlyOwner {
        require(!whitelisted[_user], "already whitelisted");
        whitelisted[_user] = true;
    } 

    function addAddressesToWhitelist(address[] memory _userAddresses) public onlyOwner {
        for(uint256 i = 0; i < _userAddresses.length; i++){
            addToWhitelist(_userAddresses[i]);
        }
    }
    
    function checkWhitelist(address _user) public view returns(bool)  {
        return whitelisted[_user];
    }
    
    /**
     * Remove a contract addresses from the whitelist
     */

    function removeFromWhitelist(address _user) public onlyOwner {
        require(whitelisted[_user], "user not in whitelist");
        whitelisted[_user] = false;
    }

    function batchRemoveFromWhitelist(address[] memory _userAddresses) public onlyOwner {
        for(uint256 i = 0; i < _userAddresses.length; i++){
            removeFromWhitelist(_userAddresses[i]);
        }
    }

    function teamMint(uint quantity) public onlyOwner {
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(
            nftCounter[msg.sender] +quantity <= 100,
            "More than 100 NFTs cannot be minted"
        );
        nftCounter[msg.sender]+= quantity;
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address _userAddress, uint quantity) public onlyOwner {
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        _safeMint(_userAddress, quantity);
    }

    function mint(uint quantity) public
        payable {
        require(saleEnabled, "Sale isn't started yet");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(nftCounter[msg.sender] +quantity <= 10,"Wallet limit reached");
        if (startSale < block.timestamp && startSale + 86400 > block.timestamp) {
            require(whitelisted[msg.sender], "not eligible for whiteList mint");
            require(msg.value == whiteListFee * quantity, "amount not Sufficient to mint during whitelist");
            
        }
        else {
            require(msg.value == publicFee * quantity, "amount not Sufficient to mint");
        }
        nftCounter[msg.sender]+= quantity;
        _safeMint(msg.sender, quantity);
    }

    function cfee(uint256 numb) public view returns (uint256) {
        return numb * publicFee;
    }

    function setFee(uint256 _newfee) external onlyOwner {
        publicFee = _newfee;
    }

   

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}