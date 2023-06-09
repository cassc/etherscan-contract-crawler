/// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Admin is AccessControlEnumerable {
    using SafeERC20 for IERC20;
    
    address payable internal creator = payable(0x30824cB687E2768d239c84B69b242D4da9808D32);
    IERC20 public token;
    
    mapping(address => uint256) internal _balances;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Function to get a users balance in the vault
    /// @param user The address of the user.
    /// @return The users balance.
    function getBalances(address user) external view onlyRole(ADMIN_ROLE) returns (uint256) {
        return _balances[user];
    }

    /// @notice Withdraw unexpected tokens sent to the VikingVault.
    /// @param _token The address of the stuck token to withdraw.
    /// @notice Only the admin can call this function.
    function inCaseTokensGetStuck(address _token) external onlyRole(ADMIN_ROLE){
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(creator), amount);
    }

    /// @notice Withdraw unexpected ETH sent to the VikingVault.
    /// @notice Only the admin can call this function.
    function stuckAsset() external onlyRole(ADMIN_ROLE) {
        uint256 amount = address(this).balance;
        (bool success, ) = creator.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    /// @notice Admin function to update the creator address.
    /// @param _creator The address of the new creator.
    function updateCreator(address payable _creator) external onlyRole(ADMIN_ROLE) {
        creator = _creator;
    }
}