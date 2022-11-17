// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/TwoStage.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract Pengu is TwoStage, DefaultOperatorFiltererUpgradeable {
  function _startTokenId()
    internal
    pure
    override(ERC721AUpgradeable)
    returns (uint256)
  {
    return 1;
  }

  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init("Pengu", "Pengu");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(7000);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained("", "");
    __CustomPaymentSplitter_init(shareholders, shares);
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 2);
    updateBalanceLimit(uint8(Stage.Public), 5);
    setPrice(uint8(Stage.Whitelist), 0.049 ether);
    setPrice(uint8(Stage.Public), 0.059 ether);
  }

  function initializeV2() public reinitializer(2) {
    __DefaultOperatorFilterer_init();
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}