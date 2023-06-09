// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@amxx/hre/contracts/ENSReverseRegistration.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";


contract Jaguars is
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    MulticallUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private baseURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory __name, string memory __symbol)
    public initializer()
    {
        __ERC721_init(__name, __symbol);
        __ERC721Burnable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address account, uint256 tokenId)
    external onlyRole(MINTER_ROLE)
    {
        _mint(account, tokenId);
    }

    function setName(address ensRegistry, string calldata ensName)
    external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ENSReverseRegistration.setName(ensRegistry, ensName);
    }

    function setBaseURI(string calldata newBaseURI)
    external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    /**
     * Override
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}