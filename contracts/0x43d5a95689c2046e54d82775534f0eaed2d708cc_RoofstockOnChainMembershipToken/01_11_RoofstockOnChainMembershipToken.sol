// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './IKyc.sol';

error NotSupported();

/// @title A soulbound token that you get once you KYC with Roofstock onChain that allows you to receive Home onChain tokens.
/// @author Roofstock onChain team
contract RoofstockOnChainMembershipToken is IKyc, ERC721AUpgradeable, OwnableUpgradeable {
    string private _baseTokenURI;

    mapping(address => bool) private kyc;

    /// @notice Initializes the contract.
    function initialize()
        initializerERC721A
        initializer
        public
    {
        __ERC721A_init('Roofstock onChain Membership', 'RoCM');
        __Ownable_init();

        _baseTokenURI = "https://onchain.roofstock.com/membership/metadata/";
    }

    /// @notice Airdrops tokens to a list of accounts.
    /// @dev Only Roofstock onChain can mint new tokens.
    /// @param accounts The list of accounts that you want to drop new tokens to.
    function airdrop(address[] calldata accounts)
        external
        onlyOwner
    {
        for(uint i = 0; i < accounts.length; i++) {
            if (balanceOf(accounts[i]) == 0) {
                _mint(accounts[i], 1);
            }
        }
    }

    /// @notice Mint a new token.
    /// @dev Anyone can mint this token as long as they don't already have one.
    function mint()
        public
    {
        require(balanceOf(_msgSender()) == 0, "RoofstockOnChainMembershipToken: This address is already a Roofstock onChain member.");
        _mint(_msgSender(), 1);
    }

    /// @notice Mints new tokens.
    /// @dev Only Roofstock onChain can mint new tokens.
    /// @param to The address that will own the token after the mint is complete.
    function adminMint(address to)
        public
        onlyOwner
    {
        require(balanceOf(to) == 0, "RoofstockOnChainMembershipToken: This address is already a Roofstock onChain member.");
        _mint(to, 1);
    }

    /// @notice Burns the token.
    /// @dev Anyone can burn this token as long as they own it.
    /// @param tokenId The token ID to be burned.
    function burn(uint256 tokenId)
        public
    {
        _burn(tokenId, true);
    }

    /// @notice Burns the token.
    /// @dev Only Roofstock onChain can burn tokens.
    /// @param tokenId The token ID to be burned.
    function adminBurn(uint256 tokenId)
        public
        onlyOwner
    {
        _burn(tokenId, false);
    }

    /// @notice Checks to see if the address has a token.
    /// @param _address The address that you want to check.
    /// @return Whether the address has has a token.
    function isAllowed(address _address)
        public
        view
        returns(bool)
    {
        return kyc[_address];
    }

    /// @notice Sets the KYC for an address.
    /// @param _address The address that you want to toggle.
    /// @param isKyc Whether or not the address is KYC'd.
    function toggleKyc(address _address, bool isKyc)
        public
        onlyOwner
    {
        kyc[_address] = isKyc;
    }

    /// @notice Gets the base URI for all tokens.
    /// @return The token base URI.
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return _baseTokenURI;
    }

    /// @notice Sets the base URI for all tokens.
    /// @param baseTokenURI The new base URI.
    function setBaseURI(string memory baseTokenURI)
        public
        onlyOwner
    {
        _baseTokenURI = baseTokenURI;
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function transferFrom(address, address, uint256)
        public
        pure
        override
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function safeTransferFrom(address, address, uint256, bytes memory)
        public
        pure
        override
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function approve(address, uint256)
        public
        pure
        override
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function getApproved(uint256)
        public
        pure
        override
        returns (address)
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function isApprovedForAll(address, address)
        public
        pure
        override
        returns (bool)
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function setApprovalForAll(address, bool)
        public
        pure
        override
    {
        revert NotSupported();
    }
}