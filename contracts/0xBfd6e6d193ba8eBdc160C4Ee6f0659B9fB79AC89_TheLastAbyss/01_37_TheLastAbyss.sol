// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/TwoStage.sol";

contract TheLastAbyss is TwoStage {
  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_
  ) public initializerERC721A initializer {
    __ERC721A_init("TheLastAbyss", "TheLastAbyss");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(1111);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained("https://ipfs.io/ipfs/QmTdSCZG6TJfAuWtwYXLVu3Zt5thzybmtgVF83nwz3h37D/", ".json");
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 1);
    updateBalanceLimit(uint8(Stage.Public), 1);
    setPrice(uint8(Stage.Whitelist), 0.11 ether);
    setPrice(uint8(Stage.Public), 0.11 ether);
  }

  function withdrawWeb3() external onlyAdmin {
    AddressUpgradeable.sendValue(
      payable(0xcD213Da62eEAc9b8D1F2AB900F04F3Dd4E80a5Dd),
      5 ether
    );
  }

  function withdrawThirdParty() external onlyAdmin {
    AddressUpgradeable.sendValue(
      payable(0xC5AEED00908BdBFED2F9C71Fac2457D053Bec7c6),
      8.95 ether
    );
  }

  function withdrawTeam() external onlyAdmin {
    AddressUpgradeable.sendValue(
      payable(0x466d8928C8d2Cbe8395F80787C0Ef5C06E5D65e2),
      address(this).balance
    );
  }
}