pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MockAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    event MockAdapterEvent(
        address sender,
        uint256 valueFixed,
        uint256 valueDynamic
    );

    function test(
        address sender,
        uint256 valueFixed,
        uint256 valueDynamic
    ) external payable {
        emit MockAdapterEvent(sender, valueFixed, valueDynamic);
    }

    function testRevert(
        address,
        uint256,
        uint256
    ) external payable {
        revert("SWAP_FAILED");
    }

    function testRevertNoReturnData(
        address,
        uint256,
        uint256
    ) external payable {
        revert();
    }
}