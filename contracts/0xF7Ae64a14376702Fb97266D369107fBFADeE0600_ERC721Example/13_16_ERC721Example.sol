// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "../interfaces/IHostileMarketplaceRegistry.sol";
import "../interfaces/IHostileMarketplaceRegistryImplementer.sol";

contract ERC721Example is
    ERC721,
    Ownable,
    ERC2981ContractWideRoyalties,
    IHostileMarketplaceRegistryImplementer
{
    address public deployedHostileRegistryAddress;
    bool public useRegistry;

    constructor(
        address marketplaceRegistryAddress
    ) ERC721("ERC721Example", "Example") {
        if (marketplaceRegistryAddress != address(0)) {
            setBlocklistRegistry(marketplaceRegistryAddress);
            useRegistry = true;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981Base) returns (bool) {
        return
            interfaceId ==
            type(IHostileMarketplaceRegistryImplementer).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Allows to set the royalties on the contract
    /// @dev This function in a real contract should be protected with a onlyOwner (or equivalent) modifier
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public {
        _setRoyalties(recipient, value);
    }

    function setBlocklistRegistry(address _t) public onlyOwner {
        // This contract allows the registry address to be changed by its owner, but each implementer should decide for
        // themselves whether to lock to the current blocked marketplace registry or to allow it to change.
        deployedHostileRegistryAddress = _t;
    }

    function requireAddressIsNotBlocked(address addressToCheck) public {
        if (useRegistry) {
            IHostileMarketplaceRegistry(deployedHostileRegistryAddress)
                .requireAddressIsNotBlocked(addressToCheck);
        }
    }

    function toggleMarketplaceBlockList(
        bool newRegistryStatus
    ) public onlyOwner {
        // Similarly, this contract allows the marketplace block to be turned off or on.
        useRegistry = newRegistryStatus;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        // Block approvals for blocked marketplace addresses
        if (approved) {
            requireAddressIsNotBlocked(operator);
        }
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        address owner = ownerOf(tokenId);
        if (_msgSender() != owner) {
            // This would block marketplaces that were added to the registry after the user
            // called approve() or setApprovalForAll(),
            // at the expense of some gas on each transfer.
            // However, we should never prevent a transfer by the token owner
            // regardless of block status.
            requireAddressIsNotBlocked(_msgSender());
        }
        super.transferFrom(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal override {
        // Block approvals for blocked marketplace addresses
        requireAddressIsNotBlocked(to);
        super._approve(to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Block transfers to blocked custodial marketplaces or brokers.  If you're not worried about those kind of
        // marketplaces, you can save gas by skipping this check.
        requireAddressIsNotBlocked(to);
        super._transfer(from, to, tokenId);
    }

    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}