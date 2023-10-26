// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IEscrow.sol";
import "./libraries/TransferHelper.sol";
import "./UniswapV3ForMto.sol";

abstract contract Escrow is IEscrow, UniswapV3ForMto {
    // Escrow Status
    uint256 public currentEscrowId;
    uint8 constant DEFAULT = 1;
    uint8 constant DISPUTE = 2;
    uint8 constant REFUNDABLE = 3;
    uint8 constant COMPLETED = 4;
    uint8 constant REFUNDED = 5;

    mapping(uint256 => Escrow) public escrows;

    // _escrowDisputableTime(Epoch time in seconds) - After this time, a customer can make a dispute case
    // _escrowWithdrawableTime(Epoch time in seconds) - After this time, a merchant can withdraw funds from an escrow contract
    function _purchase(
        address _token,
        address _currentCaller,
        uint256 _productId,
        address _merchantAddress,
        uint256 _amount,
        uint256 _escrowDisputableTime,
        uint256 _escrowWithdrawableTime
    ) internal {
        require(_merchantAddress != address(0), "Invalid Merchant Address");
        require(_amount > 0, "Amount should be bigger than zero");
        
        
        require(
            TransferHelper.allowance(_token, _currentCaller, address(this)) >=
                _amount,
            "You should approve token transfer to this contract first"
        );
        require(
            _escrowDisputableTime > block.timestamp,
            "Disputable time should be later than current time"
        );
        require(
            _escrowWithdrawableTime > _escrowDisputableTime,
            "Withdraw Time should be later than Disputable time"
        );

        escrows[currentEscrowId + 1] = Escrow(
            _productId,
            _currentCaller,
            _merchantAddress,
            _amount,
            _escrowWithdrawableTime,
            _escrowDisputableTime,
            DEFAULT,
            block.timestamp
        );
        currentEscrowId = currentEscrowId + 1;
        TransferHelper.safeTransferFrom(
            _token,
            _currentCaller,
            address(this),
            _amount
        );
        emit Escrowed(_currentCaller, _productId, _amount, currentEscrowId);
    }
    function _withdraw(
        address _token,
        address _currentCaller,
        uint256 _escrowId
    ) public {
        require(
            escrows[_escrowId].status == DEFAULT ||
                escrows[_escrowId].status == REFUNDABLE,
            "Invalid Status"
        );
        require(
            block.timestamp > escrows[_escrowId].escrowWithdrawableTime,
            "Escrowd time has not passed yet"
        );
        require(
            _currentCaller == escrows[_escrowId].buyerAddress ||
                _currentCaller == escrows[_escrowId].merchantAddress,
            "Caller is neither Buyer nor Merchant"
        );
        /*
        require(
            TransferHelper.balanceOf(_token, address(this)) >=
                escrows[_escrowId].amount,
            "Contract doesn't have enough funds"
        );
        */
        if (
            escrows[_escrowId].status == DEFAULT &&
            escrows[_escrowId].buyerAddress == _currentCaller
        ) {
            revert("Buyer cannot withdraw in default status");
        }
        if (
            escrows[_escrowId].status == REFUNDABLE &&
            escrows[_escrowId].merchantAddress == _currentCaller
        ) {
            revert("Merchant cannot withdraw in refund status");
        }
        if (
            escrows[_escrowId].status == REFUNDABLE &&
            escrows[_escrowId].buyerAddress == _currentCaller
        ) {
            // Transfers tokens to buyer
            TransferHelper.safeTransfer(
                _token,
                escrows[_escrowId].buyerAddress,
                escrows[_escrowId].amount
            );
            // Update the escrow status as REFUNDED
            escrows[_escrowId].status = REFUNDED;
            // emit Withdraw(_currentCaller, _escrowId, escrows[_escrowId].amount);
            emit Refunded(_currentCaller, _escrowId, escrows[_escrowId].amount);
        } else if (
            escrows[_escrowId].status == DEFAULT &&
            escrows[_escrowId].merchantAddress == _currentCaller
        ) {
            // Update the escrow status as COMPLETED
            escrows[_escrowId].status = COMPLETED;
            // Transfers tokens to merchant
            TransferHelper.safeTransfer(
                _token,
                escrows[_escrowId].merchantAddress,
                escrows[_escrowId].amount
            );
            emit Withdraw(_currentCaller, _escrowId, escrows[_escrowId].amount);
        }
    }
}