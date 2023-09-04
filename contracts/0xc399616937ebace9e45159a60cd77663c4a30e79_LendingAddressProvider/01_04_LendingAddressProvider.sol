// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ILendingAddressProvider.sol";

/// @title Lending Address Provider
/// @notice Manages addresses across Wasabi lending
contract LendingAddressProvider is Ownable, ILendingAddressProvider {
    mapping(address => bool) private _isLending;

    /// @notice Checks if given address is lending contract or not
    function isLending(address _lending) external view returns (bool) {
        return _isLending[_lending];
    }

    /// @notice Add NFTLending contract address
    /// @param _lending New NFTLending contract address
    function addLending(address _lending) external onlyOwner {
        require(_lending != address(0), "zero address");
        _isLending[_lending] = true;

        emit LendingAdded(_lending);
    }

    /// @notice Remove NFTLending contract address
    /// @param _lending NFTLending contract address to remove
    function removeLending(address _lending) external onlyOwner {
        require(_lending != address(0), "zero address");
        _isLending[_lending] = false;

        emit LendingRemoved(_lending);
    }
}