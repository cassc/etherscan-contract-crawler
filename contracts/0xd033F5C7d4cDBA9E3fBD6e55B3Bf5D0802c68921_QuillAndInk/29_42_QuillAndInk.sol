// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import '@chocolate-factory/contracts/token/ERC721/presets/TwoStage.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract QuillAndInk is TwoStage {
    function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init("Quill & Ink", "Quill Ink");
    __Ownable_init();
     __ERC721ABurnable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(1500);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      "ipfs.io/ipfs/QmQF4N28MPjNWDdejGTeh7vWs5LhWcKcbtdmFKZ1fnMhPK/",
      "json"
    );
    __CustomPaymentSplitter_init(shareholders, shares);
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 1);
    updateBalanceLimit(uint8(Stage.Public), 1);
    setPrice(uint8(Stage.Whitelist), 0 ether);
    setPrice(uint8(Stage.Public), 0 ether);
  }


}