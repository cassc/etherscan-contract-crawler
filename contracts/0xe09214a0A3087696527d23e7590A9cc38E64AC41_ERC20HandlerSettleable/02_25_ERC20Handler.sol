// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IDepositExecute.sol";
import "./HandlerHelpers.sol";
import "./ERC20Safe.sol";

/// @notice This contract is intended to be used with the Bridge contract.

contract ERC20Handler is IDepositExecute, HandlerHelpers, ERC20Safe {
    /// @param bridgeAddress Contract address of previously deployed Bridge.
    constructor(address bridgeAddress) HandlerHelpers(bridgeAddress) {}

    /// @notice A deposit is initiatied by making a deposit in the Bridge contract.
    ///
    /// @param resourceID ResourceID used to find address of token to be used for deposit.
    /// @param depositer Address of account making the deposit in the Bridge contract.
    /// @param data Consists of {amount} padded to 32 bytes.
    /// @return an empty data.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// amount                      uint256     bytes   0 - 32
    /// @dev Depending if the corresponding {tokenAddress} for the parsed {resourceID} is
    /// marked true in {_burnList}, deposited tokens will be burned, if not, they will be locked.
    // slither-disable-next-line locked-ether
    function deposit(
        bytes32 resourceID,
        address depositer,
        bytes calldata data
    ) external payable override onlyBridge returns (bytes memory) {
        require(msg.value == 0, "can't accept value");
        uint256 amount;
        (amount) = abi.decode(data, (uint256));

        address tokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(
            _contractWhitelist[tokenAddress],
            "not an allowed token address"
        );

        if (_burnList[tokenAddress]) {
            burnERC20(tokenAddress, depositer, amount);
        } else {
            lockERC20(tokenAddress, depositer, address(this), amount);
        }

        return "";
    }

    /// @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
    /// by a relayer on the deposit's destination chain.
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
        address tokenAddress = _resourceIDToTokenContractAddress[resourceID];

        // slither-disable-next-line assembly
        assembly {
            // Skip the length field (first 32 bytes) and load 32 bytes
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }

        require(
            _contractWhitelist[tokenAddress],
            "not an allowed token address"
        );

        if (_burnList[tokenAddress]) {
            mintERC20(tokenAddress, address(recipientAddress), amount);
        } else {
            releaseERC20(tokenAddress, address(recipientAddress), amount);
        }
    }

    /// @notice Used to manually release ERC20 tokens from ERC20Safe.
    ///
    /// @param data Consists of {tokenAddress}, {recipient}, and {amount} all padded to 32 bytes.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// tokenAddress                           address     bytes  0 - 32
    /// recipient                              address     bytes  32 - 64
    /// amount                                 uint        bytes  64 - 96
    function withdraw(bytes memory data) external override onlyBridge {
        address tokenAddress;
        address recipient;
        uint256 amount;

        (tokenAddress, recipient, amount) = abi.decode(
            data,
            (address, address, uint256)
        );

        releaseERC20(tokenAddress, recipient, amount);
    }
}