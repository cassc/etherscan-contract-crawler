// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title LDRToken
 */
contract LDRToken is ERC1155, ReentrancyGuard, Pausable, AccessControl {
    using SignatureChecker for address;

    // Wallet who will be the backend signer
    address public signer;

    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    // mapping of hash of address + category -> bool.
    mapping(bytes32 => bool) private categoriesMinted;

    event LDRTokenRedeemed(address _sender, uint256 _categoryId);

    string public name;
    string public symbol;

    /**
     * @dev Creates an instance of `LDRToken`.
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
     * @dev It mints/creates 1 LDR Token calling `_mint()` from ERC1155 OpenZeppelin implementation.
     *      Each address can only mint one token per category.
     * @param _category LDR Token category
     * @param _data Additional data with no specified format
     * @param _signature Signature authorizing the mint
     */
    function mint(
        uint256 _category,
        bytes memory _data,
        bytes memory _signature
    ) external nonReentrant whenNotPaused {
        require(isSignatureValid(_category, _signature), "LDRT: Invalid signature");
        require(_category >= 1, "LDRT: Invalid category. It is less than 1.");
        require(_category <= 9, "LDRT: Invalid category. It is greater than 9.");

        bytes32 hashAdrrCategory = keccak256(abi.encodePacked(msg.sender, _category));
        bool hasMinted = categoriesMinted[hashAdrrCategory];
        require(
            !hasMinted,
            "LDRT: Address already has token for that category."
        );
        categoriesMinted[hashAdrrCategory] = true;

        // 1 is because it will mint 1 token for that category
        _mint(msg.sender, _category, 1, _data);
    }

    /// @dev Returns if signature is valid
    function isSignatureValid(uint256 _category, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        bytes32 result = keccak256(abi.encodePacked(msg.sender, _category));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyRole(REDEEMER_ROLE) {
        _burnBatch(_account, _ids, _amounts);
    }

    /**
     * @dev It burns 1 LDR Token. To be called by another smart contract or wallet with the REDEEMER_ROLE role.
     *
     * Emits a {LDRTokenRedeemed} event.
     *
     * @param _account Token owner address - cannot be the zero address.
     * @param _category LDR Token category
     */
    function redeem(address _account, uint256 _category) external onlyRole(REDEEMER_ROLE) {
        require(balanceOf(_account, _category) >= 1, "LDRT: No LDR Token.");
        _burn(_account, _category, 1);

        emit LDRTokenRedeemed(_account, _category);
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

    /**
     * @dev Sets new signer address. Only Admin can call this function.
     *
     * @param _signer The account address to sign licenses requests
     */
    function updateSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    /// @dev Pause
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @dev Unpause
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}