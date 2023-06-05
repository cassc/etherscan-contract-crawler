// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/Errors.sol";

contract BentCVX is Ownable, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event SetMultisig(address indexed multisig);
    event Deposit(address indexed user, uint256 amount);

    IERC20 public cvx;
    address public multisig;

    constructor(address _cvx, address _multisig)
        Ownable()
        ERC20("Bent CVX", "bentCVX")
    {
        cvx = IERC20(_cvx);
        multisig = _multisig;
    }

    function setMultisig(address _multisig) external onlyOwner {
        require(_multisig != address(0), Errors.INVALID_ADDRESS);

        multisig = _multisig;

        emit SetMultisig(_multisig);
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount != 0, Errors.ZERO_AMOUNT);

        cvx.safeTransferFrom(msg.sender, multisig, _amount);

        _mint(msg.sender, _amount);

        emit Deposit(msg.sender, _amount);
    }
}