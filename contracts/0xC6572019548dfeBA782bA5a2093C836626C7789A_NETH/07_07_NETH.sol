// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "src/interfaces/INETH.sol";

/**
 * @title NodeDao nETH Contract
 */
contract NETH is INETH, ERC20, Ownable {
    address public liquidStakingContractAddress;

    modifier onlyLiquidStaking() {
        require(liquidStakingContractAddress == msg.sender, "Not allowed to touch funds");
        _;
    }

    constructor() ERC20("Node ETH", "nETH") {}

    /**
     * @notice set LiquidStaking contract address
     * @param _liquidStakingContractAddress liquidStaking address
     */
    function setLiquidStaking(address _liquidStakingContractAddress) public onlyOwner {
        require(_liquidStakingContractAddress != address(0), "LiquidStaking address invalid");
        emit LiquidStakingContractSet(liquidStakingContractAddress, _liquidStakingContractAddress);
        liquidStakingContractAddress = _liquidStakingContractAddress;
    }

    /**
     * @notice mint nETHH
     * @param _amount mint amount
     * @param _account mint account
     */
    function whiteListMint(uint256 _amount, address _account) external onlyLiquidStaking {
        _mint(_account, _amount);
    }

    /**
     * @notice burn nETHH
     * @param _amount burn amount
     * @param _account burn account
     */
    function whiteListBurn(uint256 _amount, address _account) external onlyLiquidStaking {
        _burn(_account, _amount);
    }
}