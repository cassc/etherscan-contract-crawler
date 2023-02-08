// SPDX-License-Identifier: MIT
// contracts/MilitaryAchievementValue.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MilitaryAchievementValue is AccessControlEnumerable, ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => uint[]) public swapPair;

    address public wallet;

    event Swap(address indexed from, address indexed token, uint amountIn, uint amountOut);

    constructor() ERC20("Military Achievement Value", "MAV") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function mint(address to, uint amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "MAV: Must have minter role to mint");

        _mint(to, amount);
    }

    function swap(address token, uint amountIn) public {
        require(amountIn > 0, "MAV: Amount too small");

        uint amountOut = getAmountOut(token, amountIn);
        require(amountOut > 0, "MAV: Amount Out Insuffcient");

        IERC20(token).transferFrom(_msgSender(), wallet, amountIn);
        _mint(_msgSender(), amountOut);

        emit Swap(_msgSender(), token, amountIn, amountOut);
    }

    function setSwapPair(address token, uint amountIn, uint amountOut) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MAV: Must have admin role to set price");
        require(token.code.length > 0, "MAV: Token address invalid");
        require(amountIn > 0, "MAV: Amount in too samll");
        require(amountOut > 0, "MAV: Amount out too samll");

        swapPair[token] = [amountIn, amountOut];
    }

    function setWallet(address addr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MAV: Must have admin role to set wallet");

        wallet = addr;
    }

    function getAmountOut(address token, uint amountIn) public view returns (uint) {
        require(swapPair[token].length == 2, "MAV: Swap pair length invalid");

        uint[] memory amounts = swapPair[token];
        return (amountIn * amounts[1]) / amounts[0];
    }
}