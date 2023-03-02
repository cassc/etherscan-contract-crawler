// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract OrbiterXRouterV1 is Ownable, Multicall {
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
            bool success = IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
            require(success, "Withdraw Fail");
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
            require(
                IERC20(token).allowance(msg.sender, address(this)) >= value,
                "Insufficient Balance"
            );
            bool success = IERC20(token).transferFrom(
                msg.sender,
                recipient,
                value
            );
            require(success, "Tranfer Wrong");
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
    )
        external
        payable
    {
        require(getMaker[recipient], "Maker does not exist");
        value = token == address(0) ? msg.value : value;
        forward(token, recipient, value);
    }
  /// @notice Swap response
  /// @param recipient User receiving address
  /// @param token Token sent to user
  /// @param value Amount sent to user
  /// @param data parameters are encoded by RLP compression  = RLP(fromHash + type)
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