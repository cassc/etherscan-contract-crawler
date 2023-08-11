// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FundsManager is Initializable, OwnableUpgradeable {
    address payable public feeRecipient;
    address payable public beneficiary;
    uint256 public feePercentage;

    event BeneficiaryChanged(
        address indexed previousBeneficiary,
        address indexed newBeneficiary
    );
    event FeeRecipientChanged(
        address indexed previousFeeRecipient,
        address indexed newFeeRecipient
    );
    event FeePercentageChanged(
        uint256 indexed previousFeePercentage,
        uint256 indexed newFeePercentage
    );
    event Withdrawal(
        address indexed feeRecipient,
        address indexed beneficiary,
        uint256 fee,
        uint256 beneficiaryAmount
    );

    function initialize(
        address payable _feeRecipient,
        address payable _beneficiary,
        uint256 _feePercentage
    ) public initializer {
        __Ownable_init();
        require(
            _feePercentage <= 100,
            "Fee percentage should be between 0 and 100"
        );
        feeRecipient = _feeRecipient;
        beneficiary = _beneficiary;
        feePercentage = _feePercentage;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        emit BeneficiaryChanged(beneficiary, _beneficiary);
        beneficiary = _beneficiary;
    }

    function setFeeRecipient(address payable _feeRecipient) public onlyOwner {
        emit FeeRecipientChanged(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        require(
            _feePercentage <= 100,
            "Fee percentage should be between 0 and 100"
        );
        emit FeePercentageChanged(feePercentage, _feePercentage);
        feePercentage = _feePercentage;
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 fee = (balance * feePercentage) / 100;
        uint256 beneficiaryAmount = balance - fee;
        feeRecipient.transfer(fee);
        beneficiary.transfer(beneficiaryAmount);
        emit Withdrawal(feeRecipient, beneficiary, fee, beneficiaryAmount);
    }
}