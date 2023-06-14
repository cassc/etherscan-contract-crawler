// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IERC20Wnft.sol";

/// @title IERC721Pool
/// @author Hifi
interface IERC721Pool is IERC20Wnft {
    /// CUSTOM ERRORS ///

    error ERC721Pool__CallerNotFactory(address factory, address caller);
    error ERC721Pool__MustContainExactlyOneNFT();
    error ERC721Pool__PoolFrozen();
    error ERC721Pool__NFTAlreadyInPool(uint256 id);
    error ERC721Pool__NFTNotFoundInPool(uint256 id);
    error ERC721Pool__ZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when NFT are deposited and an equal amount of pool tokens are minted.
    /// @param id The asset token ID sent from the user's account to the pool.
    /// @param beneficiary The address to receive the pool tokens.
    /// @param caller The caller of the function equal to msg.sender.
    event Deposit(uint256 id, address beneficiary, address caller);

    /// @notice Emitted when the last NFT of a pool is rescued.
    /// @param lastNFT The last NFT of the pool.
    /// @param to The address to which the NFT was sent.
    event RescueLastNFT(uint256 lastNFT, address to);

    /// @notice Emitted when NFT are withdrawn from the pool in exchange for an equal amount of pool tokens.
    /// @param id The asset token IDs released from the pool.
    /// @param beneficiary The address to receive the NFT.
    /// @param caller The caller of the function equal to msg.sender.
    event Withdraw(uint256 id, address beneficiary, address caller);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the asset token ID held at index.
    /// @param index The index to check.
    function holdingAt(uint256 index) external view returns (uint256);

    /// @notice Returns true if the asset token ID is held in the pool.
    /// @param id The asset token ID to check.
    function holdingContains(uint256 id) external view returns (bool);

    /// @notice Returns the total number of asset token IDs held.
    function holdingsLength() external view returns (uint256);

    /// @notice A boolean flag indicating whether the pool is frozen.
    function poolFrozen() external view returns (bool);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Deposit NFT in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Deposit} event.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the Pool to transfer the NFT.
    /// - The pool must not be frozen.
    /// - The address `beneficiary` must not be the zero address.
    ///
    /// @param id The asset token ID sent from the user's account to the pool.
    /// @param beneficiary The address to receive the pool tokens. Can be the caller themselves or any other address.
    function deposit(uint256 id, address beneficiary) external;

    /// @notice Allows the factory to rescue the last NFT in the pool and set the pool to frozen.
    ///
    /// Emits a {RescueLastNFT} event.
    ///
    /// @dev Requirements:
    /// - The caller must be the factory.
    /// - The pool must only hold one NFT.
    ///
    /// @param to The address to send the NFT to.
    function rescueLastNFT(address to) external;

    /// @notice Allows the factory to set the ENS name for the pool.
    ///
    /// Emits a {ENSNameSet} event.
    ///
    /// @dev Requirements:
    /// - The caller must be the factory.
    ///
    /// @param registrar The address of the ENS registrar.
    /// @param name The name to set.
    /// @return The ENS node hash.
    function setENSName(address registrar, string memory name) external returns (bytes32);

    /// @notice Withdraws a specified NFT in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// @dev Requirements:
    /// - The pool must not be frozen.
    /// - The address `beneficiary` must not be the zero address.
    /// - The specified NFT must be held in the pool.
    /// - The caller must hold the equivalent amount of pool tokens
    ///
    /// @param id The asset token ID to be released from the pool.
    /// @param beneficiary The address to receive the NFT. Can be the caller themselves or any other address.
    function withdraw(uint256 id, address beneficiary) external;
}