// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ERC721PresetMinterPauserAutoIdUpgradeSafe} from "../../external/ERC721PresetMinterPauserAutoId.sol";
import {ERC721UpgradeSafe} from "../../external/ERC721.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {IWithdrawalRequestToken} from "../../interfaces/IWithdrawalRequestToken.sol";
import {HasAdmin} from "./HasAdmin.sol";
import {IERC721} from "../../interfaces/openzeppelin/IERC721.sol";

// TODO - supportsInterface and setBaseURI functions
contract WithdrawalRequestToken is
  IWithdrawalRequestToken,
  ERC721PresetMinterPauserAutoIdUpgradeSafe,
  HasAdmin
{
  using ConfigHelper for GoldfinchConfig;

  GoldfinchConfig private config;

  /*
    We are using our own initializer function so that OZ doesn't automatically
    set owner as msg.sender. Also, it lets us set our config contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );

    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ERC165_init_unchained();
    // This is setting name and symbol of the NFT's
    __ERC721_init_unchained("Goldfinch SeniorPool Withdrawal Tokens", "GFI-SENIOR-WITHDRAWALS");
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();

    config = _config;

    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /// @inheritdoc IWithdrawalRequestToken
  /// @notice Can only be called by senior pool or protocol admin
  function mint(address receiver) external override onlySeniorPool returns (uint256) {
    _tokenIdTracker.increment();
    _mint(receiver, _tokenIdTracker.current());
    return _tokenIdTracker.current();
  }

  /// @inheritdoc IWithdrawalRequestToken
  function burn(uint256 tokenId) external override onlySeniorPool {
    _burn(tokenId);
  }

  /// @notice Disabled
  function approve(address, uint256) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  /// @notice Disabled
  function setApprovalForAll(address, bool) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  /// @notice Disabled
  function transferFrom(address, address, uint256) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  /// @notice Disabled
  function safeTransferFrom(address, address, uint256) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  /// @notice Disabled
  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes memory
  ) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  modifier onlySeniorPool() {
    require(msg.sender == address(config.getSeniorPool()), "NA");
    _;
  }
}