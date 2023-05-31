// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface ERC20Mock {
    function symbol() external view returns (string memory);
}

contract CPC is ERC20, Ownable {
    struct Investment {
        uint256 floatDecimals;
        uint256 interestRate;
        uint256 investmentStartingDate;
        uint256 investmentPaymentDate;
        uint256 investmentAmount;
        uint256 investmentDueAmount;
        address investorAddress;
        bool isPaid;
        string USDCInvestmentTransaction;
    }

    struct Payment {
        uint256 idInvestmentOperation;
        string USDCPaymentTransaction;
    }

    struct Collateral {
        address contractAddress;
        string ticker;
        uint256 collateralAmount;
        uint256 CPCAmount;
        string dollarQuotation;
    }

    Investment[] public investments;
    Payment[] public payments;
    Collateral[] public collaterals;

    uint256 public constant FLOAT_DECIMALS = 18;

    // Token Issuer
    string public constant INVESTOR = "Criptoloja - https://criptoloja.com";
    // Collateral Assets
    string public constant COLLATERAL_ASSETS =
        "MB Tokens - https://www.mercadobitcoin.com.br";

    // Event to register each Investment
    event InvestmentEvent(
        uint256 idInvestment,
        string investor,
        address investorAddress,
        string collateralAssets,
        uint256 floatDecimals,
        uint256 interestRate,
        uint256 investmentStartingDate,
        uint256 investmentPaymentDate,
        uint256 investmentAmount,
        uint256 investmentDueAmount,
        string USDCInvestmentTransaction
    );

    // Event to register each Payment
    event PaymentEvent(uint256 idInvestment, string USDCPaymentTransaction);

    constructor(string memory name, string memory ticker) ERC20(name, ticker) {}

    function approveAndTransfer(address from, uint256 amount)
        internal
        onlyOwner
        returns (bool)
    {
        _approve(from, owner(), amount);
        transferFrom(from, owner(), amount);
        return true;
    }

    function newInvestment(
        uint256 interestRate,
        uint256 investmentStartingDate,
        uint256 investmentPaymentDate,
        uint256 investmentAmount,
        uint256 investmentDueAmount,
        address investorAddress,
        string memory USDCInvestmentTransaction
    ) public onlyOwner {
        transfer(investorAddress, investmentAmount);
        investments.push(
            Investment(
                FLOAT_DECIMALS,
                interestRate,
                investmentStartingDate,
                investmentPaymentDate,
                investmentAmount,
                investmentDueAmount,
                investorAddress,
                false,
                USDCInvestmentTransaction
            )
        );

        emit InvestmentEvent(
            investments.length - 1,
            INVESTOR,
            investorAddress,
            COLLATERAL_ASSETS,
            FLOAT_DECIMALS,
            interestRate,
            investmentStartingDate,
            investmentPaymentDate,
            investmentAmount,
            investmentDueAmount,
            USDCInvestmentTransaction
        );
    }

    function newPayment(
        uint256 idInvestment,
        string memory USDCPaymentTransaction
    ) public onlyOwner {
        require(
            investments[idInvestment].isPaid == false,
            "Investment already paid"
        );
        approveAndTransfer(
            investments[idInvestment].investorAddress,
            investments[idInvestment].investmentAmount
        );
        investments[idInvestment].isPaid = true;
        payments.push(Payment(idInvestment, USDCPaymentTransaction));

        emit PaymentEvent(idInvestment, USDCPaymentTransaction);
    }

    function addCollateral(
        address contractAddress,
        uint256 collateralAmount,
        uint256 CPCAmount,
        string memory dollarQuotation
    ) public onlyOwner {
        require(CPCAmount > 0, "CPC Amount should be > 0");
        require(collateralAmount > 0, "Asset Amount should be > 0");
        _mint(msg.sender, CPCAmount);
        ERC20Mock mdbaMock = ERC20Mock(contractAddress);
        string memory _ticker = mdbaMock.symbol();

        collaterals.push(
            Collateral(
                contractAddress,
                _ticker,
                collateralAmount,
                CPCAmount,
                dollarQuotation
            )
        );
    }

    function endCollateral(uint256 _id) public onlyOwner {
        require(_id < collaterals.length, "Collateral asset doesn't exist");

        _burn(owner(), collaterals[_id].CPCAmount);
    }

    function getCollateralList() public view returns (Collateral[] memory) {
        Collateral[] memory collateral_ = new Collateral[](collaterals.length);
        for (uint256 i = 0; i < collaterals.length; i++) {
            collateral_[i] = collaterals[i];
        }
        return collateral_;
    }

    function getActiveInvestmentsCount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investments.length; i++) {
            if (!investments[i].isPaid) {
                total++;
            }
        }
        return total;
    }

    function getTotalInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investments.length; i++) {
            total += investments[i].investmentAmount;
        }
        return total;
    }

    function getTotalActiveInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investments.length; i++) {
            if (!investments[i].isPaid) {
                total += investments[i].investmentAmount;
            }
        }
        return total;
    }

    function getTotalDueInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investments.length; i++) {
            if (!investments[i].isPaid) {
                total += investments[i].investmentDueAmount;
            }
        }
        return total;
    }

    function getTotalPaidAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investments.length; i++) {
            if (investments[i].isPaid) {
                total += investments[i].investmentDueAmount;
            }
        }
        return total;
    }
}