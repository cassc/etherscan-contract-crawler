// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ECDSASignature.sol";

contract Router is Ownable, SigVerify {
    event TokenBatchSend(
        address indexed sender,
        IERC20 indexed token,
        uint256 indexed send_type,
        address[] recipients,
        uint256[] values,
        uint256 amount
    );
    using SafeERC20 for IERC20;

    mapping(address => uint256) public deduplication;

    function routTokens(
        IERC20 token,
        uint256 send_type,
        address[] memory recipients,
        uint256[] memory values,
        uint256 amount,
        uint256 num,
        bytes memory sig
    ) external {
        require (recipients.length == values.length, "Router::routTokens: bad input arrays dimension");

        uint sum = 0;
        for (uint a = 0; a < values.length; a++)
          sum += values[a];

        require(sum == amount, "Router::routTokens: values sum != amount");
        require(isValidData(_msgSender(), address(token), send_type, recipients, values, amount, num, sig), "Router::routTokens: signature is invalid");
        require(num >= deduplication[_msgSender()], "Router::routTokens: deduplication fail");

        deduplication[_msgSender()] = num + 1;
        token.safeTransferFrom(msg.sender, address(this), amount);

        for (uint i = 0; i < recipients.length; i++)
            token.safeTransfer(recipients[i], values[i]);

        emit TokenBatchSend(
            _msgSender(),
            token,
            send_type,
            recipients,
            values,
            amount
        );
    }
}