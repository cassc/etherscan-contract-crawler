// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IMasterChef {
    function userInfo(uint256, address) external view returns (uint256, uint256);
}


interface IVault {
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );
}