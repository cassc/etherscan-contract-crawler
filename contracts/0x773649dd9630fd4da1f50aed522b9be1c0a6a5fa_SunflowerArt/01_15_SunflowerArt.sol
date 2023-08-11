// Sunflower Art V1
// V2: 0xb761cef3ac09d249a3f1e79d1facea809b31457e

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


contract SunflowerArt is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable {

  uint256 public sunflowerPercent;
  string public tokenBaseURI;
  bool public isArtCodeSealed;
  string public artCode;
  string public artCodeDependencies; //e.g. [email protected] w/ hash;
  string public artDescription;

  uint256 currentTokenID;
  uint256 public maxTokens;
  uint256 public tokenPrice;

  address payable public artistAddress;
  address payable constant platformAddress = payable(0xf0bE1F2FB8abfa9aBF7d218a226ef4F046f09a40);

  // Block hashes are determined at mint time.
  // The seed corresponding to a token can only be accesed one block after, and is equal to keccak256(blockhash + tokenID)
  mapping(uint256 => bytes32) internal blockhashForToken;

  // Want "initialize" so can use proxy
  function initialize(string memory _name, string memory _symbol, uint256 _maxTokens, uint256 _tokenPrice, address _artistAddress) public initializer {
    __ERC721_init(_name, _symbol);
    __ERC721Enumerable_init_unchained();
    __Ownable_init();
    __Pausable_init();
    isArtCodeSealed = false;
    sunflowerPercent = 10;
    tokenBaseURI = "";

    maxTokens = _maxTokens;
    tokenPrice = _tokenPrice;
    currentTokenID = 0;

    artistAddress = payable(_artistAddress);

    pauseMinting();
  }

  // If set blockhashForToken to blockNumber-1, minters will have 10-20s to decide whether they want a work and mint it. This is not as good as a reveal (which would require minter to call the contract again within 256 blocks), but is a good starting point.
  function seedForToken(uint256 tokenID) public view returns (uint256) {
    require(_exists(tokenID), "Token does not exist.");
    bytes32 intermediate = bytes32(tokenID) ^ blockhashForToken[tokenID];
    bytes32 hashed = keccak256(abi.encodePacked(intermediate));
    uint256 seed = uint256(hashed);
    return seed;
  }

  // Minting function
  function _mintBase() internal {
    require(currentTokenID < maxTokens, "Max number of tokens minted.");
    require(isArtCodeSealed == true, "Art code has not been sealed.");
    require(msg.value == tokenPrice, "Transaction value incorrect.");
    _safeMint(msg.sender, currentTokenID);
    blockhashForToken[currentTokenID] = blockhash(block.number - 1);

    uint256 sunflowerFee = (sunflowerPercent * 100 * msg.value) / (100*100);
    uint256 artistAmount = msg.value - sunflowerFee;

    currentTokenID = currentTokenID + 1;

    platformAddress.transfer(sunflowerFee);
    artistAddress.transfer(artistAmount);
  }
  // Mint for owner, ignoring pause status
  function mintTokenOwner() public payable onlyOwner {
    _mintBase();
  }
  // Only mintable when not paused
  function mintToken() public payable whenNotPaused {
    _mintBase();
  }


  function pauseMinting() public onlyOwner {
    _pause();
  }
  function resumeMinting() public onlyOwner {
    _unpause();
  }
  function adjustPrice(uint256 _tokenPrice) public onlyOwner {
    require(msg.sender == platformAddress, "Platform only");
    tokenPrice = _tokenPrice;
  }

  function setArtCode(string memory _artCode, string memory _artCodeDependencies, string memory _artDescription) public onlyOwner {
    require(isArtCodeSealed == false, "Art code is sealed.");
    artCode = _artCode;
    artCodeDependencies = _artCodeDependencies;
    artDescription = _artDescription;
  }
  function sealArtCode() public onlyOwner {
    require(isArtCodeSealed == false, "Art code is already sealed.");
    require(bytes(artCode).length != 0, "No art code set.");
    require(bytes(artCodeDependencies).length != 0, "No art code deps. set.");
    require(bytes(artDescription).length != 0, "No art code description set.");
    isArtCodeSealed = true;
  }

  // Changing the token URI
  function _baseURI() internal view override returns (string memory) {
    return tokenBaseURI;
  }
  function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
    tokenBaseURI = _tokenBaseURI;
  }
}