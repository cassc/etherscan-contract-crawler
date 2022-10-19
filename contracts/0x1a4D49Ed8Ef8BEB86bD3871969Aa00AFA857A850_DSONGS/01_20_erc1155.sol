// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact [email protected]
contract DSONGS is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address payable;
    struct CollectionDetails {
        uint256 maxSupply;
        uint256 price;
        bool start;
        string ipfs;
    }
    string public symbol;
    string public name;
    bytes32 public constant ADMIN_ROLE = keccak256("AdminRole");
    address payable _vault;
    uint256 public collectionNumber;
    mapping(uint256 => CollectionDetails) public collectionInfo;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __AccessControl_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, 0x0a3C1bA258c0E899CF3fdD2505875e6Cc65928a8);
        _grantRole(ADMIN_ROLE, 0x71ab07Dbf11094a097b1947BB27Ce4268b6AF7Cf);
        // transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
        symbol = "dSONGS";
        name = "Songs by Dan The Lost Boy";
        _vault = payable(0xAf61C1C5057fb701CF5F4aACb9cE843bCD349fF4);
    }

    function setVault(address newVault) public onlyOwner {
        _vault = payable(newVault);
    }

    function addCollection(
        uint256 price,
        string calldata ipfs,
        uint256 maxSupply,
        bool start
    ) public onlyRole(ADMIN_ROLE) {
        collectionInfo[collectionNumber] = CollectionDetails(
            maxSupply,
            price,
            start,
            ipfs
        );
        ++collectionNumber;
    }

    function manageCollection(
        uint256 price,
        string calldata ipfs,
        uint256 maxSupply,
        bool start,
        uint collectionId
    ) public onlyRole(ADMIN_ROLE) {
        collectionInfo[collectionId] = CollectionDetails(
            maxSupply,
            price,
            start,
            ipfs
        );
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public payable {
        CollectionDetails memory info = collectionInfo[id];
        require(msg.value == info.price * amount, "Wrong price");
        require(totalSupply(id) < info.maxSupply || info.maxSupply == 0, "Minted out");
        _mint(account, id, amount, "0x");
        _vault.sendValue(msg.value);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = collectionInfo[tokenId].ipfs;
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function exists(uint256 id) public view virtual override returns (bool) {
        return id < collectionNumber;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}