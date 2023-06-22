pragma solidity 0.6.6;

interface IBorrower {
  function executeOnFlashMint(uint256 amount, bytes32 data) external;
}