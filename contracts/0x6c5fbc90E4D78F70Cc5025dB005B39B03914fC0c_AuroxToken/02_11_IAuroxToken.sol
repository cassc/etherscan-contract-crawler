pragma solidity 0.7.4;

interface IAuroxToken {
    /**
        @dev This function sets the allowance of a given contract to have access to the pool funds
        @param allowanceAddress The address of the contract to set the allowance for
     */
    function setAllowance(address allowanceAddress) external;
}