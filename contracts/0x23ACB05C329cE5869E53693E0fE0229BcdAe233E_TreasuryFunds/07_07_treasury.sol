// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract TreasuryFunds is Initializable{
    using SafeERC20 for IERC20;
    using Address for address;

    address public operator;

    event WithdrawTo(address indexed user, uint256 amount);
    event ApproveTo(address indexed user, uint256 amount);
    modifier onlyOwner {
        require(msg.sender==operator,"!operator");
        _;
    }

    function setOperator(address _op)onlyOwner external {
        operator = _op;
    }
    
    function withdrawTo(IERC20 _asset, uint256 _amount, address _to)onlyOwner external {

        _asset.safeTransfer(_to, _amount);
        emit WithdrawTo(_to, _amount);
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    )onlyOwner external returns (bool, bytes memory) {

        (bool success, bytes memory result) = _to.call{value:_value}(_data);

        return (success, result);
    }
    
    function approveTo(IERC20 _asset, uint256 _amount, address _to)onlyOwner external {

        _asset.safeIncreaseAllowance(_to, _amount);
        emit ApproveTo(_to, _amount);
    }

    function initialize(address _operator) external initializer{
        operator=_operator;

    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}