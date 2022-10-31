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

    uint256 public treasuryFees;

    IMolecule public moleculeContract;
    address public moleculeAddress;

    function initialize() external initializer {
        __Ownable_init();

        treasuryFees = 3;
        sellBurnFee = 2;
        sellTotalFees = sellBurnFee + treasuryFees;

        buyBurnFee = 2;
        buyTotalFees = buyBurnFee + treasuryFees;
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

    function updateTreasuryFees(uint256 _treasuryFees) external onlyOwner{
        require(_treasuryFees > 0 && _treasuryFees <= 6, "Must keep fees between 0 and 6");
        treasuryFees = _treasuryFees;

    }
    function updateSellFees(uint256 _burnFee)
        external
        onlyOwner
    {
        sellBurnFee = _burnFee;
        sellTotalFees = sellBurnFee + treasuryFees;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateBuyFees(uint256 _burnFee)
        external
        onlyOwner
    {
        buyBurnFee = _burnFee;
        buyTotalFees = buyBurnFee + treasuryFees;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function updateMoleculeAddress(address _newAddr) external onlyOwner {
        require(_newAddr != address(0xdead), "Can't be dead address");
        moleculeContract = IMolecule(_newAddr);
        moleculeAddress = _newAddr;
    }
}