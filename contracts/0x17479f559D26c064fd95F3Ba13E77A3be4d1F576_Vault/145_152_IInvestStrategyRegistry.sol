// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title IInvestStrategyRegistry
 * @author Opty.fi
 * @notice Contains functionality to setting all the strategies for all tokens
 */
interface IInvestStrategyRegistry {
    /**
     * @dev Assign strategy in form of _strategySteps to the _tokensHash
     * @param  _tokensHash Hash of underlying token address/addresses
     * @param _strategySteps Strategy steps containing [pool, outputToken, isSwap]
     * @return Returns true indicating successful operation.
     */
    function setStrategy(bytes32 _tokensHash, DataTypes.StrategyStep[] memory _strategySteps) external returns (bool);

    /**
     * @dev Assign multiple strategies in form of _strategySteps to the _tokensHash
     * @param  _tokensHash List of Hashes of underlying token address/addresses
     * @param _strategySteps List of Strategy steps containing [pool, outputToken, isSwap]
     * @return Returns true indicating successful operation.
     */
    function setStrategy(bytes32 _tokensHash, DataTypes.StrategyStep[][] memory _strategySteps) external returns (bool);

    /**
     * @dev Assign multiple strategies in form of _strategySteps to multiple tokens in form of _tokensHash
     * @param  _tokensHash List of Hashes of underlying token address/addresses
     * @param _strategySteps List of Strategy steps containing [pool, outputToken, isSwap]
     * @return Returns true indicating successful operation.
     */
    function setStrategy(bytes32[] memory _tokensHash, DataTypes.StrategyStep[][] memory _strategySteps)
        external
        returns (bool);

    /**
     * @notice Returns the Strategy Steps corresponding to _hash
     * @param _hash Hash of the strategy steps
     * @return _index Index at which strategy is stored
     * @return _strategySteps Returns the Strategy Steps corresponding to _hash provided
     */
    function getStrategy(bytes32 _hash)
        external
        view
        returns (uint256 _index, DataTypes.StrategyStep[] memory _strategySteps);

    /**
     * @notice Returns the Strategy Steps corresponding to _tokensHash
     * @param _tokensHash Hash of the underlying token address/addresses
     * @return Returns the List of Strategies corresponding to _tokensHash provided
     */
    function getTokenToStrategies(bytes32 _tokensHash) external view returns (bytes32[] memory);
}