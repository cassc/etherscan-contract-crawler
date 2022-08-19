// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./HandlerHelpers.sol";
import "../interfaces/IDepositExecute.sol";
import "../utils/rollup/Settleable.sol";

/// @notice This contract is intended to be used with the Bridge contract.

contract NativeHandlerSettleable is
    IDepositExecute,
    HandlerHelpers,
    Settleable
{
    /// @param bridgeAddress Contract address of previously deployed Bridge.
    constructor(address bridgeAddress)
        HandlerHelpers(bridgeAddress)
        Settleable(bridgeAddress)
    {}

    event EtherTransfer(address indexed account, uint256 indexed amount);
    event FailedEtherTransfer(address indexed account, uint256 indexed amount);

    /// @notice A deposit is initiatied by making a deposit in the Bridge contract.
    ///
    /// @notice Requirements:
    /// - {resourceAddress} must be this address.
    /// - {resourceAddress} must be allowed.
    /// - {msg.value} must be equal to {amount}.
    /// - {amount} must be greater than 0.
    /// - Recipient address in data hex string must not be zero address.
    ///
    /// @param resourceID ResourceID used to find address of token to be used for deposit.
    /// @param data Consists of {amount} padded to 32 bytes.
    /// @return an empty data.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// amount                                 uint256     bytes  0  - 32
    /// destinationRecipientAddress length     uint256     bytes  32 - 64
    /// destinationRecipientAddress            bytes       bytes  64 - END
    ///
    /// @dev Depending if the corresponding {resourceAddress} for the parsed {resourceID} is
    /// marked true in {_burnList}, deposited tokens will be burned, if not, they will be locked.
    function deposit(
        bytes32 resourceID,
        address,
        bytes calldata data
    ) external payable override onlyBridge returns (bytes memory) {
        uint256 amount;
        uint256 lenDestinationRecipientAddress;
        bytes memory destinationRecipientAddress;

        (amount, lenDestinationRecipientAddress) = abi.decode(
            data,
            (uint256, uint256)
        );
        destinationRecipientAddress = bytes(
            data[64:64 + lenDestinationRecipientAddress]
        );

        bytes20 recipientAddress;
        address resourceAddress = _resourceIDToTokenContractAddress[resourceID];

        // slither-disable-next-line assembly
        assembly {
            // Skip the length field (first 32 bytes) and load 32 bytes
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }

        require(resourceAddress == address(this), "invalid resource address");
        require(msg.value == amount, "invalid native token amount");
        require(amount > 0, "invalid amount");
        require(
            address(recipientAddress) != address(0),
            "must not be zero address"
        );

        return "";
    }

    /// @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
    /// by a relayer on the deposit's destination chain.
    ///
    /// @notice Requirements:
    /// - {resourceAddress} must be this address.
    /// - {resourceAddress} must be allowed.
    ///
    /// @param data Consists of {resourceID}, {amount}, {lenDestinationRecipientAddress},
    /// and {destinationRecipientAddress} all padded to 32 bytes.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// amount                                 uint256     bytes  0 - 32
    /// destinationRecipientAddress length     uint256     bytes  32 - 64
    /// destinationRecipientAddress            bytes       bytes  64 - END
    function executeProposal(bytes32 resourceID, bytes calldata data)
        external
        override
        onlyBridge
    {
        uint256 amount;
        uint256 lenDestinationRecipientAddress;
        bytes memory destinationRecipientAddress;

        (amount, lenDestinationRecipientAddress) = abi.decode(
            data,
            (uint256, uint256)
        );
        destinationRecipientAddress = bytes(
            data[64:64 + lenDestinationRecipientAddress]
        );

        bytes20 recipientAddress;
        address resourceAddress = _resourceIDToTokenContractAddress[resourceID];

        // slither-disable-next-line assembly
        assembly {
            // Skip the length field (first 32 bytes) and load 32 bytes
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }
        require(resourceAddress == address(this), "invalid resource address");
        require(
            _contractWhitelist[resourceAddress],
            "not an allowed token address"
        );
        safeTransferETH(address(recipientAddress), amount);
    }

    function safeTransferETH(address to, uint256 value) internal {
        // slither-disable-next-line low-level-calls,arbitrary-send
        (bool success, ) = to.call{value: value}("");
        require(success, "ether transfer failed");
        // slither-disable-next-line reentrancy-events
        emit EtherTransfer(to, value);
    }

    /// @notice Used to manually release ERC20 tokens from ERC20Safe.
    ///
    /// @notice Requirements:
    /// - {resourceAddress} must be this address.
    ///
    /// @param data Consists of {resourceAddress}, {recipient}, and {amount} all padded to 32 bytes.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// resourceAddress                        address     bytes  0 - 32
    /// recipient                              address     bytes  32 - 64
    /// amount                                 uint        bytes  64 - 96
    function withdraw(bytes memory data) external override onlyBridge {
        address resourceAddress;
        address recipient;
        uint256 amount;

        (resourceAddress, recipient, amount) = abi.decode(
            data,
            (address, address, uint256)
        );
        require(resourceAddress == address(this), "invalid resource address");

        safeTransferETH(recipient, amount);
    }

    /// @notice Requirements:
    /// - {address(this)} must be allowed.
    function _settle(KeyValuePair[] memory pairs, bytes32)
        internal
        virtual
        override
    {
        require(
            _contractWhitelist[address(this)],
            "this handler is not allowed"
        );

        for (uint256 i = 0; i < pairs.length; i++) {
            address to = abi.decode(pairs[i].key, (address));
            uint256 amount = abi.decode(pairs[i].value, (uint256));

            // To prevent potential DoS Attack, check if `to` is a deployed contract.
            // It' because a receive function of a deployed contract can revert and
            // this will cause the entire state settlement process to fail.
            uint32 size;
            // slither-disable-next-line assembly
            assembly {
                size := extcodesize(to)
            }

            // slither-disable-next-line low-level-calls,unchecked-lowlevel,arbitrary-send
            (bool success, ) = to.call{value: amount}("");

            // Ether transfer must succeed only if `to` is not a deployed contract.
            if (size == 0) {
                require(success, "ether transfer failed");
            }

            // Log succeeded and failed calls.
            // It's because unchecked low-level call is used to prevent blocking operations.
            if (success) {
                // slither-disable-next-line reentrancy-events
                emit EtherTransfer(to, amount);
            } else {
                // slither-disable-next-line reentrancy-events
                emit FailedEtherTransfer(to, amount);
            }
        }
    }
}