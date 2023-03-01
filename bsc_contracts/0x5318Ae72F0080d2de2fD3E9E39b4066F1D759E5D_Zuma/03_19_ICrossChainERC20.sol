// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Required interface of an CrossChainERC20 compliant contract.
 */
interface ICrossChainERC20 is IERC20 {
    /**
     * @notice fetchCrossChainGasLimit Used to fetch CrossChainGas
     * @return crossChainGas that is set
     */
    function fetchCrossChainGasLimit() external view returns (uint256);

    function transferCrossChain(
        uint8 _chainID,
        address _recipient,
        uint256 _amount,
        uint256 _crossChainGasPrice
    ) external returns (bool, bytes32);
}