// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRubicWhitelist {
    function addOperators(address[] calldata _operators) external;

    function removeOperators(address[] calldata _operators) external;

    function getAvailableOperators() external view returns (address[] memory);

    function isOperator(address _operator) external view returns (bool);

    function addCrossChains(address[] calldata _crossChains) external;

    function removeCrossChains(address[] calldata _crossChains) external;

    function getAvailableCrossChains() external view returns (address[] memory);

    function isWhitelistedCrossChain(address _crossChain) external view returns (bool);

    function addDEXs(address[] calldata _dexs) external;

    function removeDEXs(address[] calldata _dexs) external;

    function getAvailableDEXs() external view returns (address[] memory);

    function isWhitelistedDEX(address _dex) external view returns (bool);

    function addAnyRouters(address[] calldata _anyRouters) external;

    function removeAnyRouters(address[] calldata _anyRouters) external;

    function getAvailableAnyRouters() external view returns (address[] memory);

    function isWhitelistedAnyRouter(address _anyRouter) external view returns (bool);

    function addToBlackList(address[] calldata _blackAddrs) external;

    function removeFromBlackList(address[] calldata _blackAddrs) external;

    function getBlackList() external view returns (address[] memory);

    function isBlacklisted(address _router) external view returns (bool);
}