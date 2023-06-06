//
//
//                                      ,╔φ▒╠▒▒▒
//                                   ,φ╠░▒▒▒▒▒▒▒
//                                 ,▒░░░░░▒▒▒▒▒▒ε
//                                φ░░░░░░▒▒▒▒▒▒▒╠
//                               φ░░░░░░░▒▒▒▒▒▒▒╠
//               ,≤φ░░░░░φφφ≡,   ░░░░░░░▒▒▒▒▒▒▒▒╠
//            ;φ░░░░░░░░░░░░░Γ  «░░░░░░▒▒▒▒▒▒▒▒╠╠
//         ;░░░░░░░░░░░░░░░░░[  )░░░░░▒▒▒▒▒▒▒▒▒╠╠
//      ,░░░░░░░░░░░░░░░░░░░╠"      ╙▒▒▒▒▒▒▒▒▒╠╠
//    ≤░░░░░░░░░░░░░░░░░░░░╚  ╔╠░░φ,  ▒▒▒▒▒▒▒╠╩
//     ⁿ░░││││░░░░░░░░░░░░░ε  ░░░░░▒   `╙╠▒▒╩
//       "░'\││░░░░░░░░░░░░╚  `╙╩╩"  ╓╓
//           ""░░░░░░░≥="    ,-   ,╔╠▒▒▒╠╦
//                        ,φ▒░░░▒▒▒▒▒▒▒▒▒▒╠╦
//                        ░░░░░░░▒▒▒▒▒▒▒▒▒╠╠╬
//                        `░░░░░▒▒▒▒▒▒▒▒╠╠╠╠╠╠
//                         "░░░░▒▒▒▒▒▒╠╠╠╠╠╠╠╠╬
//                           ╚░░▒▒▒▒╠╠╠╠╠╠╠╠╠╠╠
//                             "╩▒▒╠╠╠╠╠╠╠╠╠╠╠╠
//                                 "╚╠╠╠╠╠╠╠╠╠╩
//                                      "╙╝╠╠╩
//
//
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./License.sol";


contract SunflowerArtV2 is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable {

  string public artCode;
  string public artCodeDependencies; //e.g. [email protected]
  string public artDescription;
  bool public isArtCodeSealed;

  uint256 public currentTokenID;
  uint256 public maxTokens;
  uint256 public tokenPrice;

  string public tokenBaseURI;
  string public extraStringArtist;
  string public extraStringPlatform;

  // Address that can mint when paused, intended to be the address of another contract.
  address public privilegedMinterAddress; //

  address payable public artistFundsAddress;
  address public artistAddress; // Deployer address is the artist.
  uint256 private artistBalance; // For safety with arbitrary address, use withdrawal mechanism.
  address payable constant platformAddress = payable(0xf0bE1F2FB8abfa9aBF7d218a226ef4F046f09a40);

  uint256 public sunflowerMintPercent; // e.g. 10 for %10
  uint256 public sunflowerTokenRoyalty; // e.g. 31 for every 31th token
  uint256 public artistTokenRoyalty;

  address constant public sunflowerPreviousVersionContractAddress = 0xD58434F33a20661f186ff67626ea6BDf41B80bCA;
  uint256 constant public sunflowerContractVersion = 2;

  // Block hashes are determined at mint time.
  // The seed corresponding to a token can only be accesed one block after, and is equal to keccak256(blockhash ^ tokenID)
  mapping(uint256 => bytes32) internal blockhashForToken;

  // Want "initialize" so can use proxy
  function initialize(string memory _name, string memory _symbol, uint256 _maxTokens, uint256 _tokenPrice, address _artistFundsAddress, uint256 _artistTokenRoyalty) public initializer {
    __ERC721_init(_name, _symbol);
    __ERC721Enumerable_init_unchained();
    __Ownable_init();
    __Pausable_init();

    isArtCodeSealed = false;

    // Fixed, but can be adjusted for each proxy contract with setPlatformFields.
    sunflowerMintPercent = 29;
    sunflowerTokenRoyalty = 31; // Every 31th token, so 3.22%. Use a prime to reduce collisions.
    artistBalance = 0;

    tokenBaseURI = "";

    // Use these methods so the checks of those methods will run.
    setArtistFields(_artistTokenRoyalty);
    setMaxTokens(_maxTokens);
    setTokenPrice(_tokenPrice);

    currentTokenID = 0;

    artistFundsAddress = payable(_artistFundsAddress);
    privilegedMinterAddress = address(0);
    artistAddress = owner(); // initialize to the deployer address, and don't let it be changed

    pauseNormalMinting();
  }

  // Guarantee every seed is different, and make it impractical to predict, by XORing with tokenID.
  function seedForToken(uint256 tokenID) public view returns (uint256) {
    require(_exists(tokenID), "Nonexistant token");
    bytes32 intermediate = bytes32(tokenID) ^ blockhashForToken[tokenID];
    bytes32 hashed = keccak256(abi.encodePacked(intermediate));
    uint256 seed = uint256(hashed);
    return seed;
  }

  // Base minting function. Ensures only maxTokens can ever be minted. MaxTokens can only be set before the contract is sealed.
  function _mintBase(address _recipient, uint256 _tokenID) internal {
    requireSealed();
    require(_tokenID < maxTokens, "Max number of tokens minted");
    _safeMint(_recipient, _tokenID);
    blockhashForToken[_tokenID] = blockhash(block.number - 1);
  }
  function _generalMint(address _recipient) internal {
    // Skip token if it's meant for platform or artist royalties.
    if (((sunflowerTokenRoyalty != 0) && ((currentTokenID % sunflowerTokenRoyalty) == 0)) || ((artistTokenRoyalty != 0) && ((currentTokenID % artistTokenRoyalty) == 0))) {
      currentTokenID = currentTokenID + 1;
      _generalMint(_recipient);
      return;
    }

    // Mint currentTokenID
    _mintBase(_recipient, currentTokenID);
    currentTokenID = currentTokenID + 1;

    // Handle payment
    require(msg.value == tokenPrice, "Tx value incorrect");
    uint256 sunflowerFee = (sunflowerMintPercent * 100 * msg.value) / (100*100);
    uint256 artistAmount = msg.value - sunflowerFee;

    // Trusted address
    platformAddress.transfer(sunflowerFee);
    // Add to artist balance
    artistBalance += artistAmount;
  }
  function mintRoyalties() public {
    requireSealed();
    require(currentTokenID >= maxTokens - 2, "Max tokens not yet reached");
    if (artistTokenRoyalty != 0) {
      for (uint256 i =0; i<maxTokens; i+= artistTokenRoyalty) {
        // Avoid numbers where (i % sunflowerTokenRoyalty == 0) && (i % artistTokenRoyalty == 0)
        if ((i % sunflowerTokenRoyalty) != 0) {
          _mintBase(artistFundsAddress, i);
        }
      }
    }
    if (sunflowerTokenRoyalty != 0) {
      for (uint256 i =0; i<maxTokens; i+= sunflowerTokenRoyalty) {
        _mintBase(platformAddress, i);
      }
    }
  }
  // Standard minting function. Requires msg.value==tokenPrice and mintingNotPaused.
  function mintToken() public payable {
    requireMintingNotPaused();
    _generalMint(msg.sender);
  }
  // Mint for owner, ignoring pause status. Requires msg.value==tokenPrice and owner.
  function mintTokenOwner() public payable {
    requireOwner();
    _generalMint(msg.sender);
  }
  // Mintable by privilegedMinterAddress, ignoring pause status.
  function mintTokenPrivileged(address _recipient) public payable {
    require(privilegedMinterAddress != address(0));
    require(msg.sender == privilegedMinterAddress);
    _generalMint(_recipient);
  }
  function withdrawArtistBalance() public {
    uint256 balanceToSend = artistBalance;
    artistBalance = 0;
    artistFundsAddress.transfer(balanceToSend);
  }

  // Pause and unpause
  function pauseNormalMinting() public {
    requireOwner();
    _pause();
  }
  function resumeNormalMinting() public {
    requireOwner();
    _unpause();
  }
  function requireMintingNotPaused() internal view whenNotPaused {}

  // Fields that are adjustable any time.
  function setTokenPrice(uint256 _tokenPrice) public {
    requireOwner();
    tokenPrice = _tokenPrice;
    require(_tokenPrice == 0 || artistTokenRoyalty == 0);
  }
  function setPrivilegedMinterAddress(address _privilegedMinterAddress) public {
    // RequirePlatform
    requirePlatform();
    privilegedMinterAddress = _privilegedMinterAddress;
  }

  // Fields that are only adjustable before sealing.
  function setPlatformFields(uint256 _sunflowerMintPercent, uint256 _sunflowerTokenRoyalty) public {
    requirePlatform();
    requireNotSealed();
    sunflowerMintPercent = _sunflowerMintPercent;
    sunflowerTokenRoyalty = _sunflowerTokenRoyalty;
  }
  function setArtistFields(uint256 _artistTokenRoyalty) public {
    requireOwner();
    requireNotSealed();
    require((_artistTokenRoyalty == 0) || (((_artistTokenRoyalty % sunflowerTokenRoyalty) != 0) && (_artistTokenRoyalty > 2)), "See requirements for artistTokenRoyalty");
    artistTokenRoyalty = _artistTokenRoyalty;
    require(tokenPrice == 0 || _artistTokenRoyalty == 0);
  }
  function setMaxTokens(uint256 _maxTokens) public {
    requireOwner();
    requireNotSealed();
    maxTokens = _maxTokens;
  }
  function setArtCode(string memory _artCode, string memory _artCodeDependencies, string memory _artDescription) public {
    requireOwner();
    requireNotSealed();
    artCode = _artCode;
    artCodeDependencies = _artCodeDependencies;
    artDescription = _artDescription;
  }

  // Seal the art code. Disables many functions of the contract
  function sealArtCode() public {
    requireOwner();
    requireNotSealed();
    require((bytes(artCode).length != 0) && (bytes(artCodeDependencies).length != 0) && (bytes(artDescription).length != 0), "Art not fully set.");
    isArtCodeSealed = true;
  }
  function requireNotSealed() internal view {
    require(isArtCodeSealed == false, "Art is sealed");
  }
  function requireSealed() internal view {
    require(isArtCodeSealed == true, "Art is not sealed");
  }

  // Functions for token URI and other strings that provide extra context (e.g. social links that may change, IPFS links to contract ABI, etc.). Can be set anytime.
  function _baseURI() internal view override returns (string memory) {
    return tokenBaseURI;
  }
  function setBaseURI(string memory _tokenBaseURI) public {
    requireOwner();
    tokenBaseURI = _tokenBaseURI;
  }
  function setExtraStringArtist(string memory _extraStringArtist) public {
    requireOwner();
    extraStringArtist = _extraStringArtist;
  }
  function setExtraStringPlatform(string memory _extraStringPlatform) public {
    requirePlatform();
    extraStringPlatform = _extraStringPlatform;
  }

  // Convert any modifiers to require functions, for readability.
  function requireOwner() internal view onlyOwner {}
  function requirePlatform() internal view {
    require(platformAddress == msg.sender, "Platform only");
  }
}