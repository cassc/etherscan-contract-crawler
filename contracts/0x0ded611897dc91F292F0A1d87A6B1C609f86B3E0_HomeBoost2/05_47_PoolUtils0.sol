// contracts/PoolUtils0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import './../PoolCore/Pool4.sol';
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';


contract PoolUtils0 is Initializable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    uint constant servicerFeePercentage = 1000000;
    uint constant baseInterestPercentage = 0;
    uint constant curveK = 200000000;

    address poolCore;

    /** 
    *   @dev Function initialize replaces constructor in upgradable contracts
    *   - Sets the poolCore contract Address 
    */
    function initialize(address _poolCore) public initializer {
        poolCore = _poolCore;
    }

    /********************************************
    *           Pool Getter Funcs               * 
    ********************************************/



    /**  
    *   @dev Function getAverageInterest() returns an average interest for the pool
    */
    function getAverageInterest() public view returns (uint256) {
        uint256 sumOfRates = 0;
        uint256 borrowedCounter = 0;
        
        uint256 interestRate = 0;
        uint256 principal = 0;
        uint256 loanCount = 0;

        (, , , , , loanCount) = Pool4(poolCore).getContractData();

        for (uint i = 0; i < loanCount; i++) {

            (, , interestRate, principal, , , ) = Pool4(poolCore).getLoanDetails(i);
            if(principal != 0){
                sumOfRates = sumOfRates.add(interestRate.mul(principal));
                borrowedCounter = borrowedCounter.add(principal);
            }
        }

       return sumOfRates.div(borrowedCounter);
    }

    /**  
    *   @dev Function getActiveLoans() returns an array of the loans currently out by users
    *   @return array of bools, where the index i is the loan ID and the value bool is active or not
    */
    function getActiveLoans() public view returns (bool[] memory) {
        uint256 principal = 0;
        uint256 loanCount = 0;

        (, , , , , loanCount) = Pool4(poolCore).getContractData();
        bool[] memory loanActive = new bool[](loanCount);

        for (uint i = 0; i < loanCount; i++) {
            (, , , principal, , , ) = Pool4(poolCore).getLoanDetails(i);

            if(principal != 0) {
                loanActive[i] = true;
            } else {
                loanActive[i] = false;
            }
        }

        return loanActive;
    }


    /**  
    *   @dev Function getPoolInterestAccrued() returns the the amount of interest accreued by the pool in total
    */
    function getPoolInterestAccrued() public view returns (uint256) {
        uint256 totalInterest = 0;
        uint256 loanCount = Pool4(poolCore).getLoanCount();


        for (uint i=0; i<loanCount; i++) {
            uint256 accruedInterest = Pool4(poolCore).getLoanAccruedInterest(i);
            totalInterest = totalInterest.add(accruedInterest);
        }

        return totalInterest;
    }

    /**  
    *   @dev Function getInterestRate calculates the new interest rate if a loan was to be taken out in this block
    *   @param amount The size of the potential loan in (probably usdc).
    *   @return interestRate The interest rate in APR for the loan
    */
    function getInterestRate(uint256 amount) public view returns (int256) {
        //I = (( U - k ) / (U - 100)) - 0.01k + Base + ServicerFee
        //all ints multiplied by 1000000 to represent the 6 decimal points available

        uint256 poolBorrowed = 0;
        uint256 poolLent = 0;
        (, , poolLent, , poolBorrowed, ) = Pool4(poolCore).getContractData();
        
        //first check available allocation
        require(amount < (poolLent - poolBorrowed));

        //get new proposed utilization amount
        int256 newUtilizationRatio = int256(poolBorrowed).add(int256(amount)).mul(100000000).div(int256(poolLent));

        //calculate interest
        //subtract k from U
        int256 numerator = newUtilizationRatio.sub(int256(curveK));  
        //subtract 100 from U
        int256 denominator = newUtilizationRatio.sub(100000000);
        //divide numerator by denominator and multiply percentage by 10^6 to account for decimal places
        int256 interest = numerator.mul(1000000).div(denominator);
        //add base and fees to interest
        interest = interest.sub(int256(curveK).div(100)).add(int256(servicerFeePercentage)).add(int256(baseInterestPercentage)); 
        
        return interest;
    }

    /********************************************
    *           Loan Getter Funcs               * 
    ********************************************/
 
}