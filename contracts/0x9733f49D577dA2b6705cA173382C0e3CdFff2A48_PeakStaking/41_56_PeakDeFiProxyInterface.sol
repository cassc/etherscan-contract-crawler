pragma solidity 0.5.17;

interface PeakDeFiProxyInterface {
  function peakdefiFundAddress() external view returns (address payable);
  function updatePeakDeFiFundAddress() external;
}