// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
BUDVERSE LIVE SCOREBOARD 2022 

Introducing the Budverse Live Scoreboard collectible: A real-time NFT that 
tracks live data, connecting you and fellow fans with up-to-date tournament 
scores of your favorite football teams. Visit nft.budweiser.com for more information.
Terms and Conditions apply: https://www.ab-inbev.com/nftterms, 
or https://www.ab-inbev.com/nftterms/Canada in Canada. 
21+ Only. Enjoy Responsibly. 
©2022 Anheuser-Busch, Budweiser® Lager Beer, St. Louis, MO.

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
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";


contract LiveScoreBoard is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  AccessControlUpgradeable,
  UUPSUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  CountersUpgradeable.Counter private _tokenIdCounter;
  string _baseUri;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(string calldata baseURI, address minterMan)
    public
    initializer
  {
    __ERC721_init("Budverse Live Scoreboard Collectible 2022", "WORLD");
    __ERC721Enumerable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();
    _baseUri = baseURI;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, minterMan);
    _grantRole(UPGRADER_ROLE, msg.sender);
    
    // Set first tokenId to 1
    _tokenIdCounter.increment();
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseUri;
  }

  function setBaseURI(string memory baseURI) public onlyRole(UPGRADER_ROLE) {
    _baseUri = baseURI;
  }

  function mint(address to, uint256 number) public onlyRole(MINTER_ROLE) {
    uint256 tokenId = _tokenIdCounter.current();
    for (uint256 index = 0; index < number; index++) {
      _safeMint(to, tokenId);
      _tokenIdCounter.increment();
      tokenId = _tokenIdCounter.current();
    }
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