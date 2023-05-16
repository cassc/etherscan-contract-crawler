// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

import "../security/Ownable.sol";
import "./CompanyVault.sol";
import "./AlternativeTokenHelper.sol";
import "./FeeConfiguration.sol";

abstract contract TokenProcessing is CompanyVault, AlternativeTokenHelper, FeeConfiguration {
    event FeeTaken(uint amount, address indexed targetAddress, bool isAlternative);

    struct DepositedValue {
        uint mainAmount;
    }

    constructor(address mainToken) CompanyVault(mainToken) {}

    // Deposit amount from sender
    function deposit(address sender, uint amount) internal returns (DepositedValue memory) {
        require(amount > 0, "TokenProcessing - deposit zero amount");
        depositToken(getMainIERC20Token(), sender, amount);
        return DepositedValue(amount);
    }

    // Withdrawal main tokens to user
    // Used only in take prize and bet cancellation
    function withdrawalMainToken(address recipient, uint amount) internal {
        bool result = getMainIERC20Token().transfer(recipient, amount);
        require(result, "TokenProcessing: withdrawal token failed");
    }


    // Evaluate fee from amount and take it. Return the rest of it.
    function takeFeeFromAmount(address winner, uint amount, bool useAlternativeFee) internal returns (uint) {
        if (useAlternativeFee) {
            require(isAlternativeTokenEnabled(), "TokenProcessing: alternative token disabled");
            uint alternativeFeePart = applyAlternativeFee(amount);
            uint feeInAlternativeToken = evaluateAlternativeAmount(alternativeFeePart, address(getMainIERC20Token()), address(getAlternativeIERC20Token()));
            depositToken(getAlternativeIERC20Token(), winner, feeInAlternativeToken);
            increaseFee(feeInAlternativeToken, address(getAlternativeIERC20Token()));
            return amount;
        } else {
            uint feePart = applyCompanyFee(amount);
            increaseFee(feePart, address(getMainIERC20Token()));
            return amount - feePart;
        }
    }


    // Deposit amount of tokens from sender to this contract
    function depositToken(IERC20 token, address sender, uint amount) internal {
        require(token.allowance(sender, address(this)) >= amount, "TokenProcessing: depositMainToken, not enough funds to deposit token");

        bool result = token.transferFrom(sender, address(this), amount);
        require(result, "TokenProcessing: depositMainToken, transfer from failed");
    }

    // Start take company fee from main token company balance
    function takeFeeStart(uint amount, address targetAddress, bool isAlternative) external onlyOwner {
        if (isAlternative) {
            require(amount <= getCompanyFeeBalance(address(getAlternativeIERC20Token())), "CompanyVault: take fee amount exeeds alter token balance");
        } else {
            require(amount <= getCompanyFeeBalance(address(getMainIERC20Token())), "CompanyVault: take fee amount exeeds token balance");
        }

        uint votingCode = startVoting("TAKE_FEE");
        takeFeeVoting = SecurityDTOs.TakeFee(
            amount,
            targetAddress,
            isAlternative,
            block.timestamp,
            votingCode
        );
    }

    function acquireTakeFee() external onlyOwner {
        pass(takeFeeVoting.votingCode);

        IERC20 token;
        if (takeFeeVoting.isAlternative) {
            token = getAlternativeIERC20Token();
            decreaseFee(takeFeeVoting.amount, address(getAlternativeIERC20Token()));
        } else {
            token = getMainIERC20Token();
            decreaseFee(takeFeeVoting.amount, address(getMainIERC20Token()));
        }

        bool result = token.transfer(takeFeeVoting.targetAddress, takeFeeVoting.amount);
        require(result, "TokenProcessing: take fee transfer failed");
        emit FeeTaken(takeFeeVoting.amount, takeFeeVoting.targetAddress, takeFeeVoting.isAlternative);
    }
}