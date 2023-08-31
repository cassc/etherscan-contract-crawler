// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GaslessRelayer is ERC2771Context {
    address gasProvider;

    constructor(address forwarder, address _gasProvider)
        ERC2771Context(forwarder)
    {
        gasProvider = _gasProvider;
    }

    function transferGasless(
        address owner,
        address destination,
        uint256 amount,
        uint256 fee,
        address tokenAddress,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        require(
            isTrustedForwarder(msg.sender),
            "Only transactions from the trusted forwarder are allowed"
        );

        ERC20Permit token = ERC20Permit(tokenAddress);

        token.permit(owner, address(this), amount + fee, deadline, v, r, s);

        bool feeTransferResult = IERC20(tokenAddress).transferFrom(
            owner,
            gasProvider,
            fee
        );
        require(feeTransferResult, "Unable to transfer fee to gasProvider");

        bool transferResult = IERC20(tokenAddress).transferFrom(
            owner,
            destination,
            amount
        );
        require(transferResult, "Unable to transfer token");
    }
}