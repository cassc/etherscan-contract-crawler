// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AgoraNFT is Pausable, ERC1155, AccessControl {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool public transferPaused;

    mapping(uint256 => uint256) public supplyLeft;

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Iniial Supply
        supplyLeft[1] = 10;
        supplyLeft[2] = 25; // Socrates
        supplyLeft[3] = 150; // Plato
        supplyLeft[4] = 200; // Aristotle
        supplyLeft[5] = 3000; // Pythagoras
        supplyLeft[6] = 6000; // Epicurus
        supplyLeft[7] = 46667; // Thales
        supplyLeft[8] = type(uint256).max; // Citizen
    }

    modifier whenNotTransferPaused() {
        require(!transferPaused, "transfer paused");
        _;
    }

    modifier whenTransferPaused() {
        require(transferPaused, "transfer unpaused");
        _;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function pauseTransfer()
        public
        whenNotTransferPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        transferPaused = true;
    }

    function unpauseTransfer()
        public
        whenTransferPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        transferPaused = false;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override whenNotTransferPaused {
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override whenNotTransferPaused {
        return super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) whenNotPaused {
        for (uint256 i; i < ids.length; i++) {
            require(supplyLeft[ids[i]] >= amounts[i], "not enough NFT");
            supplyLeft[ids[i]] -= amounts[i];
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}