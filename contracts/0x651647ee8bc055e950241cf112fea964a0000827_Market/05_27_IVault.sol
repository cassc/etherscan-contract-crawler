// SPDX-License-Identifier: None
pragma solidity =0.8.13;

interface IVault {
  function factoryContract() external view returns (address);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function approve(address _to, uint256 _tokenId) external;

  function burn(uint256 _tokenId) external;

  function mintONft(uint256 _lockId) external;

  function mintWNft(
    address _renter,
    uint256 _starts,
    uint256 _expires,
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount
  ) external;

  function activate(
    uint256 _rentId,
    uint256 _lockId,
    address _renter,
    uint256 _amount
  ) external;

  function originalCollection() external view returns (address);

  function redeem(uint256 _tokenId) external;

  function ownerOf(uint256 _tokenId) external view returns (address owner);

  function collectionOwner() external view returns (address);

  function payoutAddress() external view returns (address);

  function collectionOwnerFeeRatio() external view returns (uint256);

  function getTokenIdAllowed(uint256 _tokenId) external view returns (bool);

  function getPaymentTokens() external view returns (address[] memory);

  //function paymentTokenWhiteList(address _paymentToken) external view returns (uint256 _bool);

  function setMinPrices(uint256[] memory _minPrices, address[] memory _paymentTokens) external;

  //NOTE ホワリスの代わり
  function minPrices(address _paymentToken) external view returns (uint256);

  function minDuration() external view returns (uint256);

  function maxDuration() external view returns (uint256);

  function flashloan(
    address _tokenAddress,
    uint256 _tokenId,
    address _receiver
  ) external payable;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external;
}