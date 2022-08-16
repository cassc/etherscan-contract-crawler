// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @dev this is the one contract call that the OTC needs to interact with the NFT contract
interface INFT {
  /// @notice function for publicly viewing a lockedToken (future) details
  /// @param _id is the id of the NFT which is mapped to the future struct
  /// @dev this returns the amount of tokens locked, the token address and the date that they are unlocked
  function futures(uint256 _id)
    external
    view
    returns (
      uint256 amount,
      address token,
      uint256 unlockDate
    );
    /// @dev Returns the number of tokens in ``owner``'s account.
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);

  /// @param _holder is the new owner of the NFT and timelock future - this can be any address
  /// @param _amount is the amount of tokens that are going to be locked
  /// @param _token is the token address to be locked by the NFT. Use WETH address for ETH - but WETH must be held by the msg.sender
  /// ... as there is no automatic wrapping from ETH to WETH for this function.
  /// @param _unlockDate is the date which the tokens become unlocked and available to be redeemed and withdrawn from the contract
  /// @dev this is a public function that anyone can call
  /// @dev the _holder can be defined as your address, or any chose address - and so you can directly mint NFTs to other addresses
  /// ... in a way to airdrop NFTs directly to contributors
  function createNFT(
    address _holder,
    uint256 _amount,
    address _token,
    uint256 _unlockDate
  ) external returns (uint256);

  /// @dev function for redeeming an NFT
  /// @notice this function will burn the NFT and delete the future struct - in return the locked tokens will be delivered
  function redeemNFT(uint256 _id) external returns (bool);

  /// @notice this event spits out the details of the NFT and future struct when a new NFT & Future is minted
  event NFTCreated(uint256 _i, address _holder, uint256 _amount, address _token, uint256 _unlockDate);

  /// @notice this event spits out the details of the NFT and future structe when an existing NFT and Future is redeemed
  event NFTRedeemed(uint256 _i, address _holder, uint256 _amount, address _token, uint256 _unlockDate);

  /// @notice this event is fired the one time when the baseURI is updated
  event URISet(string newURI);
}