pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IWETH.sol";

contract FeeReceiverMultichain is Ownable {
    address public WETH;

    constructor(address _WETH) public {
        WETH = _WETH;
    }

    /// @dev converts WETH to ETH
    function unwrapWETH() public {
        uint256 balance = IWETH(WETH).balanceOf(address(this));
        require(balance > 0, "FeeReceiver: Nothing to unwrap");
        IWETH(WETH).withdraw(balance);
    }

    /// @dev lets the owner withdraw ETH from the contract
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    /// @dev lets the owner withdraw any ERC20 Token from the contract
    function withdrawERC20Token(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// @dev allows to receive ETH on this contract
    receive() external payable {}
}