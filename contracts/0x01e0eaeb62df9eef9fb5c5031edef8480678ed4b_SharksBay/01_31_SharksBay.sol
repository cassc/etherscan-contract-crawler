// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "./upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SharksBay is Initializable, ERC721AQueryableUpgradeable, DefaultOperatorFiltererUpgradeable,  AccessControlUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {


  using StringsUpgradeable for uint256;

  bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

  bytes32 public merkleRoot;
  mapping(address => uint256) public whitelistClaimedAmount;
  mapping(address => uint256) public PublicSaleClaimedAmount;

  string public uriPrefix;
  string public uriSuffix;
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  uint256 public maxAmountWhitelistPerWallet;
  uint256 public maxAmountPublicSalePerWallet;

  uint256  firstPhaseLimit;
  bool public isFirstPhaseActive;


  bool public paused;
  bool public whitelistMintEnabled;
  bool public revealed;

  function initialize(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) public initializer initializerERC721A {
      __ERC721A_init(_tokenName, _tokenSymbol);
      __AccessControl_init();
      __UUPSUpgradeable_init();
      __ReentrancyGuard_init();
      __DefaultOperatorFilterer_init();
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(BURNER_ROLE, msg.sender);


      uriPrefix="";
      uriSuffix=".json";
      hiddenMetadataUri=_hiddenMetadataUri;
      
      cost = _cost;
      maxSupply = _maxSupply;
      maxMintAmountPerTx=_maxMintAmountPerTx;

      paused=false;
      whitelistMintEnabled=false;
      revealed=false;
      maxAmountPublicSalePerWallet = 5;
      maxAmountWhitelistPerWallet =5;
      maxMintAmountPerTx = 5;
      firstPhaseLimit = 1000;
      isFirstPhaseActive = true;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override
  {}

  function setFirstPhaseLimit(uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
    firstPhaseLimit = _value;
  }

  function setIsFirstPhaseActive(bool _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
    isFirstPhaseActive = _value;
  }

   function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');

    if(isFirstPhaseActive) {
          require(totalSupply() + _mintAmount <= firstPhaseLimit, 'Max supply for first phase reached!');

    }

    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  
  function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable,IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721AUpgradeable,IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable,IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable,IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721AUpgradeable,IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function bulkAirdrop(address[] calldata _to, uint256[] calldata _amounts) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_to.length == _amounts.length, "Receivers and IDs are different length");
    for (uint256 i = 0; i < _to.length; i++) {
        _safeMint(_to[i], _amounts[i]);

    }
  }


  function setMaxAmountPublicSalePerWallet(uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
    maxAmountPublicSalePerWallet = _value;
  }

    function setMaxAmountWhitelistPerWallet(uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
    maxAmountWhitelistPerWallet = _value;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(_mintAmount + whitelistClaimedAmount[_msgSender()] <= maxAmountWhitelistPerWallet, "you have reached the limit or try mint less tokens");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimedAmount[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(_mintAmount + PublicSaleClaimedAmount[_msgSender()] <= maxAmountPublicSalePerWallet, "you have reached the limit or try mint less tokens");

    PublicSaleClaimedAmount[_msgSender()] += _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyRole(DEFAULT_ADMIN_ROLE) {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721AUpgradeable,IERC721AUpgradeable) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyRole(DEFAULT_ADMIN_ROLE) {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyRole(DEFAULT_ADMIN_ROLE) {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
    whitelistMintEnabled = _state;
  }

  function withdraw(address _who) public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
   
    (bool os, ) = payable(_who).call{value: address(this).balance}('');
    require(os);
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}