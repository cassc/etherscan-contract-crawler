// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Editions is ERC1155, ERC1155Burnable, ERC1155Supply, AccessControl {
    struct Edition {
        bool frozenMetadata;
        uint256 maxSupply;
        string uri;
    }

    error EditionNotFound();
    error MetadataIsFrozen();
    error NotEnoughSupply();

    event EditionReleased(uint256 __id);
    event EditionURIUpdated(uint256 __id, string __uri);
    event EditionFrozen(uint256 __id);

    // The token name
    string public name;

    // The token symbol
    string public symbol;

    // Used to track ID of next edition
    uint256 private _nextEditionID = 1;

    // Mapping of editions
    mapping(uint256 => Edition) private _editions;

    // Minter Role used in minting operations
    bytes32 constant MINTER_ROLE = bytes32("MINTER_ROLE");

    /**
     * @dev Sets name/symbol and grants initial roles to owner upon construction.
     */
    constructor(string memory __name, string memory __symbol) ERC1155("") {
        name = __name;
        symbol = __symbol;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Checks if edition exists.
     *
     * Requirements:
     *
     * - `__id` must be of existing edition.
     */
    modifier onlyExistingEdition(uint256 __id) {
        if (!editionExists(__id)) {
            revert EditionNotFound();
        }
        _;
    }

    /**
     * @dev Checks if Edition exists.
     *
     * Requirements:
     *
     * - `__ids` must be of existing edition(s).
     */
    modifier onlyExistingEditionBatch(uint256[] calldata __ids) {
        for (uint256 i = 0; i < __ids.length; i++) {
            if (!editionExists(__ids[i])) {
                revert EditionNotFound();
            }
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNALS
    ////////////////////////////////////////////////////////////////////////////

    function _beforeTokenTransfer(
        address __operator,
        address __from,
        address __to,
        uint256[] memory __ids,
        uint256[] memory __amounts,
        bytes memory __data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(
            __operator,
            __from,
            __to,
            __ids,
            __amounts,
            __data
        );

        if (__from == address(0) && __ids.length > 1) {
            for (uint256 i = 0; i < __ids.length; i++) {
                if (_editions[__ids[i]].maxSupply != 0) {
                    if (totalSupply(__ids[i]) > _editions[__ids[i]].maxSupply)
                        revert NotEnoughSupply();
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to release a new Edition.
     *
     * Emits a {EditionReleased} event.
     *
     */
    function releaseEdition(
        uint256 __maxSupply,
        string calldata __uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 editionId = _nextEditionID++;

        _editions[editionId] = Edition({
            frozenMetadata: false,
            maxSupply: __maxSupply,
            uri: __uri
        });

        emit EditionReleased(editionId);
    }

    /**
     * @dev Used to edit the token URI of an Edition.
     *
     * Emits a {EditionURIUpdated} event.
     *
     */
    function editURI(
        uint256 __id,
        string calldata __uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) onlyExistingEdition(__id) {
        if (_editions[__id].frozenMetadata) {
            revert MetadataIsFrozen();
        }

        _editions[__id].uri = __uri;

        emit EditionURIUpdated(__id, __uri);
    }

    /**
     * @dev Used to freeze metadata.
     *
     * Emits a {EditionFrozen} event.
     *
     */
    function freezeMetadata(
        uint256 __id
    ) external onlyRole(DEFAULT_ADMIN_ROLE) onlyExistingEdition(__id) {
        _editions[__id].frozenMetadata = true;

        emit EditionFrozen(__id);
    }

    ////////////////////////////////////////////////////////////////////////////
    // MINTER
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to mint token(s) of an Edition for a one account.
     */
    function mint(
        address __account,
        uint256 __id,
        uint256 __amount
    ) external onlyRole(MINTER_ROLE) onlyExistingEdition(__id) {
        if (_editions[__id].maxSupply != 0) {
            if (totalSupply(__id) + __amount > _editions[__id].maxSupply)
                revert NotEnoughSupply();
        }

        _mint(__account, __id, __amount, "");
    }

    /**
     * @dev Used to mint token(s) of an Edition for a one account.
     */
    function mintMany(
        address[] calldata __accounts,
        uint256 __id,
        uint256[] calldata __amounts
    ) external onlyRole(MINTER_ROLE) onlyExistingEdition(__id) {
        if (_editions[__id].maxSupply != 0) {
            uint256 totalAmount = 0;
            for (uint i = 0; i < __amounts.length; i++) {
                totalAmount += __amounts[i];
            }
            if (totalSupply(__id) + totalAmount > _editions[__id].maxSupply)
                revert NotEnoughSupply();
        }

        for (uint256 i = 0; i < __accounts.length; i++) {
            _mint(__accounts[i], __id, __amounts[i], "");
        }
    }

    /**
     * @dev Used to mint token(s) of Edition(s) for a one account.
     */
    function mintBatch(
        address __account,
        uint256[] calldata __ids,
        uint256[] calldata __amounts
    ) external onlyRole(MINTER_ROLE) onlyExistingEditionBatch(__ids) {
        _mintBatch(__account, __ids, __amounts, "");
    }

    ////////////////////////////////////////////////////////////////////////////
    // READS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Returns whether or not an edition exists.
     */
    function editionExists(uint256 __id) public view returns (bool) {
        if (__id != 0 && __id < _nextEditionID) {
            return true;
        }
        return false;
    }

    /**
     * @dev Returns an edition.
     */
    function getEdition(
        uint256 __id
    ) external view onlyExistingEdition(__id) returns (Edition memory) {
        return _editions[__id];
    }

    /**
     * @dev Returns the max supply of an edition.
     */
    function maxSupply(
        uint256 __id
    ) external view onlyExistingEdition(__id) returns (uint256) {
        return _editions[__id].maxSupply;
    }

    /**
     * @dev Returns the number of total editions.
     */
    function totalEditions() external view returns (uint256) {
        return _nextEditionID - 1;
    }

    /**
     * @dev Returns the token URI of an edition.
     */
    function uri(
        uint256 __id
    )
        public
        view
        virtual
        override
        onlyExistingEdition(__id)
        returns (string memory)
    {
        return _editions[__id].uri;
    }

    /**
     * @dev See {ERC1155-supportsInterface} and {AccessControl-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}