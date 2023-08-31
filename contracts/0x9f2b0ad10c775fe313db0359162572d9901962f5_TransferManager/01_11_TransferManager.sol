// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "./DepositAccount.sol";
import "./TransferDetail.sol";

/**
 * @title TransferManager
 * @dev A contract for managing transfers of ethers and ERC20 tokens.
 *      It allows the owner to transfer ethers and tokens from multiple DepositAccounts to specified recipients.
 */
contract TransferManager is OwnableUpgradeable {
    event ETHTransfered(address from, address to, uint amount);
    event ERC20Transfered(
        address from,
        address to,
        address token,
        uint amount
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init();
        transferOwnership(owner);
    }

    /**
     * @dev Internal function to transfer ethers (ETH).
     * @param depositAccount The DepositAccount contract instance.
     * @param recipient The address to which the ethers are transferred.
     * @param amount The amount of ethers to transfer.
     */
    function _transferEthers(
        DepositAccount depositAccount,
        address recipient,
        uint amount
    ) internal {
        depositAccount.transferETH(payable(recipient), amount);
        emit ETHTransfered(address(depositAccount), recipient, amount);
    }

    /**
     * @dev Internal function to transfer ERC20 tokens.
     * @param depositAccount The DepositAccount contract instance.
     * @param recipient The address to which the tokens are transferred.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to transfer.
     */
    function _transferERC20(
        DepositAccount depositAccount,
        address recipient,
        address tokenAddress,
        uint amount
    ) internal {
        depositAccount.transferERC20(tokenAddress, payable(recipient), amount);
        emit ERC20Transfered(
            address(depositAccount),
            recipient,
            tokenAddress,
            amount
        );
    }

    /**
     * @dev Function to transfer multiple tokens.
     * @param transfers An array of TransferDetail structs containing transfer details.
     * TODO: Reentrancy is not possible, test related is pending
     */
    function transferTokens(
        TransferDetail[] calldata transfers
    ) external onlyOwner {
        uint length = transfers.length;

        for (uint index = 0; index < length; ) {
            TransferDetail memory transfer = transfers[index];

            DepositAccount depositAccount = DepositAccount(
                payable(transfer.fromDepositAccount)
            );
            if (transfer.tokenAddress == address(0)) {
                _transferEthers(
                    depositAccount,
                    transfer.recipient,
                    transfer.amount
                );
            } else {
                _transferERC20(
                    depositAccount,
                    transfer.recipient,
                    transfer.tokenAddress,
                    transfer.amount
                );
            }
            unchecked {
                index += 1;
            }
        }
    }
}