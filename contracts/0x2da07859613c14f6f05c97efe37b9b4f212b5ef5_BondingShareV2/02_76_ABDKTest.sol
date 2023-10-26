// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUARForDollarsCalculator.sol";
import "./UbiquityAlgorithmicDollarManager.sol";
import "./libs/ABDKMathQuad.sol";
import "./DebtCoupon.sol";

contract ABDKTest {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    function max() public pure returns (uint256) {
        //   115792089237316195423570985008687907853269984665640564039457584007913129639935

        uint256 maxUInt256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        return maxUInt256.fromUInt().toUInt();
    }

    function add(uint256 amount) public pure returns (uint256) {
        uint256 maxUInt256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        return maxUInt256.fromUInt().add(amount.fromUInt()).toUInt();
    }
}