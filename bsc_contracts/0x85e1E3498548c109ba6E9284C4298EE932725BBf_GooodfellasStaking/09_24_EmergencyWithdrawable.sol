// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract EmergencyWithdrawable is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    event EmergencyWithdrawERC721(address indexed owner, address indexed token, uint256[] tokenIds);

    /**
     * @notice Allows the owner to withdraw non-fungible tokens for emergencies
     * @param _token: NFT address
     * @param _tokenIds: tokenIds
     * @dev Callable by owner
     */
    function emergencyWithdraw(address _token, uint256[] calldata _tokenIds) public onlyOwner {
        emit EmergencyWithdrawERC721(msg.sender, _token, _tokenIds);
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenIds[i]);
        }
    }
}