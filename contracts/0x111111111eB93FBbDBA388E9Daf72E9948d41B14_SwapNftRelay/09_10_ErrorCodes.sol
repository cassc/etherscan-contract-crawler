// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.4.25;

/**
 * Gas-efficient error codes and replacement for require.
 *
 * This uses significantly less gas, and reduces the length of the contract bytecode.
 */
contract ErrorCodes {

    bytes2 constant ERROR_RESERVED = 0xe100;
    bytes2 constant ERROR_RESERVED2 = 0xe200;
    bytes2 constant ERROR_MATH = 0xe101;
    bytes2 constant ERROR_FROZEN = 0xe102;
    bytes2 constant ERROR_INVALID_ADDRESS = 0xe103;
    bytes2 constant ERROR_ZERO_VALUE = 0xe104;
    bytes2 constant ERROR_INSUFFICIENT_BALANCE = 0xe105;
    bytes2 constant ERROR_WRONG_TIME = 0xe106;
    bytes2 constant ERROR_EMPTY_ARRAY = 0xe107;
    bytes2 constant ERROR_LENGTH_MISMATCH = 0xe108;
    bytes2 constant ERROR_UNAUTHORIZED = 0xe109;
    bytes2 constant ERROR_DISALLOWED_STATE = 0xe10a;
    bytes2 constant ERROR_TOO_HIGH = 0xe10b;
    bytes2 constant ERROR_ERC721_CHECK = 0xe10c;
    bytes2 constant ERROR_PAUSED = 0xe10d;
    bytes2 constant ERROR_NOT_PAUSED = 0xe10e;
    bytes2 constant ERROR_ALREADY_EXISTS = 0xe10f;

    bytes2 constant ERROR_OWNER_MISMATCH = 0xe110;
    bytes2 constant ERROR_LOCKED = 0xe111;
    bytes2 constant ERROR_TOKEN_LOCKED = 0xe112;
    bytes2 constant ERROR_ATTORNEY_PAUSE = 0xe113;
    bytes2 constant ERROR_VALUE_MISMATCH = 0xe114;
    bytes2 constant ERROR_TRANSFER_FAIL = 0xe115;
    bytes2 constant ERROR_INDEX_RANGE = 0xe116;
    bytes2 constant ERROR_PAYMENT = 0xe117;
    bytes2 constant ERROR_BAD_PARAMETER_1 = 0xe118;
    bytes2 constant ERROR_BAD_PARAMETER_2 = 0xe119;

    function expect(bool pass, bytes2 code) internal pure {
        if (!pass) {
            assembly {
                mstore(0x40, code)
                revert(0x40, 0x02)
            }
        }
    }
}