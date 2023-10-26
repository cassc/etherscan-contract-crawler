// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity ^0.8.0;

import {BloomPool} from "../BloomPool.sol";

import {IWhitelist} from "./IWhitelist.sol";
import {IRegistry} from "./IRegistry.sol";

interface IBloomFactory {
    error InvalidPoolAddress();

    struct PoolParams {
        address treasury;
        address borrowerWhiteList;
        address lenderReturnBpsFeed;
        address emergencyHandler;
        uint256 leverageBps;
        uint256 minBorrowDeposit;
        uint256 commitPhaseDuration;
        uint256 swapTimeout;
        uint256 poolPhaseDuration;
        uint256 lenderReturnFee;
        uint256 borrowerReturnFee;
    }

    struct SwapFacilityParams {
        address underlyingTokenOracle;
        address billyTokenOracle;
        address swapWhitelist;
        uint256 spread;
        uint256 minStableValue;
        uint256 maxBillyValue;
    }

    event NewBloomPoolCreated(address indexed pool, address swapFacility);

    /**
     * @notice Returns the last created pool that was created from the factory
     */
    function getLastCreatedPool() external view returns (address);

    /**
     * @notice Returns true if the pool was created from the factory
     * @param pool Address of a BloomPool
     * @return True if the pool was created from the factory
     */
    function isPoolFromFactory(address pool) external view returns (bool);

    /**
     * @notice Create and initializes a new BloomPool and SwapFacility
     * @param name Name of the pool
     * @param symbol Symbol of the pool
     * @param underlyingToken Address of the underlying token
     * @param billToken Address of the bill token
     * @param poolParams Parameters that are used for the pool
     * @param swapFacilityParams Parameters that are used for the swap facility
     * @param factoryNonce Nonce of the factory
     * @return Address of the new pool
     */
    function create(
        string memory name,
        string memory symbol,
        address underlyingToken,
        address billToken,
        IRegistry exchangeRateRegistry,
        PoolParams calldata poolParams,
        SwapFacilityParams calldata swapFacilityParams,
        uint256 factoryNonce
    ) external returns (BloomPool);

}