// SPDX-License-Identifier: Proprietary

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { DefaultOperatorFilterer721, OperatorFilterer721 } from "./opensea/DefaultOperatorFilterer721.sol";
import "./Claimable.sol";

contract SupercuteWorldNFTA is 
  ERC721A,
  ERC2981,
  AccessControl,
  DefaultOperatorFilterer721,
  Ownable,
  Pausable,
  ReentrancyGuard,
  Claimable
{

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

  uint256 private constant PUBLIC_STAGE = 3;

  uint256 private constant GENDERS = 3;

  uint256 public immutable maxSupply;

  bool revealed;

  string private defaultTokenUri;

  string private contractUri;

  uint256 private freeGenderSwitches;

  uint256 private stage; // 0-3

  address private paymentAddress;

  uint256 private genderSwitchFee;

  uint256 private genderSwitchNonce;

  uint256 private mintFee;

  uint256 private treasuryReserve;

  uint256 private treasuryMints;

  uint256 private defaultRevealedGender;

  mapping (uint256 => uint256) private genderSwitchCounts;

  mapping (uint256 => uint256) private tokenGenders;

  mapping (uint256 => bytes32) private merkleRoots;

  mapping (address => mapping(uint256 => uint256)) private mintCounts;

  mapping (uint256 => uint256) private stageMintLimits;

  mapping (uint256 => string) private genderBaseUris;

  constructor(
    string memory _contractUri,
    string memory _defaultTokenUri,
    uint256 _maxSupply,
    uint256 _treasuryReserve,
    address _paymentAddress,
    address _royaltyAddress,
    uint96 _feeNumerator
  )
    ERC721A("Supercute World", "SUPERCUTE") 
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MANAGER_ROLE, _msgSender());
    _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    contractUri = _contractUri;
    defaultTokenUri = _defaultTokenUri;
    maxSupply = _maxSupply;
    treasuryReserve = _treasuryReserve;
    paymentAddress = _paymentAddress;

    mintFee = 90000000000000000; //0.09ETH
    genderSwitchFee = 10000000000000000; // 0.01ETH
    freeGenderSwitches = 1;
    genderBaseUris[1] = "https://ipfs.w3box.io/ipns/supercuteworld.com/n/";
    genderBaseUris[2] = "https://ipfs.w3box.io/ipns/supercuteworld.com/m/";
    genderBaseUris[3] = "https://ipfs.w3box.io/ipns/supercuteworld.com/f/";
    stageMintLimits[1] = 2;
    stageMintLimits[2] = 2;
    stageMintLimits[3] = 2;
  }

  /* ------------ User Operations ------------ */

  function mint(
    uint256 _quantity,
    bytes32[] calldata _merkleProof
  )
    external
    payable
    whenNotPaused
    nonReentrant
    mintAllowed(_msgSender(), _quantity, _merkleProof)
  {
    if(msg.value < mintFee * _quantity) {
      revert InsufficientFee();
    }
    (bool paid, ) = paymentAddress.call{ value: msg.value }("");
    
    if(!paid) {
      revert UnableCollectFee();
    }

    _safeMint(_msgSender(), _quantity);
  }

  function switchGender(
    uint256 _tokenId,
    uint256 _gender
  )
    external
    payable
    whenNotPaused
    nonReentrant
    validGender(_gender)
  {
    if(ownerOf(_tokenId) != _msgSender()) {
      revert Unauthorized();
    }
    if(tokenGenders[_tokenId] == _gender) {
      revert SameGender();
    }
    if(!revealed) {
      revert WaitForReveal();
    }

    if(getGenderSwitchFee(_tokenId) > 0) {
      if(msg.value < genderSwitchFee) {
        revert InsufficientFee();
      }
      
      (bool paid, ) = paymentAddress.call{ value: msg.value }("");
      
      if(!paid) {
        revert UnableCollectFee();
      }
    }

    genderSwitchCounts[_tokenId] += 1;
    tokenGenders[_tokenId] = _gender;
    genderSwitchNonce += 1;

    emit SelfieGenderChange(genderSwitchNonce, _tokenId, _gender);
  }

  /* ------------ Public Operations ------------ */

  function contractURI()
    public
    view
    returns (string memory)
  {
    return contractUri;
  }

  function tokenURI(
    uint256 _tokenId
  ) 
    public
    view
    override 
    returns (string memory)
  {
    if(!_exists(_tokenId)) {
      revert TokenDoesNotExist();
    }
    uint256 gender = getGenderByTokenId(_tokenId);

    if(!revealed || gender == 0) {
      return defaultTokenUri;
    }

    string memory baseURI = genderBaseUris[gender];
    return string(abi.encodePacked(baseURI, _toString(_tokenId)));
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(AccessControl, ERC721A, ERC2981)
    returns (bool) 
  {
    return
      AccessControl.supportsInterface(interfaceId)
        || ERC2981.supportsInterface(interfaceId)
        || ERC721A.supportsInterface(interfaceId);
  }

  function getMintFee()
    external
    view
    returns (uint256)
  {
    return mintFee;
  }

  function getStageMintLimit()
    external
    view
    returns (uint256)
  {
    return stageMintLimits[stage];
  }

  function getMintLimit(
    address _minter
  )
    external
    view
    returns (uint256)
  {
    return stageMintLimits[stage] - mintCounts[_minter][stage];
  }

  function getStage()
    external
    view
    returns (uint256)
  {
    return stage;
  }

  function getGenderByTokenId(
    uint256 _tokenId
  )
    public
    view
    returns (uint256 _gender)
  {
    _gender = tokenGenders[_tokenId];
    if(revealed && _gender == 0) {
      _gender = defaultRevealedGender;
    }
  }

  function getGenderSwitchFee(
    uint256 _tokenId
  )
    public
    view
    returns (uint256)
  {
    return genderSwitchFee > 0 && freeGenderSwitches < genderSwitchCounts[_tokenId] + 1 ? genderSwitchFee : 0;
  }

  function isRevealed()
    public
    view
    returns (bool)
  {
    return revealed;
  }

  function getPublicSupply()
    public
    view
    returns (uint256)
  {
    return maxSupply - treasuryReserve;
  }

  /* ------------ Management Operations ------------ */

  function setPaused(
    bool _paused
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setMerkleRoot(
    uint256 _stage,
    bytes32 _root
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    validStage(_stage)
  {
    merkleRoots[_stage] = _root;
  }

  function setPaymentAddress(
    address _paymentAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    paymentAddress = _paymentAddress;
  }

  /**
  * @dev Withdraws the erc20 tokens or native coins from this contract.
  */
  function claimValues(address _token, address _to)
      external
      onlyRole(DEFAULT_ADMIN_ROLE)
  {
      _claimValues(_token, _to);
  }

  /**
    * @dev Withdraw ERC721 or ERC1155 deposited for this contract
    * @param _token address of the claimed ERC721 token.
    * @param _to address of the tokens receiver.
    */
  function claimNFTs(address _token, uint256 _tokenId, address _to)
      external
      onlyRole(DEFAULT_ADMIN_ROLE)
  {
      _claimNFTs(_token, _tokenId, _to);
  }

  function setContractUri(
    string calldata _contractUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    contractUri = _contractUri;
  }

  function setRevealed(
    bool _revealed
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revealed = _revealed;
  }

  function setDefaultTokenUri(
    string calldata _defaultTokenUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    defaultTokenUri = _defaultTokenUri;
  }

  function setGenderBaseUri(
    uint256 _gender,
    string calldata _baseUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    validGender(_gender)
  {
    genderBaseUris[_gender] = _baseUri;
  }

  function setDefaultRoyalty(
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function deleteDefaultRoyalty()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 _tokenId,
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  function resetTokenRoyalty(
    uint256 tokenId
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _resetTokenRoyalty(tokenId);
  }

  function setFreeGenderSwitches(
    uint256 _freeGenderSwitches
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    freeGenderSwitches = _freeGenderSwitches;
  }

  function setGenderSwitchFee(
    uint256 _genderSwitchFee
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    genderSwitchFee = _genderSwitchFee;
  }

  function setMintFee(
    uint256 _mintFee
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    mintFee = _mintFee;
  }

  function setStageMintLimit(
    uint256 _stage,
    uint256 _limit
  )
    external
    onlyRole(MANAGER_ROLE)
    validStage(_stage)
  {
    stageMintLimits[_stage] = _limit;
  }

  function setStage(
    uint256 _stage
  )
    external
    onlyRole(MANAGER_ROLE)
    validStage(_stage)
  {
    stage = _stage;
  }

  function setDefaultRevealedGender(
    uint256 _gender
  )
    external
    onlyRole(MANAGER_ROLE)
    validGender(_gender)
  {
    defaultRevealedGender = _gender;
    emit SelfieDefaultRevealedGenderSet(defaultRevealedGender);
  }

  function setTreasuryReserve(
    uint256 _treasuryReserve
  )
    external
    onlyRole(TREASURY_ROLE)
  {
    if(treasuryMints > _treasuryReserve) {
      revert BadTreasuryReserve();
    }
    if(totalPublicMints() + _treasuryReserve > maxSupply) {
      revert BadTreasuryReserve();
    }
    treasuryReserve = _treasuryReserve;
  }

  function mintTo(
    address _to,
    uint256 _quantity,
    bytes32[] calldata _merkleProof
  )
    external
    whenNotPaused
    onlyRole(MINTER_ROLE)
    mintAllowed(_to, _quantity, _merkleProof)
  {
    _safeMint(_to, _quantity);
  }

  function treasuryMint(
    address _to,
    uint256 _quantity
  )
    external
    whenNotPaused
    onlyRole(TREASURY_ROLE)
  {
    if(stage == 0) {
      revert SaleIsClosed();
    }
    if(treasuryMints + _quantity > treasuryReserve) {
      revert TreasuryMintsExceeded();
    }
    _safeMint(_to, _quantity);
    treasuryMints += _quantity;
  }

  /* ------------ Internal Operations/Modifiers ------------ */
  modifier mintAllowed(
    address _to,
    uint256 _quantity,
    bytes32[] calldata _merkleProof
  )
  {
    if(stage == 0) {
      revert SaleIsClosed();
    }
    if(stage < PUBLIC_STAGE && !MerkleProof.verify(_merkleProof, merkleRoots[stage], keccak256(abi.encodePacked(_to)))) {
      revert AddressNotAllowedStage();
    }
    if(totalPublicMints() + _quantity > getPublicSupply()) {
      revert MaxSupplyExceeded();
    }
    if(mintCounts[_to][stage] + _quantity > stageMintLimits[stage]) {
      revert AddressLimitExceeded();
    }

    mintCounts[_to][stage] += _quantity;
    _;
  }

  modifier validStage(
    uint256 _stage
  )
  {
    if(_stage > PUBLIC_STAGE) {
      revert InvalidStage();
    }

    _;
  }

  modifier validGender(
    uint256 _gender
  )
  {
    if(_gender == 0 || _gender > GENDERS) {
      revert UnknownGenderCode();
    }
    _;
  }

  function _startTokenId()
    internal
    pure
    override
    returns (uint256)
  {
    return 1;
  }

  function totalPublicMints()
    internal
    view
    returns (uint256)
  {
    return _totalMinted() - treasuryMints;
  }

  /* ------------ OpenSea Overrides --------------*/
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    payable
    override 
    onlyAllowedOperator(_from)
  {
      super.transferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) 
    public
    payable
    override 
    onlyAllowedOperator(_from)
  {
    super.safeTransferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    payable
    override
    onlyAllowedOperator(_from)
  {
    super.safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /* ------------ Events ------------ */
  event SelfieGenderChange(
    uint256 indexed nonce,
    uint256 indexed tokenId,
    uint256 indexed gender
  );

  event SelfieDefaultRevealedGenderSet(
    uint256 indexed gender
  );

  /* ----------- Errors ------------- */

  error InsufficientFee();
  error UnableCollectFee();
  error Unauthorized();
  error SameGender();
  error WaitForReveal();
  error SaleIsClosed();
  error InvalidStage();
  error AddressLimitExceeded();
  error TokenDoesNotExist();
  error MaxSupplyExceeded();
  error AddressNotAllowedStage();
  error UnknownGenderCode();
  error TreasuryMintsExceeded();
  error BadTreasuryReserve();
}