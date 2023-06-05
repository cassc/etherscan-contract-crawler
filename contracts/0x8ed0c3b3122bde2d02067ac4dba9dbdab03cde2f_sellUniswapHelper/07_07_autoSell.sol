// SPDX-License-Identifier: MIT

pragma solidity >=0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function WETH() external pure returns (address);
}

contract sellUniswapHelper is Ownable {
    using SafeERC20 for IERC20;

    address public pairAdd;
    address public routerAdd;

    uint public sellAmount;

    mapping(address => bool) public isAdmin;

    modifier checkAdmin() {
        require(isAdmin[msg.sender], "Only admin can call this function");
        _;
    }

    constructor() {
        isAdmin[msg.sender] = true;
    }

    function sellTokens(address _token) external checkAdmin {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = IRouter(routerAdd).WETH();
        IRouter(routerAdd).swapExactTokensForETHSupportingFeeOnTransferTokens(
            sellAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function setSellAmount(uint _amount) external checkAdmin {
        sellAmount = _amount;
    }

    function approveRouter(
        address _token,
        uint256 _amount
    ) external checkAdmin {
        IERC20(_token).approve(routerAdd, _amount);
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, balance);
    }

    function updateAdmins(address _admin, bool _isAdmin) external onlyOwner {
        isAdmin[_admin] = _isAdmin;
    }

    function setAddresses(
        address _pairAdd,
        address _routerAdd
    ) external onlyOwner {
        pairAdd = _pairAdd;
        routerAdd = _routerAdd;
    }

    receive() external payable {}
}