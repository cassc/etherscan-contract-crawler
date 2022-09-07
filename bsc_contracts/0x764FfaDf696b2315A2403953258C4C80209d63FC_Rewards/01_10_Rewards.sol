// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6 || ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Rewards is Initializable, OwnableUpgradeable {
    IUniswapV2Router02 public router;

    address private controllerAddress;

    address public paymentAddress;
    address public zunaAddress;
    address public wbnbAddress;

    uint256[] staticRewards;

    // 5 decimals

    uint256[] buybackRewards;

    event StaticRewardsReleased(address[][] holders);

    function initialize() public initializer {
        __Ownable_init();
        staticRewards = [
            165 * 10**9 * 10**9,
            80 * 10**9 * 10**9,
            7 * 10**9 * 10**9,
            35 * 10**8 * 10**9,
            18 * 10**8 * 10**9,
            10**9 * 10**9
        ];
        buybackRewards = [200000, 80000, 4925, 2000, 1000, 400];
    }

    function setSwapRouter(address _router) external onlyOwner {
        router = IUniswapV2Router02(_router);
    }

    function config(address _controllerAddress, address _paymentAddress)
        external
        onlyOwner
    {
        require(_controllerAddress != address(0) && _paymentAddress != address(0), "Invalid address");
        controllerAddress = _controllerAddress;
        paymentAddress = _paymentAddress;
    }

    function setERC20Address(address _zunaAddress, address _wbnbAddress)
        external
        onlyOwner
    {
        require(
            _zunaAddress != address(0) && _wbnbAddress != address(0),
            "Invalid address"
        );
        zunaAddress = _zunaAddress;
        wbnbAddress = _wbnbAddress;
    }

    function releaseBuybackRewards(
        address[][] calldata holders,
        uint256 wbnbAmount,
        uint256 zunaAmount
    ) external {
        require(
            _msgSender() == owner() || _msgSender() == controllerAddress,
            "No permission"
        );

        IERC20 zuna = IERC20(zunaAddress);
        IERC20 wbnb = IERC20(wbnbAddress);

        uint256 totalRewardsAmount = zunaAmount;

        // swap wbnb -> zuna

        if (wbnbAmount > 0) {

            uint256 amountIn = wbnbAmount;

            require(
                wbnb.transferFrom(paymentAddress, address(this), amountIn),
                "transferFrom failed."
            );
            require(wbnb.approve(address(router), amountIn));

            uint256 deadline = block.timestamp + 5 minutes;

            address[] memory path = new address[](2);
            path[0] = address(wbnbAddress);
            path[1] = address(zunaAddress);
            uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);
            uint256 amountOutMin = amountsOut[1];
            uint256[] memory amounts = router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                paymentAddress,
                deadline
            );
            uint256 amountOut = amounts[amounts.length - 1];
            totalRewardsAmount = zunaAmount + amountOut;
        }

        // check balance

        require(
            zuna.balanceOf(paymentAddress) > totalRewardsAmount,
            "Not enough balance"
        );

        // bulk transfer

        for (uint256 i = 0; i < holders.length; i++) {
            bulkTransfer(
                holders[i],
                (totalRewardsAmount * buybackRewards[i]) / 10**5
            );
        }
    }

    function releaseStaticRewards(address[][] calldata holders) external {
        require(
            _msgSender() == owner() || _msgSender() == controllerAddress,
            "No permission"
        );

        for (uint256 i = 0; i < holders.length; i++) {
            bulkTransfer(holders[i], staticRewards[i]);
        }

        emit StaticRewardsReleased(holders);
    }

    function bulkTransfer(address[] memory addresses, uint256 amount) internal {
        IERC20 zuna = IERC20(zunaAddress);

        for (uint256 i = 0; i < addresses.length; i++) {
            zuna.transferFrom(paymentAddress, addresses[i], amount);
        }
    }
}