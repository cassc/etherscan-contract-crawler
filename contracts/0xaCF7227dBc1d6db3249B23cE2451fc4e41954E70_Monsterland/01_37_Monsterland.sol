// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/MultiStage.sol";

contract Monsterland is MultiStage {
  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    bytes32 freelistMerkleTreeRoot_,
    bytes32 waitlistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init("Monsterland", "Monsterland");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(5555);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      "https://ipfs.io/ipfs/QmbAu7cGyyppzDFQrE64ZRPMz8QPzPba71pFdcz815p6xg/",
      ".json"
    );
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    __CustomPaymentSplitter_init(shareholders, shares);
    // WL
    updateBalanceLimit(2, 1);
    setPrice(2, 0.00666 ether);
    updateMerkleTreeRoot(2, whitelistMerkleTreeRoot_);
    // Free Mint
    updateBalanceLimit(3, 1);
    setPrice(3, 0);
    updateMerkleTreeRoot(3, freelistMerkleTreeRoot_);
    // Waitlist
    updateBalanceLimit(4, 1);
    setPrice(4, 0.00999 ether);
    updateMerkleTreeRoot(4, waitlistMerkleTreeRoot_);
    // Public
    updateBalanceLimit(1, 2);
    setPrice(1, 0.00999 ether);
  }
}