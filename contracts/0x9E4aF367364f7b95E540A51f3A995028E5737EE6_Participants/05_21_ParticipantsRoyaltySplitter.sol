// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./interfaces/IParticipantsERC20Tokens.sol";

contract ParticipantsRoyaltySplitter is PaymentSplitter {
    event PaymentReceivedOnRC(address from, uint256 amount);
    uint256 internal _payeesCount;
    IParticipantsERC20Tokens internal immutable _erc20TokensInterface;

    constructor(
        address[] memory payees,
        uint256[] memory shares_,
        address prtcAddress
    ) PaymentSplitter(payees, shares_) {
        require(payees.length == shares_.length, "LengthMismatch");
        require(payees.length > 0, "NoPayees");

        _payeesCount = payees.length;
        _erc20TokensInterface = IParticipantsERC20Tokens(prtcAddress);
    }

    function releaseAll() public payable {
        address[] memory erc20Tokens = _erc20TokensInterface
            .getRoyaltyERC20Tokens();
        for (uint256 index = 0; index < erc20Tokens.length; index++) {
            IERC20 token = IERC20(erc20Tokens[index]);
            if (token.balanceOf(address(this)) > 0) {
                for (
                    uint256 payeeIndex = 0;
                    payeeIndex < _payeesCount;
                    payeeIndex++
                ) {
                    //release erc20 tokens
                    address _payee = payee(payeeIndex);
                    release(token, payable(_payee));
                }
            }
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            for (
                uint256 payeeIndex = 0;
                payeeIndex < _payeesCount;
                payeeIndex++
            ) {
                address _payee = payee(payeeIndex);
                release(payable(_payee));
            }
        }
    }

    // Function to receive ether, msg.data must be empty
    receive() external payable override {
        releaseAll();
        emit PaymentReceivedOnRC(msg.sender, msg.value);
    }
}