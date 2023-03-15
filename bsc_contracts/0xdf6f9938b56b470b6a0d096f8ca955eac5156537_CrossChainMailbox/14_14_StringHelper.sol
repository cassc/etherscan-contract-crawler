pragma solidity ^0.8.16;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

library StringHelper {
    /// @notice Concatenates together a formatted message.
    /// @param _rawMessage The raw message bytes.
    /// @param _balance The balance of the sender.
    /// @param _ensName The ENS name of the sender ("" if none).
    /// @dev The formatting is like:
    ///
    ///     'hello, world!'
    ///     - alice.eth (1.00 ETH)
    function formatMessage(bytes memory _rawMessage, uint256 _balance, string memory _ensName)
        internal
        view
        returns (string memory)
    {
        string memory messageStr = string(_rawMessage);
        string memory ethBalanceStr = formatBalance(_balance);

        // Use the ENS name if it exists, otherwise use the address.
        string memory senderStr;
        if (bytes(_ensName).length == 0) {
            senderStr = Strings.toHexString(msg.sender);
        } else {
            senderStr = _ensName;
        }

        string memory lineOne = string.concat(string.concat("'", messageStr), "'\n");
        string memory lineTwo =
            string.concat(string.concat(string.concat(string.concat("- ", senderStr), " ("), ethBalanceStr), ")");
        string memory data = string.concat(lineOne, lineTwo);
        return data;
    }

    /// @notice Formats a native balance to a string with 2 decimal places and native currency
    ///     symbol. For example, 123456789000000000000 wei would be formatted as "123.46 ETH".
    /// @param _balance The balance to format.
    function formatBalance(uint256 _balance) public view returns (string memory) {
        uint256 integerAmount = _balance / 1 ether;
        uint256 integerDigits;
        if (integerAmount > 0) {
            while (true) {
                if (integerAmount > 10 ** integerDigits) {
                    integerDigits++;
                } else {
                    break;
                }
            }
        } else {
            integerDigits = 1;
        }

        bytes memory balanceByteArr = new bytes(integerDigits + 3); // extra 3 for "." plus 2 digits
        uint256 i = integerDigits;
        while (i > 0) {
            balanceByteArr[i - 1] = bytes1(uint8(48 + integerAmount % 10));
            integerAmount /= 10;
            i--;
        }

        balanceByteArr[integerDigits] = ".";
        balanceByteArr[integerDigits + 1] = bytes1(uint8(48 + (_balance / 1e17) % 10));
        balanceByteArr[integerDigits + 2] = bytes1(uint8(48 + (_balance / 1e16) % 10));
        string memory balanceStr = string(balanceByteArr);

        // ETH for mainnet, xDAI for Gnosis, etc
        string memory currencyStr;
        if (block.chainid == 5) {
            currencyStr = " gETH";
        } else if (block.chainid == 100) {
            currencyStr = " xDAI";
        } else if (block.chainid == 137) {
            currencyStr = " MATIC";
        } else {
            currencyStr = " ETH";
        }

        return string.concat(balanceStr, currencyStr);
    }
}