// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

interface IOxODexFactory {
    function createPool(address token) external returns (address vault);
    function allPoolsLength() external view returns (uint);
    function getPool(address token) external view returns (address);
    function allPools(uint256) external view returns (address);

    function token() external view returns (address);
    function managerAddress() external view returns (address);
    function treasurerAddress() external view returns (address);
    function relayerAddress() external view returns (address payable);
    function fee() external view returns (uint256);
    function tokenFee() external view returns (uint256);
    function relayerFee() external view returns (uint256);
    function maxRelayerGasCharge(address) external view returns (uint256);
    function paused() external view returns (bool);

    function setManager(address _manager) external;
    function setTreasurerAddress(address _treasurerAddress) external;
    function setToken(address _token) external;
    function setTokenFeeDiscountPercent(uint256 _value) external;
    function setTokenFee(uint256 _fee) external;
    function setFee(uint256 _fee) external;
    function setRelayerFee(uint256 _fee) external;
 
    function getTokenFeeDiscountLimit() external view returns (uint256);
}