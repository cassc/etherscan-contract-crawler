// SPDX-License-Identifier: MIT

//  _______  _______  _______           _______  _______  _______  _______ 
// (  ____ )(  ____ \(  ____ \|\     /|(  ____ \(  ____ )(  ____ \(  ____ \
// | (    )|| (    \/| (    \/| )   ( || (    \/| (    )|| (    \/| (    \/
// | (____)|| (__    | (__    | |   | || (__    | (____)|| (_____ | (__    
// |  _____)|  __)   |  __)   ( (   ) )|  __)   |     __)(_____  )|  __)   
// | (      | (      | (       \ \_/ / | (      | (\ (         ) || (      
// | )      | (____/\| (____/\  \   /  | (____/\| ) \ \__/\____) || (____/\
// |/       (_______/(_______/   \_/   (_______/|/   \__/\_______)(_______/
                                                                        

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/[email protected]/token/ERC721/IERC721.sol';

contract Peellets is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public claimedAmount;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  address public parentContractAddress;
  
  uint256 public maxSupply;
  uint256 public maxClaimAmountPerTx;

  bool public paused = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxClaimAmountPerTx,
    string memory _hiddenMetadataUri,
    address _parentContractAddress
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setMaxClaimAmountPerTx(_maxClaimAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setParentContractAddress(_parentContractAddress);
  }

  modifier claimCompliance(uint256 _claimAmount) {
    require(_claimAmount > 0 && _claimAmount <= maxClaimAmountPerTx, 'Invalid claim amount!');
    require(claimedAmount[_msgSender()] < IERC721(parentContractAddress).balanceOf(msg.sender), 'Already claimed all NFTs Available to wallet!');
    require(totalSupply() + _claimAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

    //modifier to check if claimer has the parent NFTs amount
    modifier hasParentNFTs(address _claimer, uint256 _claimAmount) {
        require(
            IERC721(parentContractAddress).balanceOf(_claimer) >= _claimAmount,
            'You do not have enough parent NFTs to claim!'
        );
        _;
    }

  function claim(uint256 _claimAmount) public payable claimCompliance(_claimAmount) hasParentNFTs(msg.sender, _claimAmount) {
    require(!paused, 'The contract is paused!');
    
    claimedAmount[_msgSender()] = claimedAmount[_msgSender()] + _claimAmount;
    _safeMint(_msgSender(), _claimAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setMaxClaimAmountPerTx(uint256 _maxClaimAmountPerTx) public onlyOwner {
    maxClaimAmountPerTx = _maxClaimAmountPerTx;
  }

  function setParentContractAddress(address _parentContractAddress) public onlyOwner {
    parentContractAddress = _parentContractAddress;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setBaseUri(string memory _baseUri) public onlyOwner {
    uriPrefix = _baseUri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}