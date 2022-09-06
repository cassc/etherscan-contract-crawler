// SPDX-License-Identifier: Apache2
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract KYCT is ERC721URIStorageUpgradeable, AccessControlUpgradeable {
    string public constant VERSION = "1.0.0";

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /**
     * Message: "This is a non-transferable token"
     * Reason: This token is a soulbound token, no possiblity of moving it to other accounts.
     */
    string public constant NON_TRANSFERABLE_TOKEN = "NTT";

    function initialize() public initializer {
        __ERC721_init("Identity Token", "KYCT");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    struct MappingData {
        uint256[] issuedIds;
        bool isMinted;
    }

    mapping(address => MappingData) private tokenIdMapping;

    function mint(address to, string memory uri)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 issuedId = _tokenIds.current();
        _safeMint(to, issuedId);
        _setTokenURI(issuedId, uri);

        if (tokenIdMapping[to].isMinted) {
            tokenIdMapping[to].issuedIds.push(issuedId);
        } else {
            uint256[] memory issuedIds = new uint256[](1);
            issuedIds[0] = issuedId;

            tokenIdMapping[to] = MappingData(issuedIds, true);
        }

        return issuedId;
    }

    function burn(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._burn(tokenId);
    }

    function transferRole(
        bytes32 role,
        address from,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(from != to, "Same address");
        require(to != address(0), "Zero address");

        _revokeRole(role, from);
        _grantRole(role, to);
    }

    function getTokenIds(address ownerAddress)
        external
        view
        returns (uint256[] memory)
    {
        return tokenIdMapping[ownerAddress].issuedIds;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function approve(
        address, /*to*/
        uint256 /*tokenId*/
    ) public virtual override {
        revert(NON_TRANSFERABLE_TOKEN);
    }

    function setApprovalForAll(
        address, /*operator*/
        bool /*approved*/
    ) public virtual override {
        revert(NON_TRANSFERABLE_TOKEN);
    }

    function transferFrom(
        address, /*from*/
        address, /*to*/
        uint256 /*tokenId*/
    ) public virtual override {
        revert(NON_TRANSFERABLE_TOKEN);
    }

    function safeTransferFrom(
        address, /*from*/
        address, /*to*/
        uint256 /*tokenId*/
    ) public virtual override {
        revert(NON_TRANSFERABLE_TOKEN);
    }

    function safeTransferFrom(
        address, /*from*/
        address, /*to*/
        uint256, /*tokenId*/
        bytes memory /*data*/
    ) public virtual override {
        revert(NON_TRANSFERABLE_TOKEN);
    }
}