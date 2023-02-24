// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable avoid-low-level-calls

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../../interface/module/multiTransactor/IMultiTransactorV2.sol";

/// @author RmKek
/// @title Multitransactor contract
contract MultiTransactorV2 is Initializable, AccessControlEnumerableUpgradeable, IMultiTransactorV2 {
    bytes32 public constant TRANSACTOR_ROLE = keccak256("TRANSACTOR_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
     */
    function initialize() external initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TRANSACTOR_ROLE, msg.sender);
    }

    /// @notice Check whether account address has admin rights
    /// @param account Address to check
    /// @return true if account has admin rights, false otherwise
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @notice Check whether account address has transactor rights
    /// @param account Address to check
    /// @return true if account has transactor rights, false otherwise
    function isTransactor(address account) public view returns (bool) {
        return hasRole(TRANSACTOR_ROLE, account);
    }

    /// @notice Gives admin rights to account, only accessable by admins
    /// @param account Address that will get rights
    /// @param value bool, true - gives rights, false - takes them away
    /// @return success true if rights were changed successfully, false otherwise
    function setAdmin(address account, bool value) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success) {
        if (value) {
            require(!hasRole(DEFAULT_ADMIN_ROLE, account), "MultiTransactorV1: account already has admin role");
            grantRole(DEFAULT_ADMIN_ROLE, account);
        } else {
            require(hasRole(DEFAULT_ADMIN_ROLE, account), "MultiTransactorV1: account doesn't have admin role");
            revokeRole(DEFAULT_ADMIN_ROLE, account);
        }

        emit SetAdmin(msg.sender, account, value);

        return true;
    }

    /// @notice Gives transactor rights to account, only accessable by transactors
    /// @param account Address that will get rights
    /// @param value bool, true - gives rights, false - takes them away
    /// @return success true if rights were changed successfully, false otherwise
    function setTransactor(address account, bool value) public onlyRole(TRANSACTOR_ROLE) returns (bool success) {
        if (value) {
            require(!hasRole(TRANSACTOR_ROLE, account), "MultiTransactorV1: account already has transactor role");
            grantRole(TRANSACTOR_ROLE, account);
        } else {
            require(hasRole(TRANSACTOR_ROLE, account), "MultiTransactorV1: account doesn't have transactor role");
            revokeRole(TRANSACTOR_ROLE, account);
        }

        emit SetTransactor(msg.sender, account, value);

        return true;
    }

    /// @notice Function to get list of admins
    /// @param cursor position in array where to start counting admins
    /// @param count amount of admins to return from the start of cursor
    /// @return result newCursor - resulting array and newCursor pointing at the position of finish
    function getAdminList(uint256 cursor, uint256 count)
        public
        view
        returns (address[] memory result, uint256 newCursor)
    {
        uint256 length = count;
        uint256 adminAmount = getRoleMemberCount(DEFAULT_ADMIN_ROLE);

        if (length > adminAmount - cursor) {
            length = adminAmount - cursor;
        }

        address[] memory addresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            addresses[i] = getRoleMember(DEFAULT_ADMIN_ROLE, cursor + i);
        }

        return (addresses, cursor + length);
    }

    /// @notice Function to get list of transactors
    /// @param cursor position in array where to start counting transactors
    /// @param count amount of transactors to return from the start of cursor
    /// @return result newCursor - resulting array and newCursor pointing at the position of finish
    function getTransactorList(uint256 cursor, uint256 count)
        public
        view
        returns (address[] memory result, uint256 newCursor)
    {
        uint256 length = count;
        uint256 transactorAmount = getRoleMemberCount(TRANSACTOR_ROLE);

        if (length > transactorAmount - cursor) {
            length = transactorAmount - cursor;
        }

        address[] memory addresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            addresses[i] = getRoleMember(TRANSACTOR_ROLE, cursor + i);
        }

        return (addresses, cursor + length);
    }

    /// @notice Send transaction from this SC to another, only available to TRANSACTOR_ROLE, emits SendTransaction
    /// @param to address to which the tx will be sent
    /// @param data ABI-encoded call to function with args, that will be passed to address
    /// @return memory bytes array of response from SC
    function sendTx(address to, bytes memory data) external onlyRole(TRANSACTOR_ROLE) returns (bytes memory) {
        (bool success, bytes memory result) = to.call(data);
        require(success, "MultiTransactorV1: call failed");

        emit SendTransaction(to, data, result);

        return result;
    }

    /// @notice Send multiple transactions from this SC to another, only available to TRANSACTOR_ROLE, emits SendTransaction
    /// @param to each address to which the tx will be sent
    /// @param data each ABI-encoded call to function with args, that will be passed to address
    /// @return memory bytes array of responses from calls
    function sendTxBatch(address[] calldata to, bytes[] calldata data)
        external
        onlyRole(TRANSACTOR_ROLE)
        returns (bytes[] memory)
    {
        require(to.length == data.length, "MultiTransactorV1: to.length != data.length");
        bytes[] memory results = new bytes[](data.length);

        for (uint256 i = 0; i < to.length; i++) {
            (bool success, bytes memory result) = to[i].call(data[i]);
            require(success, "MultiTransactorV1: call failed");
            results[i] = result;
        }

        emit SendTransactionBatch(to, data, results);

        return results;
    }

    /// @notice Get current version of SC
    /// @return current version of SC implementation
    function version() external pure returns (string memory) {
        return "0.0.1";
    }
}