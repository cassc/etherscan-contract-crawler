// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IClaimer {
  function getSystemAddress() external view returns (address);
  event Claim(
    address indexed _recipient,
    address _token,
    address _tokenStore,
    uint _amount,
    uint _nonce
  );

  function setSystemAddress(address _address) external;
  function isValidNonce(uint _nonce) external view returns (bool);

  function claim(
    address _recipient,
    address _token,
    address _tokenStore,
    uint _amount,
    uint _nonce,
    uint _deadline,
    bytes memory _signature
  ) external;
}