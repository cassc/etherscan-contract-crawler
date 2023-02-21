// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { FeeDistributor } from "./utils/FeeDistributor.sol";
import { Signatures } from "./utils/Signatures.sol";
import { ITokenBuyer } from "./interfaces/ITokenBuyer.sol";
import { IUniversalRouter } from "./interfaces/external/IUniversalRouter.sol";
import { LibAddress } from "./lib/LibAddress.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A smart contract for buying any kind of tokens and taking a fee.
contract TokenBuyer is ITokenBuyer, FeeDistributor, Signatures {
    using LibAddress for address payable;

    address payable public immutable universalRouter;
    address public immutable permit2;

    /// @param universalRouter_ The address of Uniswap's Universal router.
    /// @param universalRouter_ The address of the Permit2 contract.
    /// @param feeCollector_ The address that will receive a fee from the funds.
    /// @param feePercentBps_ The percentage of the fee expressed in basis points (e.g 500 for a 5% cut).
    constructor(
        address payable universalRouter_,
        address permit2_,
        address payable feeCollector_,
        uint96 feePercentBps_
    ) FeeDistributor(feeCollector_, feePercentBps_) {
        universalRouter = universalRouter_;
        permit2 = permit2_;
    }

    function getAssets(
        uint256 guildId,
        PayToken calldata payToken,
        bytes calldata uniCommands,
        bytes[] calldata uniInputs
    ) external payable {
        IERC20 token = IERC20(payToken.tokenAddress);

        // Get the tokens from the user and send the fee collector's share
        if (address(token) == address(0)) feeCollector.sendEther(calculateFee(address(0), msg.value));
        else {
            if (!token.transferFrom(msg.sender, address(this), payToken.amount))
                revert TransferFailed(msg.sender, address(this));
            if (!token.transfer(feeCollector, calculateFee(address(token), payToken.amount)))
                revert TransferFailed(address(this), feeCollector);
            if (token.allowance(address(this), permit2) < payToken.amount) token.approve(permit2, type(uint256).max);
        }

        IUniversalRouter(universalRouter).execute{ value: address(this).balance }(uniCommands, uniInputs);

        // Send out any remaining tokens
        if (address(token) != address(0) && !token.transfer(msg.sender, token.balanceOf(address(this))))
            revert TransferFailed(address(this), msg.sender);

        emit TokensBought(guildId);
    }

    function sweep(address token, address payable recipient, uint256 amount) external onlyFeeCollector {
        if (!IERC20(token).transfer(recipient, amount)) revert TransferFailed(address(this), feeCollector);
        emit TokensSweeped(token, recipient, amount);
    }
}