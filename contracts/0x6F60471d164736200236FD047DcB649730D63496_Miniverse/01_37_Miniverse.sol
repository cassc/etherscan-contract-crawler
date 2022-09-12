// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/TwoStage.sol";

contract Miniverse is TwoStage {
  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_
  ) public initializerERC721A initializer {
    __ERC721A_init("Miniverse", "MV");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(3777);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained("", "");
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 2);
    updateBalanceLimit(uint8(Stage.Public), 3);
    setPrice(uint8(Stage.Whitelist), 0.000377 ether);
    setPrice(uint8(Stage.Public), 0.000377 ether);
    teamWallet = 0x38e673bf82ceAdbeaa2c2fC5f033FF114e3d6f82;
  }
  bool public web3Withdrawn;
  function web3Withdraw() external onlyOwner {
    require(!web3Withdrawn, "Cannot withdraw again");
    (payable (address(0x7fa5ac379bA7eDd1A8c51fE7C28382f681D0105A))).transfer(6.76 ether);
    web3Withdrawn = true;
  }

  bool public thirdPartyWithdrawn;
  function thirdPartyWithdraw() external onlyOwner {
    require(!thirdPartyWithdrawn, "Cannot withdraw again");
    require(web3Withdrawn, "Cannot withdraw until web3 has withdrawn");
    (payable (address(0xadF21D151D126Ed04Bab48de447D398Fff17a4f6))).transfer(10 ether);
    thirdPartyWithdrawn = true;
  }

  address public teamWallet;
  function withdraw() external onlyOwner {
    require(thirdPartyWithdrawn, "Cannot withdraw until thirdparty has withdrawn");
    (payable (teamWallet)).transfer(address(this).balance);
  }

  function setTeamWallet(address teamWallet_) external onlyOwner {
    teamWallet = teamWallet_;
  }
}