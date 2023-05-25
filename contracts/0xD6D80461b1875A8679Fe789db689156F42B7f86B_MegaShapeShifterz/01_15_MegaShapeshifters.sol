// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../utils/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//  /$$      /$$                                                            
// | $$$    /$$$                                                            
// | $$$$  /$$$$  /$$$$$$   /$$$$$$   /$$$$$$                               
// | $$ $$/$$ $$ /$$__  $$ /$$__  $$ |____  $$                              
// | $$  $$$| $$| $$$$$$$$| $$  \ $$  /$$$$$$$                              
// | $$\  $ | $$| $$_____/| $$  | $$ /$$__  $$                              
// | $$ \/  | $$|  $$$$$$$|  $$$$$$$|  $$$$$$$                              
// |__/     |__/ \_______/ \____  $$ \_______/                              
//                         /$$  \ $$                                        
//                        |  $$$$$$/                                        
//                         \______/                                         
//   /$$$$$$  /$$                                                           
//  /$$__  $$| $$                                                           
// | $$  \__/| $$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$                        
// |  $$$$$$ | $$__  $$ |____  $$ /$$__  $$ /$$__  $$                       
//  \____  $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$$$$$$$                       
//  /$$  \ $$| $$  | $$ /$$__  $$| $$  | $$| $$_____/                       
// |  $$$$$$/| $$  | $$|  $$$$$$$| $$$$$$$/|  $$$$$$$                       
//  \______/ |__/  |__/ \_______/| $$____/  \_______/                       
//                               | $$                                       
//                               | $$                                       
//                               |__/                                       
//   /$$$$$$  /$$       /$$  /$$$$$$   /$$                                  
//  /$$__  $$| $$      |__/ /$$__  $$ | $$                                  
// | $$  \__/| $$$$$$$  /$$| $$  \__//$$$$$$    /$$$$$$   /$$$$$$   /$$$$$$$
// |  $$$$$$ | $$__  $$| $$| $$$$   |_  $$_/   /$$__  $$ /$$__  $$ /$$_____/
//  \____  $$| $$  \ $$| $$| $$_/     | $$    | $$$$$$$$| $$  \__/|  $$$$$$ 
//  /$$  \ $$| $$  | $$| $$| $$       | $$ /$$| $$_____/| $$       \____  $$
// |  $$$$$$/| $$  | $$| $$| $$       |  $$$$/|  $$$$$$$| $$       /$$$$$$$/
//  \______/ |__/  |__/|__/|__/        \___/   \_______/|__/      |_______/ 
                                                                         
interface ILoomi {
  function claimLoomiTax(address user, uint256 amount) external;
}

interface IStaking {
  function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

interface IShapes {
  function validateAndBurn(uint256[] memory tokenIds, address owner) external;
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract MegaShapeShifterz is Context, ERC721Enumerable, Ownable, ReentrancyGuard  {
    using SafeMath for uint256;
    using Strings for uint256;


    address public signer;

    bool public saleIsActive;
    bool public isPaused;
    bool public metadataFinalised;
    bool public creepzRestriction;

    string public _megaBaseURI;

    // Royalty info
    address public royaltyAddress;
    uint256 public ROYALTY_SIZE = 750;
    uint256 public ROYALTY_DENOMINATOR = 10000;
    mapping(uint256 => address) private _royaltyReceivers;

    // Loomi contract
    ILoomi public Loomi;
    IStaking public Staking;
    IShapes public Shapes;
    IERC721 public Creepz;

    enum ShapeShifter {
      Donald,
      Cuban,
      Paris,
      Elon,
      Snoop,
      Gary,
      Banks
    }

    mapping (uint256 => ShapeShifter) public tokenTypes;
    mapping (uint256 => string) public tokenTypeToUri;
    mapping (address => uint256) public userToUsedNonce;

    event TokensMinted(
      address indexed mintedBy,
      uint256 indexed tokenId,
      uint256 tokenType
    );

    event TaxClaimed(
      address indexed claimedBy,
      uint256 indexed amount,
      uint256 nonce
    );

    constructor(address _royaltyAddress, address _loomi, address _staking, address _creepz, address _shapes, address _signer, string memory _baseUri)
    ERC721("MegaShapeShifterz", "MEGA")
    {
      royaltyAddress = _royaltyAddress;

      Loomi = ILoomi(_loomi);
      Staking = IStaking(_staking);
      Creepz = IERC721(_creepz);
      Shapes = IShapes(_shapes);

      signer = _signer;

      _megaBaseURI = _baseUri;

      isPaused = true;
      creepzRestriction = true;
    }

    modifier whenNotPaused {
      require(!isPaused, "Tax collection paused!");
      _;
    }

    /*
      @dev Takes SS ids as an input and burns them into a single Mega
    */
    function mutate(uint256[] memory shapeIds, uint256 shapeType, bytes calldata signature) public nonReentrant {
      require(shapeType <= 6, "Unknown shape type");
      if (_msgSender() != owner()) require(saleIsActive, "The mint has not started yet");

      require(_validateMutateSignature(
        signature,
        shapeIds,
        shapeType
      ), "Invalid data provided");

      Shapes.validateAndBurn(shapeIds, _msgSender());

      uint256 tokenId = totalSupply();
      _safeMint(_msgSender(), tokenId);
      tokenTypes[tokenId] = ShapeShifter(shapeType);

      emit TokensMinted(_msgSender(), tokenId, shapeType);
    }

    /*
      @dev Allows SS owner to claim accumulated tax
    */
    function claimTax(uint256 amount, uint256 nonce, uint256 creepzId, bytes calldata signature) public whenNotPaused nonReentrant {
      require(amount != 0, "Cannot claim 0 $loomi");
      require(userToUsedNonce[_msgSender()] < nonce, "This nonce has been already used");
      require(_validateCreepzOwner(creepzId, _msgSender()), "!Creepz owner");
      require(_validateClaimSignature(
        signature,
        amount,
        nonce
      ), "Invalid data provided");

      Loomi.claimLoomiTax(_msgSender(), amount);
      userToUsedNonce[_msgSender()] = nonce;

      emit TaxClaimed(_msgSender(), amount, nonce);
    }

    /*
      @dev Validates data passed into Mutate function
    */
    function _validateMutateSignature(
      bytes calldata signature,
      uint256[] memory shapeIds,
      uint256 shapeType
      ) internal view returns (bool) {
      bytes32 dataHash = keccak256(abi.encodePacked(shapeIds, shapeType));
      bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

      address receivedAddress = ECDSA.recover(message, signature);
      return (receivedAddress != address(0) && receivedAddress == signer);
    }

    /*
      @dev Validates data passed into Claim function
    */
    function _validateClaimSignature(
      bytes calldata signature,
      uint256 amount,
      uint256 nonce
      ) internal view returns (bool) {
      bytes32 dataHash = keccak256(abi.encodePacked(amount, nonce, _msgSender()));
      bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

      address receivedAddress = ECDSA.recover(message, signature);
      return (receivedAddress != address(0) && receivedAddress == signer);
    }

    /*
      @dev Checks whether msg.sender ownes a Genesis Creepz or not
    */
    function _validateCreepzOwner(uint256 tokenId, address user) internal view returns (bool) {
      if (!creepzRestriction) return true;
      if (Staking.ownerOf(address(Creepz), tokenId) == user) {
        return true;
      }
      return Creepz.ownerOf(tokenId) == user;
    }

    /*
      @dev Royalty info
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      uint256 amount = _salePrice.mul(ROYALTY_SIZE).div(ROYALTY_DENOMINATOR);
      address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
      return (royaltyReceiver, amount);
    }

    /*
      @dev Token URI, returns string based on token type
    */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      return string(abi.encodePacked(_megaBaseURI, tokenId.toString()));
    }

    /*
      @dev ADMIN
    */

    function updateCreepzRestriction(bool _restrict) public onlyOwner {
      creepzRestriction = _restrict;
    }
    
    function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
      _royaltyReceivers[tokenId] = receiver;
    }

    function updateSaleStatus(bool status) public onlyOwner {
      saleIsActive = status;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
      require(!metadataFinalised, "Metadata already finalised");
      _megaBaseURI = newBaseURI;
    }

    function finalizeMetadata() public onlyOwner {
      require(!metadataFinalised, "Metadata already finalised");
      metadataFinalised = true;
    }

    function unpdateSigner(address _signer) public onlyOwner {
      signer = _signer;
    }

    function pauseTaxClaim(bool _pause) public onlyOwner {
      isPaused = _pause;
    }

    function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(owner()).transfer(balance);
    }
}