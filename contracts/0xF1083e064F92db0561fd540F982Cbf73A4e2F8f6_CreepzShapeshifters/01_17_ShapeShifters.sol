// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../utils/ERC721EnumerableBurnable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


//   /$$$$$$                                                                
//  /$$__  $$                                                               
// | $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$$             
// | $$       /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$|____ /$$/             
// | $$      | $$  \__/| $$$$$$$$| $$$$$$$$| $$  \ $$   /$$$$/              
// | $$    $$| $$      | $$_____/| $$_____/| $$  | $$  /$$__/               
// |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$| $$$$$$$/ /$$$$$$$$             
//  \______/ |__/       \_______/ \_______/| $$____/ |________/             
//                                         | $$                             
//                                         | $$                             
//                                         |__/                             
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
                                                                         
                                                                         
interface ILOOMI {
  function spendLoomi(address user, uint256 amount) external;
}

interface ISTAKING {
  function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract CreepzShapeshifters is Context, ERC721EnumerableBurnable, VRFConsumerBase, Ownable, ReentrancyGuard  {
    using SafeMath for uint256;
    using Strings for uint256;

    // currentMintIndex
    uint256 private currentIndex;

    // Provenance hash
    string public PROVENANCE_HASH;

    // Base URI
    string private _shapesBaseURI;

    // Starting Index
    uint256 public startingIndex;

    // Max number of NFTs
    uint256 public constant MAX_SUPPLY = 20000;
    uint256 public constant BASE_RATE_TOKENS = 1;
    uint256 public _purchaseTimeout;
    uint256 public _basePrice;
    uint256 public _regularPrice;
    uint256 private _maxToMint;

    bool public saleIsActive;
    bool public creepzRestriction;
    bool private metadataFinalised;
    bool private startingIndexSet;

    // Royalty info
    address public royaltyAddress;
    uint256 private ROYALTY_SIZE = 750;
    uint256 private ROYALTY_DENOMINATOR = 10000;
    mapping(uint256 => address) private _royaltyReceivers;

    // MEGA Address
    address public MEGA;

    // Loomi contract
    ILOOMI public LOOMI;
    ISTAKING public STAKING;
    IERC721 public CREEPZ;

    // Stores the number of minted tokens by user
    mapping(address => uint256) public _mintedByAddress;
    mapping(address => uint256) public _lastPurchased;

    bytes32 internal keyHash;
    uint256 internal fee;

    event TokensMinted(
      address indexed mintedBy,
      uint256 indexed tokensNumber
    );

    event StartingIndexFinalized(
      uint256 indexed startingIndex
    );

    event BaseUriUpdated(
      string oldBaseUri,
      string newBaseUri
    );

    constructor(address _royaltyAddress, address _loomi, address _staking, address _creepz, string memory _baseURI)
    ERC721("Creepz Shapeshifters", "SHAPE")
    VRFConsumerBase(
      0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
      0x514910771AF9Ca656af840dff83E8264EcF986CA // LINK Token
    )
    {
      royaltyAddress = _royaltyAddress;

      LOOMI = ILOOMI(_loomi);
      STAKING = ISTAKING(_staking);
      CREEPZ = IERC721(_creepz);

      keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
      fee = 2 * 10 ** 18;

      _shapesBaseURI = _baseURI;

      _basePrice = 10000 ether;
      _regularPrice = 15000 ether;
      creepzRestriction = true;

      _maxToMint = 50;
      _purchaseTimeout = 1 days;
    }

    modifier onlyMega() {
      require(_msgSender() == MEGA, "Call from non-mega contract");
      _;
    }

    function shapePurchase(uint256 tokensToMint, uint256 tokenId) public nonReentrant {
      if (_msgSender() != owner()) require(saleIsActive, "The mint has not started yet");

      require(tokensToMint > 0, "Min mint is 1 token");
      require(tokensToMint <= _maxToMint, "You can not mint that many tokens per transaction");
      require(currentIndex.add(tokensToMint) <= MAX_SUPPLY, "Mint more tokens than allowed");

      if (_msgSender() != owner()) {
        require(_validateCreepzOwner(tokenId, _msgSender()), "!Creepz owner");
        require(block.timestamp.sub(_lastPurchased[_msgSender()]) >= _purchaseTimeout, "Time limit restriction");
        uint256 batchPrice = getTokenPrice(_msgSender(), tokensToMint);

        LOOMI.spendLoomi(_msgSender(), batchPrice);
        _mintedByAddress[_msgSender()] += tokensToMint;
      }

      for(uint256 i = 0; i < tokensToMint; i++) {
        _safeMint(_msgSender(), currentIndex++);
      }

      _lastPurchased[_msgSender()] = block.timestamp;

      emit TokensMinted(_msgSender(), tokensToMint);
    }

    function validateAndBurn(uint256[] memory tokenIds, address owner) external onlyMega {
      require(tokenIds.length == 5, "Invalid array passed");

      for (uint256 i; i < tokenIds.length; i++) {
        require(ownerOf(tokenIds[i]) == owner, "Not the owner");
        _burn(tokenIds[i]);
      }
    }

    function _validateCreepzOwner(uint256 tokenId, address user) internal view returns (bool) {
      if (!creepzRestriction) return true;
      if (STAKING.ownerOf(address(CREEPZ), tokenId) == user) {
        return true;
      }
      return CREEPZ.ownerOf(tokenId) == user;
    }

    function getTokenPrice(address user, uint256 amount) internal view returns (uint256) {
      uint256 minted = _mintedByAddress[user];
      
      if (minted > 0) return _regularPrice.mul(amount);
      if (minted == 0 && amount > BASE_RATE_TOKENS) return _basePrice.add(amount.sub(1).mul(_regularPrice));
      return _basePrice;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      uint256 amount = _salePrice.mul(ROYALTY_SIZE).div(ROYALTY_DENOMINATOR);
      address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
      return (royaltyReceiver, amount);
    }

    function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
      _royaltyReceivers[tokenId] = receiver;
    }

    function updateSaleStatus(bool status) public onlyOwner {
      saleIsActive = status;
    }

    function updateBasePrice(uint256 _newPrice) public onlyOwner {
      require(!saleIsActive, "Pause sale before price update");
      _basePrice = _newPrice;
    }

    function updateRegularPrice(uint256 _newPrice) public onlyOwner {
      require(!saleIsActive, "Pause sale before price update");
      _regularPrice = _newPrice;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
      require(bytes(PROVENANCE_HASH).length == 0, "Provenance hash has already been set");
      PROVENANCE_HASH = provenanceHash;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
      require(!metadataFinalised, "Metadata already finalised");

      string memory currentURI = _shapesBaseURI;
      _shapesBaseURI = newBaseURI;
      emit BaseUriUpdated(currentURI, newBaseURI);
    }

    function finalizeStartingIndex() public onlyOwner returns (bytes32 requestId) {
      require(!startingIndexSet, 'startingIndex already set');

      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
      return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        startingIndex = (randomness % MAX_SUPPLY);
        startingIndexSet = true;
        emit StartingIndexFinalized(startingIndex);
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      return string(abi.encodePacked(_shapesBaseURI, tokenId.toString()));
    }

    function finalizeMetadata() public onlyOwner {
      require(!metadataFinalised, "Metadata already finalised");
      metadataFinalised = true;
    }

    function updateCreepzRestriction(bool _restrict) public onlyOwner {
      creepzRestriction = _restrict;
    }

    function updatePurchaseTimeout(uint256 _timeoutInSeconds) public onlyOwner {
      _purchaseTimeout = _timeoutInSeconds;
    }

    function updateMaxToMint(uint256 _max) public onlyOwner {
      _maxToMint = _max;
    }

    function setMegaAddress(address _megaAddress) public onlyOwner {
      require(_megaAddress != address(0), "Cannot assign zero address");
      MEGA = _megaAddress;
    }

    function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(owner()).transfer(balance);
    }
}