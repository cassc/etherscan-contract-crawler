// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/*

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─████████████───████████████████───██████████████─██████████████─██████████─██████──────────██████─██████████████████─
─██░░░░░░░░████─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░██─██░░██████████──██░░██─██░░░░░░░░░░░░░░██─
─██░░████░░░░██─██░░████████░░██───██░░██████░░██─██░░██████████─████░░████─██░░░░░░░░░░██──██░░██─████████████░░░░██─
─██░░██──██░░██─██░░██────██░░██───██░░██──██░░██─██░░██───────────██░░██───██░░██████░░██──██░░██─────────████░░████─
─██░░██──██░░██─██░░████████░░██───██░░██████░░██─██░░██───────────██░░██───██░░██──██░░██──██░░██───────████░░████───
─██░░██──██░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░██──██████───██░░██───██░░██──██░░██──██░░██─────████░░████─────
─██░░██──██░░██─██░░██████░░████───██░░██████░░██─██░░██──██░░██───██░░██───██░░██──██░░██──██░░██───████░░████───────
─██░░██──██░░██─██░░██──██░░██─────██░░██──██░░██─██░░██──██░░██───██░░██───██░░██──██░░██████░░██─████░░████─────────
─██░░████░░░░██─██░░██──██░░██████─██░░██──██░░██─██░░██████░░██─████░░████─██░░██──██░░░░░░░░░░██─██░░░░████████████─
─██░░░░░░░░████─██░░██──██░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░██─██░░██──██████████░░██─██░░░░░░░░░░░░░░██─
─████████████───██████──██████████─██████──██████─██████████████─██████████─██████──────────██████─██████████████████─
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
*/


contract OwnableDelegateProxy{}
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract JustDraginzDen is ERC721A, Ownable, ReentrancyGuard, ProxyRegistry {

  using Strings for uint256;

  string public baseURI = '';
  string public baseExtension = '.json';
  
  uint256 public price = 0 ether;
  uint256 public maxSupply = 8888;
  uint256 public presaleAmountLimit = 1;

  bool public paused;
  bool public presaleM;
  bool public publicM;
  bool public teamMinted;
  

  address immutable proxyRegistryAddress;

  bytes32 public root;
  mapping(address => bool) public _presaleClaimed;

  constructor(bytes32 merkleroot, address _proxyRegistryAddress)
  ERC721A("Just Draginz Den", "JDD")
  ReentrancyGuard() 
  {
    root = merkleroot;
    proxyRegistryAddress = _proxyRegistryAddress;

  }
  
  modifier onlyAccounts() {
        require(tx.origin == msg.sender, "JustDraginzDen :: Cannot be called by a contract");
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
    require(msg.sender == account, "JustDraginzDen: Not Allowed");
    require(presaleM, "JustDraginzDen: Presale is OFF");
    require(!paused, "JustDraginzDen: Contract is paused");
    require(_amount > 0 && _amount <= presaleAmountLimit, "JustDraginzDen: You can't mint over limit");
    require(!_presaleClaimed[_msgSender()], 'Address already claimed!');
    require(totalSupply() + _amount <= maxSupply, "JustDraginzDen: Max Supply Exceeded!");
    require(msg.value >= price * _amount, "JustDraginzDen: Insufficient funds!");

    _presaleClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _amount);
  }

  function publicSaleMint(uint256 _amount) public payable onlyAccounts {
    require(publicM, 'The public sale is not enabled!');
    require(!paused, 'The contract is paused!');
    require(_amount > 0 && _amount <= presaleAmountLimit, 'Invalid mint amount!');
    require(!_presaleClaimed[_msgSender()], 'Address already claimed!');
    require(totalSupply() + _amount <= maxSupply, 'Max supply exceeded!');
    require(msg.value >= price * _amount, 'Insufficient funds!');

  _presaleClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _amount);
  }

    function teamMint() external onlyOwner{
    require(!teamMinted, "JustDraginzDen :: Team Already Minted!");
    teamMinted = true;
    _safeMint(msg.sender, 888);
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
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
        : '';
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }
  
  function setPresaleAmountLimit(uint256 _presaleAmountLimit) public onlyOwner {
    presaleAmountLimit = _presaleAmountLimit;
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
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}