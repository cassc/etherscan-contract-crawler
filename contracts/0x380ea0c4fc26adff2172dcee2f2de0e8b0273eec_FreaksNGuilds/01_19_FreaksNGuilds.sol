// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/Interfaces.sol";
import "./interfaces/Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "erc721a/contracts/ERC721A.sol";
import "../base/controllable.sol";

contract FreaksNGuilds is Controllable, Pausable, Ownable, ERC721A("Freaks N Guilds", "FnG") {
  using MerkleProof for bytes32[];

  /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

  bytes32 internal entropySauce;
  bytes32 public whitelistRoot;

  uint256 public constant FNG_PRICE_ETH_PUBLIC = 0.099 ether;
  uint256 public constant FNG_PRICE_ETH_WHITELIST = 0.09 ether;
  uint256 public constant FNG_PRICE_ETH_HOLDERS = 0.07 ether;
  uint256 public constant FNG_PRICE_FBX = 1000 ether;

  IFBX public fbx;
  ICKEY public ckey;
  IVAULT public vault;

  uint256 public maxSupply;
  uint256 public maxCelestialSupply;
  uint256 public celestialSupply;
  uint256 public freakSupply;
  uint256 public saleState;
  uint256 public maxWlMints;
  uint256 public maxPubMints;

  uint8 internal cBody = 1;
  uint8 internal cLevel = 1;
  uint8 internal cPP = 1;
  uint8 internal offHand = 0;

  mapping(uint256 => Freak) public freaks;
  mapping(uint256 => Celestial) public celestials;

  /// mapping of token ids to bool indicating whether the key has been used to mint
  mapping(uint256 => bool) public redeemedCKEYs;
  /// mapping of whitelisted addresses indicating quantity minted through whitelist mint
  mapping(address => uint256) public whitelistMinted;
  /// mapping of public addresses indicating quantity minted through public mint
  mapping(address => uint256) public publicMinted;

  MetadataHandlerLike public metadaHandler;

  /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

  modifier noCheaters() {
    uint256 size = 0;
    address acc = msg.sender;
    assembly {
      size := extcodesize(acc)
    }

    require(msg.sender == tx.origin, "you're trying to cheat!");
    require(size == 0, "you're trying to cheat!");
    _;

    // We'll use the last caller hash to add entropy to next caller
    entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
  }



  /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/
  constructor(
    uint256 _maxSupply,
    uint256 _maxCelestialSupply,
    address _fbx,
    address _ckey,
    address _metadataHandler,
    address _vault,
    bytes32 _whitelistRoot
  ) {
    maxSupply = _maxSupply;
    maxCelestialSupply = _maxCelestialSupply;
    fbx = IFBX(_fbx);
    ckey = ICKEY(_ckey);
    vault = IVAULT(_vault);
    metadaHandler = MetadataHandlerLike(_metadataHandler);
    whitelistRoot = _whitelistRoot;
    maxWlMints = 2;
    maxPubMints = 4;
    _pause();
  }

  /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /// @dev Call the `metadaHandler` to retrieve the tokenURI for each character.
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "token does not exist");
    if (!isFreak(id)) {
      // Celestial
      Celestial memory celestial = celestials[id];
      return metadaHandler.getCelestialTokenURI(id, celestial);
    } else if (isFreak(id)) {
      // Freak
      Freak memory freak = freaks[id];
      return metadaHandler.getFreakTokenURI(id, freak);
    } else {
      return ""; // placeholder for compile
    }
  }

  /*///////////////////////////////////////////////////////////////
                   MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /// @notice Buy one or more tokens with ETH.
  function mintWithETH(uint256 amount) external payable noCheaters whenNotPaused {
    uint256 supply = _currentIndex;
    require(supply + amount <= maxSupply + 1, "maximum supply reached");
    if (msg.sender != owner()) {
      require(amount > 0 && amount + publicMinted[msg.sender] <= maxPubMints, "Invalid quantity");
      require(saleState == 2, "Mint stage not live");
      require(msg.value >= amount * FNG_PRICE_ETH_PUBLIC, "invalid ether amount");
    }
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      uint256 rNum = rand % 100;
      if (rNum < 15 && celestialSupply < 1500) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      supply += 1;
    }
    _mint(msg.sender, amount, "", false);
    publicMinted[msg.sender] += amount;
  }

  /// @notice Buy one or more tokens with ETH while holding celestial key.
  function mintWithETHHoldersOnly(uint256[] memory ckeyIds) external payable noCheaters whenNotPaused {
    require(saleState != 2, "Mint stage not live");
    uint256 supply = _currentIndex;
    uint256 amount = ckeyIds.length;
    require(amount > 0, "invalid token ID");
    require(supply + amount <= maxSupply + 1, "maximum supply reached");
    if (msg.sender != owner()) {
      require(msg.value >= amount * FNG_PRICE_ETH_HOLDERS, "invalid ether amount");
    }
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      require(msg.sender == ckey.ownerOf(ckeyIds[i]) || vault._depositedBlocks(msg.sender, ckeyIds[i]) != 0, "invalid token ID");
      require(!redeemedCKEYs[ckeyIds[i]], "token already used to mint");
      redeemedCKEYs[ckeyIds[i]] = true;
      uint256 rNum = rand % 100;
      if (rNum < 15 && celestialSupply < 1500) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      supply += 1;
    }
    _mint(msg.sender, amount, "", false);
  }

  /// @notice Buy one or more tokens with ETH with whitelisted address
  function mintWithETHWhitelist(uint256 amount, bytes32[] memory proof) external payable whenNotPaused {
    require(saleState == 1, "Mint stage not live");
    uint256 supply = _currentIndex;
    require(supply + amount <= maxSupply + 1, "maximum supply reached");
    require(amount > 0 && amount + whitelistMinted[msg.sender] <= maxWlMints, "Invalid quantity for whitelist mint");
    require(msg.value >= amount * FNG_PRICE_ETH_WHITELIST, "invalid ether amount");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(proof.verify(whitelistRoot, leaf), "Invalid proof");
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      uint256 rNum = rand % 100;
      if (rNum < 15 && celestialSupply < 1500) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      supply += 1;
    }
    _mint(msg.sender, amount, "", false);
    whitelistMinted[msg.sender] += amount;
  }

  /// @notice Buy one or more tokens with FBX.
  function mintWithFBX(uint256 amount) external noCheaters whenNotPaused {
    require(saleState != 2, "Mint stage not live");
    uint256 supply = _currentIndex;
    require(supply + amount <= maxSupply + 1, "maximum supply reached");
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      uint256 rNum = rand % 100;
      if (rNum < 15 && celestialSupply < 1500) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      supply++;
    }
    fbx.burn(msg.sender, FNG_PRICE_FBX * amount);
    _mint(msg.sender, amount, "", false);
  }

  function burn(uint256 tokenId) external onlyOwner {
    if(isFreak(tokenId)){
      delete freaks[tokenId];
      freakSupply -= 1;
    }else{
      delete celestials[tokenId];
      celestialSupply -= 1;
    }
    _burn(tokenId);
  }

  function _revealCelestial(uint256 rNum, uint256 id) internal {
    uint256 _rNum = _randomize(rNum, id);
    uint8 healthMod = _calcMod(_rNum);
    _rNum = _randomize(_rNum, id);
    uint8 powMod = _calcMod(_rNum);
    Celestial memory celestial = Celestial(healthMod, powMod, cPP, cLevel);
    celestials[id] = celestial;
    celestialSupply += 1;
  }

  function _revealFreak(uint256 rNum, uint256 id) internal {
    uint256 _rNum = _randomize(rNum, id);
    uint8 species = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 mainHand = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 body = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 power = _calcPow(species, _rNum);
    _rNum = _randomize(_rNum, id);
    uint8 health = _calcHealth(species, _rNum);
    _rNum = _randomize(_rNum, id);
    uint8 armor = uint8((_rNum % 3) + 1); 
    uint8 criticalStrikeMod = 0;
    Freak memory freak = Freak(species, body, armor, mainHand, offHand, power, health, criticalStrikeMod);
    freaks[id] = freak;
    freakSupply += 1;
  }

  /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory) {
    require(_exists(tokenId), "token does not exist");
    return (freaks[tokenId]);
  }

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory) {
    require(_exists(tokenId), "token does not exist");
    return (celestials[tokenId]);
  }

  function isFreak(uint256 tokenId) public view returns (bool) {
    require(_exists(tokenId), "token does not exist");
    return freaks[tokenId].species != 0 ? true : false;
  }

  function getSpecies(uint256 tokenId) external view returns (uint8) {
    require(isFreak(tokenId) == true);
    return freaks[tokenId].species;
  }

  function getTokens(address addr) external view returns (uint256[] memory tokens) {
    uint256 balanceLength = balanceOf(addr);
    tokens = new uint256[](balanceLength);
    uint256 index = 0;
    for (uint256 j =  1; j < _currentIndex; j++) {
      if (ownerOf(j) == addr) {
        tokens[index] = j;
        index += 1;
      }
    }
    return tokens;
  }

  /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

  /// @dev Overriden to start mints at id #1.
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @dev Create a bit more of randomness
  function _randomize(uint256 rand, uint256 spicy) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(rand, spicy)));
  }

  function _rand() internal view returns (uint256) {
    return
      uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
  }

  function _calcMod(uint256 rNum) internal pure returns (uint8) {
    return uint8((rNum % 4) + 5);
  }

  function _calcHealth(uint8 species, uint256 rNum) internal pure returns (uint8) {
    uint8 baseHealth = 90; // ogre
    if (species == 1) {
      baseHealth = 50; // troll
    } else if (species == 2) {
      baseHealth = 70; // fairy
    }
    // might need to cast? we will see...
    return uint8((rNum % 21) + baseHealth);
  }

  function _calcPow(uint8 species, uint256 rNum) internal pure returns (uint8) {
    uint8 basePow = 90; //ogre
    if (species == 1) {
      basePow = 115; // troll
    } else if (species == 2) {
      basePow = 65; //fairy
    }
    // might need to cast? we will see...
    return uint8((rNum % 21) + basePow);
  }

  /*///////////////////////////////////////////////////////////////
                    ADMIN
  //////////////////////////////////////////////////////////////*/

  function setSaleState(uint256 newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice See {ERC721-isApprovedForAll}.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // if (!marketplacesApproved) return auth[operator] || super.isApprovedForAll(owner, operator);
    return
      isController(operator) ||
      // operator == address(ProxyRegistry(opensea).proxies(owner)) ||
      // operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }

  function setMaxMints(uint256 _maxWlMints, uint256 _maxPubMints) external onlyOwner {
    maxWlMints = _maxWlMints;
    maxPubMints = _maxPubMints;
  }

  function setPause(bool _pauseToggle) external onlyOwner {
    if (_pauseToggle == true) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setWhitelistRoot(bytes32 root) external onlyOwner {
    whitelistRoot = root;
  }

  function setContracts(address _fbx, address _ckey, address _vault, address _metadataHandler) external onlyOwner {
    fbx = IFBX(_fbx);
    ckey = ICKEY(_ckey);
    vault = IVAULT(_vault);
    metadaHandler = MetadataHandlerLike(_metadataHandler);
  }

    /// @notice Withdraw `amount` of ether to msg.sender.
  function withdraw(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }

  /// @notice Withdraw `amount` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }

  /// @notice Withdraw `tokenId` of `token` to the sender.
  function withdrawERC721(IERC721 token, uint256 tokenId) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /// @notice Withdraw `tokenId` with amount of `value` from `token` to the sender.
  function withdrawERC1155(
    IERC1155 token,
    uint256 tokenId,
    uint256 value
  ) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, value, "");
  }

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) super._setController(addrs[i], state);
  }
}