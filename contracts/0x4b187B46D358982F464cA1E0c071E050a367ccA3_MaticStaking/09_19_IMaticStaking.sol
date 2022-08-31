//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IMaticStaking {
    /**
     * Events
     */

    event StartedExit(bytes data);

    event Staked(
        address indexed staker,
        uint256 amount,
        bool indexed isRebasing
    );

    event Unstaked(
        address indexed claimer,
        uint256 amount,
        bool indexed isRebasing,
        uint256 fee
    );

    event UnstakedAcrossToPolygon(address indexed operator, uint256 amount);

    event BondTokenChanged(address indexed bondToken);

    event CertTokenChanged(address indexed certToken);

    event AnkrTokenChanged(address indexed ankrToken);

    event PolygonPoolChanged(address indexed polygonPool);

    event BridgeChanged(address indexed bridge);

    event DepositManagerChanged(address indexed depositManager);

    event MaticPredicateChanged(address indexed maticPredicate);

    event RootChainManagerChanged(address indexed rootChainManager);

    event OperatorChanged(address indexed operator);

    event ToChainIdChanged(uint256 indexed toChainId);

    /**
     * Methods
     */

    function stake(
        address receiver,
        uint256 amount,
        bool isRebasing
    ) external;

    function startExit(bytes calldata data) external;

    // function delegateLast() external;
}