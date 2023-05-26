// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

/// Define additional data storage for BoredBoxNFT
abstract contract BoredBoxStorage {
    uint256 public constant TOKEN_STATUS__CLOSED = 0;
    uint256 public constant TOKEN_STATUS__OPENED = 1;
    uint256 public constant TOKEN_STATUS__PENDING = 2;

    // TODO: rename to something like `box__current_generation`
    uint256 public current_box;

    // Authorized to preform certain actions
    address public coordinator;

    bool public all_paused;

    // Mapping boxId to is paused state
    mapping(uint256 => bool) public box__is_paused;

    // Mapping boxId to URI IPFS root
    mapping(uint256 => string) public box__uri_root;

    // Mapping boxId to tokenId bounds
    mapping(uint256 => uint256) public box__lower_bound;
    mapping(uint256 => uint256) public box__upper_bound;

    // Mapping boxId to quantity
    mapping(uint256 => uint256) public box__quantity;

    // Mapping boxId to price
    mapping(uint256 => uint256) public box__price;

    // Mapping boxId to array of Validate contract references
    mapping(uint256 => address[]) public box__validators;

    // Mapping boxId to open sale
    mapping(uint256 => uint256) public box__sale_time;

    // Mapping boxId to open time
    mapping(uint256 => uint256) public box__open_time;

    // Mapping boxId to cool down after mint
    mapping(uint256 => uint256) public box__cool_down;

    // Mapping hash of auth to tokenId
    mapping(bytes32 => uint256) public hash__auth_token;

    // Mapping tokenId to opened timestamp
    mapping(uint256 => uint256) public token__opened_timestamp;

    // Mapping from tokenId to TokenStatus_{Closed,Opened,Pending} states
    mapping(uint256 => uint256) public token__status;

    // Mapping boxId to owner to tokenId
    mapping(uint256 => mapping(address => uint256)) public token__original_owner;

    // Mapping from tokenId to boxId
    mapping(uint256 => uint256) public token__generation;
}