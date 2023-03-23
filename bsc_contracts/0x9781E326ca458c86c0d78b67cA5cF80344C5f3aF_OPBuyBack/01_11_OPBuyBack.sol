// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./common/DelegateInterface.sol";
import "./common/Adminable.sol";
import "./common/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/DexData.sol";
import "./libraries/Utils.sol";
import "./interfaces/OPBuyBackInterface.sol";
import "./libraries/Aggregator1InchV5.sol";
import "./IWrappedNativeToken.sol";

contract OPBuyBack is DelegateInterface, Adminable, ReentrancyGuard {
    using TransferHelper for IERC20;
    using DexData for bytes;
    event Received(address token, uint256 inAmount, uint256 received);
    event BuyBacked(address token, uint256 sellAmount, uint256 boughtAmount);

    address public ole;
    address public wrappedNativeToken;
    address public router1inch;

    address private constant _ZERO_ADDRESS = address(0);

    constructor() {}

    /// @notice Initialize contract only by admin
    /// @dev This function is supposed to call multiple times
    /// @param _ole The ole token address
    /// @param _router1inch The 1inch router address
    function initialize(address _ole, address _wrappedNativeToken, address _router1inch) external onlyAdmin {
        ole = _ole;
        wrappedNativeToken = _wrappedNativeToken;
        router1inch = _router1inch;
    }

    function transferIn(address token, uint amount) external payable {
        if (isNativeToken(token)) {
            emit Received(token, msg.value, msg.value);
        } else {
            uint256 received = IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            emit Received(token, amount, received);
        }
    }

    function withdraw(address token, address to, uint amount) external onlyAdmin {
        if (isNativeToken(token)) {
            (bool success, ) = to.call{ value: amount }("");
            require(success);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function buyBack(address sellToken, uint sellAmount, uint minBuyAmount, bytes memory data) external nonReentrant onlyAdminOrDeveloper {
        require(sellToken != ole, "Token err");
        if (isNativeToken(sellToken)) {
            sellToken = wrappedNativeToken;
            IWrappedNativeToken(wrappedNativeToken).deposit{ value: sellAmount }();
        }
        uint boughtAmount = Aggregator1InchV5.swap1inch(router1inch, data, address(this), ole, sellToken, sellAmount, minBuyAmount);
        emit BuyBacked(sellToken, sellAmount, boughtAmount);
    }

    function setRouter1inch(address _router1inch) external onlyAdmin {
        router1inch = _router1inch;
    }

    function isNativeToken(address token) private pure returns (bool) {
        return token == _ZERO_ADDRESS;
    }
}