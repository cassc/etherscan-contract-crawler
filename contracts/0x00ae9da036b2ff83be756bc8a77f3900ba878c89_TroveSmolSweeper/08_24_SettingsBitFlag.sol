// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @dev Settings for a buy order.
 */

library SettingsBitFlag {
    // default action is 0b00000000
    uint16 internal constant NONE = 0x00;

    // if marketplace fails to buy an item for some reason
    // default: will skip the item.
    // if 0x04 is set, will revert the entire buy transaction.
    uint16 internal constant MARKETPLACE_BUY_ITEM_REVERTED = 0x0001;

    // if the quantity of an item is less than the requested quantity (for ERC1155)
    // default: will skip the item.
    // if 0x02 is set, will buy as many items as possible (all listed items)
    uint16 internal constant INSUFFICIENT_QUANTITY_ERC1155 = 0x0002;

    // if total spend allowance is exceeded
    // default: will skip the item and continue.
    // if 0x08 is set, will skill the item and stop the transaction.
    uint16 internal constant EXCEEDING_MAX_SPEND = 0x0004;

    // refund in the input token
    // default: refunds in the payment token
    // if 0x10 is set, refunds in the input token
    uint16 internal constant REFUND_IN_INPUT_TOKEN = 0x0008;

    // turn on success event logging
    // default: will not log success events.
    // if 0x20 is set, will log success events.
    uint16 internal constant EMIT_SUCCESS_EVENT_LOGS = 0x000C;

    // turn on failure event logging
    // default: will not log failure events.
    // if 0x40 is set, will log failure events.
    uint16 internal constant EMIT_FAILURE_EVENT_LOGS = 0x0010;

    function checkSetting(uint16 _inputSettings, uint16 _settingBit)
        internal
        pure
        returns (bool)
    {
        return (_inputSettings & _settingBit) == _settingBit;
    }
}