// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract HinataStorage is
    Initializable,
    ERC1155SupplyUpgradeable,
    IERC1155ReceiverUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct Collection {
        address owner;
        uint256 royaltyFee;
        uint256 royalty;
    }

    address public hinata;
    address public weth;
    mapping(address => mapping(uint256 => bool)) public allowedIds;

    string public baseURI;
    mapping(uint256 => string) public uris;
    mapping(uint256 => address) public artists;
    mapping(address => bool) public airdrops;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ownable: caller is not the owner");
        _;
    }

    function initialize(
        address[] memory owners,
        address _hinata,
        address _weth
    ) public initializer {
        __ERC1155Supply_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        hinata = _hinata;
        weth = _weth;

        for (uint256 i = 0; i < owners.length; ++i) {
            _setupRole(DEFAULT_ADMIN_ROLE, owners[i]);
        }
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, hinata);
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    modifier onlyArtist() {
        require(hasRole(MINTER_ROLE, msg.sender), "Ownable: caller is not the artist");
        _;
    }

    function addArtist(address _user) public {
        grantRole(MINTER_ROLE, _user);
    }

    function addArtists(address[] calldata _users) external {
        uint256 len = _users.length;
        for (uint256 i; i < len; i += 1) {
            addArtist(_users[i]);
        }
    }

    function allowTokenIdsForArtist(
        address _user,
        uint256[] calldata _tokenIds,
        bool[] calldata _approved
    ) external onlyAdmin {
        require(_tokenIds.length == _approved.length, "Hinata: INVALID_ARGUMENTS");

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; i += 1) {
            allowedIds[_user][_tokenIds[i]] = _approved[i];
        }
    }

    function removeArtist(address _user) public {
        revokeRole(MINTER_ROLE, _user);
    }

    function removeArtists(address[] calldata _users) external {
        uint256 len = _users.length;
        for (uint256 i; i < len; i += 1) {
            removeArtist(_users[i]);
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory uri_
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Hinata: NO_MINTER_ROLE");
        uris[id] = uri_;
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Hinata: NO_MINTER_ROLE");
        _mintBatch(to, ids, amounts, data);
    }

    function mintArtistNFT(
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory uri_
    ) external onlyArtist {
        if (artists[id] == address(0)) artists[id] = msg.sender;
        require(artists[id] == msg.sender, "Hinata: NOT_OWNER");
        mint(msg.sender, id, amount, data, uri_);
    }

    function mintBatchArtistNFT(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) external onlyArtist {
        for (uint256 i; i < ids.length; i += 1) {
            if (artists[ids[i]] == address(0)) artists[ids[i]] = msg.sender;
            require(artists[ids[i]] == msg.sender, "Hinata: NOT_OWNER");
        }
        mintBatch(msg.sender, ids, amounts, data);
    }

    function mintAirdropNFT(
        address receiver,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        require(hinata == msg.sender);
        require(!airdrops[receiver], "Hinata: FREE_MINTED_ALREADY");
        airdrops[receiver] = true;
        mint(receiver, id, amount, data, uris[id]);
    }

    function setBaseURI(string memory baseURI_) external onlyAdmin {
        baseURI = baseURI_;
    }

    function setURI(uint256 id, string memory uri_) external onlyAdmin {
        uris[id] = uri_;
    }

    function uri(uint256 id) public view override returns (string memory) {
        if (bytes(uris[id]).length > 0) return uris[id];
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, IERC165Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}