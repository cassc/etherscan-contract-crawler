// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IWithdrawable} from "./IWithdrawable.sol";

///@notice Ownable helper contract to withdraw ether or tokens from the contract address balance
contract CommissionWithdrawable is IWithdrawable, Ownable {
    address internal immutable commissionPayoutAddress;
    uint256 internal immutable commissionPayoutPerMille;

    error CommissionPayoutAddressIsZeroAddress();
    error CommissionPayoutPerMilleTooLarge();

    constructor(
        address _commissionPayoutAddress,
        uint256 _commissionPayoutPerMille
    ) {
        if (_commissionPayoutAddress == address(0)) {
            revert CommissionPayoutAddressIsZeroAddress();
        }
        if (_commissionPayoutPerMille > 1000) {
            revert CommissionPayoutPerMilleTooLarge();
        }
        commissionPayoutAddress = _commissionPayoutAddress;
        commissionPayoutPerMille = _commissionPayoutPerMille;
    }

    ////////////////////////
    // Withdrawal methods //
    ////////////////////////

    ///@notice Withdraw Ether from contract address. OnlyOwner.
    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;
        (
            uint256 ownerShareMinusCommission,
            uint256 commissionFee
        ) = calculateOwnerShareAndCommissionFee(balance);
        payable(msg.sender).transfer(ownerShareMinusCommission);
        payable(commissionPayoutAddress).transfer(commissionFee);
    }

    ///@notice Withdraw tokens from contract address. OnlyOwner.
    ///@param _token ERC20 smart contract address
    function withdrawToken(address _token) external override onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        (
            uint256 ownerShareMinusCommission,
            uint256 commissionFee
        ) = calculateOwnerShareAndCommissionFee(balance);
        IERC20(_token).transfer(msg.sender, ownerShareMinusCommission);
        IERC20(_token).transfer(commissionPayoutAddress, commissionFee);
    }

    function calculateOwnerShareAndCommissionFee(uint256 _balance)
        private
        view
        returns (uint256, uint256)
    {
        uint256 commissionFee;
        // commissionPayoutPerMille is max 1000 which is ~2^10; will only overflow if balance is > ~2^246
        if (_balance < 2**246) {
            commissionFee = (_balance * commissionPayoutPerMille) / 1000;
        } else {
            // commission fee may be truncated by up to 999000 units (<2**20) – but only for balances > 2**246
            commissionFee = (_balance / 1000) * commissionPayoutPerMille;
        }
        uint256 ownerShareMinusCommission = _balance - commissionFee;
        return (ownerShareMinusCommission, commissionFee);
    }
}