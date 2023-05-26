// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LightCultCryptoClub is ERC721Enumerable, Ownable, ReentrancyGuard {

  /**
   * @dev Events
   */

  event Burn(uint256 tokenId, address burner);

  /**
   * @dev Constants
   */

  uint256 public constant TOKEN_LIMIT = 10006;
  uint256 public constant PRESALE_MINT_LIMIT = 5000;
  uint256 private constant _GIVEAWAY_LIMIT = 100;
  uint256 public mintPrice = .06 ether;
  uint256 public constant MAX_MINT_QUANTITY = 20;

  /**
   * @dev Addresses
   */

  address payable constant private _RON_WALLET = payable(0x8e3331BbC9aF9B5fDEAE7e2ea83B207ccf66BC39);
  address payable constant private _1XRUN_WALLET = payable(0xB82cbB2cD0Cb7E29015845A82c18D183fE254C45);
  address payable constant private _DOM_WALLET = payable(0xf331AFba4179FBfEA8464f69e69ea7Fa4cF37474);
  address payable constant private _DEV_WALLET = payable(0x6626a2739959B2355f29184fA0db390920ccFc40);

  /**
   * @dev Variables
   */

  uint256 public saleState = 0; // 0 = closed, 1 = presale tier 1, 2 = presale tier 2, 3 = sale
  bool public burnActive = false;
  string public baseURI;
  string public PROVENANCE_HASH = "";

  // Internal state
  // _presaleAllowance[address] > 0 | tier 2 eligible
  // _presaleAllowance[address] - 1 | remaining tier 1 mints
  mapping(address => uint256) private _presaleAllowance; 
  mapping(uint256 => address) private _tokenIdBurners;

  // For random index
  uint256 private _nonce = 0;
  uint256[TOKEN_LIMIT] private _indices;

  constructor() ERC721("LightCultCryptoClub", "LCCC") {}

  /**
   * General usage
   */

  function _randomMint(address to) private {
    uint256 randomIndex = uint256(keccak256(abi.encodePacked(_nonce, msg.sender, block.difficulty, block.timestamp)));
    _validMint(to, randomIndex);
  }

  function _validMint(address to, uint256 index) private {
    uint256 validIndex = _validateIndex(index);
    _safeMint(to, validIndex);
  }

  function _validateIndex(uint256 indexToValidate) private returns (uint256) {
    uint256 totalSize = TOKEN_LIMIT - totalSupply();
    uint256 index = indexToValidate % totalSize;
    uint256 value = 0;
    if (_indices[index] != 0) {
      value = _indices[index];
    } else {
      value = index;
    }

    if (_indices[totalSize - 1] == 0) {
      _indices[index] = totalSize - 1;
    } else {
      _indices[index] = _indices[totalSize - 1];
    }

    _nonce++;
    return value;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function listTokensForOwner(address owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory result = new uint256[](tokenCount);
    uint256 index;
    for (index = 0; index < tokenCount; index++) {
      result[index] = tokenOfOwnerByIndex(owner, index);
    }
    return result;
  }

  /**
   * Presale eligibility
   */

  function isTierTwoPresaleEligible(address minter) external view returns(bool) {
    return _presaleAllowance[minter] > 0;
  }
 
  function isTierOnePresaleEligible(address minter) external view returns(bool) {
    return _presaleAllowance[minter] > 1;
  }
 
  function presaleAllowanceForAddress(address minter) external view returns(uint) {
    return _presaleAllowance[minter];
  }

  /**
   * Minting
   */

  function mintTokens(uint256 numTokens) external payable nonReentrant {
    require(saleState != 0, "Sale is closed");
    require(numTokens > 0 && numTokens <= MAX_MINT_QUANTITY, "You can only mint 1 to 20 tokens at a time");

    if (saleState == 3) {
      // Open sale
      require(totalSupply() + numTokens <= TOKEN_LIMIT, "LCCC has sold out");
    } else {
      require(totalSupply() + numTokens <= PRESALE_MINT_LIMIT, "The maximum presale tokens have been minted");
      if (saleState == 2) {
        // Tier 2 presale
        require(_presaleAllowance[msg.sender] > 0, "You are not eligible to presale mint");
      } else if (saleState == 1) {
        // Tier 1 presale
        require(_presaleAllowance[msg.sender] - numTokens >= 1, "You cannot mint that many tokens at this time");
        _presaleAllowance[msg.sender] -= numTokens;
      }
    } 

    uint256 totalPrice = mintPrice * numTokens;
    require(msg.value >= totalPrice, "Ether value sent is below the price");

    for (uint256 i = 0; i < numTokens; i++) {
      _randomMint(msg.sender);
    }
  }

  /**
   * Burn
   */

  function burn(uint256 tokenId) external {
    require(burnActive, "You cannot burn at this time");
    require(ownerOf(tokenId) == msg.sender, "You cannot burn a token you do not own");
    _burn(tokenId);
    _tokenIdBurners[tokenId] = msg.sender;
    emit Burn(tokenId, msg.sender);
  }

  function burnerOf(uint256 tokenId) external view returns (address) {
    return _tokenIdBurners[tokenId];
  }

  /**
   * Owner only
   */

  function setProvenanceHash(string calldata provenanceHash) external onlyOwner {
    PROVENANCE_HASH = provenanceHash;
  }

  function editPresaleAllowance(address[] memory addresses, uint256 amount) public onlyOwner {
    for(uint256 i; i < addresses.length; i++){
      _presaleAllowance[addresses[i]] = amount;
    }
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function reserveTokens(uint256[] calldata tokens) external onlyOwner {
    require(saleState == 0, "Sale is not in closed state");
    require(totalSupply() + tokens.length <= _GIVEAWAY_LIMIT, "Exceeded giveaway supply");

    for (uint256 i = 0; i < tokens.length; i++) {
      _validMint(_1XRUN_WALLET, tokens[i]);
    }
  }

  function setMintPrice(uint256 newMintPrice) external onlyOwner {
    mintPrice = newMintPrice;
  }

  function setSaleState(uint256 newState) external onlyOwner {
    saleState = newState;
  }

  function toggleBurnState() external onlyOwner {
    burnActive = !burnActive;
  }

  function withdraw() external onlyOwner {
    uint256 fortyPercentOfBalance = (address(this).balance * 40)/100; // 40.0%
    uint256 twelvePercentOfBalance = (address(this).balance * 12)/100; // 12.0%
    uint256 eightPercentOfBalance = (address(this).balance * 8)/100; // 8.0%
    _RON_WALLET.transfer(fortyPercentOfBalance);
    _1XRUN_WALLET.transfer(fortyPercentOfBalance);
    _DOM_WALLET.transfer(twelvePercentOfBalance);
    _DEV_WALLET.transfer(eightPercentOfBalance);
  }
}