// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./external/IMasterOracle.sol";
import "./IPauseable.sol";
import "./IGovernable.sol";
import "./ISyntheticToken.sol";
import "./external/ISwapper.sol";
import "./IQuoter.sol";
import "./ICrossChainDispatcher.sol";

interface IPoolRegistry is IPauseable, IGovernable {
    function feeCollector() external view returns (address);

    function isPoolRegistered(address pool_) external view returns (bool);

    function nativeTokenGateway() external view returns (address);

    function getPools() external view returns (address[] memory);

    function registerPool(address pool_) external;

    function unregisterPool(address pool_) external;

    function masterOracle() external view returns (IMasterOracle);

    function updateFeeCollector(address newFeeCollector_) external;

    function idOfPool(address pool_) external view returns (uint256);

    function nextPoolId() external view returns (uint256);

    function swapper() external view returns (ISwapper);

    function quoter() external view returns (IQuoter);

    function crossChainDispatcher() external view returns (ICrossChainDispatcher);

    function doesSyntheticTokenExist(ISyntheticToken syntheticToken_) external view returns (bool _exists);
}