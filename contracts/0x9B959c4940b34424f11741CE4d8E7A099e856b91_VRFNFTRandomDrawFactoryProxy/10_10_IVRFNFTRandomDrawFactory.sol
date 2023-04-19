// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVRFNFTRandomDraw} from "./IVRFNFTRandomDraw.sol";

interface IVRFNFTRandomDrawFactory {
    /// @notice Cannot be initialized with a zero address impl.
    error IMPL_ZERO_ADDRESS_NOT_ALLOWED();

    /// @notice Event emitted when a new drawing contract is created
    event SetupNewDrawing(address user, address drawing);

    /// @notice Called to initialize the factory contract from the proxy
    /// @param _initialOwner the initial owner for the factory
    function initialize(address _initialOwner) external;

    /// @notice Emitted when the factory is setup
    event SetupFactory();

    function getDrawingAddressById(address admin, uint256 id)
        external
        returns (address);

    function getNextDrawingAddress(address admin) external returns (address);

    /// @notice Function to make a new drawing
    /// @param settings settings for the new drawing
    function makeNewDraw(IVRFNFTRandomDraw.Settings memory settings)
        external
        returns (address, uint256);
}