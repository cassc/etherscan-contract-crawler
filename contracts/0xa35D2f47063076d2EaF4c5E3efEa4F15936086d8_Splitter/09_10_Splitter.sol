// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Withdrawable} from "./Withdrawable.sol";

/**
 * @title Splitter
 * @author Immunefi
 */
contract Splitter is Ownable, Withdrawable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct ERC20Payment {
        address token;
        uint256 amount;
    }

    event FeeRecipientChanged(address prevFeeRecipient, address newFeeRecipient);
    event FeeChanged(uint256 prevFee, uint256 newFee);
    event PayWhitehat(address indexed from, bytes32 indexed referenceId, address wh, ERC20Payment[] payout, uint256 nativeTokenAmt, address feeRecipient, uint256 fee);

    uint256 public fee;
    uint256 public constant FEE_BASIS = 100_00;
    uint256 public immutable MAX_FEE;
    address payable public feeRecipient;

    constructor(uint256 maxFee, uint256 _fee, address _owner, address payable _feeRecipient) {
        require(maxFee <= FEE_BASIS, "Splitter: MAX_FEE must be below FEE_BASIS");
        MAX_FEE = maxFee;

        _setFee(_fee);

        feeRecipient = _feeRecipient;
        _transferOwnership(_owner);
    }

    /**
     * @notice internal set fee
     * @param newFee value of the new fee. Must be less than MAX_FEE
     */
    function _setFee(uint256 newFee) internal {
        require(newFee <= MAX_FEE, "Splitter: fee must be below MAX_FEE");

        emit FeeChanged(fee, newFee);
        fee = newFee;        
    }

    /**
     * @notice set fee
     * @dev only callable by owner
     * @param newFee value of the new fee
     */
    function setFee(uint256 newFee) public onlyOwner {
        _setFee(newFee);
    }

    /**
     * @notice internal change fee recipient
     * @param newFeeRecipient address of new fee recipient
     */
    function _changeFeeRecipient(address payable newFeeRecipient) internal {
        emit FeeRecipientChanged(feeRecipient, newFeeRecipient);

        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice change fee recipient
     * @dev only callable by owner
     * @param newFeeRecipient address of new fee recipient
     */
    function changeFeeRecipient(address payable newFeeRecipient) public onlyOwner {
        _changeFeeRecipient(newFeeRecipient);
    }

    /**
     * @notice Pay a whitehat
     * @dev If whitehats attempt to grief payments, project/immunefi reserves the right to nullify bounty payout
     * @dev The amount of gas forwarded to the whitehat should be enough for a delegatecall to be made to support
     *      gnosis safe wallets
     * @param referenceId id reference to report
     * @param wh whitehat address
     * @param payout The payout of tokens/token amounts to whitehat
     * @param nativeTokenAmt The payout of native Ether amount to whitehat
     * @param gas The amount of gas to forward to the whitehat to mitigate gas griefing
     */
    function payWhitehat(
        bytes32 referenceId,
        address payable wh,
        ERC20Payment[] calldata payout,
        uint256 nativeTokenAmt,
        uint256 gas
    ) public payable nonReentrant {
        for (uint256 i; i < payout.length; i++) {
            uint256 feeAmount = (payout[i].amount * fee) / FEE_BASIS;
            if (feeAmount > 0) IERC20(payout[i].token).safeTransferFrom(msg.sender, feeRecipient, feeAmount);
            IERC20(payout[i].token).safeTransferFrom(msg.sender, wh, payout[i].amount);
        }

        if (nativeTokenAmt > 0) {
            uint256 feeAmount = (nativeTokenAmt * fee) / FEE_BASIS;
            if (feeAmount > 0) {
                (bool successFee, ) = feeRecipient.call{value: feeAmount}("");
                require(successFee, "Splitter: Failed to send ether to fee receiver");
            }
            (bool successWh, ) = wh.call{value: nativeTokenAmt, gas: gas}("");
            require(successWh, "Splitter: Failed to send ether to whitehat");

            uint256 nativeAmountDistributed = nativeTokenAmt + feeAmount;
            if (msg.value > nativeAmountDistributed) {
                (bool successRefund, ) = msg.sender.call{value: (msg.value - nativeAmountDistributed)}("");
                require(successRefund, "Splitter: Failed to refund to msg.sender");
            }
        }

        emit PayWhitehat(msg.sender, referenceId, wh, payout, nativeTokenAmt, feeRecipient, fee);
    }

    /**
     * @notice Withdraw asset ERC20 or ETH
     * @param _assetAddress Asset to be withdrawn.
     */
    function withdrawERC20ETH(address _assetAddress) public virtual override onlyOwner {
        super.withdrawERC20ETH(_assetAddress);
    }
}