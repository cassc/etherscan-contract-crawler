// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TreasuryFunds is Initializable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public operator;

    event WithdrawTo(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == operator, "!operator");
        _;
    }

    function setOperator(address _op) external onlyOwner {
        operator = _op;
    }

    function withdrawTo(
        IERC20 _asset,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        _asset.safeTransfer(_to, _amount);
        emit WithdrawTo(_to, _amount);
    }

    function initialize(address _operator) external initializer {
        operator = _operator;
    }
}