// SPDX-License-Identifier: AGPL-3.0-only

/*
    CommunityPool.sol - SKALE Manager
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaiev
    @author Artem Payvin
    @author Vadim Yavorsky

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.16;

import "@skalenetwork/ima-interfaces/mainnet/ICommunityPool.sol";
import "@skalenetwork/skale-manager-interfaces/IWallets.sol";

import "../Messages.sol";
import "./Twin.sol";


/**
 * @title CommunityPool
 * @dev Contract contains logic to perform automatic self-recharging ETH for nodes.
 */
contract CommunityPool is Twin, ICommunityPool {

    using AddressUpgradeable for address payable;

    bytes32 public constant CONSTANT_SETTER_ROLE = keccak256("CONSTANT_SETTER_ROLE");

    // address of user => schainHash => balance of gas wallet in ETH
    mapping(address => mapping(bytes32 => uint)) private _userWallets;

    // address of user => schainHash => true if unlocked for transferring
    mapping(address => mapping(bytes32 => bool)) public activeUsers;

    uint public minTransactionGas;

    uint public multiplierNumerator;
    uint public multiplierDivider;

    /**
     * @dev Emitted when minimal value in gas for transactions from schain to mainnet was changed 
     */
    event MinTransactionGasWasChanged(
        uint oldValue,
        uint newValue
    );

    /**
     * @dev Emitted when basefee multiplier was changed 
     */
    event MultiplierWasChanged(
        uint oldMultiplierNumerator,
        uint oldMultiplierDivider,
        uint newMultiplierNumerator,
        uint newMultiplierDivider
    );

    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker linker,
        IMessageProxyForMainnet messageProxyValue
    )
        external
        override
        initializer
    {
        Twin.initialize(contractManagerOfSkaleManagerValue, messageProxyValue);
        _setupRole(LINKER_ROLE, address(linker));
        minTransactionGas = 1e6;
        multiplierNumerator = 3;
        multiplierDivider = 2;
    }

    /**
     * @dev Allows MessageProxyForMainnet to reimburse gas for transactions 
     * that transfer funds from schain to mainnet.
     * 
     * Requirements:
     * 
     * - User that receives funds should have enough funds in their gas wallet.
     * - Address that should be reimbursed for executing transaction must not be null.
     */
    function refundGasByUser(
        bytes32 schainHash,
        address payable node,
        address user,
        uint gas
    )
        external
        override
        onlyMessageProxy
        returns (uint)
    {
        require(node != address(0), "Node address must be set");
        if (!activeUsers[user][schainHash]) {
            return gas;
        }
        uint amount = tx.gasprice * gas;
        if (amount > _userWallets[user][schainHash]) {
            amount = _userWallets[user][schainHash];
        }
        _userWallets[user][schainHash] = _userWallets[user][schainHash] - amount;
        if (!_balanceIsSufficient(schainHash, user, 0)) {
            activeUsers[user][schainHash] = false;
            messageProxy.postOutgoingMessage(
                schainHash,
                getSchainContract(schainHash),
                Messages.encodeLockUserMessage(user)
            );
        }
        node.sendValue(amount);
        return (tx.gasprice * gas - amount) / tx.gasprice;
    }

    function refundGasBySchainWallet(
        bytes32 schainHash,
        address payable node,
        uint gas
    )
        external
        override
        onlyMessageProxy
        returns (bool)
    {
        if (gas > 0) {

            IWallets(payable(contractManagerOfSkaleManager.getContract("Wallets"))).refundGasBySchain(
                schainHash,
                node,
                gas,
                false
            );
        }
        return true;
    }

    /**
     * @dev Allows `msg.sender` to recharge their wallet for further gas reimbursement.
     * 
     * Requirements:
     * 
     * - 'msg.sender` should recharge their gas wallet for amount that enough to reimburse any 
     *   transaction from schain to mainnet.
     */
    function rechargeUserWallet(string calldata schainName, address user) external payable override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            _balanceIsSufficient(schainHash, user, msg.value),
            "Not enough ETH for transaction"
        );
        _userWallets[user][schainHash] = _userWallets[user][schainHash] + msg.value;
        if (!activeUsers[user][schainHash]) {
            activeUsers[user][schainHash] = true;
            messageProxy.postOutgoingMessage(
                schainHash,
                getSchainContract(schainHash),
                Messages.encodeActivateUserMessage(user)
            );
        }
    }

    /**
     * @dev Allows `msg.sender` to withdraw funds from their gas wallet.
     * If `msg.sender` withdraws too much funds,
     * then he will no longer be able to transfer their tokens on ETH from schain to mainnet.
     * 
     * Requirements:
     * 
     * - 'msg.sender` must have sufficient amount of ETH on their gas wallet.
     */
    function withdrawFunds(string calldata schainName, uint amount) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(amount <= _userWallets[msg.sender][schainHash], "Balance is too low");
        require(!messageProxy.messageInProgress(), "Message is in progress");
        _userWallets[msg.sender][schainHash] = _userWallets[msg.sender][schainHash] - amount;
        if (
            !_balanceIsSufficient(schainHash, msg.sender, 0) &&
            activeUsers[msg.sender][schainHash]
        ) {
            activeUsers[msg.sender][schainHash] = false;
            messageProxy.postOutgoingMessage(
                schainHash,
                getSchainContract(schainHash),
                Messages.encodeLockUserMessage(msg.sender)
            );
        }
        payable(msg.sender).sendValue(amount);
    }

    /**
     * @dev Allows `msg.sender` set the amount of gas that should be 
     * enough for reimbursing any transaction from schain to mainnet.
     * 
     * Requirements:
     * 
     * - 'msg.sender` must have sufficient amount of ETH on their gas wallet.
     */
    function setMinTransactionGas(uint newMinTransactionGas) external override {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "CONSTANT_SETTER_ROLE is required");
        emit MinTransactionGasWasChanged(minTransactionGas, newMinTransactionGas);
        minTransactionGas = newMinTransactionGas;
    }

    /**
     * @dev Allows `msg.sender` set the amount of gas that should be 
     * enough for reimbursing any transaction from schain to mainnet.
     * 
     * Requirements:
     * 
     * - 'msg.sender` must have sufficient amount of ETH on their gas wallet.
     */
    function setMultiplier(uint newMultiplierNumerator, uint newMultiplierDivider) external override {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "CONSTANT_SETTER_ROLE is required");
        require(newMultiplierDivider > 0, "Divider is zero");
        emit MultiplierWasChanged(
            multiplierNumerator,
            multiplierDivider,
            newMultiplierNumerator,
            newMultiplierDivider
        );
        multiplierNumerator = newMultiplierNumerator;
        multiplierDivider = newMultiplierDivider;
    }

    /**
     * @dev Returns the amount of ETH on gas wallet for particular user.
     */
    function getBalance(address user, string calldata schainName) external view override returns (uint) {
        return _userWallets[user][keccak256(abi.encodePacked(schainName))];
    }

    /**
     * @dev Checks whether user is active and wallet was recharged for sufficient amount.
     */
    function checkUserBalance(bytes32 schainHash, address receiver) external view override returns (bool) {
        return activeUsers[receiver][schainHash] && _balanceIsSufficient(schainHash, receiver, 0);
    }

    /**
     * @dev Checks whether passed amount is enough to recharge user wallet with current basefee.
     */
    function getRecommendedRechargeAmount(
        bytes32 schainHash,
        address receiver
    )
        external
        view
        override
        returns (uint256)
    {
        uint256 currentValue = _multiplyOnAdaptedBaseFee(minTransactionGas);
        if (currentValue  <= _userWallets[receiver][schainHash]) {
            return 0;
        }
        return currentValue - _userWallets[receiver][schainHash];
    }

    /**
     * @dev Checks whether user wallet was recharged for sufficient amount.
     */
    function _balanceIsSufficient(bytes32 schainHash, address receiver, uint256 delta) private view returns (bool) {
        return delta + _userWallets[receiver][schainHash] >= minTransactionGas * tx.gasprice;
    }

    function _multiplyOnAdaptedBaseFee(uint256 value) private view returns (uint256) {
        return value * block.basefee * multiplierNumerator / multiplierDivider;
    }
}