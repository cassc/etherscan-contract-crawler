// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/errors.sol";

/**
// @title Abstract Contract for middleware services.
// @notice All middleware services will follow this interface. 
*/
abstract contract MiddlewareImplBase is Ownable {
    using SafeERC20 for IERC20;
    address public immutable registry;

    /// @notice only registry address is required.
    constructor(address _registry) Ownable() {
        registry = _registry;
    }

    modifier onlyRegistry {
        require(msg.sender == registry, MovrErrors.INVALID_SENDER);
        _;
    }

    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address receiverAddress,
        bytes memory data
    ) external payable virtual returns (uint256);

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }
}