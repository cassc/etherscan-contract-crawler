pragma solidity ^0.8.2;

interface IVendingMachine {

	function NFTMachineFor(uint256 NFTId, address _recipient) external;
}