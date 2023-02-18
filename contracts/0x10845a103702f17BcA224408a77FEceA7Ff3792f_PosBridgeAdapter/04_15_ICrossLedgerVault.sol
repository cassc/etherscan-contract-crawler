pragma solidity >0.8.0;


interface ICrossLedgerVault
{
	function depositFundsToRootVault(bytes32 transferId, address token, uint value) external returns(uint256);

    function transferCompleted(bytes32 transferId, address asset, uint256 value) external;
}