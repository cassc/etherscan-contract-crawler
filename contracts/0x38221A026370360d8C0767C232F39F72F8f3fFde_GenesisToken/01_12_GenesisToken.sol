// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title GenesisToken
 *
 */
contract GenesisToken is ERC1155, ReentrancyGuard, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");
    bytes32 public constant PRIVATE_MINTER_ROLE = keccak256("PRIVATE_MINTER_ROLE");

    event GenesisTokenRedeemed(address _sender, uint256 _categoryId);
    event PrivateMintExecuted(address _sender, uint256 _categoryId, uint256 _amount);

    string public name;
    string public symbol;

    /**
     * @dev Creates an instance of `GenesisToken`.
     *
     * 'msg.sender' gets the Admin role.
     *
     */
    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev It mints/creates 1 Genesis Token calling `_mint()` from ERC1155 OpenZeppelin implementation.
     * To be called by another smart contract or wallet with the MINTER_ROLE role.
     *
     * @param _account Token owner address - cannot be the zero address.
     * @param _category Genesis Token category
     * @param _data Additional data with no specified format
     */
    function mint(
        address _account,
        uint256 _category,
        bytes memory _data
    ) external nonReentrant onlyRole(MINTER_ROLE) {
        _mint(_account, _category, 1, _data);
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external nonReentrant onlyRole(MINTER_ROLE) {
        _mintBatch(_to, _ids, _amounts, _data);
    }

    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyRole(REDEEMER_ROLE) {
        _burnBatch(_account, _ids, _amounts);
    }

    /**
     * @dev It burns 1 Genesis Token. To be called by another smart contract or wallet with the MINTER_ROLE role.
     *
     * Emits a {GenesisTokenRedeemed} event.
     *
     * @param _account Token owner address - cannot be the zero address.
     * @param _category Genesis Token category
     */
    function redeem(address _account, uint256 _category) external onlyRole(REDEEMER_ROLE) {
        require(balanceOf(_account, _category) >= 1, "HGT: No Genesis Token.");
        _burn(_account, _category, 1);

        emit GenesisTokenRedeemed(_account, _category);
    }

    /**
     * @dev It mints Genesis Token. To be called by an admin address that can private mint.
     *
     * Emits a {PrivateMintExecuted} event.
     *
     * @param _account Token owner address - cannot be the zero address.
     * @param _amountToMint Amount to mint
     * @param _category Genesis Token category
     * @param _data Additional data with no specified format
     */
    function privateMintBatch(
        address _account,
        uint256 _amountToMint,
        uint256 _category,
        bytes memory _data
    ) external nonReentrant onlyRole(PRIVATE_MINTER_ROLE) {
        _mint(_account, _category, _amountToMint, _data);

        emit PrivateMintExecuted(_account, _category, _amountToMint);
    }

    /**
     * @dev Sets a new URI for all token categories
     */
    function setURI(string memory _newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(_newuri);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}