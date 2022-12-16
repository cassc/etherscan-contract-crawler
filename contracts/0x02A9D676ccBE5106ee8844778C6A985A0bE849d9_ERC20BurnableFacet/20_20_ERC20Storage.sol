// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "./../interfaces/IERC20.sol";
import {IERC20Allowance} from "./../interfaces/IERC20Allowance.sol";
import {IERC20BatchTransfers} from "./../interfaces/IERC20BatchTransfers.sol";
import {IERC20SafeTransfers} from "./../interfaces/IERC20SafeTransfers.sol";
import {IERC20Mintable} from "./../interfaces/IERC20Mintable.sol";
import {IERC20Burnable} from "./../interfaces/IERC20Burnable.sol";
import {IERC20Receiver} from "./../interfaces/IERC20Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC20Storage {
    using Address for address;
    using ERC20Storage for ERC20Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 supply;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.token.ERC20.ERC20.storage")) - 1);

    bytes4 internal constant ERC20_RECEIVED = IERC20Receiver.onERC20Received.selector;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20, ERC20Allowance.
    function init() internal {
        InterfaceDetectionStorage.Layout storage erc165Layout = InterfaceDetectionStorage.layout();
        erc165Layout.setSupportedInterface(type(IERC20).interfaceId, true);
        erc165Layout.setSupportedInterface(type(IERC20Allowance).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20BatchTransfers.
    function initERC20BatchTransfers() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20BatchTransfers).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20SafeTransfers.
    function initERC20SafeTransfers() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20SafeTransfers).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Mintable.
    function initERC20Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Burnable.
    function initERC20Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Burnable).interfaceId, true);
    }

    /// @notice Sets the allowance to an account by an owner.
    /// @dev Note: This function implements {ERC20-approve(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Emits an {Approval} event.
    /// @param owner The account to set the allowance from.
    /// @param spender The account being granted the allowance by `owner`.
    /// @param value The allowance amount to grant.
    function approve(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        s.allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @notice Increases the allowance granted to an account by an owner.
    /// @dev Note: This function implements {ERC20Allowance-increaseAllowance(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender`'s allowance by `owner` overflows.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by `owner`.
    /// @param owner The account increasing the allowance.
    /// @param spender The account whose allowance is being increased.
    /// @param value The allowance amount increase.
    function increaseAllowance(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        uint256 allowance_ = s.allowances[owner][spender];
        if (value != 0) {
            unchecked {
                uint256 newAllowance = allowance_ + value;
                require(newAllowance > allowance_, "ERC20: allowance overflow");
                s.allowances[owner][spender] = newAllowance;
                allowance_ = newAllowance;
            }
        }
        emit Approval(owner, spender, allowance_);
    }

    /// @notice Decreases the allowance granted to an account by an owner.
    /// @dev Note: This function implements {ERC20Allowance-decreaseAllowance(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender` does not have at least `value` of allowance by `owner`.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by `owner`.
    /// @param owner The account decreasing the allowance.
    /// @param spender The account whose allowance is being decreased.
    /// @param value The allowance amount decrease.
    function decreaseAllowance(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        uint256 allowance_ = s.allowances[owner][spender];

        if (allowance_ != type(uint256).max && value != 0) {
            unchecked {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                uint256 newAllowance = allowance_ - value;
                require(newAllowance < allowance_, "ERC20: insufficient allowance");
                s.allowances[owner][spender] = newAllowance;
                allowance_ = newAllowance;
            }
        }
        emit Approval(owner, spender, allowance_);
    }

    /// @notice Transfers an amount of tokens from an account to a recipient.
    /// @dev Note: This function implements {ERC20-transfer(address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    function transfer(Layout storage s, address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: transfer to address(0)");

        if (value != 0) {
            uint256 balance = s.balances[from];
            unchecked {
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC20: insufficient balance");
                if (from != to) {
                    s.balances[from] = newBalance;
                    s.balances[to] += value;
                }
            }
        }

        emit Transfer(from, to, value);
    }

    /// @notice Transfers an amount of tokens from an account to a recipient by a sender.
    /// @dev Note: This function implements {ERC20-transferFrom(address,address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from`.
    /// @param sender The message sender.
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    function transferFrom(Layout storage s, address sender, address from, address to, uint256 value) internal {
        if (from != sender) {
            s.decreaseAllowance(from, sender, value);
        }
        s.transfer(from, to, value);
    }

    //================================================= Batch Transfers ==================================================//

    /// @notice Transfers multiple amounts of tokens from an account to multiple recipients.
    /// @dev Note: This function implements {ERC20BatchTransfers-batchTransfer(address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Emits a {Transfer} event for each transfer.
    /// @param from The account transferring the tokens.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    function batchTransfer(Layout storage s, address from, address[] calldata recipients, uint256[] calldata values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 balance = s.balances[from];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: transfer to address(0)");

                uint256 value = values[i];
                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    if (from != to) {
                        s.balances[to] += value;
                    } else {
                        require(value <= balance, "ERC20: insufficient balance");
                        selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                    }
                }
                emit Transfer(from, to, value);
            }

            if (totalValue != 0 && totalValue != selfTransferTotalValue) {
                uint256 newBalance = balance - totalValue;
                require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
                s.balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
            }
        }
    }

    /// @notice Transfers multiple amounts of tokens from an account to multiple recipients by a sender.
    /// @dev Note: This function implements {ERC20BatchTransfers-batchTransferFrom(address,address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `sum(values)` of allowance by `from`.
    /// @dev Emits a {Transfer} event for each transfer.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account transferring the tokens.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    function batchTransferFrom(Layout storage s, address sender, address from, address[] calldata recipients, uint256[] calldata values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 balance = s.balances[from];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: transfer to address(0)");

                uint256 value = values[i];

                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    if (from != to) {
                        s.balances[to] += value;
                    } else {
                        require(value <= balance, "ERC20: insufficient balance");
                        selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                    }
                }

                emit Transfer(from, to, value);
            }

            if (totalValue != 0 && totalValue != selfTransferTotalValue) {
                uint256 newBalance = balance - totalValue;
                require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
                s.balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
            }
        }

        if (from != sender) {
            s.decreaseAllowance(from, sender, totalValue);
        }
    }

    //================================================= Safe Transfers ==================================================//

    /// @notice Transfers an amount of tokens from an account to a recipient. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Note: This function implements {ERC20SafeTransfers-safeTransfer(address,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received` fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    function safeTransfer(Layout storage s, address from, address to, uint256 value, bytes calldata data) internal {
        s.transfer(from, to, value);
        if (to.isContract()) {
            _callOnERC20Received(from, from, to, value, data);
        }
    }

    /// @notice Transfers an amount of tokens to a recipient from a specified address. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Note: This function implements {ERC20SafeTransfers-safeTransferFrom(address,address,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 value, bytes calldata data) internal {
        s.transferFrom(sender, from, to, value);
        if (to.isContract()) {
            _callOnERC20Received(sender, from, to, value, data);
        }
    }

    //================================================= Minting ==================================================//

    /// @notice Mints an amount of tokens to a recipient, increasing the total supply.
    /// @dev Note: This function implements {ERC20Mintable-mint(address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits a {Transfer} event with `from` set to the zero address.
    /// @param to The account to mint the tokens to.
    /// @param value The amount of tokens to mint.
    function mint(Layout storage s, address to, uint256 value) internal {
        require(to != address(0), "ERC20: mint to address(0)");
        if (value != 0) {
            uint256 supply = s.supply;
            unchecked {
                uint256 newSupply = supply + value;
                require(newSupply > supply, "ERC20: supply overflow");
                s.supply = newSupply;
                s.balances[to] += value; // balance cannot overflow if supply does not
            }
        }
        emit Transfer(address(0), to, value);
    }

    /// @notice Mints multiple amounts of tokens to multiple recipients, increasing the total supply.
    /// @dev Note: This function implements {ERC20Mintable-batchMint(address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits a {Transfer} event for each transfer with `from` set to the zero address.
    /// @param recipients The list of accounts to mint the tokens to.
    /// @param values The list of amounts of tokens to mint to each of `recipients`.
    function batchMint(Layout storage s, address[] memory recipients, uint256[] memory values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 totalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: mint to address(0)");

                uint256 value = values[i];
                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    s.balances[to] += value; // balance cannot overflow if supply does not
                }
                emit Transfer(address(0), to, value);
            }

            if (totalValue != 0) {
                uint256 supply = s.supply;
                uint256 newSupply = supply + totalValue;
                require(newSupply > supply, "ERC20: supply overflow");
                s.supply = newSupply;
            }
        }
    }

    //================================================= Burning ==================================================//

    /// @notice Burns an amount of tokens from an account, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-burn(uint256)}.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @param from The account burning the tokens.
    /// @param value The amount of tokens to burn.
    function burn(Layout storage s, address from, uint256 value) internal {
        if (value != 0) {
            uint256 balance = s.balances[from];
            unchecked {
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC20: insufficient balance");
                s.balances[from] = newBalance;
                s.supply -= value; // will not underflow if balance does not
            }
        }

        emit Transfer(from, address(0), value);
    }

    /// @notice Burns an amount of tokens from an account by a sender, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-burnFrom(address,uint256)}.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account to burn the tokens from.
    /// @param value The amount of tokens to burn.
    function burnFrom(Layout storage s, address sender, address from, uint256 value) internal {
        if (from != sender) {
            s.decreaseAllowance(from, sender, value);
        }
        s.burn(from, value);
    }

    /// @notice Burns multiple amounts of tokens from multiple owners, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-batchBurnFrom(address,address[],uint256[])}.
    /// @dev Reverts if `owners` and `values` have different lengths.
    /// @dev Reverts if an `owner` does not have at least the corresponding `value` of balance.
    /// @dev Reverts if `sender` is not an `owner` and does not have at least the corresponding `value` of allowance by this `owner`.
    /// @dev Emits a {Transfer} event for each transfer with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event for each transfer if `sender` is not this `owner` (non-standard).
    /// @param sender The message sender.
    /// @param owners The list of accounts to burn the tokens from.
    /// @param values The list of amounts of tokens to burn.
    function batchBurnFrom(Layout storage s, address sender, address[] calldata owners, uint256[] calldata values) internal {
        uint256 length = owners.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 totalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address from = owners[i];
                uint256 value = values[i];

                if (from != sender) {
                    s.decreaseAllowance(from, sender, value);
                }

                if (value != 0) {
                    uint256 balance = s.balances[from];
                    uint256 newBalance = balance - value;
                    require(newBalance < balance, "ERC20: insufficient balance");
                    s.balances[from] = newBalance;
                    totalValue += value; // totalValue cannot overflow if the individual balances do not underflow
                }

                emit Transfer(from, address(0), value);
            }

            if (totalValue != 0) {
                s.supply -= totalValue; // _totalSupply cannot underfow as balances do not underflow
            }
        }
    }

    /// @notice Gets the total token supply.
    /// @dev Note: This function implements {ERC20-totalSupply()}.
    /// @return supply The total token supply.
    function totalSupply(Layout storage s) internal view returns (uint256 supply) {
        return s.supply;
    }

    /// @notice Gets an account balance.
    /// @dev Note: This function implements {ERC20-balanceOf(address)}.
    /// @param owner The account whose balance will be returned.
    /// @return balance The account balance.
    function balanceOf(Layout storage s, address owner) internal view returns (uint256 balance) {
        return s.balances[owner];
    }

    /// @notice Gets the amount that an account is allowed to spend on behalf of another.
    /// @dev Note: This function implements {ERC20-allowance(address,address)}.
    /// @param owner The account that has granted an allowance to `spender`.
    /// @param spender The account that was granted an allowance by `owner`.
    /// @return value The amount which `spender` is allowed to spend on behalf of `owner`.
    function allowance(Layout storage s, address owner, address spender) internal view returns (uint256 value) {
        return s.allowances[owner][spender];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Calls {IERC20Receiver-onERC20Received} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param value The value transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC20Received(address sender, address from, address to, uint256 value, bytes memory data) private {
        require(IERC20Receiver(to).onERC20Received(sender, from, value, data) == ERC20_RECEIVED, "ERC20: safe transfer rejected");
    }
}