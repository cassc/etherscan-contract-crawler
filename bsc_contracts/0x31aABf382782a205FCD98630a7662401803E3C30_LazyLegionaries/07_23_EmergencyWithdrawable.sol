// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract EmergencyWithdrawable is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    event EmergencyWithdrawERC721(address indexed owner, address indexed token, uint256[] tokenIds);
    event EmergencyWithdrawERC20(address indexed owner, address indexed token, uint256 balance);
    event EmergencyWithdraw(address indexed owner, uint256 amount);

    /**
     * @notice Allows the owner to withdraw non-fungible tokens for emergencies
     * @param _token: NFT address
     * @param _tokenIds: tokenIds
     * @dev Callable by owner
     */
    function emergencyWithdraw(address _token, uint256[] memory _tokenIds) external onlyOwner {
        require(_tokenIds.length != 0, "Cannot recover zero balance");

        emit EmergencyWithdrawERC721(msg.sender, _token, _tokenIds);
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenIds[i]);
        }
    }

    /**
     * @notice Allows the owner to withdraw tokens for emergencies
     * @param _token: token address
     * @dev Callable by owner
     */
    function emergencyWithdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "Cannot recover zero balance");

        emit EmergencyWithdrawERC20(msg.sender, _token, balance);
        IERC20(_token).safeTransfer(address(msg.sender), balance);
    }

    /**
     * @notice Allows the owner to withdraw Ether for emergencies
     * @dev Callable by owner
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "Cannot recover zero balance");

        emit EmergencyWithdraw(msg.sender, balance);
        Address.sendValue(payable(msg.sender), balance);
    }
}