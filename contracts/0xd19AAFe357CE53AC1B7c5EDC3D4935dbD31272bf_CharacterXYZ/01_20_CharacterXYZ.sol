// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

contract CharacterXYZ is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC1155URIStorageUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");

    uint256[] private CollectionIdList;

    mapping(uint256 => bool) public CollectionIdExists;
    mapping(uint256 => bool) public tokenIsForRent;
    mapping(address => mapping(address => lendStruct)) public lendMap;
    mapping(address => mapping(uint256 => bool)) private blockTransfer;

    struct lendStruct {
        uint256 id;
        uint256 amount;
        bytes data;
    }

    function initialize() public initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __ERC1155URIStorage_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEVELOPER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    //----- READ FUNCTIONS -----//

    function getCollectionIdList() external view returns (uint256[] memory) {
        return CollectionIdList;
    }

    function isTransferBlocked(address _address, uint256 _id)
        public
        view
        returns (bool)
    {
        return blockTransfer[_address][_id];
    }

    //----- ADMINISTRATIVE FUNCTIONS -----//

    function setBlockTransfer(
        address _address,
        uint256 _id,
        bool _status
    ) public onlyRole(MINTER_ROLE) {
        blockTransfer[_address][_id] = _status;
    }

    function setURI(uint256 _tokenId, string memory newuri)
        public
        onlyRole(DEVELOPER_ROLE)
    {
        _setURI(_tokenId, newuri);
    }

    function withdrawFunds(address fundsReciever)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        AddressUpgradeable.sendValue(
            payable(fundsReciever),
            address(this).balance
        );
    }

    function pause() public onlyRole(DEVELOPER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEVELOPER_ROLE) {
        _unpause();
    }

    //----- PUBLIC FUNCTIONS -----//

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _manageCollectionIds(id);

        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            _manageCollectionIds(ids[i]);
        }

        _mintBatch(to, ids, amounts, data);
    }

    //----- INTERNAL FUNCTIONS -----//

    function _manageCollectionIds(uint256 id) internal {
        if (CollectionIdExists[id] == false) {
            CollectionIdExists[id] = true;
            CollectionIdList.push(id);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable) whenNotPaused {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                isTransferBlocked(from, ids[i]) == false,
                "Transfer blocked for rented collection"
            );
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
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
}