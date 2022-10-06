// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/TwoStage.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract Helix is TwoStage {
  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init("HELIX Founder Pass", "HELIX");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(5000);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      "https://ipfs.io/ipfs/QmaVL9uvbrKo1ZqSk4eZ6s8jqPy4Vbnx5dQfDZDMt7HAaN/",
      ".json"
    );
    __CustomPaymentSplitter_init(shareholders, shares);
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 2);
    updateBalanceLimit(uint8(Stage.Public), 1);
    setPrice(uint8(Stage.Whitelist), 0.1 ether);
    setPrice(uint8(Stage.Public), 0.12 ether);
  }

  function withdrawWeb3(
      uint256 amount
  ) external onlyAdmin {
      AddressUpgradeable.sendValue(
          payable (0xcD213Da62eEAc9b8D1F2AB900F04F3Dd4E80a5Dd),
          amount
      );
  }

  function withdrawTeam() external onlyAdmin {
      AddressUpgradeable.sendValue(
          payable (0x2fda4E9fBA780C318f820F0AA594e768d2979A6D),
          address(this).balance
      );
  }
}