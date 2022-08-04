// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

abstract contract MultiOwnable {
    /// @notice The address which can admin mint for free, set merkle roots, and set auction params
    address public mintingOwner;
    /// @notice The address which can update the metadata uri
    address public metadataOwner;
    /// @notice The address which will be returned for the ERC721 owner() standard for setting royalties
    address public royaltyOwner;

    /// @notice Raised when an unauthorized user calls a gated function
    error AccessControl();

    constructor() {
        mintingOwner = msg.sender;
        metadataOwner = msg.sender;
        royaltyOwner = msg.sender;
    }

    modifier onlyMintingOwner() {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        _;
    }

    modifier onlyMetadataOwner() {
        if (msg.sender != metadataOwner) {
            revert AccessControl();
        }
        _;
    }

    modifier onlyRoyaltyOwner() {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _;
    }

    ////////////////////////////////////
    // ACCESS CONTROL ADDRESS UPDATES //
    ////////////////////////////////////

    /// @notice Update the mintingOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    function setMintingOwner(address _mintingOwner) external onlyMintingOwner {
        mintingOwner = _mintingOwner;
    }

    /// @notice Update the metadataOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    /// @dev Should only be revoked after setting an IPFS url so others can pin
    function setMetadataOwner(address _metadataOwner) external onlyMetadataOwner {
        metadataOwner = _metadataOwner;
    }

    /// @notice Update the royaltyOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    function setRoyaltyOwner(address _royaltyOwner) external onlyRoyaltyOwner {
        royaltyOwner = _royaltyOwner;
    }

    /// @notice The address which can set royalties
    function owner() external view returns (address) {
        return royaltyOwner;
    }
}