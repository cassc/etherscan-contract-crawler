pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SpynPool is Ownable {

    // The MAIN TOKEN
    IERC20 public token;

    string public name;
    mapping(address => bool) public operators;
    event OperatorUpdated(address indexed operator, bool indexed status);
    event PoolOutOfToken();

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    constructor(
        string memory _name,
        IERC20 _token
    ) {
        token = _token;
        name = _name;
        operators[msg.sender] = true;
    }

    function setOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    // Safe transfer <amount> of token to <to>
    function safeTransfer(address _to, uint256 _amount) external onlyOperator returns (bool) {
        uint256 bal = token.balanceOf(address(this));
        if (_amount > bal) {
            emit PoolOutOfToken();
            return false;
        } else if (_amount > 0) {
            token.transfer(_to, _amount);
            return true;
        } else {
            return true;
        }
    }

    // withdraw other token deposited
    function withdrawToken(address _to, uint256 _amount, address _token) external onlyOperator {
        require(_token != address(0), "token address is zero");
        IERC20(_token).transfer(_to, _amount);
    }
}