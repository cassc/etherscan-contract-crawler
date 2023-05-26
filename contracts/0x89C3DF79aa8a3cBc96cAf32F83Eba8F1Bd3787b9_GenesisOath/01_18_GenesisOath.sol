// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./../../interfaces/IMintable.sol";

contract GenesisOath is
    IMintable,
    ERC1155,
    ERC1155Supply,
    AccessControlEnumerable,
    ReentrancyGuard
{
    using Address for address;
    using Strings for string;

    event Minted(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _amount
    );

    event TokenURISet(uint256 indexed _tokenId, string indexed _tokenURI);

    string public name = "Genesis Oath";
    string public symbol = "MTNT";

    uint256 public constant MAX_TIER_1 = 6000;
    uint256 public constant TOKEN_ID_TIER_1 = 1;

    uint256 public constant MAX_TIER_2 = 1000;
    uint256 public constant TOKEN_ID_TIER_2 = 2;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant ADMIN_ROLE = 0x00;

    bool public metadataFrozen;

    mapping(uint256 => string) public tokenURIs;

    constructor(address adminAddress, address devAddress)
        ERC1155("")
        ReentrancyGuard()
    {
        _grantRole(ADMIN_ROLE, adminAddress);
        _grantRole(ADMIN_ROLE, devAddress);
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public override nonReentrant onlyMinter {
        require(
            tokenId == TOKEN_ID_TIER_1 || tokenId == TOKEN_ID_TIER_2,
            "Invalid token id"
        );
        uint256 tokenSupply = tokenId == TOKEN_ID_TIER_1
            ? totalSupply(TOKEN_ID_TIER_1)
            : totalSupply(TOKEN_ID_TIER_2);
        uint256 tokenMax = tokenId == TOKEN_ID_TIER_1 ? MAX_TIER_1 : MAX_TIER_2;
        require((amount + tokenSupply) <= tokenMax, "Not enough supply");
        _mint(to, tokenId, amount, "");
        emit Minted(to, tokenId, amount);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override(IERC1155MetadataURI, ERC1155)
        returns (string memory)
    {
        return tokenURIs[tokenId];
    }

    function setURI(uint256 tokenId, string calldata tokenURI)
        public
        override
        onlyMinter
    {
        require(!metadataFrozen, "Metadata is frozen");
        tokenURIs[tokenId] = tokenURI;
        emit TokenURISet(tokenId, tokenURI);
    }

    function freezeMetadata() public onlyRole(ADMIN_ROLE) {
        metadataFrozen = true;
    }

    /*
     * @note For OpenSea Integration
     */
    function owner() public view returns (address) {
        return getRoleMember(ADMIN_ROLE, 0);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function addMinterContract(address account) public {
        grantRole(MINTER_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function removeMinterContract(address account) public {
        revokeRole(MINTER_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function grantAdminRole(address account) public {
        grantRole(ADMIN_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function removeAdminRole(address account) public {
        require(account != _msgSender(), "Cannot revoke yourself");
        revokeRole(ADMIN_ROLE, account);
    }

    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        require(account != address(0), "Cannot grant role to null");
        require(role == MINTER_ROLE || role == ADMIN_ROLE, "Invalid role");
        require(
            role == ADMIN_ROLE || account.isContract(),
            "Integration must be contract"
        );
        super._grantRole(role, account);
    }

    modifier onlyMinter() {
        validateMinter();
        _;
    }

    function validateMinter() private view {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");
    }

    function totalSupply(uint256 tokenId)
        public
        view
        override(IMintable, ERC1155Supply)
        returns (uint256)
    {
        return super.totalSupply(tokenId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155, IERC165)
        returns (bool)
    {
        return
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId) ||
            type(IMintable).interfaceId == interfaceId;
    }
}