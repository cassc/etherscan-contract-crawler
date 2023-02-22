//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

interface IDaylight {
    function burn(uint256 amount) external returns (bool);
    function getOwner() external view returns (address);
}

interface IApollo {
    function sell(uint256 tokenAmount) external returns (uint256);
}

contract FeeReceiver {

    // daylight token and redeem contract
    address public constant daylight = 0x62529D7dE8293217C8F74d60c8C0F6481DE47f0E;
    address public daylightRedeem = 0xDf61a33C1aC650978641E4BB0e45204a89bDeC3b;

    // BUSD
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant Apollo = 0x32a05625d2A25054479d0c5d661857147c34483D;
    address public constant router = 0xb34DA672837aFe372eceF419b25a357A36f59F6f;
    address public constant treasury = 0x4A3Be597418a12411F31C94cc7bCAD136Af2E242;

    // wallet to distribute rewards for staking and farming
    address public rewardWallet = 0xfA5F9b81Ee35F679d2Cf0C569EfAcf8Cba7b00aC;

    // use daylight owner
    modifier onlyOwner() {
        require(
            msg.sender == IDaylight(daylight).getOwner(),
            'Only Daylight Owner'
        );
        _;
    }

    function withdrawETH() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function withdrawToken(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function burnAll() external onlyOwner {
        IDaylight(daylight).burn( IERC20(daylight).balanceOf(address(this)) );
    }

    function setRewardWallet(address newWallet) external onlyOwner {
        rewardWallet = newWallet;
    }

    function setDaylightRedeem(address newRedeem) external onlyOwner {
        daylightRedeem = newRedeem;
    }

    function trigger() external {

        // daylight balance
        uint256 balance = IERC20(daylight).balanceOf(address(this));
        if (balance <= 1000) {
            return;
        }

        // send 20% to the reward distributor
        IERC20(daylight).transfer(rewardWallet, ( balance * 2 ) / 10);

        // sell DAYL for Apollo
        address[] memory path = new address[](2);
        path[0] = daylight;
        path[1] = Apollo;
        IERC20(daylight).approve(router, (balance * 6 ) / 10);
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            (balance * 6 ) / 10,
            1,
            path,
            address(this),
            block.timestamp + 1000
        );

        // sell Apollo
        IApollo(Apollo).sell(IERC20(Apollo).balanceOf(address(this)));

        // give half BUSD to the Treasury
        IERC20(BUSD).transfer(treasury, IERC20(BUSD).balanceOf(address(this)) / 2);
        
        // give rest of BUSD to daylight redeem
        IERC20(BUSD).transfer(daylightRedeem, IERC20(BUSD).balanceOf(address(this)));

        // burn remainder of balance
        IDaylight(daylight).burn( IERC20(daylight).balanceOf(address(this)) );

        // clear storage
        delete path;
    }

    receive() external payable {}
}