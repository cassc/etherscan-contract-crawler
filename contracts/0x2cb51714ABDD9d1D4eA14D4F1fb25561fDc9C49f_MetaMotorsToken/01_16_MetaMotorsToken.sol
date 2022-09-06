// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MetaMotorsToken is ERC721A, AccessControl, ReentrancyGuard, ERC2981 {
    using Strings for uint256;

    //Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    //Flags
    bool public isMintingPermanentlyLocked = false;
    bool public isMintingActive = false;
    bool public isBurningActive = false;

    //URI extension
    string private _uriExtension = "";

    //Base uri for metadata
    string private _baseUri;

    /**
     * @dev Initializes the contract by setting `initialBaseUri`, `name`, `symbol`,
     * `collectionsPrices`, `initialRoyaltyReceiver`, and `intialRoyaltyFeeNumerator`.
     * All roles are assigned to the creator of the contract.
     */
    constructor(
        string memory initialBaseUri,
        string memory name,
        string memory symbol,
        address initialRoyaltyReceiver,
        uint96 intialRoyaltyFeeNumerator
    ) ERC721A(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        setBaseURI(initialBaseUri);
        setDefaultRoyalty(initialRoyaltyReceiver, intialRoyaltyFeeNumerator);
    }

    modifier notPermanentlyLocked() {
        require(!isMintingPermanentlyLocked, "Minting permanently locked");
        _;
    }

    modifier mintingActive() {
        require(isMintingActive, "Mint is not active");
        _;
    }

    modifier burningActive() {
        require(isBurningActive, "Burn is not active");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Get the base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev Update the base token URI
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setBaseURI(string memory baseUri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseUri = baseUri;
    }

    /**
     * @dev Get the base token URI
     */
    function _URIExtension() internal view virtual returns (string memory) {
        return _uriExtension;
    }

    /**
     * @dev Update the base token URI
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setURIExtension(string memory uriExtension)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _uriExtension = uriExtension;
    }

    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev Permanently lock minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function permanentlyLockMinting() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isMintingPermanentlyLocked = true;
    }

    /**
     * @dev Set the active/inactive state of minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleMintingActive() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isMintingActive = !isMintingActive;
    }

    /**
     * @dev Set the active/inactive state of burning
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleBurningActive() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isBurningActive = !isBurningActive;
    }

    /**
     * @dev Get total tokens minted
     */
    function getTotalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev mint `quantity` to `to`
     *
     * Requirements:
     *
     * - minting is not permanently locked
     * - the caller must be a minter role
     */
    function mint(address to, uint256 quantity)
        external
        nonReentrant
        mintingActive
        notPermanentlyLocked
        onlyRole(MINTER_ROLE)
    {
        _mint(to, quantity);
    }

    /**
     * @dev mint batch `quantities` to `tos`
     *
     * Requirements:
     *
     * - minting is not permanently locked
     * - the caller must be a minter role
     */
    function mintBatch(address[] memory tos, uint256[] memory quantities)
        external
        nonReentrant
        notPermanentlyLocked
        onlyRole(MINTER_ROLE)
    {
        require(
            tos.length == quantities.length,
            "tos length much equal quantities length"
        );
        for (uint256 index = 0; index < tos.length; index++) {
            _mint(tos[index], quantities[index]);
        }
    }

    /**
     * @dev burn `from` token `tokenId`
     *
     * Requirements:
     *
     * - burning must be active
     * - the caller must be a burner role
     */
    function burn(uint256 tokenId)
        external
        nonReentrant
        burningActive
        onlyRole(BURNER_ROLE)
    {
        _burn(tokenId, true);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        _URIExtension()
                    )
                )
                : "";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Widthraw balance on contact to msg sender
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function withdrawMoney() external onlyRole(DEFAULT_ADMIN_ROLE) {
        address payable to = payable(_msgSender());
        to.transfer(address(this).balance);
    }
}