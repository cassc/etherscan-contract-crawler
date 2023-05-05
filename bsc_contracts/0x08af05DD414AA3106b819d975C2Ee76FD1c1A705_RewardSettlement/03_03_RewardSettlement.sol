// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface INFT {
    struct TokenAddr {
        address addr;
        uint256 tokenBalance;
    }

    function getAll() external view returns (TokenAddr[] memory);
}

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IRouter {
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external view returns (address);
}

contract RewardSettlement is Ownable {
    address public nftAddr = 0x16dCF4A53C1Ba38db39F15e5b4e13de9D5d92dB8;
    address public filCatAddr = 0xdBb14714405bB54828cACb1293C73a88Cb999999;

    address public usdtAddr = 0x55d398326f99059fF775485246999027B3197955;
    address public routerAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public weth = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 public usdtAmount = 500e18;

    uint256 public feesPercent = 15;

    address public receiveAddr = 0x5C59a0dbdd354d8b558FeF5FB1B7C87B7DCACC0A;

    constructor(address owner) {
        if (owner == address(0)) {
            owner = 0x5C59a0dbdd354d8b558FeF5FB1B7C87B7DCACC0A;
        }
        _transferOwnership(owner);
    }

    function setUSDTAmount(uint256 amount) external onlyOwner {
        usdtAmount = amount;
    }

    function setFeesPercent(uint256 feesP) external onlyOwner {
        feesPercent = feesP;
    }

    function setReceiveAddr(address addr) external onlyOwner {
        receiveAddr = addr;
    }

    function set(
        address nftAdr,
        address filCatAdr,
        address usdtAdr,
        address routerAdr
    ) external onlyOwner {
        if (nftAdr != address(0)) {
            nftAddr = nftAdr;
        }
        if (filCatAdr != address(0)) {
            filCatAddr = filCatAdr;
        }
        if (usdtAdr != address(0)) {
            usdtAddr = usdtAdr;
        }
        if (routerAdr != address(0)) {
            routerAddr = routerAdr;
            weth = IRouter(routerAddr).WETH();
        }
    }

    function pendingSettlement() public view returns (bool) {
        uint256 balanceCat = IERC20(filCatAddr).balanceOf(address(this));
        return filCatoUSDTAmount(balanceCat) >= usdtAmount;
    }

    function settlement() public {
        require(pendingSettlement(), "filCat balance is not enough");

        uint256 balanceCat = IERC20(filCatAddr).balanceOf(address(this));

        uint256 balanceNew = (balanceCat * (100 - feesPercent)) / 100 - 2e18;
        INFT.TokenAddr[] memory addrsUser = INFT(nftAddr).getAll();
        require(addrsUser.length > 0, "nft owner is empty");

        uint256 amountAvg = balanceNew / 200;

        for (uint256 i = 0; i < addrsUser.length; i++) {
            IERC20(filCatAddr).transfer(
                addrsUser[i].addr,
                amountAvg * addrsUser[i].tokenBalance
            );
        }

        uint256 balanceCatAfter = IERC20(filCatAddr).balanceOf(address(this));
        if (
            IERC20(filCatAddr).allowance(address(this), routerAddr) <
            balanceCatAfter
        ) {
            IERC20(filCatAddr).approve(routerAddr, type(uint256).max);
        }

        require(receiveAddr != address(0), "receiveAddr is empty");

        IRouter(routerAddr).swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceCatAfter,
            0,
            filCatUSDTBNBPATH(),
            receiveAddr,
            block.timestamp + 1000000
        );
    }

    function filCatoUSDTAmount(uint256 _amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = filCatAddr;
        path[1] = usdtAddr;
        return IRouter(routerAddr).getAmountsOut(_amount, path)[1];
    }

    function filCatUSDTBNBPATH() public view returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = filCatAddr;
        path[1] = usdtAddr;
        path[2] = weth;
        return path;
    }
}