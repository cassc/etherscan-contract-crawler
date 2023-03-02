// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


abstract contract Umi{
  function ActivateUMI(address to, uint256 tokenId)public virtual returns (uint256);
}

contract TheMetaBucksUMI is ERC721ABurnable, ERC721AQueryable, Ownable, ReentrancyGuard, ERC2981 {

error  CannotRevealID();
error  IdIsPrivate();
error  MysteryModeON();

  using Strings for uint256;
  using ECDSA for bytes32;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  //Umi Variables
  address private UMIContract;
  bool public AllowedToDoxx;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

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
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }


  //modifier for compliance of mint amounts during sale of Umis
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
 
   
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A, IERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    //Burns token Id for Umi and mints your Doxxable PFP from proxy contracts
      function ActivateUMI(uint256 tokenId) public nonReentrant() returns (uint256) {
        if (!AllowedToDoxx) {
            if (msg.sender != owner()) revert ();
        }
        
        address to = ownerOf(tokenId);

        if (to != msg.sender) {
            if (msg.sender != owner()) revert CannotRevealID();
        }

       Umi factory = Umi(UMIContract);
        _burn(tokenId, true);

        uint256 UMITokenId = factory.ActivateUMI(to, tokenId);
        return UMITokenId;
    }

    //sets the contract address for the proxy contract to be able to mint after manual reveal.
    function setUMIContract(address contractAddress) external onlyOwner {
        UMIContract = contractAddress;
    }

    //reads the amount of Umis opened(burned)
    function UMIsIssued(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

  

    //Mint function for whitelisted wallets.  
    function WhitelistedMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
   
   // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  //public mint function
  function MintUMI(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  
  function AirdropUMI(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }


  function _starttokenId() internal view virtual returns (uint256) {
    return 1;
  }

  //reads the location of the UMI uri
  function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A)returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent Data');

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

  //toggles the ability to burn to mint 2.0 UMI
   function toggleAllowedToDoxx() external onlyOwner {
        if (UMIContract == address(0)) revert MysteryModeON();
        AllowedToDoxx = !AllowedToDoxx;
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


    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}