// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface FactoryInterface {
    function pause() external;

    function unpause() external;

    function setCustodianDepositAddress(address merchant, string memory depositAddress) external returns (bool);

    function setMerchantDepositAddress(string memory depositAddress) external returns (bool);

    function setMerchantMintLimit(address merchant, uint256 amount) external returns (bool);

    function setMerchantBurnLimit(address merchant, uint256 amount) external returns (bool);

    function addMintRequest(
        uint256 amount,
        string memory txid,
        string memory depositAddress
    ) external returns (uint256);

    function cancelMintRequest(bytes32 requestHash) external returns (bool);

    function confirmMintRequest(bytes32 requestHash) external returns (bool);

    function rejectMintRequest(bytes32 requestHash) external returns (bool);

    function burn(uint256 amount, string memory txid) external returns (uint256);

    function confirmBurnRequest(bytes32 requestHash) external returns (bool);

    function getMintRequestsLength() external view returns (uint256 length);

    function getBurnRequestsLength() external view returns (uint256 length);

    function getBurnRequest(uint256 nonce)
        external
        view
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        );

    function getMintRequest(uint256 nonce)
        external
        view
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        );

        ///=============================================================================================
    /// Events
    ///=============================================================================================

    event CustodianDepositAddressSet(
        address indexed merchant,
        address indexed sender,
        string depositAddress
    );

    event MerchantDepositAddressSet(
        address indexed merchant,
        string depositAddress
    );

    event MintRequestAdd(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    event MintRequestCancel(
        uint256 indexed nonce,
        address indexed requester,
        bytes32 requestHash
    );

    event MintConfirmed(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    event MintRejected(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    event Burned(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        uint256 timestamp,
        bytes32 requestHash
    );

    event BurnConfirmed(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 inputRequestHash
    );

}