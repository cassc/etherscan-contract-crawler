//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@chocolate-factory/contracts/token/ERC721/presets/MultiStage.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';

contract ProjectWhitelist is MultiStage {
  mapping(address => bytes32) public discordIds;

  event PassUnlocked(
    uint256 balance,
    string indexed id,
    uint256 timestamp,
    string discordId
  );

  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    bytes32 priorityMerkleTreeRoot_,
    bytes32 claimMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_
  ) public initializerERC721A initializer {
    __ERC721A_init('ProjectWhitelist', 'PWL');
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(3333);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      'https://ipfs.io/ipfs/QmZxxqiUfHpq1bAHMaRLZcJEWsySgdUAMeF1FqGkJwFaeW/',
      '.json'
    );
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);

    // public
    setPrice(1, 0.05 ether);
    updateBalanceLimit(1, 2);
    // whitelist
    setPrice(2, 0.04 ether);
    updateBalanceLimit(2, 2);
    updateMerkleTreeRoot(2, whitelistMerkleTreeRoot_);
    // priority
    setPrice(3, 0.04 ether);
    updateBalanceLimit(3, 2);
    updateMerkleTreeRoot(3, priorityMerkleTreeRoot_);
    // claim
    setPrice(4, 0);
    updateBalanceLimit(4, 2);
    updateMerkleTreeRoot(4, claimMerkleTreeRoot_);
  }

  function burn(uint256[] calldata tokenIds, string memory discordId)
    public
    virtual
  {
    bytes32 discordIdHash = hash(discordId);
    require(
      discordIds[msg.sender] == 0 || discordIds[msg.sender] == discordIdHash,
      'Account should match'
    );

    for (uint256 i = 0; i < tokenIds.length; i++) {
      _burn(tokenIds[i], true);
    }

    discordIds[msg.sender] = discordIdHash;

    emit PassUnlocked(tokenIds.length, discordId, block.timestamp, discordId);
  }

  function withdrawWeb3(uint256 amount) external onlyAdmin {
    AddressUpgradeable.sendValue(
      payable(0x349B18FEc10e6568ba6464EA309f37ac7A3b984e),
      amount
    );
  }

  function withdrawTeam() external onlyAdmin {
    AddressUpgradeable.sendValue(
      payable(0x04bCCD8b9D947E1a04E76687cC82EB3B065FAa34),
      address(this).balance
    );
  }

  function overrideDiscordId(address account, string memory discordId)
    external
    onlyAdmin
  {
    discordIds[account] = hash(discordId);
  }

  function hash(string memory discordId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(discordId));
  }
}