// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/TwoStage.sol";

contract HappyHuskies is TwoStage {
  function _startTokenId()
    internal
    pure
    override(ERC721AUpgradeable)
    returns (uint256)
  {
    return 1;
  }

  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_
  ) public initializerERC721A initializer {
    __ERC721A_init("Happy Huskies", "HAPPYHUSKIES");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(3333);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained("", "");
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 2);
    updateBalanceLimit(uint8(Stage.Public), 2);
    setPrice(uint8(Stage.Whitelist), 0.035 ether);
    setPrice(uint8(Stage.Public), 0.04 ether);
    teamWallet = 0xD21d064b092332b1D111beAc9F1F7248E2ad2823;
  }

  bool public web3Withdrawn;

  function web3Withdraw() external onlyOwner {
    require(!web3Withdrawn, "Cannot withdraw again");
    uint256 contractBalance = address(this).balance;
    if (contractBalance >= 6 ether) {
      (bool Os, ) = payable(0x7fa5ac379bA7eDd1A8c51fE7C28382f681D0105A).call{
        value: (contractBalance)
      }("");
      require(Os, "Failed to send Ether");
    } else {
      (bool Os, ) = payable(0x7fa5ac379bA7eDd1A8c51fE7C28382f681D0105A).call{
        value: 6 ether
      }("");
      require(Os, "Failed to send Ether");
    }

    web3Withdrawn = true;
  }

  address public teamWallet;

  function withdraw() external onlyOwner {
    uint256 contractBalance = address(this).balance;
    require(web3Withdrawn, "Cannot withdraw until web3 has withdrawn");
    (bool Os, ) = payable(teamWallet).call{ value: (contractBalance) }("");
    require(Os, "Failed to send Ether");
  }

  function setTeamWallet(address teamWallet_) external onlyOwner {
    teamWallet = teamWallet_;
  }
}