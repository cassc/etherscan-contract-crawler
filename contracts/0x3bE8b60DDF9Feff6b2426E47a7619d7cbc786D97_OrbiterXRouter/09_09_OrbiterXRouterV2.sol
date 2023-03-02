// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OrbiterXRouter is Ownable, Multicall {
    using SafeERC20 for IERC20;
    mapping(address => bool) public getMaker;
    event ChangeMaker(address indexed maker, bool indexed enable);

    constructor(address maker) {
        changeMaker(maker, true);
    }

    receive() external payable {}

    function changeMaker(address maker, bool enable) public onlyOwner {
        getMaker[maker] = enable;
        emit ChangeMaker(maker, enable);
    }

    function withdraw(address token) external onlyOwner {
        if (token != address(0)) {
            IERC20 coin = IERC20(token);
            coin.safeTransfer(msg.sender, coin.balanceOf(address(this)));
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function forward(
        address token,
        address payable recipient,
        uint256 value
    ) private {
        if (token == address(0)) {
            require(address(this).balance >= value, "Insufficient Balance");
            recipient.transfer(value);
        } else {
            IERC20 coin = IERC20(token);
            require(
                coin.allowance(msg.sender, address(this)) >= value,
                "Approve Insufficient Balance"
            );
            coin.safeTransferFrom(msg.sender, recipient, value);
        }
    }

    /// @notice This method allows you to initiate a Swap transaction
    /// @dev You can call our contract Swap anywhere
    /// @param recipient maker wallet address
    /// @param token source chain token, chain mainToken address is 0x000....000
    /// @param value source chain send token value
    /// @param data Other parameters are encoded by RLP compression
    function swap(
        address payable recipient,
        address token,
        uint256 value,
        bytes calldata data
    ) external payable {
        require(getMaker[recipient], "Maker does not exist");
        value = token == address(0) ? msg.value : value;
        forward(token, recipient, value);
    }

    /// @notice Swap response
    /// @param recipient User receiving address
    /// @param token Token sent to user
    /// @param value Amount sent to user
    /// @param data parameters are encoded by RLP compression
    function swapAnswer(
        address payable recipient,
        address token,
        uint256 value,
        bytes calldata data
    ) external payable {
        require(getMaker[msg.sender], "caller is not the maker");
        forward(token, recipient, value);
    }
}