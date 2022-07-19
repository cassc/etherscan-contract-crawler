// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract WithdrawalSplittable is Ownable, ReentrancyGuard {
     
    struct Beneficiary {
        address wallet;
        uint256 basisPoints;     // decimal: 2, e.g. 1000 = 10.00%
    }

    Beneficiary[] public beneficiaries;

    error WithdrawalFailedBeneficiary(uint256 index, address beneficiary);
    error ZeroBeneficiaryAddress();
    error ArrayLengthMismatch();
    error ZeroArrayLength();
    error ZeroBalance();
    error ZeroWithdrawalAddress();
    error ZeroWithdrawalBasisPoints();

    receive() external payable {}
    
     modifier checkWithdrawalBasisPoints(address[] memory _wallets, uint256[] memory _basisPoints) {
        if (_wallets.length != _basisPoints.length)
            revert ArrayLengthMismatch();
        if (_wallets.length == 0)
            revert ZeroArrayLength();
        for (uint256 i; i < _wallets.length; i++) {
            if(_wallets[i] == address(0)) revert ZeroWithdrawalAddress();
            if(_basisPoints[i] == 0) revert ZeroWithdrawalBasisPoints();
        }
        _;
    }

    function setBeneficiaries(address[] memory _wallets, uint256[] memory _basisPoints) 
        public 
        onlyOwner 
        checkWithdrawalBasisPoints(_wallets, _basisPoints)
    {        
        delete beneficiaries;

        for (uint256 i; i < _wallets.length; i++) {
            if (_wallets[i] == address(0))
                revert ZeroBeneficiaryAddress();
            beneficiaries.push(Beneficiary(_wallets[i], _basisPoints[i]));
        }
    }

    function calculateSplit(uint256 balance)
        public view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](beneficiaries.length);

        for (uint256 i; i < beneficiaries.length; i++) {
            uint256 amount = (balance * beneficiaries[i].basisPoints) / 10000;
            amounts[i] = amount;
        }
        return amounts;
    }

    function withdrawErc20(IERC20 token) public nonReentrant {
        uint256 totalBalance = token.balanceOf(address(this));
        if (totalBalance == 0) 
            revert ZeroBalance();

        uint256[] memory amounts = calculateSplit(totalBalance);

        for (uint256 i; i < beneficiaries.length; i++) {
            if (!token.transfer(beneficiaries[i].wallet, amounts[i]))
                revert WithdrawalFailedBeneficiary(i, beneficiaries[i].wallet);
        }
    }

    function withdrawEth() public nonReentrant {
        uint256 totalBalance = address(this).balance;
        if (totalBalance == 0) 
            revert ZeroBalance();

        uint256[] memory amounts = calculateSplit(totalBalance);

        for (uint256 i; i < beneficiaries.length; i++) {
            if (!payable(beneficiaries[i].wallet).send(amounts[i]))
                revert WithdrawalFailedBeneficiary(i, beneficiaries[i].wallet);
        }
    }
}