// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library DigitsOfUint {
    using SafeMathUpgradeable for uint256;
    function numDigits(uint256 _number) internal pure returns (uint256) {
        uint256 number = _number;
        uint256 digits = 0;
        while (number != 0) {
            number = number.div(10);
            digits = digits.add(1);
        }
        return digits;
    }
    function hasFirstDigit(uint256 _accountId, uint _firstDigit) internal pure returns (bool) {
        uint256 number = _accountId;
        while (number >= 10) {
            number = number.div(10);
        }
        return number == _firstDigit;
    }


}