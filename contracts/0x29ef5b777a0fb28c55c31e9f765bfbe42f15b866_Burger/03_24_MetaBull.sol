//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Burger.sol";

error MintingNotActive();
error AstrobullAlreadyClaimed();

/**
 * @title Metabulls
 * @author Matt Carter
 * June 6, 2022
 *
 * This contract is an implementation of chiru lab's erc721a contract and is used for minting
 * 3d metaverse bulls. To mint a metabull, an account will input tokenIds of astrobulls
 * they are using to claim; meaning the account must own each astrobull or be the staker of it,
 * and each astrobull can only be used once. The contract will store which astrobull traits to
 * give each metabull. Users will burn burgers for each metabull they mint.
 */
contract MetaBull is ERC721A, Ownable {
  using Strings for uint256;
  /// contract instances ///
  Burger public immutable BurgerContract;
  Grill2 public immutable GrillContract;
  ISUPER1155 public constant Astro =
    ISUPER1155(0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af);
  address public constant OldGrill = 0xE11AF478aF241FAb926f4c111d50139Ae003F7fd;
  /// if minting is active ///
  bool public isMinting;
  /// if tokens are revealed ///
  bool public isRevealed;
  /// the number of burgers to burn each mint ///
  uint256 public burnScalar = 2;
  /// the number of burgers burned by this contract ///
  uint256 public totalBurns;
  /// the base uri for all tokens ///
  string public URI;
  /// if an astrobull has been claimed for yet ///
  mapping(uint256 => bool) public portedIds;
  /// which astrobull traits to give each metabull ///
  mapping(uint256 => uint256) public portingMeta;
  /// the number of burgers each account has burned ///
  mapping(address => uint256) public accountBurns;

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Sets the initial base uri and address for the burger contract
   * @param _URI The baseURI for each token
   * @param burgerAddr The address of the burger contract
   * @param grillAddr The address of the grill contract
   */
  constructor(
    string memory _URI,
    address burgerAddr,
    address grillAddr
  ) ERC721A("METABULLS", "MBULL") {
    URI = _URI;
    BurgerContract = Burger(burgerAddr);
    GrillContract = Grill2(grillAddr);
  }

  /// ============ INTERNAL ============ ///

  /**
   * Overrides tokens to start at index 1 instead of 0
   * @return _id The tokenId of the first token
   */
  function _startTokenId() internal pure override returns (uint256 _id) {
    _id = 1;
  }

  /// ============ OWNER ============ ///

  /**
   * Sets a new base URI for tokens
   * @param _URI The new baseURI for each token
   */
  function setURI(string memory _URI) public onlyOwner {
    URI = _URI;
  }

  /**
   * Toggles if minting is allowed.
   */
  function toggleMinting() public onlyOwner {
    isMinting = !isMinting;
  }

  /**
   * Toggles if tokens are revealed.
   */
  function toggleReveal() public onlyOwner {
    isRevealed = !isRevealed;
  }

  /**
   * Sets the quantity of burgers an account must burn to mint each metabull
   * @param _burnScalar The number of burgers to burn
   */
  function setBurnScalar(uint256 _burnScalar) public onlyOwner {
    burnScalar = _burnScalar;
  }

  /**
   * Mints `quantity` tokens to `account`
   * @param quantity The number of tokens to mint
   * @param account The address to mint the tokens to
   * @notice Each token an owner mints will point to a 0 in the portingMeta mapping
   * since it does not share traits with a minted astrobull
   */
  function ownerMint(uint256 quantity, address account) public onlyOwner {
    _safeMint(account, quantity);
  }

  /// ============ PUBLIC ============ ///

  /**
   * Mints a metabull for each astrobull input
   * @param astrobullIds An array of astrobull IDs caller is claiming metabulls for
   * @notice The caller must own each astrobull ID they are claiming for; meaning it must
   * be removed from the grill before use
   */
  function claimBull(uint256[] memory astrobullIds) public {
    if (!isMinting) {
      revert MintingNotActive();
    }
    /// @dev gets the first tokenId being minted ///
    uint256 currentIndex = _currentIndex;
    for (uint256 i = 0; i < astrobullIds.length; ++i) {
      if (!_checkOwnerShip(msg.sender, astrobullIds[i])) {
        revert CallerNotTokenOwner();
      }
      if (portedIds[astrobullIds[i]]) {
        revert AstrobullAlreadyClaimed();
      }
      /// @dev sets the astrobull traits to give each metabull being minted ///
      portingMeta[currentIndex] = astrobullIds[i];
      /// @dev sets contract state ///
      portedIds[astrobullIds[i]] = true;
      /// @dev sets the next tokenId being minted ///
      currentIndex += 1;
    }
    /// burn caller's burgers ///
    uint256 toBurn = burnScalar * astrobullIds.length;
    BurgerContract.burnBurger(msg.sender, toBurn);
    /// sets contract state ///
    totalBurns += toBurn;
    accountBurns[msg.sender] += toBurn;
    /// mint metabulls to caller ///
    _safeMint(msg.sender, astrobullIds.length);
  }

  /// ============ INTERNAL ============ ///

  /**
   * Checks if `account` is the owner or staker of `tokenId`
   * @param account The address to check ownership for
   * @param tokenId The tokenId to check ownership of
   * @return _b If `account` is the owner or staker of `tokenId`
   */
  function _checkOwnerShip(address account, uint256 tokenId)
    internal
    view
    returns (bool _b)
  {
    _b = false;
    /// @dev first checks if account owns token ///
    if (Astro.balanceOf(account, tokenId) == 1) {
      _b = true;
    }
    /// @dev next, checks if token is staked in the old grill and caller is staker ///
    else if (Astro.balanceOf(address(OldGrill), tokenId) == 1) {
      if (GrillContract.stakeStorageOld(tokenId).staker == account) {
        _b = true;
      }
    }
    /// @dev last, checks if token is staked in current grill and caller is staker ///
    else if (GrillContract.stakeStorageGetter(tokenId).staker == account) {
      _b = true;
    }
  }

  /// ============ READ-ONLY ============ ///

  /**
   * Gets a token's URI
   * @param _tokenId The tokenId to lookup
   * @return _URI The token's uri
   */
  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory _URI)
  {
    if (isRevealed) {
      _URI = string(abi.encodePacked(URI, _tokenId.toString(), ".json"));
    } else {
      _URI = URI;
    }
  }
}