// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface MetadataProvider {
  function tokenURI(uint256 id) external view returns (string memory);
}

contract BaseURIMetadataProvider is Ownable, MetadataProvider {

  using Strings for uint256;

  string public baseURI;

  constructor(string memory _baseURI) {
    setBaseURI(_baseURI);
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function tokenURI(uint256 id) public override view returns (string memory) {
    return string(abi.encodePacked(baseURI, id.toString()));
  }

}

contract Pinyottas is ERC721Enumerable, Ownable, AccessControlEnumerable {

  bytes32 public constant WHITELIST = keccak256("WHITELIST");

  address public metadataProvider;
  
  uint256 public mintCount = 0;
  uint256 public maxSupply = 25000;

  uint256 public emptyPinyottyMintCount = 0;
  uint256 public maxEmptyPinyottasSupply = 100;

  uint256 public tokenPrice = 0.08 ether;

  // Determines whether minting is available or not
  bool public saleIsActive = true;

  // The number of pinyottas minted containing each type of token
  mapping(address => uint256) public tokenAddressesToMintCounts;
  
  // Map of pinyotta IDs to a map of ERC20 contracts to the number of those kinds of tokens it holds
  mapping(uint256 => mapping(IERC20 => uint256)) public idToTokenBalances;
  mapping(uint256 => mapping(IERC20 => uint256)) public idToOriginalTokenBalances;

  // Map of pinyotta IDs to an array of the contract addresses for tokens inside that pinyotta
  mapping(uint256 => address[]) public idToTokenContracts;

  // Map of IDs of empty pinyottas to its position among all other empty pinyottas.
  // E.g. If Pinyotta 10 was the first empty pinyotta minted, the mapping will include {10: 1}
  mapping(uint256 => uint256) public idToEmptyTokenNumbers;

  // Map of IDs to booleans indicating if they are busted
  mapping(uint256 => bool) public bustedPinyottas;

  event Mint(address minter, uint id);
  event Bust(address minter, uint id);

  constructor() ERC721("Pinyottas", "PINYOTTAS") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControlEnumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setMetadataProvider(address _metadataProvider) public onlyOwner {
    metadataProvider = _metadataProvider;
  }

  function setTokenPrice(uint256 _newTokenPrice) public onlyOwner {
    tokenPrice = _newTokenPrice;
  }
  
  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  // Test that we don't allow duplicates in the whitelisted array
  function addContractsToWhitelist(address[] memory _tokenContracts) public onlyOwner {
    for(uint i = 0; i < _tokenContracts.length; i++) {
      grantRole(WHITELIST, _tokenContracts[i]);
    }
  }

  // Test this method that it removes the correct item and doesn't remove others
  function removeContractsFromWhitelist(address[] memory _tokenContracts) public onlyOwner {
    for(uint i = 0; i < _tokenContracts.length; i++) {
      revokeRole(WHITELIST, _tokenContracts[i]);
    }
  }

  function getWhitelistedErc20Count() public view returns(uint count) {
    return getRoleMemberCount(WHITELIST);
  }

  function getTokenContractsInPinyotta(uint256 _id) public view returns (address[] memory tokenContracts) {
    require(_exists(_id), "Cannot getTokenContractsInPinyotta for nonexistant token");
    return idToTokenContracts[_id];
  }

  function getTokenBalanceInPinyotta(uint256 _id, address _tokenContract) public view returns (uint256 balance) {
    require(_exists(_id), "Cannot getTokenBalanceInPinyotta for nonexistant token");
    return idToTokenBalances[_id][IERC20(_tokenContract)];
  }

  function getOriginalTokenBalanceInPinyotta(uint256 _id, address _tokenContract) public view returns (uint256 balance) {
    require(_exists(_id), "Cannot getOriginalTokenBalanceInPinyotta for nonexistant token");
    return idToOriginalTokenBalances[_id][IERC20(_tokenContract)];
  }

  function getEmptyTokenNumber(uint256 _id) public view returns (uint256 num) {
    require(_exists(_id), "Cannot getEmptyTokenNumber for nonexistant token");
    require(getTokenContractsInPinyotta(_id).length == 0, "Cannot getEmptyTokenNumber for a non-empty token");
    return idToEmptyTokenNumbers[_id];
  }

  // Returns 0 if this is the first time at least one of the tokens in the token list is included in a pinyotta
  function getMintPrice(address[] memory _tokenContracts) public view returns (uint256 price) {
    for(uint i = 0; i < _tokenContracts.length; i++) {
      if(tokenAddressesToMintCounts[_tokenContracts[i]] == 0) {
        return 0;
      }
    }
    return tokenPrice;
  }

  function mint(address[] memory _tokenContracts, uint256[] memory _tokenAmounts) public payable {
    require(saleIsActive, "Sale paused, minting disabled");
    require(mintCount < maxSupply, "Exceeds maximum supply");
    require(msg.value == getMintPrice(_tokenContracts), "Incorrect amount of ether sent");
    require(_tokenContracts.length == _tokenAmounts.length, "Mismatch between tokens and amounts");

    if(_tokenContracts.length == 0) {
      require(emptyPinyottyMintCount < maxEmptyPinyottasSupply, "No more empty pinyottas are available to mint");
    }
    else {
      for(uint i = 0; i < _tokenContracts.length - 1; i++) {
        for(uint j = i + 1; j < _tokenContracts.length; j++) {
          require(_tokenContracts[i] != _tokenContracts[j], "Each item in _tokenContracts must be unique"); 
        }
      }
    }
    
    for(uint i = 0; i < _tokenContracts.length; i++) {
      IERC20 erc20 = IERC20(_tokenContracts[i]);
      uint256 amount = _tokenAmounts[i];
      require(hasRole(WHITELIST, _tokenContracts[i]), "Attempted to mint with a non-whitelisted ERC-20 contract");
      require(_tokenAmounts[i] > 0, "All token amounts must be greater than 0");
      require(erc20.balanceOf(msg.sender) >= amount, "Token balance is less than deposit amount");
      require(erc20.allowance(msg.sender, address(this)) >= amount, "Allowance is less than deposit amount");
    }

    // Update the number of pinyottas minted for each ERC20
    for(uint i = 0; i < _tokenContracts.length; i++) {
      tokenAddressesToMintCounts[_tokenContracts[i]] = tokenAddressesToMintCounts[_tokenContracts[i]] + 1;
    }
    
    uint256 id = mintCount + 1;
    for(uint i = 0; i < _tokenContracts.length; i++) {
      IERC20 erc20 = IERC20(_tokenContracts[i]);
      uint256 amount = _tokenAmounts[i];
      erc20.transferFrom(msg.sender, address(this), amount);
      idToTokenBalances[id][erc20] = amount;
      idToOriginalTokenBalances[id][erc20] = amount;
    }
    idToTokenContracts[id] = _tokenContracts;
    
    mintCount++;
    if(_tokenContracts.length == 0) {
      emptyPinyottyMintCount++;
      idToEmptyTokenNumbers[id] = emptyPinyottyMintCount;
    }

    _safeMint(msg.sender, id);

    emit Mint(msg.sender, id);
  }

  // Prevent transfering of busted pinyottas except when minting
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);
    if(from != address(0)) {
      require(!isBusted(tokenId), "Attempted to transfer a bustedPinyotta");
    }
  }

  function isBusted(uint256 _id) public view returns (bool busted) {
    require(_exists(_id), "Attempted call isBusted with a non-existant token ID");
    return bustedPinyottas[_id];
  }

  function bust(uint256 _id) public {
    require(_exists(_id), "Attempted to bust a nonexistant token");
    require(!isBusted(_id), "Token is already busted");
    require(msg.sender == ownerOf(_id), "msg.sender is not the owner of the token to burn");
    address[] memory erc20s = getTokenContractsInPinyotta(_id);
    for(uint i = 0; i < erc20s.length; i++) {
      IERC20 erc20 = IERC20(erc20s[i]);
      uint256 pinyottaTokenBalance = getTokenBalanceInPinyotta(_id, address(erc20));
      if(pinyottaTokenBalance > 0) {
        idToTokenBalances[_id][erc20] = 0;
        erc20.transfer(msg.sender, pinyottaTokenBalance);
      }
    }
    bustedPinyottas[_id] = true;

    emit Bust(msg.sender, _id);
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "Cannot get tokenURI for nonexistant token");
    return MetadataProvider(metadataProvider).tokenURI(id);
  }

  function tokensOfWalletOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for(uint256 i; i < tokenCount; i++){
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
}