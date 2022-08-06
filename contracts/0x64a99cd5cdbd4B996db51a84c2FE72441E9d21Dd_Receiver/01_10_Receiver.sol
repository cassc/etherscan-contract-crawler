/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2022 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IMRC20.sol";
import "./IERC20PredicateBurnOnly.sol";

error Unauthorized();
error TransferFailed();
error ZeroBalance();
error NoRecipient();
error NotPolygon();
error NotEthereum();

/**
 * A contract for receiving MATIC on Polygon.
 */
contract Receiver is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    event RecipientUpdated(address recipient, address previousRecipient);
    event PolygonWithdrawal(address initiator, uint256 amount); 
    event CoinsClaimed(address recipient, uint256 amount);
    event TokensClaimed(address recipient, address token, uint256 amount);
    event AuthorizedInitiatorsUpdated(address initiator, bool permitted);

    // Polygon (MATIC) token is at this address on Polygon & Mumbai per
    // https://docs.polygon.technology/docs/develop/network-details/mapped-tokens/
    IMRC20 public mrc20 = IMRC20(0x0000000000000000000000000000000000001010); 

    IERC20PredicateBurnOnly public erc20Predicate;

    address public recipient;
    mapping(address => bool) public authorizedInitiators;

    // only on mainnet (1) or goerli (5) or hardhat (31337, for tests)
    modifier onlyOnEthereum() {
        if (!(block.chainid == 1 || block.chainid == 5 || block.chainid == 31337)) {
            revert NotEthereum();
        }
        _;
    }

    // only on polygon mainnet (137) or mumbai (80001)
    modifier onlyOnPolygon() {
        if (block.chainid != 137 && block.chainid != 80001) {
            revert NotPolygon();
        }
        _;
    }

    modifier onlyAuthorizedInitiators() {
        if (!authorizedInitiators[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    // used to ensure we don't transfer to address(0)
    modifier requiresValidRecipient() {
        if (recipient == address(0)) {
            revert NoRecipient();
        }
        _;
    }

    constructor(address owner_, address recipient_, address initiator_) Ownable() {
        if (owner() != owner_) {
            _transferOwnership(owner_);
        }

        _updateRecipient(recipient_);
        _updateAuthorizedInitiators(initiator_, true);

        // https://docs.polygon.technology/docs/develop/network-details/genesis-contracts/ (outdated)
        if (block.chainid == 1) { // mainnet
            erc20Predicate = IERC20PredicateBurnOnly(0x158d5fa3Ef8e4dDA8a5367deCF76b94E7efFCe95);
        } else if (block.chainid == 5) { // goerli
            // the doc linked above is outdated and says 0x39c1e715316a1acbce0e6438cf62edf83c111975
            // the correct address is this one per https://github.com/maticnetwork/static/blob/master/network/testnet/mumbai/index.json
            erc20Predicate = IERC20PredicateBurnOnly(0xf213e8fF5d797ed2B052D3b96C11ac71dB358027);
        }
    }

    // silently accept ETH/MATIC transfers
    receive() external payable {}

    function updateRecipient(address recipient_) external onlyOwner {
        _updateRecipient(recipient_);
    }

    function _updateRecipient(address recipient_) internal {
        emit RecipientUpdated(recipient_, recipient);
        recipient = recipient_;
    }

    function updateAuthorizedInitiators(address initiator, bool permitted) external onlyOwner {
        _updateAuthorizedInitiators(initiator, permitted);
    }

    function _updateAuthorizedInitiators(address initiator, bool permitted) internal {
        emit AuthorizedInitiatorsUpdated(initiator, permitted);
        authorizedInitiators[initiator] = permitted;
    }

    // Transfer entire ETH/MATIC balance to the recipient address.
    function claimCoins() external nonReentrant onlyAuthorizedInitiators requiresValidRecipient {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert ZeroBalance();
        }
        emit CoinsClaimed(recipient, balance);
        (bool success, ) = recipient.call{value: balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    // Transfer entire balance of `token` to the recipient address.
    function claimTokens(IERC20 token) external nonReentrant onlyAuthorizedInitiators requiresValidRecipient {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) {
            revert ZeroBalance();
        }
        emit TokensClaimed(recipient, address(token), balance);
        token.safeTransfer(recipient, balance);
    }

    // Withdraw entire balance from Polygon to this contract's address on Ethereum.
    // finalizePolygonWithdrawal() must be called on the partner contract on Ethereum
    // after the plasma withdrawal is confirmed on Ethereum (~7 days on polygon mainnet,
    // ~3 hours on mumbai).
    function withdrawMATIC() external onlyAuthorizedInitiators onlyOnPolygon {
        uint256 amount = address(this).balance;
        emit PolygonWithdrawal(msg.sender, amount);
        mrc20.withdraw{value: amount}(amount);
    }

    // Finalize Polygon MATIC withdrawal on Ethereum
    // The payload here is described at https://docs.polygon.technology/docs/develop/advanced/calling-plasma-contracts/#4-withdraw-erc20-tokens-from-polygon-to-goerli
    function finalizePolygonWithdrawal(bytes calldata data) external onlyOnEthereum {
        erc20Predicate.startExitWithBurntTokens(data);
    }
}