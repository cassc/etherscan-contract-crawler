//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBKErrors.sol";

contract BKCommon is IBKErrors, Ownable, Pausable, ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    mapping(address => bool) isOperator;
        
    event RescueETH(address indexed recipient, uint256 amount);
    event RescueERC20(address indexed asset, address recipient);
    event SetOperator(address operator, bool isOperator);

    modifier onlyOperator() {
        require(isOperator[_msgSender()], "Operator: caller is not the operator");
        _;
    }
    
    function setOperator(address[] calldata _operators, bool _isOperator) external onlyOwner {
        for(uint i = 0; i < _operators.length; i++) {
            isOperator[_operators[i]] = _isOperator;
            emit SetOperator(_operators[i], _isOperator);
        }
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function rescueERC20(address asset, address recipient) external onlyOperator {
        IERC20(asset).safeTransfer(
            recipient,
            IERC20(asset).balanceOf(address(this))
        );
        emit RescueERC20(asset, recipient);
    }
    
    function rescueETH(address recipient) external onlyOperator {
        _transferEth(recipient, address(this).balance);
    }

    function _transferEth(address _to, uint256 _amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callStatus, "_transferEth: Eth transfer failed");
        emit RescueETH(_to, _amount);
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) internal pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    receive() external payable {}
}