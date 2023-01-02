// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC5192} from "./IERC5192.sol";
import {IMVHQSBT} from "./IMVHQSBT.sol";

/// @title MVHQ Soulbound Tokens
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
contract MVHQSBT is
    Initializable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    IERC5192,
    IMVHQSBT
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @notice Minter Role
    /// @dev Will be granted to the Orchestrator
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice  Upgrader Role
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice Token ID counter
    CountersUpgradeable.Counter private _tokenIdCounter;
    /// @notice base URI used to retrieve metadata
    /// @dev tokenURI will use .json at the end for each token
    string public baseURI;
    /// @notice Enable/disable tokens transfer
    bool private _tokenLocked;

    /// @notice Emitted when the token transfer status change.
    event ToggleTokenLocked(address sender, bool state);
    /// @notice Emitted when the baseURI change.
    event BaseURIChanged(
        address indexed sender,
        string previousURI,
        string newURI
    );
    /// @notice Emitted when Whale mint.
    event WhaleMint(address indexed _to, uint256 tokenId);

    /// @notice enable/disable Token Transfer
    /// Emits an {ToggleTokenLocked} event.
    function toggleTokenLoked() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenLocked = !_tokenLocked;
        emit ToggleTokenLocked(msg.sender, _tokenLocked);
    }

    /// @notice Used to set the baseURI for metadata
    /// @param newBaseURI the base URI
    /// Emits an {BaseURIChanged} event.
    function setBaseURI(string memory newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (bytes(newBaseURI).length == 0) revert InvalidBaseURI();
        emit BaseURIChanged(msg.sender, baseURI, newBaseURI);
        baseURI = newBaseURI;
    }

    /// @notice Safely mints and transfers it to `to`.
    /// @dev Explain to a developer any extra details
    /// @param to If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    /// @param isWhale if the token to be minted is a whale soulbound token
    /// Emits a {Transfer} event.
    function safeMint(address to, bool isWhale) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        if (_tokenLocked) emit Locked(tokenId);
        else emit Unlocked(tokenId);
        if (isWhale) emit WhaleMint(to, tokenId);
    }

    /// @inheritdoc	IERC5192
    function locked(uint256 tokenId) external view returns (bool) {
        if (!_exists(tokenId)) revert InvalidTokenID();
        return _tokenLocked;
    }

    function initialize() public initializer {
        __AccessControl_init_unchained();
        __ERC721_init_unchained("MVHQ SBT", "MVHQSBT");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        baseURI = "https://www.mvhq.io/";
        _tokenLocked = true;
        _tokenIdCounter.increment();
    }

    /// @notice Approve operator for a token
    /// @dev overriden to avoid approvals for SBT
    function approve(address to, uint256 tokenId) public virtual override {
        if (_tokenLocked) revert ApprovalNotAllowed();
        super.approve(to, tokenId);
    }

    /// @notice Approve operator for an address
    /// @dev overriden to avoid approvals for SBT
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (_tokenLocked) revert ApprovalNotAllowed();
        super.setApprovalForAll(operator, approved);
    }

    /// @notice Override of ERC721, AccessControl supportsInterface function
    /// @param _interfaceId the interfaceId
    /// @return bool if interfaceId is supported or not
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        bytes4 interfaceIDIERC5192 = 0xb45a3c0e;
        return
            _interfaceId == interfaceIDIERC5192 ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Hook to check whether a key is transferrable
    /// @dev admins can always transfer regardless of whether keys are flagged
    /// @param _from address that holds the tokenId
    /// @param _to address that will receive the tokenId
    /// @param _startTokenId index of first tokenId that will be transferred
    /// @param _quantity amount that will be transferred
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _startTokenId,
        uint256 _quantity
    ) internal override {
        if (_tokenLocked && !hasRole(MINTER_ROLE, msg.sender))
            revert TransferNotAllowed();
        super._beforeTokenTransfer(_from, _to, _startTokenId, _quantity);
    }

    /// @inheritdoc	ERC721Upgradeable
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) // solhint-disable-line
        internal
        virtual
        override
        onlyRole(UPGRADER_ROLE)
    {} // solhint-disable-line
}