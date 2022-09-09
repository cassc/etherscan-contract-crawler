// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC20.sol";

/// @title IERC1400 Security Token Standard
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec

interface IERC1400 is IERC20 {
    /*------------------ Documentation Management --------------------*/

    /**
     * @dev Returns the documents url and hash
     */
    function getDocument(bytes32 _docName)
        external
        view
        returns (string memory, bytes32);

    /**
     * @dev Creates a new document when the document doesn't already exist
     * and updates otherwise
     *
     * Emits {Document} event
     */
    function setDocument(
        bytes32 _docName,
        string calldata _uri,
        bytes32 _documentHash
    ) external;

    /*--------------------- Token Information -----------------------*/

    /**
     * @dev Returns the `_tokenHolder` balance in the `_partition` partition
     */
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the partitions where the `_tokenHolder` has tokens
     */
    function partitionsOf(address _tokenHolder)
        external
        view
        returns (bytes32[] memory);

    /*------------------------- Transfers ---------------------------*/

    /**
     * @dev Moves `_value` amount of tokens from the caller`s
     * account to `_to`, the caller is known to the contract by
     * its `_data` in document
     *
     * Emits {Transfer}
     */
    function transferWithData(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
     * @dev Moves `_value` amount of tokens from `_from` account to `_to`
     * using the allowance mechanism. `_value` is then deducted from the
     * caller's allowance.
     *
     * Emits {Transfer}
     */
    function transferFromWithData(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;

    /*------------------- Partition Token Transfers ---------------------*/
    /**
     * @dev Moves `_value` amount of tokens in the `_partition` from the
     * caller's account to `_to`
     *
     * Emits {TransferByPartition}
     */
    function transferByPartition(
        bytes32 _partition,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes32);

    /*------------------------ Token Issuance --------------------------*/
    /**
     * @dev Returns true if the token can be issued, false otherwise
     */
    function isIssuable() external view returns (bool);

    /**
     * @dev Mints token to `_tokenHolder` which is known to the contract by
     * its `_data` in document
     *
     * Emits {Issued}
     */
    function issue(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
     * @dev Creates token in the `_partition` and moves it to `_tokenHolder`
     * which is known to the contract by its `_data` in document
     *
     * note Creates a new partition if the `_partition` doesn't already exist
     *
     * Emits {IssuedByPartition}
     */
    function issueByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external;

    /*------------------------ Token Redemption --------------------------*/
    /**
     * @dev Burns and deducts the `_value` amount of tokens from the caller's
     * account which is known to the contract by its `_data` in document
     *
     * Emits {Redeemed}
     */
    function redeem(uint256 _value, bytes calldata _data) external;

    /**
     * @dev Burns and deducts the `_value` amount of tokens from the `_tokenHolder`
     * account which is known to the contract by its `_data` in document using the
     * allowance mechanism. `_value` is then deducted from the caller's allowance
     *
     * Emits {Redeemed}
     */
    function redeemFrom(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external;

    /*------------------------ Transfer Validity --------------------------*/
    /**
     * @dev Returns true if the caller's data the `_data` is valid, false otherwise
     */
    function canTransfer(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bytes1, bytes32);

    /**
     * @dev Returns true if the caller's data the `_data` is valid and enough
     *  allowance, false otherwise
     */
    function canTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bytes1, bytes32);

    /**
     * @dev Returns a type {bytes1} reason code, type {bytes32} message, and data
     * if necessary
     */
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (
            bytes1,
            bytes32,
            bytes32
        );

    /*------------------------ Document Events --------------------------*/
    /**
     * @dev Emittied when a document is created/updated
     */
    event Document(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    /*------------------------ Transfer Events --------------------------*/
    /**
     * @dev Emittied when `_value` amount of token in the partition `_fromPartition`
     * from the `_from` to `_to`
     */
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    /*------------------ Issuance / Redemption Events -------------------*/
    /**
     * @dev Emittied when `_value` amount of token is issued to `_to`
     * which is known to the contract by its `_data` in document
     *
     * note `_operator` is the caller
     */
    event Issued(
        address indexed _operator,
        address indexed _to,
        uint256 _value,
        bytes _data
    );

    /**
     * @dev Emittied when `_value` amount of token is redeemed
     * from the `_from` which is known to the contract by
     *  its `_data` in document
     *
     * note `_operator` is the caller
     */
    event Redeemed(
        address indexed _operator,
        address indexed _from,
        uint256 _value,
        bytes _data
    );

    /**
     * @dev Emittied when `_value` amount of token is issued to `_to`
     * in the partition `_fromPartition` which is known to the contract
     * by its `_data` in document
     *
     * note `_operator` is the caller and `_operatorData` depends on
     * the logic applied and can be nothing
     */
    event IssuedByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    /**
     * @dev Emittied when `_value` amount of token is redeemed
     * from the `_from` in the partition `_fromPartition` which
     * is known to the contract by its `_data` in document
     *
     * note `_operator` is the caller and `_operatorData` depends on
     * the logic applied and can be nothing
     */
    event RedeemedByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _from,
        uint256 _value,
        bytes _operatorData
    );
}

/**
 * Reason codes - ERC-1066
 *
 * To improve the token holder experience, canTransfer MUST return a reason byte code
 * on success or failure based on the ERC-1066 application-specific status codes specified below.
 * An implementation can also return arbitrary data as a bytes32 to provide additional
 * information not captured by the reason code.
 *
 * Code	Reason
 * 0x50	transfer failure
 * 0x51	transfer success
 * 0x52	insufficient balance
 * 0x53	insufficient allowance
 * 0x54	transfers halted (contract paused)
 * 0x55	funds locked (lockup period)
 * 0x56	invalid sender
 * 0x57	invalid receiver
 * 0x58	invalid operator (transfer agent)
 * 0x59
 * 0x5a
 * 0x5b
 * 0x5a
 * 0x5b
 * 0x5c
 * 0x5d
 * 0x5e
 * 0x5f	token meta or info
 *
 * These codes are being discussed at: https://ethereum-magicians.org/t/erc-1066-ethereum-status-codes-esc/283/24
 */
