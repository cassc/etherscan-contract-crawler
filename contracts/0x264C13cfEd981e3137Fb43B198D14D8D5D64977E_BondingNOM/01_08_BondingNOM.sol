// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

interface ERC20Token {
  function allowance(address, address) external returns (uint256);
  function balanceOf(address) external returns (uint256);
  function totalSupply() external view returns (uint256);
  function transferFrom(address, address, uint256) external returns (bool);
  function transfer(address, uint256) external returns (bool);
}

/// @title bNOM Bonding Contract
contract BondingNOM is Ownable {
    ERC20Token nc;
    using SafeMath for uint256;
    /// @notice Address of the nc (NOM ERC20 Contract)
    address public NOMTokenContract;
    uint256 public supplyNOM = 0;
    uint256 public priceBondCurve = 0;
    uint8 public decimals = 18;
    uint256 public a = SafeMath.mul(100000000, 10**decimals);
    bool public tradingEnabled = false;

    event Transaction(address indexed _by, uint256 amountNOM, uint256 amountETH, uint256 price, uint256 supply, string buyOrSell, int256 slippage);

    constructor (address NOMContAddr) {
        // Add in the NOM ERC20 contract address
        NOMTokenContract = NOMContAddr;
        nc = ERC20Token(NOMContAddr);
    }

    /// @return Return the bool value which indicates whether the trading is enabled.
    function getTradingEnabled() public view returns (bool) {
        return tradingEnabled;
    }

    /// @notice Return the NOM Token Contract address
    function getNOMAddr() public view returns (address) {
        return NOMTokenContract;
    }

    /// @return Return the NOM Token circulate supply
    function getSupplyNOM() public view returns (uint256) {
        return supplyNOM;
    }

    /// @return Return the price based on current NOM supply
    function getBondPrice() public view returns (uint256) {
        return priceBondCurve;
    }

    /// @param token uint256 token amount
    /// @return Return token amount to F64(Fixed Point 64) format
    /// @notice This function will use `ABDKMath64x64.divu` module from `abdk-libraries-solidity` library
    function tokToF64(uint256 token) public view returns(int128) {
        return ABDKMath64x64.divu(token, 10**uint256(decimals));
    }

    /// @return Return F64(Fixed Point 64) token amount to uint256
    /// @notice This function will use `ABDKMath64x64.mulu` module from `abdk-libraries-solidity` library
    function f64ToTok(int128 fixed64) public view returns(uint256) {
        return ABDKMath64x64.mulu(fixed64, 10**uint256(decimals));
    }

    /// @return Return the amount of burned bNOM
    /// @notice Formula: totalSupply[initial] - totalSupply[now]
    function burnedNOM() public view returns(uint256) {
        return  a.sub(nc.totalSupply());
    }

    /// @return Return the token price base on the input supply amount
    /// @param _supplyNOM token supply amount in uint256
    /// @notice Formula: `ETH/NOM = pow(_supplyNOM/a, 2)`  Using this function, everyone can predict the exact price base on token supply
    function priceAtSupply(uint256 _supplyNOM) public view returns(uint256) {
        if (_supplyNOM == 0) return 0;

        require(_supplyNOM <= a, "Bonding Curve terminates below bNOM amount input");
        
        return  f64ToTok(
            ABDKMath64x64.pow(
                ABDKMath64x64.div(
                    tokToF64(_supplyNOM),
                    tokToF64(a)
                ),
                uint256(2)
            )
        );
    }

    /// @return Return token supply amount for input price
    /// @param price F64(Fixed Point 64) formated amount
    /// @notice Formula: `_suppliedNom = sqrt(ETH/NOM) * a`  Using this function, everyone can predict the exact token supply base on token price
    function supplyAtPrice(uint256 price) public view returns (uint256) {
        if (price == 0) return 0;

        require(price <= 10**18, "Bonding Curve terminates below ETH/bNOM price input");
        
        return f64ToTok(
            ABDKMath64x64.mul(
                ABDKMath64x64.sqrt(
                    tokToF64(price)
                ),
                tokToF64(a)
            )
        );
    }


    /// @return Return NOM supply range to ETH
    /// @param supplyTop NOM supply top amount
    /// @param supplyBot NOM supply bottom amount
    /// @notice Formula: `ETH = a/3((supplyNOM_Top/a)^3 - (supplyNOM_Bot/a)^3)`
    /// Integrate over a curve to get the amount of ETH needed to buy the amount of NOM
    function NOMSupToETH(uint256 supplyTop, uint256 supplyBot) public view returns(uint256) {
        if (supplyTop - supplyBot == 0) return 0;

        require(supplyTop > supplyBot, "Supply Bot greater than Supply Top");
        require(supplyTop <= a, "Supply Top greater than initial supply of bNOM");
        require(supplyTop.sub(supplyBot) <= a.sub(supplyNOM), "Request greater than the bonded supply of bNOM");

        return f64ToTok(
            ABDKMath64x64.mul(
                // a/3
                ABDKMath64x64.div(
                    tokToF64(a),
                    ABDKMath64x64.fromUInt(uint256(3))
                ),
                // ((NomSold_Top/a)^3 - (supplyNOM_Bot/a)^3)
                ABDKMath64x64.sub(
                    // (NomSold_Top/a)^3
                    ABDKMath64x64.pow(
                        ABDKMath64x64.div(
                            tokToF64(supplyTop),
                            tokToF64(a)
                        ),
                        uint256(3)
                    ),
                    // (NomSold_Bot/a)^3
                    ABDKMath64x64.pow(
                        ABDKMath64x64.div(
                            tokToF64(supplyBot),
                            tokToF64(a)
                        ),
                        uint256(3)
                    )
                )
            )
        );
    }


    /// @return Return quote for a particular amount of NOM (Dec 18) in ETH (Dec 18)
    /// @param amountNOM amount of NOM to be purchased in 18 decimal
    /// @notice 1. Determine supply range based on spread and current curve price based on supplyNOM
    /// 2. Integrate over curve to get amount of ETH needed to buy amount of NOM
    /// ETH = a/3((supplyNOM_Top/a)^3 - (supplyNOM_Bot/a)^3)
    /// Parameters:
    /// Input
    /// uint256 buyAmount: amount of NOM to be purchased in 18 decimal
    /// Output
    /// uint256: amount of ETH needed in Wei or ETH 18 decimal
    function buyQuoteNOM(uint256 amountNOM) public view returns(uint256) {
        if (amountNOM == 0) return 0;
        
        require(amountNOM <= a.sub(supplyNOM), "Sell amount of bNOM greater than unbonded amount of bNOM");

        uint256 supplyTop = supplyNOM.add(amountNOM);
        uint256 amountETH = NOMSupToETH(supplyTop, supplyNOM);
        return amountETH.sub(amountETH.div(100));
    }

    /// @return Return cubrtu(x) rounding down, where x is unsigned 256-bit integer
    /// @param x unsigned 256-bit integer number
    function cubrtu (uint256 x) public pure returns (uint256) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x1000000000000000000000000000000000000) {xx >>= 144; r <<= 48;}
            if (xx >= 0x1000000000000000000) {xx >>= 72; r <<= 24;}
            if (xx >= 0x1000000000) {xx >>= 36; r <<= 12;}
            if (xx >= 0x40000) {xx >>= 18; r <<= 6;}
            if (xx >= 0x1000) {xx >>= 12; r <<= 4;}
            if (xx >= 0x200) {xx >>= 9; r <<= 3;}
            if (xx >= 0x40) {xx >>= 6; r <<= 2;}
            if (xx >= 0x8) {r <<= 1;}
            r = (x/(r**2) + 2*r)/3;
            r = (x/(r**2) + 2*r)/3;
            r = (x/(r**2) + 2*r)/3;
            r = (x/(r**2) + 2*r)/3;
            r = (x/(r**2) + 2*r)/3;
            r = (x/(r**2) + 2*r)/3;
            r = (x/(r**2) + 2*r)/3; // Seven iterations should be enough
            return r;
        }
    }

    /// @param amountETH amoutt of ETH
    /// @return Buy Quote for the purchase of NOM based on amount of ETH (Dec 18)
    /// @notice 1. Determine supply bottom
    /// 2. Integrate over curve, and solve for supply top supplyNOM_Top = a*(3*ETH/a + (supplyNOM_Bot/a)^3)^(1/3)
    /// 3. Subtract supply bottom from top to get #NOM for ETH
    function buyQuoteETH(uint256 amountETH) public view returns(uint256) {
        if (amountETH == 0) return 0;

        uint256 amountNet = amountETH.sub(amountETH.div(100));
        uint256 supplyTop = // supplyNOM_Top = (a^2*(3*ETH + (supplyNOM_Bot/a)^2*supplyNOM_Bot))^(1/3)
            cubrtu(
                SafeMath.mul(
                    // a^2
                    a.mul(a),
                    // (3*ETH + (supplyNOM_Bot/a)^2*supplyNOM_Bot)
                    f64ToTok(
                        ABDKMath64x64.add(
                            ABDKMath64x64.mul(
                                ABDKMath64x64.fromUInt(uint256(3)),
                                tokToF64(amountNet)
                            ),
                            ABDKMath64x64.mul(
                                ABDKMath64x64.pow(
                                    ABDKMath64x64.div(
                                        tokToF64(supplyNOM),
                                        tokToF64(a)
                                    ),
                                    uint256(2)
                                ),
                                tokToF64(supplyNOM)
                            )
                        )
                    )
                )

            );
        
        require(supplyTop <= a, "Supply Top greater than initial supply");

        return supplyTop - supplyNOM;
    }

    function abs(int128 x) private pure returns (int128) {
        return x >= 0 ? x : -x;
    }

    /// @param estAmountNOM amount of NOM
    /// @param allowSlip amount of slippage allowed in 0100 means 1%
    function buyNOM(uint256 estAmountNOM, uint256 allowSlip) public payable {
        require(tradingEnabled, "The trading is disabled");
        require(msg.value > 0, "Amount ETH sent with request equal to zero");
        require(estAmountNOM <= (a.sub(supplyNOM)), "Estimated amount of bNOM greater bonded supply of bNOM");

        uint256 amountNOM = buyQuoteETH(msg.value);

        // Positive slippage is bad.  Negative slippage is good.
        // Positive slippage means we will receive less NOM than estimated
        if(estAmountNOM > amountNOM) {
            require(
                // Slippage
                estAmountNOM.sub(amountNOM)
                <
                // Allowed slippage
                estAmountNOM.div(10000).mul(allowSlip)
                ,
                "Slippage greater than allowed"
            );
        }

        int256 slippage = int256(estAmountNOM) - int256(amountNOM);

        // Update total supply released by Bonding Curve
        supplyNOM = supplyNOM.add(amountNOM);
        // Update current bond curve price
        priceBondCurve = priceAtSupply(supplyNOM);

        nc.transfer(msg.sender, amountNOM);

        emit Transaction(msg.sender, amountNOM, msg.value, priceBondCurve, supplyNOM, "buy", slippage);
    }

    /// @param amountNOM amount of NOM
    /// @return Return Sell Quote: NOM for ETH (Dec 18)
    /// @notice 1. Determine supply top: priceBondCurve - 1% = Top Sale Price
    /// 2. Integrate over curve to find ETH: `ETH = a/3((supplyNOM_Top/a)^3 - (supplyNOM_Bot/a)^3)`
    /// 3. Subtract supply bottom from top to get #NOM for ETH
    function sellQuoteNOM(uint256 amountNOM) public view returns(uint256) {
        if (amountNOM == 0) return 0;
        
        require(amountNOM <= (supplyNOM - burnedNOM()), "Sell amount of bNOM greater than unbonded amount of bNOM");
        
        uint256 supplyBot = supplyNOM.sub(amountNOM);
        uint256 amountETH = NOMSupToETH(supplyNOM, supplyBot);
        return amountETH.sub(amountETH.div(100));
    }

    /// @param amountNOM amount of NOM
    /// @param estAmountETH estimation of ETH amount
    /// @param allowSlip is a percentage represented as an percentage * 10^2 with a 2 decimal fixed point
    /// 1% would be uint256 representation of 0100, 1.25% would be 0125, 25.5% would be 2550
    /// @notice Transfer ETH worth amount of NOM to msg.sender
    function sellNOM(uint256 amountNOM, uint256 estAmountETH, uint256 allowSlip) public payable {
        require(amountNOM > 0, "Sell amount of bNOM equal to zero");
        require(amountNOM <= (supplyNOM - burnedNOM()), "Sell amount of bNOM greater than unbonded amount of bNOM");
        require(amountNOM <= nc.allowance(msg.sender, address(this)), "Insufficient Bond Contract bNOM allowance");

        uint256 amountETH = sellQuoteNOM(amountNOM);

        // Positive slippage is bad.  Negative slippage is good.
        // Positive slippage means we will receive less NOM than estimated
        if(estAmountETH > amountETH) {
            require(
                // Slippage
                estAmountETH.sub(amountETH) <
                estAmountETH.div(10000).mul(allowSlip),
                "Slippage greater than allowed"
            );
        }

        int256 slippage = int256(estAmountETH) - int256(amountETH);

        // Transfer NOM to contract
        nc.transferFrom(msg.sender, address(this), amountNOM);
        // Update persistent contract state variables
        // Update total supply released by Bonding Curve
        supplyNOM = supplyNOM.sub(amountNOM);
        // Update current bond curve price
        priceBondCurve = priceAtSupply(supplyNOM);
        emit Transaction(msg.sender, amountNOM, amountETH, priceBondCurve, supplyNOM, "sell", slippage);

        // Transfer ETH to Sender
        payable(msg.sender).transfer(amountETH);
    }

    /// @return Teambalance in ETH
    /// @notice 1. Calculate amount ETH to cover all current NOM outstanding based on bonding curve integration.
    /// 2. Subtraction lockedETH from Contract Balance to get amount available for withdrawal.
    function teamBalance() public view returns(uint256) {
        if (supplyNOM == 0) {
            return address(this).balance;
        }

        uint256 lockedETH = NOMSupToETH(supplyNOM, burnedNOM());
        return address(this).balance.sub(lockedETH);
    }

    /// @notice 1. Calculate amount ETH to cover all current NOM outstanding based on bonding curve integration.
    /// 2. Subtraction lockedETH from Contract Balance to get amount available for withdrawal.
    function withdraw() public onlyOwner returns(bool success) {
        if (supplyNOM == 0) {
            payable(msg.sender).transfer(address(this).balance);
            return true;
        }
        
        uint256 lockedETH = NOMSupToETH(supplyNOM, burnedNOM());
        uint256 paymentETH = address(this).balance.sub(lockedETH);
        // Transfer ETH to Owner
        payable(msg.sender).transfer(paymentETH);
        return true;
    }

    /// @notice Enables trading.
    function enableTrading() public onlyOwner {
        tradingEnabled = true;
    }

}