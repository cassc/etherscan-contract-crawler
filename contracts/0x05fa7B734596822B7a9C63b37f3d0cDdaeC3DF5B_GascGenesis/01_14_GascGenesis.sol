// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/*
─────────────────────────────────────────────────────────────
─██████████████─██████████████─██████████████─██████████████─
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─
─██░░██████████─██░░██████░░██─██░░██████████─██░░██████████─
─██░░██─────────██░░██──██░░██─██░░██─────────██░░██─────────
─██░░██─────────██░░██████░░██─██░░██████████─██░░██─────────
─██░░██──██████─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────
─██░░██──██░░██─██░░██████░░██─██████████░░██─██░░██─────────
─██░░██──██░░██─██░░██──██░░██─────────██░░██─██░░██─────────
─██░░██████░░██─██░░██──██░░██─██████████░░██─██░░██████████─
─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─
─██████████████─██████──██████─██████████████─██████████████─
─────────────────────────────────────────────────────────────
*/


contract OwnableDelegateProxy{}
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract GascGenesis is ERC721A, Ownable, ReentrancyGuard, ProxyRegistry {

  using Strings for uint256;

  string public baseURI = '';
  string public baseExtension = '.json';
  string public notRevealedUri;
  
  uint256 public price = 0.06 ether;
  uint256 public maxSupply = 7777;
  uint256 public presaleAmountLimit = 25;

  bool public paused;
  bool public revealed;
  bool public presaleM;
  bool public publicM;
  bool public teamMinted;
  bool public airdrop;
  

  address immutable proxyRegistryAddress;

  bytes32 public root;
  mapping(address => bool) public _presaleClaimed;

  constructor(string memory _notRevealedURI, bytes32 merkleroot, address _proxyRegistryAddress)
  ERC721A("Grandma Ape Spa Club", "GASC")
  ReentrancyGuard() 
  {
    root = merkleroot;
    proxyRegistryAddress = _proxyRegistryAddress;
    setNotRevealedURI(_notRevealedURI);

  }
  
  modifier onlyAccounts() {
        require(tx.origin == msg.sender, "Grandma Apes Spa Club :: Cannot be called by a contract");
        _;
    }
  modifier isValidMerkleProof(bytes32[] calldata _merkleProof) {
         require(MerkleProof.verify(
            _merkleProof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
  }

  function presaleMint(address account, uint256 _amount, bytes32[] calldata _merkleProof) public payable isValidMerkleProof(_merkleProof) onlyAccounts {
    require(msg.sender == account, "GrandmaApes: Not Allowed");
    require(presaleM, "GrandmaApes: Presale is OFF");
    require(!paused, "GrandmaApes: Contract is paused");
    require(_amount > 0 && _amount <= presaleAmountLimit, "GrandmaApes: You can't mint over limit");
    require(!_presaleClaimed[_msgSender()], 'Address already claimed!');
    require(totalSupply() + _amount <= maxSupply, "GrandmaApes: Max Supply Exceeded!");
    require(msg.value >= price * _amount, "GrandmaApes: Insufficient funds!");

    _presaleClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _amount);
  }

  function publicSaleMint(uint256 _amount) public payable onlyAccounts {
    require(publicM, 'The whitelist sale is not enabled!');
    require(!paused, 'The contract is paused!');
    require(_amount > 0 && _amount <= presaleAmountLimit, 'Invalid mint amount!');
    require(totalSupply() + _amount <= maxSupply, 'Max supply exceeded!');
    require(msg.value >= price * _amount, 'Insufficient funds!');

    _safeMint(_msgSender(), _amount);
  }

  function teamMint() external onlyOwner{
    require(!teamMinted, "Grandma Apes Spa Club :: Team Already Minted!");
    teamMinted = true;
    _safeMint(msg.sender, 500);
  }

  function airdropMint() external onlyOwner{
      require(!airdrop, "Grandma Apes Spa Club :: Airdrop Mints already claimed!");
      airdrop = true;
      _safeMint(msg.sender, 976);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
        : '';
  }

  function setRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }
  
  function setPresaleAmountLimit(uint256 _presaleAmountLimit) public onlyOwner {
    presaleAmountLimit = _presaleAmountLimit;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
    baseURI = _tokenBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function togglePause() public onlyOwner {
    paused = !paused;
  }

  function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
    root = merkleroot;
  }

  function togglePresale() public onlyOwner {
    presaleM = !presaleM;
  }

  function togglePublicSale() public onlyOwner {
    publicM = !publicM;
  }

  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true; 
        }
        
        return super.isApprovedForAll(owner, operator);
}

   function withdraw() public onlyOwner nonReentrant {
    // =============================================================================
    (bool hs, ) = payable(0x76F587939b115dB240d93598d553a83f7e598AC9).call{value: address(this).balance * 2 / 100}('');
    require(hs);
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}