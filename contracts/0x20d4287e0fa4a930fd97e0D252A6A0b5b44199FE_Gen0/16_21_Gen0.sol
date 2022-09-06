// SPDX-License-Identifier: MIT

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@             /@@@@@@@@@/             @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@         *@@@@@@@@@@@@@@@@@@@@@@@,         @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@#        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@       @@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@
@@@@@@@@@@@@@       @@&@@@((*,,,, *(((((((*((((((@@@@@@@@@@@@       @@@@@@@@@@@@
@@@@@@@@@@@@      @,@@@@#           .                 @@@@@@@@@      @@@@@@@@@@@
@@@@@@@@@@@      @@@@&&@                                @@@@@@@@      @@@@@@@@@@
@@@@@@@@@@      @@@@@@@@%          %%%%%%%%%%%%%%       @@@@@@@@@      @@@@@@@@@
@@@@@@@@@@     /@@@@@@@(@/       #/%@@@@@@@@@@@@@       @@@@@@@@@      @@@@@@@@@
@@@@@@@@@.     @@@@@@@@&@*   .   #@@@@@@@@@@@@@@@       @@@@@@@@@@     &@@@@@@@@
@@@@@@@@@      @@@@@@@@@@&       #@@@@@@@@@@@@@@@       @@@@@@@@@@      @@@@@@@@
@@@@@@@@@.     @@@@@@@@&@%   .   #@@                    @@@@@@@@@@     &@@@@@@@@
@@@@@@@@@@     *@@@@@%@@@@       #@&@#      .          @@@@@@@@@@      @@@@@@@@@
@@@@@@@@@@      @@@@@@@@@@       #@@@@@@           [email protected]@@@@@@@@@@@@      @@@@@@@@@
@@@@@@@@@@@      @@@@@@@@@      .#@@@@@@@@         @@@@@@@@@@@@@      @@@@@@@@@@
@@@@@@@@@@@@      @@@@@@@@       #@@@@@@@@@@         @@@@@@@@@%      @@@@@@@@@@@
@@@@@@@@@@@@@       @@@@@@       #@@@@@@@@@@@@         @@@@@@       @@@@@@@@@@@@
@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@              (@@@@@@@(              @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,               (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
pragma solidity 0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "./BaseOwnableERC721Upgradeable.sol";

contract Gen0 is Initializable, BaseOwnableERC721Upgradeable, ERC2981 {
  uint256 public MAX_SUPPLY;
  uint256 public CURATED_SUPPLY_REMAINING;

  mapping(address => uint256) public curatedList;

  // solhint-disable-next-line no-empty-blocks
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _customBaseURI,
    uint256 _tokensMaxSupply,
    uint256 _tokensReservedCurated,
    address _contractOwner,
    address payable _royaltyReceiver,
    uint96 _royaltyfeeBasisPoints
  ) external initializer {
    require(_tokensMaxSupply > 0, "gen0: Max Supply not greater than zero");
    require(
      _tokensReservedCurated <= _tokensMaxSupply,
      "gen0: Curated allocated must be less than max supply"
    );

    __BaseOwnableERC721Upgradeable_init(_tokenName, _tokenSymbol);

    //Transfer Ownership on init
    _transferOwnership(_contractOwner);

    //Set Royalty
    _setDefaultRoyalty(_royaltyReceiver, _royaltyfeeBasisPoints);

    baseTokenURI = _customBaseURI;
    MAX_SUPPLY = _tokensMaxSupply;
    CURATED_SUPPLY_REMAINING = _tokensReservedCurated;
  }

  /** ==================== Minting Window Flags ==================== **/
  /**
    @dev Manage the opening and closing of windows. 
         We expect 2 scenarios :
         1) Mint closed
         2) Curated Mint Open
     */

  /**
    @notice Flags to indicated whether the unreserved list can mint. 
     */
  /// @custom:oz-upgrades-unsafe-allow state-variable-assignment

  bool public curatedMintingOpen = false;

  /**
    @dev Emitted when a Curated Minting is Open/Closed.
     */
  event CuratedMintOpen();
  event CuratedMintClosed();

  /**
    @notice Enable curatedMintingOpen flag.
     */
  function openCuratedMinting(bool open) external onlyOwner {
    curatedMintingOpen = open;
    if (open) {
      emit CuratedMintOpen();
    } else {
      emit CuratedMintClosed();
    }
  }

  /** ==================== Minting ==================== **/

  /**
    @dev A common minting function for all mint paths, enforces max supply. 
     */
  function handleMint(address to, uint256 n) internal {
    require(totalSupply() + n <= MAX_SUPPLY, "gen0: Will exceed max supply");
    _safeMint(to, n);
  }

  /**
    @dev A single minting entry point. 
     */
  function mint() external {
    require(curatedMintingOpen, "gen0: curated minting closed");
    uint256 amount = curatedList[_msgSender()];
    require(amount > 0, "gen0: not eligible for curated mint");
    require(
      CURATED_SUPPLY_REMAINING >= amount,
      "gen0: mint request gt than remaining curated supply"
    );

    curatedList[_msgSender()] = 0;
    CURATED_SUPPLY_REMAINING = CURATED_SUPPLY_REMAINING - amount;
    handleMint(_msgSender(), amount);
  }

  /** ==================== Curated Admin Functions ==================== **/
  /**
    @dev Allows owner to seed curatedList mapping. Expects array of address and array of mint slots where
    address and mint slots indexs are matched.
     */
  function seedCuratedList(
    address[] memory addresses,
    uint256[] memory mintSlots
  ) external onlyOwner {
    uint256 addressesLength = addresses.length;
    uint256 mintSlotsLength = mintSlots.length;
    require(
      addressesLength == mintSlotsLength,
      "gen0: addresses must match mintSlots length"
    );

    uint256 allocatedCount = 0;
    for (uint256 i = 0; i < addressesLength; i++) {
      curatedList[addresses[i]] = mintSlots[i];
      allocatedCount += mintSlots[i];
    }
    require(
      allocatedCount <= CURATED_SUPPLY_REMAINING,
      "gen0: Seed list must be less or equal to the curated supply"
    );
  }

  /**
    @dev Allows owner to reset curatedList mapping before minting starts Expects array of address that are known.
         This can not be called once minting has started as previous mint balances are not stored.
     */
  function resetCuratedList(address[] memory addresses) external onlyOwner {
    require(!curatedMintingOpen, "gen0: Minting has started. Unable to reset");
    for (uint256 i = 0; i < addresses.length; i++) {
      delete curatedList[addresses[i]];
    }
  }

  /** ==================== Treasury ==================== **/

  /**
    @notice Mints an arbitrary number of tokens to an arbitrary address, only as
    the contract owner. Created to allow mint initial treasury and any unclaimed
    tokens.
     */
  function treasuryMint(address to, uint256 n) external onlyOwner {
    handleMint(to, n);
  }

  /** ==================== URI Handling ==================== **/

  string public baseTokenURI;

  function setBaseURI(string memory __baseTokenURI) external onlyOwner {
    baseTokenURI = __baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /**
    @dev ERC2981 is not globally implemented across all marketplaces
        but it will become universal royalty standard. 
     */
  /**
    @notice Sets the contract-wide royalty info. feeBasisPoints 500 = 5% 
     */
  function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
    external
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeBasisPoints);
  }

  //As both ERC721A, ERC2981 include supportsInterface we need to override both.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721AUpgradeable, ERC2981)
    returns (bool)
  {
    return
      ERC721AUpgradeable.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}