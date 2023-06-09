// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IChainlinkAggregatorV3Like {

    function latestRoundData()
        external
        view
        returns (
            uint80  roundId_,
            int256  price_,
            uint256 startedAt_,
            uint256 updatedAt_,
            uint80  answeredInRound_
        );

}

interface IPoolLike {

    function manager() external view returns (address manager_);

}

interface IPoolManagerLike {

    function factory() external view returns (address factory_);

    function poolDelegate() external view returns (address poolDelegate_);

    function setActive(bool active_) external;

}

interface IProxyLike {

    function factory() external view returns (address factory_);

}

interface IProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

}