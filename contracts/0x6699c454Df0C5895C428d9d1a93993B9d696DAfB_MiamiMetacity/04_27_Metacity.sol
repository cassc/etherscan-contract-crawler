// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721Opensea.sol";
import "./utils/Helpers.sol";
import "./utils/Security.sol";
import "./Interfaces/IMetacity.sol";
import "./Interfaces/ITraits.sol";
import "./CITY.sol";


contract Metacity is IMetacity, ERC721Opensea, Ownable, Pausable, ReentrancyGuard, Security {

  using ECDSA for bytes32;

  uint256 public startTime = 1669053600; // Monday, November 21, 2022 18:00:00

  // first round
  uint256 public constant firstRoundSupply = 5000;
  uint256 public constant firstRoundPrice = 0.02 ether; // ETH
  uint256 public constant firstRoundMaxWlPerUser = 3;
  // second round
  uint256 public constant secondRoundSupply = 800;
  uint256 public secondRoundPrice = 1 ether; // ETH
  // third round
  uint256 public thirdRoundPrice = 500 ether; // CITY

  uint256 public constant ratChance = 10; // percentage

  uint256 public maxSupply = 15_800;

  // open / close rounds
  bool public firstRoundOpen = true;
  bool public secondRoundOpen = false;
  bool public thirdRoundOpen = false;
  // wl
  bool public wlOnly = true;

  // saving for max per round
  mapping(address => uint256) public firstRoundWlMints;
  mapping(address => bool) public secondRoundMinted;

  // number of tokens that have been minted
  uint16 public totalSupply;
  // mapping from tokenId to an array containing the token's traits
  mapping(uint256 => uint256[]) private tokenTraits;
  // mapping from tokenId to bool isZen
  mapping(uint256 => bool) private isZens;
  // mapping from hashed(tokenTrait) to the tokenId it's associated with
  // used to ensure there are no duplicates
  mapping(uint256 => uint256) public existingCombinations;
  // mint block per token id
  mapping(uint256 => uint256) public mintBlocks;
  // allowed to add traits after mint in game / shop
  mapping(address => bool) public controllers;
  // allowed to sign whitelist addresses
  mapping(address => bool) private signers;
  // reference to $CITY for mint
  CITY public city;
  // reference to Traits
  ITraits public traits;

  /// @dev instantiates contract and rarity tables
  constructor(address _city, address _traits) ERC721Opensea("MetaCity", 'METACITY') { 
    city = CITY(_city);
    traits = ITraits(_traits);
  }

  /** EXTERNAL */

  function mintGen0(uint256 amount, bytes memory sig) external payable nonReentrant whenNotPaused {
    require(block.timestamp >= startTime, "Sale haven't started yet");
    require(firstRoundOpen, "Round is closed");
    require(amount > 0 && totalSupply + amount <= firstRoundSupply, "Round ended");
    require(amount * firstRoundPrice == msg.value, "Invalid payment amount");
    if (wlOnly) {
      require(isWhitelisted(_msgSender(), sig), "Address is not whitelisted");
      require(amount + firstRoundWlMints[_msgSender()] <= firstRoundMaxWlPerUser, "Invalid mint amount"); // max per mint
      firstRoundWlMints[_msgSender()] += amount;
    }

    _mint(amount, ratChance);
  }

  function mintGen1(bytes memory sig) external payable nonReentrant whenNotPaused {
    require(totalSupply >= firstRoundSupply, "Round not started yet");
    require(secondRoundOpen, "Round is closed");
    require(totalSupply + 1 <= (firstRoundSupply + secondRoundSupply), "Round ended");
    require(secondRoundPrice == msg.value, "Invalid payment amount");
    require(!secondRoundMinted[_msgSender()], "Already minted");
    if (wlOnly) {
      require(isWhitelisted(_msgSender(), sig), "Address is not whitelisted");
    }
    secondRoundMinted[_msgSender()] = true;

    _mint(1, 100);
  }

  function mintGen2(uint256 amount) external nonReentrant whenNotPaused {
    require(thirdRoundOpen, "Round is closed");
    require(totalSupply >= (firstRoundSupply + secondRoundSupply), "Round not started yet");
    require(amount > 0 && totalSupply + amount <= maxSupply, "Round ended");

    // payment
    uint256 totalCityCost = amount * thirdRoundPrice;
    city.transferFrom(_msgSender(), address(this), totalCityCost);

    _mint(amount, ratChance);
  }

  function _mint(uint256 amount, uint256 _ratChance) internal {
    uint256 seed;
    for (uint i = 0; i < amount; i++) {
      totalSupply++;
      seed = Helpers.random(totalSupply);
      bool _isZen = (seed & 0xFFFF) % 100 >= _ratChance; // % getting a rat
      generate(totalSupply, seed, _isZen);
      mintBlocks[totalSupply] = block.number;
      _safeMint(_msgSender(), totalSupply);
    }
  }

  /** INTERNAL */

  /**
   * generates traits for a specific token, checking to make sure it's unique
   * @param tokenId the id of the token to generate traits for
   * @param seed a pseudorandom 256 bit number to derive traits from
   */
  function generate(uint256 tokenId, uint256 seed, bool _isZen) internal {
    uint256[] memory t = traits.selectTraits(seed, _isZen);
    isZens[tokenId] = _isZen;
    if (_isZen) { // zens are unique
      uint256 traitsHash = uint256(keccak256(abi.encodePacked(t)));
      if (existingCombinations[traitsHash] == 0) {
        tokenTraits[tokenId] = t;
        existingCombinations[traitsHash] = tokenId;
        return;
      } else {
        return generate(tokenId, Helpers.random(seed), _isZen);
      }
    } else {
      tokenTraits[tokenId] = t;
      return;
    }
  }

  function setTrait(uint256 tokenId, uint256 traitIdx, uint256 traitValue) external {
    require(controllers[_msgSender()], "Only controllers can add traits");
    require(tokenTraits[tokenId].length >= traitIdx, "Trait index invalid");

    if (tokenTraits[tokenId].length == traitIdx) { // new trait
      tokenTraits[tokenId].push(traitValue);
    } else { // edit trait
      tokenTraits[tokenId][traitIdx] = traitValue;
    }
  }

  function getTokenTraits(uint256 tokenId) external view override returns (uint256[] memory) {
    require(mintBlocks[tokenId] < block.number, "Reavel only the next block");
    return tokenTraits[tokenId];
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    require(mintBlocks[tokenId] < block.number, "Reavel only the next block");
    return traits.tokenURI(tokenId);
  }

  function level(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Query for nonexistent token");
    require(mintBlocks[tokenId] < block.number, "Reavel only the next block");
    return traits.level(tokenId);
  }

  function isZen(uint256 tokenId) public view override returns (bool) {
    require(_exists(tokenId), "Query for nonexistent token");
    require(mintBlocks[tokenId] < block.number, "Reavel only the next block");
    return isZens[tokenId];
  }

  /// @dev check if an address was off chain whitelisted
  /// @param account the address to check
  /// @return isValid boolean
  function isWhitelisted(address account, bytes memory sig) public view returns (bool isValid) {
    return signers[keccak256(abi.encodePacked(account)).toEthSignedMessageHash().recover(sig)];
  }

  /** ADMIN */
  /**
   * @param _traits the address of the Traits
   */
  function setTraits(address _traits) external onlyOwner {
    traits = ITraits(_traits);
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw(address token) external onlyOwner {
    if (token == address(0))
      payable(owner()).transfer(address(this).balance);
    else
      CITY(token).transfer(owner(), CITY(token).balanceOf(address(this)));
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /// @dev // add list of addresses that can sign
    /// @param accounts list of addresses
    function addSigners(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            if (accounts[i] != address(0)) {
                signers[accounts[i]] = true;
            }
        }
    }

    /// @dev // remove address that can sign
    /// @param account address to remove from signers
    function removeSigner(address account) external onlyOwner {
        signers[account] = false;
    }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  function setFirstRoundOpen(bool _isOpen) external onlyOwner {
    firstRoundOpen = _isOpen;
  }

  function setSecondRoundOpen(bool _isOpen) external onlyOwner {
    secondRoundOpen = _isOpen;
  }

  function setThirdRoundOpen(bool _isOpen) external onlyOwner {
    thirdRoundOpen = _isOpen;
  }

  function setWlOnly(bool _wlOnly) external onlyOwner {
    wlOnly = _wlOnly;
  }

  function setStartTime(uint256 _startTime) external onlyOwner {
    startTime = _startTime;
  }

  function setSecondRoundPrice(uint256 _secondRoundPrice) external onlyOwner {
    secondRoundPrice = _secondRoundPrice;
  }

  function setThirdRoundPrice(uint256 _thirdRoundPrice) external onlyOwner {
    thirdRoundPrice = _thirdRoundPrice;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    require(_maxSupply < maxSupply, "max supply can only be reduced");
    maxSupply = _maxSupply;
  }
}