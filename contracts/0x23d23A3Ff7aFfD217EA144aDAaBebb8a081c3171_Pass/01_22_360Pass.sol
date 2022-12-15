// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@      @@@     @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@        @@           ,@@@@@@@@@                @@    @@@@@@@@@@@@@
@@@@@@@@@@@        @@                    @@                     @@    @@@@@@@@@@
@@@@@@@@@        @.                      @@                        @@@@@@@@@@@@@
@@@@@@@@      (@                          @@                       @@@@@@@@@@@@@
@@@@@@ @@@@@@@@                           @@                       @@@@@@@@@@@@@
@@@@@@@@@@@@@@@                           %@                        @@@@@@@@@@@@
@@@@@@@@@@@@@@@                            @                        @@@@@@@@@@@@
@@@@@@@@@@@@@@@@                         @@@@@@                     @@@@@@@@@@@@
@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@              @@@ @@@@@@@@@@@
@@@@@@@@@@@@@@@@(                  @@@@@@@@@@@@@@@@@@@@      @@@       (@@@@@@@@
@@@@@@@@@@@@@@@   @@@@@@@%      @@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@ @
@@@@@@@@@@@@@@              @@@@@@@@@@@  @@@@@@@@@@/  %@@@                  @  @
@@ @@@@@@@@@                   @@@@@@                @@@@%                  @  @
@@.  @@@@@                      @@@@   (@@@@@@@@   @@@@@@                  @  %@
@@@    @/                        @@@@@@@@@@@@@@@@@@@@@@@                   @  @@
@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@[email protected](@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@
@@@@@[email protected]@@@@@@@@@@@@@@[email protected]@@[email protected]@[email protected]@@@
@@@@@@[email protected]@@@[email protected]@[email protected]@@@@@
@@@@@@@@[email protected]@@[email protected]@[email protected]@@@@@[email protected]@@@@@@
@@@@@@@@@[email protected]@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,@@@@@@,,,,,@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@,@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,@@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@
*/

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

contract Pass is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  AccessControlUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  CountersUpgradeable.Counter private _tokenIdCounter;
  uint256 public maxSupply;
  string _baseUri;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(string calldata baseURI, address minterMan, address adminMan)
    public
    initializer
  {
    __ERC721_init("Budverse 360 Experience Collectible 2022", "360PASS");
    __ERC721Enumerable_init();
    __AccessControl_init();
    __Ownable_init();
    __UUPSUpgradeable_init();
    _baseUri = baseURI;
    maxSupply = 1;
    _grantRole(DEFAULT_ADMIN_ROLE, adminMan);
    _grantRole(MINTER_ROLE, minterMan);
    _grantRole(UPGRADER_ROLE, adminMan);

    _tokenIdCounter.increment();
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseUri;
  }

  function setBaseURI(string memory baseURI) public onlyRole(UPGRADER_ROLE) {
    _baseUri = baseURI;
  }

  function mint(address to) public onlyRole(MINTER_ROLE) {
    uint256 tokenId = _tokenIdCounter.current();
    require(tokenId <= maxSupply, "Fully minted");
      _safeMint(to, tokenId);
      _tokenIdCounter.increment();
  }

  function walletInventory(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(UPGRADER_ROLE)
  {}

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(
      ERC721Upgradeable,
      ERC721EnumerableUpgradeable,
      AccessControlUpgradeable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}