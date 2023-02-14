// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../interfaces/IVaultHelper.sol";

abstract contract SubCollectionHelper is OwnableUpgradeable, IVaultHelper {
    error InvalidNFT(uint256 _idx);

    address public override nftContract;

    function initialize(address _nftContract) external initializer {
        __Ownable_init();
        nftContract = _nftContract;
    }

    /// @notice Returns the owner of the nft at index `_idx`
    /// @dev If the owner of the nft is this contract we return the address of the {NFTVault} for compatibility
    /// @param _idx The nft index
    /// @return The owner of the nft if != `address(this)`, otherwise the owner of this contract
    function ownerOf(uint256 _idx) external view override returns (address) {
        if (!isValid(_idx))
            revert InvalidNFT(_idx);

        address account = IERC721Upgradeable(nftContract).ownerOf(_idx);

        return account == address(this) ? owner() : account;
    }

    /// @notice Function called by {NFTVault} to transfer nfts. Can only be called by the owner
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _idx The index of the nft to transfer
    function transferFrom(address _from, address _to, uint256 _idx) external override onlyOwner {
        if (!isValid(_idx))
            revert InvalidNFT(_idx);

        address _owner = owner();
        _from = _from == _owner
            ? address(this)
            : _from;

        _to = _to == _owner
            ? address(this)
            : _to;

        IERC721Upgradeable(nftContract).transferFrom(_from, _to, _idx);
    }

    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _idx The index of the rock to transfer
    function safeTransferFrom(address _from, address _to, uint256 _idx) external override onlyOwner {
        if (!isValid(_idx))
            revert InvalidNFT(_idx);
        
        address _owner = owner();
        IERC721Upgradeable _nftContract = IERC721Upgradeable(nftContract);
        //we are assuming _from and _to won't both be the owner
        if (_to == _owner)
            _nftContract.transferFrom(_from, address(this), _idx);
        else if (_from == _owner)
            _nftContract.safeTransferFrom(address(this), _to, _idx);
        else
            _nftContract.safeTransferFrom(_from, _to, _idx);
    }

    /// @dev Prevent the owner from renouncing ownership. Having no owner would render this contract unusable
    function renounceOwnership() public view override onlyOwner {
        revert();
    }

    function isValid(uint256 _idx) internal view virtual returns (bool);
}