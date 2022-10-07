// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @title Decentralized Creator Nonfungible Token Vault Wrapper (DCNT VWs)
/// @notice claimable ERC20s for NFT holders after vault expiration
contract DCNTVault is Ownable, Initializable {
  /// ============ Immutable storage ============

  /// ============ Mutable storage ============

  /// @notice vault token to be distributed to token holders
  IERC20 public vaultDistributionToken;
  /// @notice "ticket" token held by user
  IERC721 public nftVaultKey;
  /// @notice total supply of nft used in determining payouts
  uint256 public nftTotalSupply;
  /// @notice unlock date when distribution can start happening
  uint256 public unlockDate;

  /// @notice Mapping of addresses who have claimed tokens
  mapping(uint256 => bool) internal hasClaimedTokenId;

  /// @notice total # of tokens already released
  uint256 private _totalReleased;

  /// ============ Events ============

  /// @notice Emitted after a successful token claim
  /// @param account recipient of claim
  /// @param amount of tokens claimed
  event Claimed(address account, uint256 amount);

  /// ============ Initializer ============

  /// @notice Initializes a new vault
  /// @param _vaultDistributionTokenAddress of token
  /// @param _nftVaultKeyAddress of token
  /// @param _unlockDate date of vault expiration
  function initialize(
    address _owner,
    address _vaultDistributionTokenAddress,
    address _nftVaultKeyAddress,
    uint256 _nftTotalSupply,
    uint256 _unlockDate
  ) public initializer {
    _transferOwnership(_owner);
    vaultDistributionToken = IERC20(_vaultDistributionTokenAddress);
    nftVaultKey = IERC721(_nftVaultKeyAddress);
    nftTotalSupply = _nftTotalSupply;
    unlockDate = _unlockDate;
  }

  /// ============ Functions ============

  // returns balance of vault
  function vaultBalance() public view returns (uint256) {
    return vaultDistributionToken.balanceOf(address(this));
  }

  // returns total # of tokens already released from vault
  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  // (total vault balance) * (nfts_owned/total_nfts)
  function _pendingPayment(uint256 numNftVaultKeys, uint256 totalReceived)
    private
    view
    returns (uint256)
  {
    return (totalReceived * numNftVaultKeys) / nftTotalSupply;
  }

  function _claimMany(address to, uint256[] memory tokenIds) private {
    require(block.timestamp >= unlockDate, "vault is still locked");
    require(vaultBalance() > 0, "vault is empty");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(
        nftVaultKey.ownerOf(tokenIds[i]) == to,
        "address does not own token"
      );
      require(!hasClaimedTokenId[tokenIds[i]], "token already claimed");
      hasClaimedTokenId[tokenIds[i]] = true;
    }

    uint256 amount = _pendingPayment(
      tokenIds.length,
      vaultBalance() + totalReleased()
    );
    require(amount > 0, "address has no claimable tokens");
    require(vaultDistributionToken.transfer(to, amount), "Transfer failed");
    _totalReleased += amount;
    emit Claimed(to, amount);
  }

  // claim tokens for multiple NFTs in collection
  function claimMany(address to, uint256[] calldata tokenIds) external {
    _claimMany(to, tokenIds);
  }

  // serves similar purpose to claim all but allows user to claim specific
  // token for one of NFTs in collection
  function claim(address to, uint256 tokenId) external {
    _claimMany(to, _asSingletonArray(tokenId));
  }

  // allows vault owner to claim ERC20 tokens sent to account
  // failsafe in case money needs to be taken off chain
  function drain(IERC20 token) public onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  function drainEth() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function _asSingletonArray(uint256 element)
    private
    pure
    returns (uint256[] memory)
  {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}