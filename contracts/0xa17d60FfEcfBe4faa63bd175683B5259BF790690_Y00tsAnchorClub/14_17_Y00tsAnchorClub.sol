// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Context.sol';
//import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
//import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../contracts/ceshi.sol';


interface Iy00tsYachtClub {
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
	function balanceOf(address owner) external view returns (uint256 balance);
}

  contract Y00tsAnchorClub is DefaultOperatorFilterer, ERC721A, Ownable, ReentrancyGuard {

    string public baseURI = "ipfs://QmV4tyZkayrt11PYYMAKdLa3RuJ9U7o6tUfPxixy9ZfT1f/";
    string public uriSuffix = '.json';

    
    uint256 public cost = 0;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTx = 400;

    bool public paused = false;
    bool public revealed = true;
    bool public mintToCommunityWalletEnabled = true;
    bool public mintComm = true;

    address private oldFounder;

    mapping(address => mapping(uint256 => bool)) public owners;
    mapping(uint256 => address) public tokenOwners;

    Iy00tsYachtClub oldContract;
    address communityWallet = address(0x9c3Ce8721a275C9C1e14aBEfdCC16d973FCA3c21);

    mapping(address => uint256) public addressMintedCount;

    constructor(address _oldContract, address _oldFounder) ERC721A("y00ts Anchor Club", "YAC") {
      oldContract = Iy00tsYachtClub(_oldContract); 
      oldFounder = _oldFounder;
      uint256[] memory communityNFTs = new uint256[](2);
      communityNFTs[0] = 1074;
      communityNFTs[1] = 8951;        

      for (uint256 i = 0; i < 2; i++) {
        totalMintedSupply++;				
        currentIndex = communityNFTs[i];
        owners[communityWallet][currentIndex] = true;
        tokenOwners[currentIndex] = communityWallet;
        _safeMint(communityWallet, 1);
      } 
    }

    function _getNextUnusedID(address _owner, uint256[] memory _ownedTokens) internal view returns (uint256 index) {

    for (uint256 i = 0; i < _ownedTokens.length; i++) {
      index = _ownedTokens[i];
      if (owners[_owner][index]) {
        continue;
      } else {
        return index;
      }
    }
    }

    function getYYCBelongingToOwner(address _owner) public view returns (uint256[] memory) {
      uint256 numYYCs = oldContract.balanceOf(_owner);

      if (numYYCs == 0) {
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](numYYCs);
        for (uint256 i = 0; i < numYYCs; i++) {
          result[i] = oldContract.tokenOfOwnerByIndex(_owner, i);
        }
        return result;
      }
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
          super.setApprovalForAll(operator, approved);
      }

      function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
          super.approve(operator, tokenId);
      }

      function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
          super.transferFrom(from, to, tokenId);
      }

      function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
          super.safeTransferFrom(from, to, tokenId);
      }

      function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
          public
          override
          onlyAllowedOperator(from)
      {
          super.safeTransferFrom(from, to, tokenId, data);
      }

    function mint(uint256 _mintAmount) public payable {
      require(!paused, 'The contract is paused!');
		  require(totalMintedSupply + _mintAmount <= maxSupply, "No more");
		  require(_mintAmount <= maxMintAmountPerTx, "Max per TX reached");
		  require(msg.sender != oldFounder, "You can not mint");

      uint256[] memory ownedTokens = getYYCBelongingToOwner(msg.sender);
      require(totalMintedSupply <= ownedTokens.length - addressMintedCount[msg.sender], "Invalid mint count");

      for (uint256 i = 0; i < _mintAmount; i++) {
        currentIndex = _getNextUnusedID(msg.sender, ownedTokens);
        owners[msg.sender][currentIndex] = true;
        tokenOwners[currentIndex] = msg.sender;
        addressMintedCount[msg.sender]++;
        totalMintedSupply++;
        _safeMint(msg.sender, 1);
        
      }
    }
    

	function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0
			? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId + 1), ".json"))
			: "";
	}

    function setCost(uint256 _cost) public onlyOwner {
      cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
      maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
      uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
      paused = _state;
    }
    function _baseURI() internal view virtual override returns(string memory) {
      return baseURI;
    }

    function setBaseUri(string memory baseuri_) public onlyOwner {
      baseURI = baseuri_;
    }
    function toggleMintToCommunity() external onlyOwner {
      mintToCommunityWalletEnabled = !mintToCommunityWalletEnabled;
    }
    
    function mintToCommunityWallet(uint256 from, uint256 to) external onlyOwner {
      require(mintToCommunityWalletEnabled, "Mint to community wallet is not live yet");
      require(from < to, "Invalid amount");

      for (uint256 i = from; i < to; i++) {
        if(tokenOwners[i] == address(0)) {
          currentIndex = i;
          owners[communityWallet][currentIndex] = true;
          tokenOwners[currentIndex] = communityWallet;
          totalMintedSupply++;
          _safeMint(communityWallet, 1);
        }
      }
    }
}