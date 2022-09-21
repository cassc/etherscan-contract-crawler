// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


// ░█▀▀▄ ▀█▀ ░█▀▀█ ▀█▀ ▀▀█▀▀ ─█▀▀█ ░█───    ░█▀▄▀█ ░█▀▀▀█ ░█▄─░█ ░█─▄▀ ░█▀▀▀ ░█──░█    ░█▀▀█ ░█▀▀█ ░█▀▀▀ ░█──░█ 
// ░█─░█ ░█─ ░█─▄▄ ░█─ ─░█── ░█▄▄█ ░█───    ░█░█░█ ░█──░█ ░█░█░█ ░█▀▄─ ░█▀▀▀ ░█▄▄▄█    ░█─── ░█▄▄▀ ░█▀▀▀ ░█░█░█ 
// ░█▄▄▀ ▄█▄ ░█▄▄█ ▄█▄ ─░█── ░█─░█ ░█▄▄█    ░█──░█ ░█▄▄▄█ ░█──▀█ ░█─░█ ░█▄▄▄ ──░█──    ░█▄▄█ ░█─░█ ░█▄▄▄ ░█▄▀▄█

contract DMC_Exoplanets is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint256 private _nftCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _nftCount = 0;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
        _nftCount++;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);

        // Update nftCount;
        for ( uint256 i = 0; i < ids.length; i++){
            _nftCount++;
        }

    }

    function mintNewTokens( uint256 quantities )
        public
        onlyRole(MINTER_ROLE)
    {
        // @dev: Initialize variables
        uint256 startToken = _nftCount + 1 ;

        // @dev: Do all the check regarding if the function can be executed
        require(!exists(startToken), "The start token id is already minted !");
        
        // TODO: Check if transaction can be done regarding cost of the transaction.
        
        // @dev: Prepare variable to use the inhereted _mintBatch function from OpenZeppelin
        uint256[] memory tokenIds = new uint[](quantities);
        uint256[] memory tokenAmounts = new uint[](quantities);
        for( uint256 i = 0; i < quantities; i++ ){
            tokenIds[i] = startToken + i;
            tokenAmounts[i] = 1;
            _nftCount++;
        }
        _mintBatch(msg.sender, tokenIds, tokenAmounts, "");

    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getCount()
        public
        view
        onlyRole(MINTER_ROLE)
        returns (uint256 count)
    {
        count = _nftCount;
    }
}