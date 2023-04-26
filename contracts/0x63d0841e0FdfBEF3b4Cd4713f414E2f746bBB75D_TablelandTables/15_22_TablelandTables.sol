// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ITablelandTables} from "./interfaces/ITablelandTables.sol";
import {ITablelandController} from "./interfaces/ITablelandController.sol";
import {TablelandPolicy} from "./TablelandPolicy.sol";

/**
 * @dev Implementation of {ITablelandTables}.
 */
contract TablelandTables is
    ITablelandTables,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // A URI used to reference off-chain table metadata.
    string internal _baseURIString;
    // A mapping of table ids to table controller addresses.
    mapping(uint256 => address) internal _controllers;
    // A mapping of table controller addresses to lock status.
    mapping(uint256 => bool) internal _locks;
    // The maximum size allowed for a query.
    uint256 internal constant QUERY_MAX_SIZE = 35001;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory baseURI
    ) public initializerERC721A initializer {
        __ERC721A_init("Tableland Tables", "TABLE");
        __ERC721AQueryable_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _baseURIString = baseURI;
    }

    /**
     * @custom:deprecated
     * This function is deprecated, please use `create`.
     */
    function createTable(
        address owner,
        string calldata statement
    ) external payable whenNotPaused returns (uint256) {
        return _create(owner, statement);
    }

    /**
     * @dev See {ITablelandTables-create}.
     */
    function create(
        address owner,
        string calldata statement
    ) external payable override whenNotPaused returns (uint256) {
        return _create(owner, statement);
    }

    /**
     * @dev See {ITablelandTables-create}.
     */
    function create(
        address owner,
        string[] calldata statements
    ) external payable override whenNotPaused returns (uint256[] memory) {
        uint256 statementsLength = statements.length;
        if (statementsLength < 1) revert Unauthorized();

        uint256[] memory tableIds = new uint256[](statementsLength);
        for (uint256 i; i < statementsLength; ) {
            tableIds[i] = _create(owner, statements[i]);
            unchecked {
                ++i;
            }
        }

        return tableIds;
    }

    /**
     * @custom:depreciated See {ITablelandTables-runSQL}.
     * This function is deprecated, please use `mutate`.
     */
    function runSQL(
        address caller,
        uint256 tableId,
        string calldata statement
    ) external payable whenNotPaused nonReentrant {
        _mutate(caller, tableId, statement);
    }

    /**
     * @dev See {ITablelandTables-mutate}.
     */
    function mutate(
        address caller,
        uint256 tableId,
        string calldata statement
    ) external payable override whenNotPaused nonReentrant {
        _mutate(caller, tableId, statement);
    }

    /**
     * @dev See {ITablelandTables-mutate}.
     */
    function mutate(
        address caller,
        ITablelandTables.Statement[] calldata statements
    ) external payable override whenNotPaused nonReentrant {
        uint256 statementsLength = statements.length;
        for (uint256 i; i < statementsLength; ) {
            _mutate(caller, statements[i].tableId, statements[i].statement);
            unchecked {
                ++i;
            }
        }
    }

    function _create(
        address owner,
        string calldata statement
    ) private returns (uint256 tableId) {
        tableId = _nextTokenId();
        _safeMint(owner, 1);

        emit CreateTable(owner, tableId, statement);

        return tableId;
    }

    function _mutate(
        address caller,
        uint256 tableId,
        string calldata statement
    ) private {
        if (!_exists(tableId) || caller != _msgSenderERC721A())
            revert Unauthorized();

        uint256 querySize = bytes(statement).length;
        if (querySize >= QUERY_MAX_SIZE)
            revert MaxQuerySizeExceeded(querySize, QUERY_MAX_SIZE);

        emit RunSQL(
            caller,
            ownerOf(tableId) == caller,
            tableId,
            statement,
            _getPolicy(caller, tableId)
        );
    }

    /**
     * @dev Returns an {TablelandPolicy} for `caller` and `tableId`.
     *
     * An allow-all policy is returned if the table's controller does not exist.
     *
     * Requirements:
     *
     * - if the controller is an EOA, caller must be controller
     * - if the controller is a contract address, it must implement {ITablelandController}
     */
    function _getPolicy(
        address caller,
        uint256 tableId
    ) private returns (TablelandPolicy memory) {
        address controller = _controllers[tableId];
        if (_isContract(controller)) {
            // Try {ITablelandController.getPolicy(address, uint256)}.
            try
                ITablelandController(controller).getPolicy{value: msg.value}(
                    caller,
                    tableId
                )
            returns (TablelandPolicy memory policy) {
                return policy;
            } catch Error(string memory reason) {
                // Controller reverted/required with a reason string. Bubble up the error.
                revert(reason);
            } catch (bytes memory err) {
                // We are here for one of two reasons:
                // 1. The controller does not implement {ITablelandController.getPolicy(address, uint256)}.
                // 2. The controller reverted w/o a reason string, e.g, a custom error, revert(), or require(condition).
                // We can't differentiate between reverting/requiring w/o a reason string and not implemented.
                // When a controller reverts/requires w/o a reason string it will be treated as not implemented,
                // i.e., we will try to call {ITablelandController.getPolicy(address)}.

                // Controller reverted with a custom error. Bubble it up.
                if (err.length > 0) {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, err), mload(err))
                    }
                }
            }

            // If the controller reverted w/o a reason string, the following _could_ result in the caller
            // seeing a different error.
            // Try {ITablelandController.getPolicy(address)}.
            return
                ITablelandController(controller).getPolicy{value: msg.value}(
                    caller
                );
        }
        if (!(controller == address(0) || controller == caller))
            revert Unauthorized();

        return
            TablelandPolicy({
                allowInsert: true,
                allowUpdate: true,
                allowDelete: true,
                whereClause: "",
                withCheck: "",
                updatableColumns: new string[](0)
            });
    }

    /**
     * @dev Returns whether or not `account` is a contract address.
     */
    function _isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }

    /**
     * @dev See {ITablelandTables-setController}.
     */
    function setController(
        address caller,
        uint256 tableId,
        address controller
    ) external override whenNotPaused {
        if (
            caller != ownerOf(tableId) ||
            caller != _msgSenderERC721A() ||
            _locks[tableId]
        ) revert Unauthorized();

        _controllers[tableId] = controller;

        emit SetController(tableId, controller);
    }

    /**
     * @dev See {ITablelandTables-getController}.
     */
    function getController(
        uint256 tableId
    ) external view override returns (address) {
        return _controllers[tableId];
    }

    /**
     * @dev See {ITablelandTables-lockController}.
     */
    function lockController(
        address caller,
        uint256 tableId
    ) external override whenNotPaused {
        if (
            caller != ownerOf(tableId) ||
            caller != _msgSenderERC721A() ||
            _locks[tableId]
        ) revert Unauthorized();

        _locks[tableId] = true;
    }

    /**
     * @dev See {ITablelandTables-setBaseURI}.
     */
    function setBaseURI(string memory baseURI) external override onlyOwner {
        _baseURIString = baseURI;
    }

    /**
     * @dev See {ERC721AUpgradeable-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURIString;
    }

    /**
     * @dev See {ITablelandTables-pause}.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @dev See {ITablelandTables-unpause}.
     */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev See {ERC721AUpgradeable-_startTokenId}.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {ERC721AUpgradeable-_afterTokenTransfers}.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
        // quantity is only > 1 after bulk minting when from == address(0)
        if (from != address(0)) emit TransferTable(from, to, startTokenId);
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(address) internal view override onlyOwner {} // solhint-disable no-empty-blocks
}