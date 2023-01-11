// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IRegistry is IERC721, IERC721Metadata {
    /**
     * Lookup address by name. Return address(0) if not found.
     */
    function lookup(string memory name) external view returns (address);

    /**
     * Batch lookup addresses by names.
     */
    function batchLookup(string[] calldata names)
        external
        view
        returns (address[] memory);

    /**
     * Do reverse lookup name by address. Return empty string "" if name is not found by address.
     */
    function reverseLookup(address registrant)
        external
        view
        returns (string memory);

    /**
     * Batch reverse lookup names by addresses.
     */
    function batchReverseLookup(address[] calldata registrants)
        external
        view
        returns (string[] memory);

    /**
     * Register a name with an address. Return tokenId and name length. This method is only called by register-controller.
     */
    function register(string memory name, address registrant)
        external
        returns (uint256, uint256);

    /**
     * Query a record by tokenId and label. Return empty string "" if record is not set.
     */
    function queryRecord(uint256 tokenId, string calldata label)
        external
        view
        returns (string memory);

    /**
     * Query records by tokenId and label array.
     */
    function queryRecords(uint256 tokenId, string[] calldata labels)
        external
        view
        returns (string[] memory);

    /**
     * Bind a record by set label = value.
     */
    function bind(
        uint256 tokenId,
        string calldata label,
        string calldata value,
        address registrant
    ) external;

    /**
     * Batch bind records.
     */
    function batchBind(
        uint256 tokenId,
        string[] calldata labels,
        string[] calldata values,
        address registrant
    ) external;

    function setBaseURI(string memory _uri) external;

    function setController(address controller, bool add) external;

    function addLabels(string[] calldata labels) external;

    function setLabel(string memory label, bool supported) external;

    function setNameValidator(address validator) external;

    /**
     * Check name and return its length in unicode.
     */
    function validateName(string memory name) external view returns (uint256);

    /**
     * Convert to tokenId by the keccak hash of name.
     */
    function toTokenId(string memory s) external view returns (uint256);

    event Register(
        address indexed registrant,
        uint256 indexed tokenId,
        string name
    );

    event Bind(
        address indexed registrant,
        uint256 indexed tokenId,
        string label,
        string value
    );

    event Proxy(address indexed proxy, bool add);

    event Controller(address indexed controller, bool supported);

    event Label(string label, bool add);

    event NameValidator(address oldValidator, address newValidator);
}