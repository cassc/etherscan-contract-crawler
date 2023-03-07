// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import '@chocolate-factory/contracts/token/ERC721/presets/MultiStage.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract Seizon is MultiStage {

   function initialize(
    bytes32 phaseOneMerkleRoot_,
    bytes32 phaseTwoMerkleRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init('Seizon', 'Seizon');
    __Ownable_init();
    __DefaultOperatorFilterer_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(7573);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      'https://ipfs.io/ipfs/Qmaxk6hQ5GGNv2Eeo453uBA2Ytvc6fTdMQEdGN4zStXfzQ/',
      '.json'
    );
     __CustomPaymentSplitter_init(shareholders, shares);
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);

    // public
    setPrice(1, 0.057 ether);
    updateBalanceLimit(1, 2);
    // phase 1
    setPrice(2, 0.057 ether);
    updateBalanceLimit(2, 2);
    updateMerkleTreeRoot(2, phaseOneMerkleRoot_);
    // phase 2
    setPrice(3, 0.057 ether);
    updateBalanceLimit(3, 1);
    updateMerkleTreeRoot(3, phaseTwoMerkleRoot_);
  }


}