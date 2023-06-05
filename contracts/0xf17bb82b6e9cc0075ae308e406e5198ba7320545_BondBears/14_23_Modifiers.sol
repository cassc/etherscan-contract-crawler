// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Modifiers {
    using SafeMath for uint16;
    using SafeMath for uint256;
    /**
     * @dev A modifier that verifies that the correct amount of Ether has been recieved prior to executing
     * the function is it applied to.
     */

    modifier requireTrue(bool x, string memory errMsg) {
        require(x, errMsg);
        _;
    }

    modifier requireFalse(bool x, string memory errMsg) {
        require(!x, errMsg);
        _;
    }

    modifier costs(uint16 num, uint256 price) {
        require(msg.value >= price.mul(num), "Insufficient funds sent to fulfill request");
        _;
    }

    /**
     * @dev A modifier that ensures it is passed a certain time before the function it is applied to can be executed.
     */
    modifier opensAt(uint256 timestamp, string memory errMsg) {
        require(block.timestamp >= timestamp, errMsg);
        _;
    }
}