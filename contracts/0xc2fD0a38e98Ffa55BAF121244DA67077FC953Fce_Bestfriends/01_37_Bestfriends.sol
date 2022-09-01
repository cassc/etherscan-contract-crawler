// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/TwoStage.sol";

contract Bestfriends is TwoStage {
  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders_,
    uint256[] memory shares_
  ) public initializerERC721A initializer {
    __ERC721A_init("BestFriend", "BF");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(6500);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __Price_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained("https://ipfs.io/ipfs/Qmeh8DHprz15F5gtnJaEajzicN1CwvW6mrFWjtg5FwpyQa/", ".json");
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    __CustomPaymentSplitter_init(shareholders_, shares_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 2);
    updateBalanceLimit(uint8(Stage.Public), 4);
    setPrice(uint8(Stage.Whitelist), 0.029 ether);
    setPrice(uint8(Stage.Public),  0.039 ether);
  }
}