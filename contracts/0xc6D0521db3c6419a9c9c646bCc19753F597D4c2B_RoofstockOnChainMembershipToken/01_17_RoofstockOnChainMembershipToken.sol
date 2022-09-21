// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import './IKyc.sol';

error NotSupported();

/// @title A soulbound token that you get once you KYC with Roofstock onChain that allows you to receive Home onChain tokens.
/// @author Roofstock onChain team
contract RoofstockOnChainMembershipToken is IKyc, ERC721AUpgradeable, ERC721AQueryableUpgradeable, AccessControlUpgradeable {
    string private _baseTokenURI;

    address private _owner;

    mapping(address => bool) private kyc;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant TOGGLE_KYC_ROLE = keccak256("TOGGLE_KYC_ROLE");

    /// @notice Initializes the contract.
    function initialize()
        initializerERC721A
        initializer
        public
    {
        __ERC721A_init('Roofstock onChain Membership', 'RoCM');
        __AccessControl_init();

        _baseTokenURI = "https://onchain.roofstock.com/membership/metadata/";

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _grantRole(TOGGLE_KYC_ROLE, _msgSender());
    }

    /// @notice Airdrops tokens to a list of accounts.
    /// @dev Only Roofstock onChain can mint new tokens.
    /// @param accounts The list of accounts that you want to drop new tokens to.
    function airdrop(address[] calldata accounts)
        external
        onlyRole(MINTER_ROLE)
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
        onlyRole(MINTER_ROLE)
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
        onlyRole(BURNER_ROLE)
    {
        _burn(tokenId, false);
    }

    /// @notice Checks to see if the address has a token and is KYC'd.
    /// @param _address The address that you want to check.
    /// @return Whether the address has has a token and it is KYC'd.
    function isAllowed(address _address)
        public
        view
        returns(bool)
    {
        return balanceOf(_address) > 0 && kyc[_address];
    }

    /// @notice Sets the KYC for an address.
    /// @param _address The address that you want to toggle.
    /// @param isKyc Whether or not the address is KYC'd.
    function toggleKyc(address _address, bool isKyc)
        public
        onlyRole(TOGGLE_KYC_ROLE)
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
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
    }

    /// @notice Sets the owner of the contract.
    /// @dev Can only be set by an admin.
    function setOwner(address newOwner)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _owner = newOwner;
    }

    /// @notice Returns the address of the current owner.
    /// @return The address of the current owner.
    function owner()
        external
        view
        returns (address)
    {
        return _owner;
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function transferFrom(address, address, uint256)
        public
        pure
        override (ERC721AUpgradeable, IERC721AUpgradeable)
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function safeTransferFrom(address, address, uint256, bytes memory)
        public
        pure
        override (ERC721AUpgradeable, IERC721AUpgradeable)
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function approve(address, uint256)
        public
        pure
        override (ERC721AUpgradeable, IERC721AUpgradeable)
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function getApproved(uint256)
        public
        pure
        override (ERC721AUpgradeable, IERC721AUpgradeable)
        returns (address)
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function isApprovedForAll(address, address)
        public
        pure
        override (ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        revert NotSupported();
    }

    /// @dev This function is not allowed because we want the token to be soulbound.
    function setApprovalForAll(address, bool)
        public
        pure
        override (ERC721AUpgradeable, IERC721AUpgradeable)
    {
        revert NotSupported();
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721AUpgradeable, IERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == 0x7965db0b; // ERC165 interface ID for AccessControl.
    }
}