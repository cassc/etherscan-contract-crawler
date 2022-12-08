// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

contract CPC is ERC20, Ownable {
    struct Investment {
        uint256 idInvestment;
        uint256 floatDecimals;
        uint256 interestRate;
        uint256 investmentStartingDate;
        uint256 investmentPaymentDate;
        uint256 investmentAmount;
        uint256 investmentDueAmount;
        bool isPaid;
        string USDCInvestmentTransaction;
        string CPCCollateralTransaction;
    }

    struct Payment {
        uint256 idInvestmentOperation;
        string USDCPaymentTransaction;
        string CPCCollateralTransaction;
    }

    struct Collateral {
        string asset;
        uint256 amount;
    }

    uint256 public investmentCount = 0;
    uint256 public paymentCount = 0;
    uint256 public collateralCount = 0;
    Investment[] public investments;
    Payment[] public payments;
    mapping(uint256 => Collateral) public collaterals;

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
        string collateralAssets,
        uint256 floatDecimals,
        uint256 interestRate,
        uint256 investmentStartingDate,
        uint256 investmentPaymentDate,
        uint256 investmentAmount,
        uint256 investmentDueAmount,
        string USDCInvestmentTransaction,
        string CPCCollateralTransaction
    );

    // Event to register each Payment
    event PaymentEvent(
        uint256 idInvestmentOperation,
        string USDCPaymentTransaction,
        string CPCCollateralTransaction
    );

    constructor(string memory name, string memory ticker, uint256 totalSupply) ERC20(name, ticker) {
        _mint(msg.sender, totalSupply);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function newInvestment(
        uint256 interestRate,
        uint256 investmentStartingDate,
        uint256 investmentPaymentDate,
        uint256 investmentAmount,
        uint256 investmentDueAmount,
        string memory USDCInvestmentTransaction,
        string memory CPCCollateralTransaction
    ) public onlyOwner {
        investments.push(
            Investment(
                investmentCount,
                FLOAT_DECIMALS,
                interestRate,
                investmentStartingDate,
                investmentPaymentDate,
                investmentAmount,
                investmentDueAmount,
                false,
                USDCInvestmentTransaction,
                CPCCollateralTransaction
            )
        );

        emit InvestmentEvent(
            investmentCount,
            INVESTOR,
            COLLATERAL_ASSETS,
            FLOAT_DECIMALS,
            interestRate,
            investmentStartingDate,
            investmentPaymentDate,
            investmentAmount,
            investmentDueAmount,
            USDCInvestmentTransaction,
            CPCCollateralTransaction
        );

        investmentCount += 1;
    }

    function newPayment(
        uint256 idInvestmentOperation,
        string memory USDCPaymentTransaction,
        string memory CPCCollateralTransaction
    ) public onlyOwner {
        require(
            investments[idInvestmentOperation].isPaid == false,
            "Investment already paid"
        );
        investments[idInvestmentOperation].isPaid = true;
        payments.push(
            Payment(
                idInvestmentOperation,
                USDCPaymentTransaction,
                CPCCollateralTransaction
            )
        );

        emit PaymentEvent(
            idInvestmentOperation,
            USDCPaymentTransaction,
            CPCCollateralTransaction
        );

        paymentCount += 1;
    }

    function addCollateral(string memory _asset, uint256 _amount)
        public
        onlyOwner
    {
        require(_amount > 0, "Amount should be > 0");
        collaterals[collateralCount].asset = _asset;
        collaterals[collateralCount].amount = _amount;
        collateralCount += 1;
    }

    function updateCollateral(uint256 _id, uint256 _amount) public onlyOwner {
        require(_amount >= 0, "Amount should be >= 0");
        require(_id < collateralCount, "Collateral asset doesn't exist");
        collaterals[_id].amount = _amount;
    }

    function getCollateralList() public view returns (Collateral[] memory) {
        Collateral[] memory collateral_ = new Collateral[](collateralCount);
        for (uint256 i = 0; i < collateralCount; i++) {
            collateral_[i] = collaterals[i];
        }
        return collateral_;
    }

    function getActiveInvestmentsCount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            if (!investments[i].isPaid) {
                total++;
            }
        }
        return total;
    }

    function getTotalInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            total += investments[i].investmentAmount;
        }
        return total;
    }

    function getTotalActiveInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            if (!investments[i].isPaid) {
                total += investments[i].investmentAmount;
            }
        }
        return total;
    }

    function getTotalDueInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            if (!investments[i].isPaid) {
                total += investments[i].investmentDueAmount;
            }
        }
        return total;
    }

    function getTotalPaidAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            if (investments[i].isPaid) {
                total += investments[i].investmentDueAmount;
            }
        }
        return total;
    }
}