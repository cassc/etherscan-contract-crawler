// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IBKErrors.sol";
import "./interfaces/IBKCommon.sol";

contract BKCommon is IBKCommon, IBKErrors, Ownable, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    mapping(address => bool) isOperator;

    event RescueETH(address indexed recipient, uint256 amount);
    event RescueERC20(address indexed asset, address recipient);
    event RescueERC721(address indexed asset, address recipient, uint256[] ids);
    event RescueERC1155(address indexed asset, address recipient, uint256[] ids, uint256[] amounts);

    event SetOperator(address operator, bool isOperator);

    modifier onlyOperator() {
        require(isOperator[_msgSender()], "Operator: caller is not the operator");
        _;
    }

    function setOperator(address[] calldata _operators, bool _isOperator) external onlyOwner {
        for (uint i = 0; i < _operators.length; i++) {
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
    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOperator external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).safeTransferFrom(address(this), recipient, ids[i]);
        }
        emit RescueERC721(asset, recipient, ids);
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOperator external {
        require(ids.length == amounts.length, "ids and amounts length mismatched");

        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
        emit RescueERC1155(asset, recipient, ids, amounts);
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
        assembly {revert(add(data, 32), mload(data))}
    }

    receive() external payable {}
}