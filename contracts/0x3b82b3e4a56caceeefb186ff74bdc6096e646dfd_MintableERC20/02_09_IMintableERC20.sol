// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintableERC20 is IERC20 {

    function mintAmount(address[] calldata accounts, uint256 amount) external;

    function mintAmounts(address[] calldata accounts, uint256[] calldata amounts) external;
    
    function addMaintainer(address maintainer) external;
    
    function removeMaintainer(address maintainer) external;
    
    function maintainers() external view returns (address[] memory);

    function maxMintedAmount() external view returns (uint256);
}