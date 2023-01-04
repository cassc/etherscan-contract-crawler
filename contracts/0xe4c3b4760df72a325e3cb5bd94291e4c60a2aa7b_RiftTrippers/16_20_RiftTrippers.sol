// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";





abstract contract Portals{
  function enterPortal(address to, uint256 tokenId)public virtual returns (uint256);
}

//portal error messages
error  CannotEnterUnopenedPortal();
error  PortalOpeningIsClosed();
error  PortalNotOpenYet();

contract RiftTrippers is ERC721AQueryable, ERC2981, Ownable, ReentrancyGuard{

  using Strings for uint256;
  using ECDSA for bytes32;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  //portal Variables
  address private portalContract;
  bool public canEnterPortal;
  
 
  //variables for URI Strings
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
 
  //variables for Cost and Mint Amounts
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  //variables for admin functions
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;


  address payable payments;
  
  




  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  )ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  } 


  //modifier for compliance of mint amounts during sale of portals
    modifier mintCompliance(uint256 _mintAmount) {
      require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
      require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
    }
  //modifier for compliance of price. assures the message sender has sufficient funds
    modifier mintPriceCompliance(uint256 _mintAmount) {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
   }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    //Burns token Id for portal and mints Rift Trip NFT from proxy contracts
      function enterPortal(uint256 tokenId) public nonReentrant() returns (uint256) {
        if (!canEnterPortal) {
            if (msg.sender != owner()) revert PortalOpeningIsClosed();
        }

        address to = ownerOf(tokenId);

        if (to != msg.sender) {
            if (msg.sender != owner()) revert CannotEnterUnopenedPortal();
        }

       Portals factory = Portals(portalContract);

        _burn(tokenId, true);

        uint256 RTPTokenId = factory.enterPortal(to, tokenId);
        return RTPTokenId;
    }

    //sets the contract address for the proxy contract to be able to mint after manual reveal.
    function setPortalContract(address contractAddress) external onlyOwner {
        portalContract = contractAddress;
    }

    //reads the amount of portals opened(burned)
    function portalsOpened(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

  

    //Mint function for whitelisted wallets.  
    function whitelistPortal(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  //public mint function
  function mintPortal(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  //admin mint function(mints portal for address)
  function AirdropPortal(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }


  function _starttokenId() internal view virtual returns (uint256) {
    return 1;
  }

  //reads the location of the portal uri
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent Portal');

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

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  //toggles portal entrance on and off
   function toggleCanEnterPortal() external onlyOwner {
        if (portalContract == address(0)) revert PortalNotOpenYet();
        canEnterPortal = !canEnterPortal;
    }
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }
  function withdraw() public onlyOwner nonReentrant {
    //48%,44%,6%,2% =100%
    (bool hs, ) = payable(0xCc12E017aAEE2C927dbb41d070cbAcD6fe3D9c5a).call{value: address(this).balance * 48 / 100}(''); //48% leaves 52 of 100 points
    (0x48a4e9E102c5AF6f4Ff2249e77266a9008aAc479).call{value: address(this).balance * 44 / 52}(''); //44 points from 52 points left is 84/100 remaining balance points
    (0x20A6075522AB5fCD3bE6bE43aB1Bce3CCD3616b0 ).call{value: address(this).balance * 6/ 8}('');  //6 points from 8 points paid from the remaining balance points
    (0xccE01C00E6E80aA826f3F0eCCE0b23848eA5d244).call{value: address(this).balance * 2/2}(''); // 2% of the original balance should be remaining which is 100/100 of remaining points
   

    require(hs);

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}