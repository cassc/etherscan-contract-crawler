// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVaultInventoryReporter {
    // ============= Events ==============

    event Add(address indexed vault, address indexed reporter, bytes32 itemHash);
    event Remove(address indexed vault, address indexed reporter, bytes32 itemHash);
    event Clear(address indexed vault, address indexed reporter);
    event SetApproval(address indexed vault, address indexed target);
    event SetGlobalApproval(address indexed target, bool isApproved);

    // ============= Errors ==============

    error VIR_NoItems();
    error VIR_TooManyItems(uint256 maxItems);
    error VIR_InvalidRegistration(address vault, uint256 itemIndex);
    error VIR_NotVerified(address vault, uint256 itemIndex);
    error VIR_NotInInventory(address vault, bytes32 itemHash);
    error VIR_NotApproved(address vault, address target);
    error VIR_PermitDeadlineExpired(uint256 deadline);
    error VIR_InvalidPermitSignature(address signer);

    // ============= Data Types ==============

    enum ItemType {
        ERC_721,
        ERC_1155,
        ERC_20,
        PUNKS
    }

    struct Item {
        ItemType itemType;
        address tokenAddress;
        uint256 tokenId; // Not used for ERC20 items - will be ignored
        uint256 tokenAmount; // Not used for ERC721 items - will be ignored
    }

    // ================ Inventory Operations ================

    function add(address vault, Item[] calldata items) external;

    function remove(address vault, Item[] calldata items) external;

    function clear(address vault) external;

    function addWithPermit(
        address vault,
        Item[] calldata items,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeWithPermit(
        address vault,
        Item[] calldata items,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function clearWithPermit(
        address vault,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permit(
        address owner,
        address target,
        address vault,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // ================ Verification ================

    function verify(address vault) external view returns (bool);

    function verifyItem(address vault, Item calldata item) external view returns (bool);

    // ================ Enumeration ================

    function enumerate(address vault) external view returns (Item[] memory);

    function enumerateOrFail(address vault) external view returns (Item[] memory);

    function keys(address vault) external view returns (bytes32[] memory);

    function keyAtIndex(address vault, uint256 index) external view returns (bytes32);

    function itemAtIndex(address vault, uint256 index) external view returns (Item memory);

    // ================ Permissions ================

    function setApproval(address vault, address target) external;

    function isOwnerOrApproved(address vault, address target) external view returns (bool);

    function setGlobalApproval(address caller, bool isApproved) external;

    function isGloballyApproved(address target) external view returns (bool);
}