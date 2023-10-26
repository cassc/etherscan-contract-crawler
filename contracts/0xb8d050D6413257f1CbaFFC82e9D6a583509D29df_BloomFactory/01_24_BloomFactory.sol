// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {LibRLP} from "solady/utils/LibRLP.sol";

import {BloomPool} from "./BloomPool.sol";
import {SwapFacility} from "./SwapFacility.sol";

import {IBloomFactory} from "./interfaces/IBloomFactory.sol";
import {IWhitelist} from "./interfaces/IWhitelist.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";

contract BloomFactory is IBloomFactory, Ownable2Step {
    // =================== Storage ===================   
    address private _lastCreatedPool;
    mapping(address => bool) private _isPoolFromFactory;

    constructor(address owner) Ownable2Step() {
        _transferOwnership(owner);
    }

    function getLastCreatedPool() external view override returns (address) {
        return _lastCreatedPool;
    }

    function isPoolFromFactory(address pool)
        external
        view
        override
        returns (bool) 
    {
        return _isPoolFromFactory[pool];
    }

    function create(
        string memory name,
        string memory symbol,
        address underlyingToken,
        address billToken,
        IRegistry exchangeRateRegistry,
        PoolParams calldata poolParams,
        SwapFacilityParams calldata swapFacilityParams,
        uint256 factoryNonce
    ) external override onlyOwner returns (BloomPool) {
        // Precompute the address of the BloomPool
        address expectedPoolAddress = LibRLP.computeAddress(address(this), factoryNonce + 1);
        
        // Deploys SwapFacility
        SwapFacility swapFacility = new SwapFacility(
            underlyingToken,
            billToken,
            swapFacilityParams.underlyingTokenOracle,
            swapFacilityParams.billyTokenOracle,
            IWhitelist(swapFacilityParams.swapWhitelist),
            swapFacilityParams.spread,
            expectedPoolAddress,
            swapFacilityParams.minStableValue,
            swapFacilityParams.maxBillyValue
        );

        // Deploys BloomPool
        BloomPool bloomPool = new BloomPool(
            underlyingToken,
            billToken,
            IWhitelist(poolParams.borrowerWhiteList),
            address(swapFacility),
            poolParams.treasury,
            poolParams.lenderReturnBpsFeed,
            poolParams.emergencyHandler,
            poolParams.leverageBps,
            poolParams.minBorrowDeposit,
            poolParams.commitPhaseDuration,
            poolParams.swapTimeout,
            poolParams.poolPhaseDuration,
            poolParams.lenderReturnFee,
            poolParams.borrowerReturnFee,
            name,
            symbol
        );

        // Verify that the deployed BloomPool address matches the expected address
        // If this isn't the case we should revert because the swap facility is associated 
        //     with the wrong address
        if (address(bloomPool) != expectedPoolAddress) {
            revert InvalidPoolAddress();
        }

        // Add the pool to the set of pools & store the last created pool
        _isPoolFromFactory[address(bloomPool)] = true;
        _lastCreatedPool = address(bloomPool);

        // Register the pool in the exchange rate registry & activate the token
        exchangeRateRegistry.registerToken(bloomPool);

        emit NewBloomPoolCreated(address(bloomPool), address(swapFacility));

        return bloomPool;
    }
}