pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TokenVesting.sol";
import "./IAuroxToken.sol";

// Ignoring the 19 states declaration for simpler deployment for the Aurox guys
contract AuroxToken is IAuroxToken, ERC20, Ownable {
    TokenVesting public reservesVestingContract;
    TokenVesting public teamRewardVestingContract;

    constructor(address teamRewardAddress, address reservesAddress)
        public
        ERC20("Aurox Token", "URUS")
    {
        // Mint the supply to the deployer address
        _mint(_msgSender(), 1000000 ether);

        // Create the vesting contracts
        createVestingContracts(reservesAddress, teamRewardAddress);
    }

    // Expose a new function to update the allowance of a new contract
    function setAllowance(address allowanceAddress)
        external
        override
        onlyOwner
    {
        _approve(address(this), allowanceAddress, 650000 ether);

        emit SetNewContractAllowance(allowanceAddress);
    }

    function createVestingContracts(
        address reservesAddress,
        address teamRewardAddress
    ) private {
        // Start vesting now
        // Distribute linearly over 1 year
        reservesVestingContract = new TokenVesting(
            reservesAddress,
            // Original reserves start time
            1630315384,
            0,
            365 days,
            false
        );
        // Distribute rewards over 1 yr
        teamRewardVestingContract = new TokenVesting(
            teamRewardAddress,
            // Original Team vesting start time
            1646040184,
            0,
            730 days,
            false
        );
    }
}