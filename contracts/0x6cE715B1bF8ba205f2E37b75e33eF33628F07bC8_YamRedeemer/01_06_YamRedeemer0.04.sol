// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title contract used to redeem a list of tokens, by permanently
/// taking another token out of circulation.
/// @author Yam Protocol
contract YamRedeemer is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice event to track redemptions
    event Redeemed(
        address indexed owner,
        address indexed receiver,
        uint256 amount,
        uint256 base
    );

    /// @notice final event triggered by the charity redemption
    event donated(address txSender);

    /// @notice token to redeem
    address public immutable redeemedToken;

    /// @notice tokens to receive when redeeming
    address[] private tokensReceived;

    /// @notice base used to compute the redemption amounts.
    /// For instance, if the base is 100, and a user provides 100 `redeemedToken`,
    /// they will receive all the balances of each `tokensReceived` held on this contract.
    uint256 public redeemBase;

    /// @notice the timstamp at deploy
    uint256 public deployTimestamp;

    uint256 public oneYearInSeconds = 365 * 24 * 60 * 60;

    address public charity1 = 0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6;
    address public charity2 = 0xC76AbD442D750fDeb9e3735BC39A4E70F634d678;

    uint256 public charity1Ratio = 0.385 ether; // Gitcoin
    uint256 public charity2Ratio = 0.615 ether; // Watoto

    constructor(
        address _redeemedToken,
        address[] memory _tokensReceived,
        uint256 _redeemBase
    ) {
        redeemedToken = _redeemedToken;
        tokensReceived = _tokensReceived;
        redeemBase = _redeemBase;
        deployTimestamp = block.timestamp;
    }

    /// @notice Public function to get `tokensReceived`
    function tokensReceivedOnRedeem() public view returns (address[] memory) {
        return tokensReceived;
    }

    /// @notice Return the balances of `tokensReceived` that would be
    /// transferred if redeeming `amountIn` of `redeemedToken`.
    function previewRedeem(uint256 amountIn)
        public
        view
        returns (address[] memory tokens, uint256[] memory amountsOut)
    {
        tokens = tokensReceivedOnRedeem();
        amountsOut = new uint256[](tokens.length);

        uint256 base = redeemBase;
        for (uint256 i = 0; i < tokensReceived.length; i++) {
            uint256 balance = IERC20(tokensReceived[i]).balanceOf(
                address(this)
            );
            require(balance != 0, "ZERO_BALANCE");
            // @dev, this assumes all of `tokensReceived` and `redeemedToken`
            // have the same number of decimals
            uint256 redeemedAmount = (amountIn * balance) / base;
            amountsOut[i] = redeemedAmount;
        }
    }

    /// @notice Redeem `redeemedToken` for a pro-rata basket of `tokensReceived`
    function redeem(address to, uint256 amountIn) external nonReentrant {
        IERC20(redeemedToken).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        (address[] memory tokens, uint256[] memory amountsOut) = previewRedeem(
            amountIn
        );

        uint256 base = redeemBase;
        redeemBase = base - amountIn; // decrement the base for future redemptions
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(to, amountsOut[i]);
        }

        emit Redeemed(msg.sender, to, amountIn, base);
    }

    /// @notice Donate sends the remaining funds to the hardcoded charities after
    /// 365 days has ellapsed
    function donate() external nonReentrant {
        require(
            block.timestamp >= deployTimestamp + oneYearInSeconds,
            "not enough time"
        );

        (
            address[] memory tokens,
            uint256[] memory amountsOutCharity1
        ) = previewDonation(charity1Ratio);

        (, uint256[] memory amountsOutCharity2) = previewDonation(
            charity2Ratio
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(charity1, amountsOutCharity1[i]);
            IERC20(tokens[i]).safeTransfer(charity2, amountsOutCharity2[i]);
        }

        emit donated(msg.sender);
    }

    /// @notice Return the ratio of tokens to be sent to the charity
    /// previewDonation() is intentionally not gas optimized to alter as little code as possible
    function previewDonation(uint256 charityRatio)
        public
        view
        returns (address[] memory tokens, uint256[] memory amountsOut)
    {
        tokens = tokensReceivedOnRedeem();
        amountsOut = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokensReceived.length; i++) {
            uint256 balance = IERC20(tokensReceived[i]).balanceOf(
                address(this)
            );
            require(balance != 0, "ZERO_BALANCE");
            uint256 redeemedAmount = (charityRatio * balance) / 1 ether;
            amountsOut[i] = redeemedAmount;
        }
    }
}