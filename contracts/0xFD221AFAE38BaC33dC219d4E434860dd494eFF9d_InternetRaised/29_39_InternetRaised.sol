// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import '@chocolate-factory/contracts/token/ERC721/presets/MultiStage.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract InternetRaised is MultiStage {

   function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    bytes32 freeMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init('Internet Raised', 'Internet Raised');
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(4444);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      '',
      '.json'
    );
     __CustomPaymentSplitter_init(shareholders, shares);
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);

    // public
    setPrice(1, 0.025 ether);
    updateBalanceLimit(1, 2);
    // whitelist
    setPrice(2, 0.025 ether);
    updateBalanceLimit(2, 2);
    updateMerkleTreeRoot(2, whitelistMerkleTreeRoot_);
    // free
    setPrice(3, 0);
    updateBalanceLimit(3, 2);
    updateMerkleTreeRoot(3, freeMerkleTreeRoot_);
  }

}