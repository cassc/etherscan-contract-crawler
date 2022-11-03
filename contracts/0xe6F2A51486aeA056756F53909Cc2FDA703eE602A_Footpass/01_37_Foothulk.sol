// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/MultiStage.sol";

contract Footpass is MultiStage {
  function _startTokenId()
    internal
    pure
    override(ERC721AUpgradeable)
    returns (uint256)
  {
    return 1;
  }

  function withdraw() external onlyAdmin {
    AddressUpgradeable.sendValue(
      payable(0xE3e62Af17385dfE4C1A2D6b349A54C03CE2C407D),
      address(this).balance
    );
  }

  function initialize(
    bytes32 goldListMerkleTreeRoot_,
    bytes32 whiteListMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_
  ) public initializerERC721A initializer {
    __ERC721A_init("Footpass", "Footpass");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(1111);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained("", ".json");
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    // whales
    updateBalanceLimit(2, 10);
    setPrice(2, 0.12 ether);
    updateMerkleTreeRoot(2, goldListMerkleTreeRoot_);
    // WhiteList
    updateBalanceLimit(3, 2);
    setPrice(3, 0.15 ether);
    updateMerkleTreeRoot(3, whiteListMerkleTreeRoot_);
    // waitlist
    updateBalanceLimit(4, 2);
    setPrice(4, 0.15 ether);
    updateMerkleTreeRoot(4, whiteListMerkleTreeRoot_);
    // Public
    updateBalanceLimit(1, 5);
    setPrice(1, 0.15 ether);
  }
}