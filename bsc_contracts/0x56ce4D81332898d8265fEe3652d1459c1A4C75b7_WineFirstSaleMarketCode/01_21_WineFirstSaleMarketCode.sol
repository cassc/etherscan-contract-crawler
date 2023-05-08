// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./interfaces/IWineManager.sol";
import "./interfaces/IWinePoolFull.sol";
import "./interfaces/IWineFirstSaleMarket.sol";
import "./vendors/access/ManagerLikeOwner.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract WineFirstSaleMarketCode is
    ManagerLikeOwner,
    Initializable,
    IWineFirstSaleMarket
{
    using SafeERC20 for IERC20;

    address public override firstSaleCurrency;

    // firstSaleCurrency => balance
    mapping (address => uint256) private firstSaleMarketTreasury;

    function initialize(
        address manager_,
        address firstSaleCurrency_ // IERC20 like USDT
    )
        override
        public
        initializer
    {
        _initializeManager(manager_);
        _editFirstSaleCurrency(firstSaleCurrency_);
    }

//////////////////////////////////////// Treasury

    function _editFirstSaleCurrency(
        address firstSaleCurrency_
    )
        override
        public
        onlyManager
    {
        firstSaleCurrency = firstSaleCurrency_;
        emit NewFirstSaleCurrency(firstSaleCurrency);
    }

    function _treasuryGetBalance(address currency)
        override
        public
        view
        onlyManager
        returns (uint256)
    {
        return firstSaleMarketTreasury[currency];
    }

    function _withdrawFromTreasury(address currency, uint256 amount, address to)
        override
        public
        onlyManager
    {
        if (currency == address(0)) {
            currency = firstSaleCurrency;
        }
        require(firstSaleMarketTreasury[currency] >= amount, "firstSaleMarketWithdrawFromTreasury - not enough balance");

        IERC20(currency).safeTransfer(to, amount);
        firstSaleMarketTreasury[currency] -= amount;
    }

//////////////////////////////////////// Token

   function buyToken(uint256[] memory poolIds, address newTokenOwner) override public {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < poolIds.length; i++) {
            IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolIds[i]);
            totalAmount += pool.getWinePrice();
        }

        IERC20 token = IERC20(firstSaleCurrency);
        token.safeTransferFrom(_msgSender(), address(this), totalAmount);
        firstSaleMarketTreasury[firstSaleCurrency] += totalAmount;

        for (uint256 i = 0; i < poolIds.length; i++) {
            IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolIds[i]);
            pool.mint(newTokenOwner);
        }
    }

}