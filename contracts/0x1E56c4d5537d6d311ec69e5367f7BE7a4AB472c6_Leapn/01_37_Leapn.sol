// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/TwoStage.sol";

contract Leapn is TwoStage {
  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init("Leapn", "Leapn");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(3333);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained("", "");
    __CustomPaymentSplitter_init(shareholders, shares);
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 2);
    updateBalanceLimit(uint8(Stage.Public), 5);
    setPrice(uint8(Stage.Whitelist), 0.09 ether);
    setPrice(uint8(Stage.Public), 0.12 ether);
  }

     function _startTokenId()
        internal
        pure
        override(ERC721AUpgradeable)
        returns (uint256)
    {
        return 1;
    }

}