// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Token is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor() ERC20("KK", "KK") {
        _mint(msg.sender, 1000_0000 * 1e18);
    }

    address public LPChefAddress;

    function mint(address account, uint256 amount) public {
        super._mint(account, amount);
    }
}