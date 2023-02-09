// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import '@chocolate-factory/contracts/token/ERC721/presets/MultiStage.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract Them3gazine is MultiStage {

   function initialize(
    bytes32 ogMerkleTreeRoot_,
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init('Them3gazine', 'Them3gazine');
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(5000);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      'https://ipfs.io/ipfs/QmNLu2FR8ppvFouQuj3iVD1VkPsq8uXXhjy7BCg357f3Zc/',
      '.json'
    );
     __CustomPaymentSplitter_init(shareholders, shares);
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);

    // public
    setPrice(1, 0.04 ether);
    updateBalanceLimit(1, 2);
    // og
    setPrice(2, 0.02 ether);
    updateBalanceLimit(2, 2);
    updateMerkleTreeRoot(2, ogMerkleTreeRoot_);
    // whitelist
    setPrice(3, 0.03 ether);
    updateBalanceLimit(3, 2);
    updateMerkleTreeRoot(3, whitelistMerkleTreeRoot_);
  }

}