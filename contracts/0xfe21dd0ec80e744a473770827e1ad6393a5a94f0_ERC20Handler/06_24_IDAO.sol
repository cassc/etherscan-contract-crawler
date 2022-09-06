pragma solidity 0.8.11;

interface IDAO {
    function isOwnerChangeAvailable(uint256 id) external view returns (address);
    function confirmOwnerChangeRequest(uint256 id) external returns (bool);

    function isTransferAvailable(uint256 id) external view returns (address payable[] memory, uint[] memory);
    function confirmTransferRequest(uint256 id) external returns (bool);

    function isPauseStatusAvailable(uint256 id) external view returns (bool);
    function confirmPauseStatusRequest(uint256 id) external returns (bool);

    function isChangeRelayerThresholdAvailable(uint256 id) external view returns (uint256);
    function confirmChangeRelayerThresholdRequest(uint256 id) external returns (bool);

    function isSetResourceAvailable(uint256 id) external view returns (address, bytes32, address);
    function confirmSetResourceRequest(uint256 id) external returns (bool);

    function isSetGenericResourceAvailable(uint256 id) external view returns (address, bytes32, address, bytes4, uint256, bytes4);
    function confirmSetGenericResourceRequest(uint256 id) external returns (bool);

    function isSetBurnableAvailable(uint256 id) external view returns (address, address);
    function confirmSetBurnableRequest(uint256 id) external returns (bool);

    function isSetNonceAvailable(uint256 id) external view returns (uint8, uint64);
    function confirmSetNonceRequest(uint256 id) external returns (bool);

    function isSetForwarderAvailable(uint256 id) external view returns (address, bool);
    function confirmSetForwarderRequest(uint256 id) external returns (bool);

    function isChangeFeeAvailable(uint256 id) external view returns (address, uint8, uint256, uint256, uint256);
    function confirmChangeFeeRequest(uint256 id) external returns (bool);

    function isChangeFeePercentAvailable(uint256 id) external view returns (uint128, uint64);
    function confirmChangeFeePercentRequest(uint256 id) external returns (bool);

    function isWithdrawAvailable(uint256 id) external view returns (address, bytes memory);
    function confirmWithdrawRequest(uint256 id) external returns (bool);

    function isSetTreasuryAvailable(uint256 id) external view returns (address);
    function confirmSetTreasuryRequest(uint256 id) external returns (bool);

    function isSetNativeTokensForGasAvailable(uint256 id) external view returns (uint256);
    function confirmSetNativeTokensForGasRequest(uint256 id) external returns (bool);

    function isTransferNativeAvailable(uint256 id) external view returns (address, uint256);
    function confirmTransferNativeRequest(uint256 id) external returns (bool);
}