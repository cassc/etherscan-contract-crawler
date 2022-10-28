// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "hardhat/console.sol";
import "../lib/IUniswapV2Router.sol";

pragma solidity ^0.8.4;

/**
 * @title Liquidity Vault for holders
 * @dev This vault holds taxed tokens and performs operations as needed.
 */

contract SwapVault is Ownable, ReentrancyGuard, KeeperCompatibleInterface {
    // ERC20 token being held by this contract
    IERC20Upgradeable public defaultToken;
    IERC20Upgradeable public linkToken;
    IUniswapV2Router02 public uniswapV2Router;

    bool public autoTopUpLink;

    // Fees
    uint256 public treasuryFee; // bips
    uint256 public devFee; // bips
    uint256 public liquidityFee; // bips

    uint256 public linkTopUpAmount;
    uint256 public linkThreshold;

    // Addresses
    address public devAddr;
    address public treasuryAddr;
    address public lpAddr;

    // counters
    uint256 public swapAndLiquifycount;
    uint256 public swapTokensAtAmount;

    // events
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    receive() external payable {}

    constructor(
        address uniswapRouterAddress,
        address erc20TokenAddr,
        address _devAddr,
        address _treasuryAddr,
        address _lpAddr,
        address _linkTokenAddr
    ) {
        // Initialize Fees
        treasuryFee = 300; // bips
        devFee = 100; // bips
        liquidityFee = 500; // bips

        // init link vars
        linkTopUpAmount = 50e18;
        linkThreshold = 100e18;

        // Initialize Addr
        devAddr = _devAddr;
        treasuryAddr = _treasuryAddr;
        lpAddr = _lpAddr;
        autoTopUpLink = false;

        // Initialize Counters
        swapAndLiquifycount = 0;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            address(uniswapRouterAddress)
        );

        defaultToken = IERC20Upgradeable(erc20TokenAddr);
        linkToken = IERC20Upgradeable(_linkTokenAddr);

        swapTokensAtAmount = defaultToken.totalSupply() / 1e3; // 0.1%
        uniswapV2Router = _uniswapV2Router;
    }

    /**************************/
    /* ADMIN SETTER FUNCTIONS */
    /*************************/
    function setAddresses(
        address _devAddr,
        address _treasuryAddr,
        address _lpAddr,
        bool _autoTopUpLink
    ) public onlyOwner {
        devAddr = _devAddr;
        treasuryAddr = _treasuryAddr;
        lpAddr = _lpAddr;
        autoTopUpLink = _autoTopUpLink;
    }

    function setFees(
        uint256 _treasuryFee,
        uint256 _devFee,
        uint256 _liquidityFee,
        uint256 _swapTokensAtAmount,
        uint256 _linkThreshold,
        uint256 _linkTopUpAmount
    ) public onlyOwner {
        treasuryFee = _treasuryFee; // bips
        devFee = _devFee; // bips
        liquidityFee = _liquidityFee; // bips
        swapTokensAtAmount = _swapTokensAtAmount;
        linkTopUpAmount = _linkTopUpAmount;
        linkThreshold = _linkThreshold;
    }

    /******************************/
    /* MANUAL LIQUIDITY FUNCTIONS */
    /******************************/
    function swapAndSendDividendsAndLiquidity(uint256 amount) public onlyOwner {
        _swapAndSendDividendsAndLiquidity(amount);
    }

    /****************************/
    /* ADMIN WITHDRAW FUNCTIONS */
    /****************************/
    function withdrawErc20(
        address erc20address,
        address recipient,
        uint256 amount
    ) public onlyOwner {
        IERC20Upgradeable token = IERC20Upgradeable(erc20address);
        token.transfer(recipient, amount);
    }

    function withdrawETH(address recipient) public onlyOwner {
        uint256 ethToSend = address(this).balance;
        (bool successDev, ) = address(recipient).call{value: ethToSend}("");
        require(successDev, "Error Sending Tokens");
    }

    /*********************/
    /* PRIVATE FUNCTIONS */
    /*********************/

    function _swapAndSendDividendsAndLiquidity(uint256 amount) private {
        // Calculate amount to swap for eth
        uint256 totalFee = treasuryFee + devFee;
        uint256 tokensToSend = (amount * (totalFee)) /
            (totalFee + liquidityFee);

        // ensure tokensToSend leaves some eth for maintaining link balance;

        uint256 tokensForLiquify = amount - tokensToSend;

        // Liquify Tokens.
        _swapAndLiquify(tokensForLiquify);
        swapAndLiquifycount = swapAndLiquifycount + (1);

        // swap for ETH
        _swapTokensForEth(tokensToSend);

        // Maintain link balance
        _maintainLinkBalance();

        uint256 ethToSend = address(this).balance;

        // Send eth
        (bool successDev, ) = address(devAddr).call{
            value: (ethToSend * devFee) / totalFee
        }("");
        (bool successTreasury, ) = address(treasuryAddr).call{
            value: address(this).balance
        }("");
        require(successDev && successTreasury, "ETH Transfer Failed");
    }

    function _swapTokensForEth(uint256 amount) private {
        defaultToken.approve(address(uniswapV2Router), amount);
        address[] memory path = new address[](2);
        path[0] = address(defaultToken);
        path[1] = uniswapV2Router.WETH();
        // perform swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH... unlimited slippage
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapAndLiquify(uint256 _amount) internal {
        // split the contract balance into halves
        uint256 half = _amount / (2);
        uint256 otherHalf = _amount - (half); // in event of odd numbers

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half);

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - (initialBalance);

        // add liquidity
        _addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        defaultToken.approve(address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(defaultToken),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            lpAddr,
            block.timestamp
        );
        swapAndLiquifycount += 1;
    }

    // Chainlink Functions

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        return (_shouldSendBatch(), "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override nonReentrant {
        if (_shouldSendBatch()) {
            _swapAndSendDividendsAndLiquidity(
                swapTokensAtAmount
            );
            _maintainLinkBalance();
        }
    }

    // Private functions
    function _shouldSendBatch() internal view returns (bool) {
        return defaultToken.balanceOf(address(this)) >= swapTokensAtAmount;
    }

    function _maintainLinkBalance() internal {
        if (
            linkToken.balanceOf(address(this)) < linkThreshold &&
            autoTopUpLink == true
        ) {
            // defaultToken.approve(address(uniswapV2Router), amount);
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(linkToken);
            // perform swap

            // see how many tokens we can buy.
            uint256[] memory amounts = uniswapV2Router.getAmountsOut(
                address(this).balance,
                path
            );

            // buy the minimum of 50 or the amount we can buy
            uint256 amountOut = amounts[amounts.length - 1] >= linkTopUpAmount
                ? linkTopUpAmount
                : amounts[amounts.length - 1];

            // TODO - somehow pass ethereum into this
            //uniswapV2Router.swapExactETHForTokens{value: ethAmount}( ... )
            uniswapV2Router.swapExactETHForTokens(
                amountOut,
                path,
                address(this),
                block.timestamp + 1000
            );
        }
    }
}