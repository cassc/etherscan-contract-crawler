// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../interfaces/IPoolInteractor.sol";
import "../interfaces/Venus/IVToken.sol";
import "../interfaces/IWETH.sol";
import "hardhat/console.sol";

contract VenusPoolInteractor is IPoolInteractor {
    using SaferERC20 for IERC20;

    function burn(
        address lpTokenAddress,
        uint256 amount,
        address self
    ) external payable returns (address[] memory, uint256[] memory) {
        IVToken lpTokenContract = IVToken(lpTokenAddress);
        (address[] memory underlying, ) = getUnderlyingTokens(lpTokenAddress);
        lpTokenContract.approve(lpTokenAddress, amount);
        uint256 balanceStart = IERC20(underlying[0]).balanceOf(address(this));
        lpTokenContract.redeem(amount);
        if (address(this).balance > 0) {
            IWETH(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)).deposit{value: address(this).balance}();
        }
        uint256 balanceEnd = IERC20(underlying[0]).balanceOf(address(this));
        uint256[] memory receivedTokenAmounts = new uint256[](1);
        receivedTokenAmounts[0] = balanceEnd - balanceStart;
        return (underlying, receivedTokenAmounts);
    }

    receive() external payable {}

    function mint(
        address toMint,
        address[] memory underlyingTokens,
        uint256[] memory underlyingAmounts,
        address receiver,
        address self
    ) external payable returns (uint256) {
        IVToken lpTokenContract = IVToken(toMint);
        uint256 balanceBefore = lpTokenContract.balanceOf(address(this));
        if (toMint == 0xA07c5b74C9B40447a954e1466938b865b6BBea36) {
            IWETH(payable(underlyingTokens[0])).withdraw(underlyingAmounts[0]);
            lpTokenContract.mint{value: underlyingAmounts[0]}();
        } else {
            for (uint256 i = 0; i < underlyingTokens.length; i++) {
                ERC20 tokenContract = ERC20(underlyingTokens[i]);
                tokenContract.approve(toMint, underlyingAmounts[i]);
            }
            lpTokenContract.mint(underlyingAmounts[0]);
        }
        uint256 minted = lpTokenContract.balanceOf(address(this)) - balanceBefore;
        if (receiver != address(this)) {
            lpTokenContract.transfer(receiver, minted);
        }
        return minted;
    }

    function simulateMint(
        address toMint,
        address[] memory underlyingTokens,
        uint256[] memory underlyingAmounts
    ) external view returns (uint256 minted) {
        IVToken lpToken = IVToken(toMint);
        uint256 exchangeRate = lpToken.exchangeRateStored();
        minted = (underlyingAmounts[0] * uint256(10) ** 18) / exchangeRate;
    }

    function testSupported(address token) external view override returns (bool) {
        try IVToken(token).isVToken() returns (bool isVToken) {
            return isVToken;
        } catch {
            return false;
        }
        // try IVToken(token).borrowRatePerBlock() returns (uint) {} catch {return false;}
        // try IVToken(token).supplyRatePerBlock() returns (uint) {} catch {return false;}
        // return true;
    }

    function getUnderlyingAmount(
        address lpTokenAddress,
        uint256 amount
    ) external view returns (address[] memory underlying, uint256[] memory amounts) {
        IVToken lpToken = IVToken(lpTokenAddress);
        uint256 exchangeRate = lpToken.exchangeRateStored();
        (underlying, ) = getUnderlyingTokens(lpTokenAddress);
        amounts = new uint256[](1);
        amounts[0] = (exchangeRate * amount) / uint256(10) ** 18;
    }

    function getUnderlyingTokens(address lpTokenAddress) public view returns (address[] memory, uint256[] memory) {
        uint256[] memory ratios = new uint256[](1);
        address[] memory receivedTokens = new address[](1);
        ratios[0] = 1;
        if (lpTokenAddress == 0xA07c5b74C9B40447a954e1466938b865b6BBea36) {
            receivedTokens[0] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
            return (receivedTokens, ratios);
        }
        IVToken lpTokenContract = IVToken(lpTokenAddress);
        address underlyingAddress = lpTokenContract.underlying();
        receivedTokens[0] = underlyingAddress;
        return (receivedTokens, ratios);
    }
}