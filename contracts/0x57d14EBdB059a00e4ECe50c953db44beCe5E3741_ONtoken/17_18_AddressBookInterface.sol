// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface AddressBookInterface {
    /* Getters */

    function getONtokenImpl() external view returns (address);

    function getONtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setONtokenImpl(address _onTokenImpl) external;

    function setONtokenFactory(address _factory) external;

    function setOracleImpl(address _onTokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}