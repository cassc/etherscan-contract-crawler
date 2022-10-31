// SPDX-License-Identifier: UNLICENSED

/*
🔥 TG: https://t.me/mol_community

Ⓜ️ https://medium.com/@moleculeweb3
*/

pragma solidity ^0.8.11;

import "./interfaces/IMolecule.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TreasuryManager is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 public sellBurnFee;
    uint256 public sellTreasuryFee;
    uint256 public sellTotalFees;

    uint256 public buyBurnFee;
    uint256 public buyTreasuryFee;
    uint256 public buyTotalFees;

    IMolecule public moleculeContract;
    address public moleculeAddress;

    function initialize() external initializer {
        __Ownable_init();

        sellBurnFee = 2;
        sellTreasuryFee = 3;
        sellTotalFees = sellBurnFee + sellTreasuryFee;

        buyBurnFee = 2;
        buyTreasuryFee = 3;
        buyTotalFees = buyBurnFee + buyTreasuryFee;
    }

    // Main burn and fees algorithm, might change for optimisation
    function estimateFees(
        bool _isSelling,
        bool _isBuying,
        uint256 _amount
    ) external view returns (uint256, uint256) {
        require(_msgSender() == moleculeAddress, "Not Molecule contract");

        uint256 fees = 0;
        uint256 tokensForBurn = 0;

        // On sell
        if (_isSelling && sellTotalFees > 0) {
            fees = _amount.mul(sellTotalFees).div(100);
            tokensForBurn += (fees * sellBurnFee) / sellTotalFees;
        }
        // On buy
        else if (_isBuying && buyTotalFees > 0) {
            fees = _amount.mul(buyTotalFees).div(100);
            tokensForBurn += (fees * buyBurnFee) / buyTotalFees;
        }

        return (fees, tokensForBurn);
    }

    function updateSellFees(uint256 _burnFee, uint256 _devFee)
        external
        onlyOwner
    {
        sellBurnFee = _burnFee;
        sellTreasuryFee = _devFee;
        sellTotalFees = sellBurnFee + sellTreasuryFee;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateBuyFees(uint256 _burnFee, uint256 _devFee)
        external
        onlyOwner
    {
        buyBurnFee = _burnFee;
        buyTreasuryFee = _devFee;
        buyTotalFees = buyBurnFee + buyTreasuryFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function updateMoleculeAddress(address _newAddr) external onlyOwner {
        moleculeContract = IMolecule(_newAddr);
        moleculeAddress = _newAddr;
    }
}