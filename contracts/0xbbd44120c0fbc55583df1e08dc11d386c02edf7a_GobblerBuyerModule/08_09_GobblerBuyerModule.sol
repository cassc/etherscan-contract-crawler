// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ModuleManager} from "@gnosis-safe/base/ModuleManager.sol";
import {Enum} from "@gnosis-safe/common/Enum.sol";
import {IArtGobblers} from "./interfaces/IArtGobblers.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

/// @author philogy <https://github.com/philogy>
contract GobblerBuyerModule {
    address internal immutable THIS;
    address internal constant GOBBLERS = 0x60bb1e2AA1c9ACAfB4d34F71585D7e959f387769;
    address internal constant GOO = 0x600000000a36F3cD48407e35eB7C5c910dc1f7a8;

    mapping(address => address) public buyerOf;

    event BuyerSet(address indexed safe, address indexed buyer);

    error NotBuyer();
    error BuyFailed();
    error AttemptedDelegate();
    error NotDelegateCall();
    error RemoveFailed();

    constructor() {
        THIS = address(this);
    }

    /// @dev Prevent safe from accidentally calling this module via `DelegateCall` operation.
    modifier preventDelegateCall() {
        if (address(this) != THIS) revert AttemptedDelegate();
        _;
    }

    /// @dev Allows safes to setup this method in their `setup` method
    function setupGobblerBuyer(address _buyer) external {
        if (address(this) == THIS) revert NotDelegateCall();
        ModuleManager(address(this)).enableModule(THIS);
        GobblerBuyerModule(THIS).setBuyer(_buyer);
    }

    /// @notice Permits `_buyer` to mint new Gobblers with GOO on behalf of safe.
    /// @param _buyer Account allowed to trigger `mintFromGoo` method.
    function setBuyer(address _buyer) external preventDelegateCall {
        buyerOf[msg.sender] = _buyer;
        emit BuyerSet(msg.sender, _buyer);
    }

    /// @dev Always uses virtual balances, GOO tokens are not spendable by the buyer
    function buyFor(address _safe, uint256 _maxPrice) external preventDelegateCall {
        if (buyerOf[_safe] != msg.sender) revert NotBuyer();
        bool success = ModuleManager(_safe).execTransactionFromModule(
            GOBBLERS,
            0,
            abi.encodeCall(IArtGobblers.mintFromGoo, (_maxPrice, true)),
            Enum.Operation.Call
        );
        if (!success) revert BuyFailed();
    }

    function removeAllGoo() external preventDelegateCall {
        uint256 totalVirtualGoo = IArtGobblers(GOBBLERS).gooBalance(msg.sender);
        bool success = ModuleManager(msg.sender).execTransactionFromModule(
            GOBBLERS,
            0,
            abi.encodeCall(IArtGobblers.removeGoo, (totalVirtualGoo)),
            Enum.Operation.Call
        );
        if (!success) revert RemoveFailed();
    }

    function removeAllGooAndTransferTo(address _recipient) external preventDelegateCall {
        uint256 totalVirtualGoo = IArtGobblers(GOBBLERS).gooBalance(msg.sender);
        bool successRemove = ModuleManager(msg.sender).execTransactionFromModule(
            GOBBLERS,
            0,
            abi.encodeCall(IArtGobblers.removeGoo, (totalVirtualGoo)),
            Enum.Operation.Call
        );
        bool successTransfer = ModuleManager(msg.sender).execTransactionFromModule(
            GOO,
            0,
            abi.encodeCall(IERC20.transfer, (_recipient, totalVirtualGoo)),
            Enum.Operation.Call
        );
        if (!(successRemove && successTransfer)) revert RemoveFailed();
    }
}