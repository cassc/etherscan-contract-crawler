// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of Asset
 */
interface IAsset is IERC20Metadata {
    function aggregateAccount() external view returns (address);

    function cash() external view returns (uint256);

    function liability() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;

    function getCompensationRatio() external view returns (uint256);
}