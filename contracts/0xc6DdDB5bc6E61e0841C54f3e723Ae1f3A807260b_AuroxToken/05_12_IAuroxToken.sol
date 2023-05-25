pragma solidity 0.8.10;

interface IAuroxToken {
    event SetNewContractAllowance(address indexed _newAddress);

    /**
        @dev This function sets the allowance of a given contract to have access to the pool funds
        @param allowanceAddress The address of the contract to set the allowance for
     */
    function setAllowance(address allowanceAddress) external;
}