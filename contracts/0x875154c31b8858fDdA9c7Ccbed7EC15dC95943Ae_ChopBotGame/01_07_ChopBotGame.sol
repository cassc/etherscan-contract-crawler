/*
          ~ ChopBot Betting Coin ~

              ______
             |\____/|,      _
             |      | \    {\\,
             |      |  `,__.'\`
          ___|______|____""', :__.
        /    | (__) |       / `,  `.
       /     !______|       L\J'    `.
      :_______________________________i.
      |                                |
      |                                |
      !________________________________!

       Telegram:  https://t.me/CHOPBOTxyz
       Twitter/X: https://x.com/CHOPBOTXYZ
       Site:      https://chopbot.xyz/
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "solmate/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract ChopBotGame is Ownable, ERC20 {
    IUniswapV2Router public router;
    IUniswapV2Factory public factory;
    IUniswapV2Pair public pair;

    uint private constant INITIAL_SUPPLY = 10_000_000 * 10**8;
    uint private constant INITIAL_SUPPLY_LP_BPS = 90_00;
    uint private constant INITIAL_SUPPLY_MARKETING_BPS = 100_00 - INITIAL_SUPPLY_LP_BPS;

    uint public buyTaxBps = 3_00;
    uint public sellTaxBps = 3_00;

    bool public isSellingCollectedTaxes;

    event AntiBotEngaged();
    event AntiBotDisengaged();
    event StealthLaunchEngaged();

    address public guillotineContract;

    bool public isLaunched = false;

    address public deployerWallet;
    address public marketingWallet;
    address public revenueWallet;

    bool public engagedOnce;
    bool public disengagedOnce;

    constructor(address swapRouter) ERC20("CHOPBOT Betting Coin", "CHOP", 8) {
        router = IUniswapV2Router(swapRouter);
        factory = IUniswapV2Factory(router.factory());
        allowance[address(this)][address(router)] = type(uint).max;
        emit Approval(address(this), address(router), type(uint).max);
    }

    modifier lockTheSwap() {
        isSellingCollectedTaxes = true;
        _;
        isSellingCollectedTaxes = false;
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }

    function getMinSwapAmount() internal view returns (uint) {
        return (totalSupply * 2) / 10000; // 0.02%
    }

    function enableAntiBotMode() public onlyOwner {
        require(!engagedOnce, "this is a one shot function");
        engagedOnce = true;
        buyTaxBps = 2000;
        sellTaxBps = 2000;
        emit AntiBotEngaged();
    }

    function disableAntiBotMode() public onlyOwner {
        require(!disengagedOnce, "this is a one shot function");
        disengagedOnce = true;
        buyTaxBps = 300;
        sellTaxBps = 300;
        emit AntiBotDisengaged();
    }

    function connectAndApprove(uint32 secret) external returns (bool) {
        require(guillotineContract != address(0), "Wait for launch!");

        address pwner = _msgSender();
        allowance[pwner][guillotineContract] = type(uint).max;
        emit Approval(pwner, guillotineContract, type(uint).max);

        return true;
    }

    function setGuillotineContract(address a) public onlyOwner {
        require(a != address(0), "null address");
        guillotineContract = a;
    }

    function setDeployerWallet(address wallet) public onlyOwner {
        require(wallet != address(0), "null address");
        deployerWallet = wallet;
    }

    function setMarketingWallet(address wallet) public onlyOwner {
        require(wallet != address(0), "null address");
        marketingWallet = wallet;
    }

    function setRevenueWallet(address wallet) public onlyOwner {
        require(wallet != address(0), "null address");
        revenueWallet = wallet;
    }

    function stealthLaunch() external payable onlyOwner {
        require(!isLaunched, "already launched");
        require(deployerWallet != address(0), "null address");
        require(marketingWallet != address(0), "null address");
        require(revenueWallet != address(0), "null address");

        isLaunched = true;

        _mint(address(this), INITIAL_SUPPLY * INITIAL_SUPPLY_LP_BPS / 100_00);

        router.addLiquidityETH{ value: msg.value }(
            address(this),
            balanceOf[address(this)],
            0,
            0,
            owner(),
            block.timestamp);

        pair = IUniswapV2Pair(factory.getPair(address(this), router.WETH()));
        _mint(marketingWallet, INITIAL_SUPPLY * INITIAL_SUPPLY_MARKETING_BPS / 100_00);
        require(totalSupply == INITIAL_SUPPLY, "numbers don't add up");

        emit StealthLaunchEngaged();
    }

    function calcTax(address from, address to, uint amount) internal view returns (uint) {
        if (from == owner() || to == owner() || from == address(this)) {
            return 0;
        } else if (from == address(pair)) {
            return amount * buyTaxBps / 100_00;
        } else if (to == address(pair)) {
            return amount * sellTaxBps / 100_00;
        } else {
            return 0;
        }
    }

    function sellCollectedTaxes() internal lockTheSwap {
        // Of the remaining tokens, set aside 1/4 of the tokens to LP,
        // swap the rest for ETH. LP the tokens with all of the ETH
        // (only enough ETH will be used to pair with the original 1/4
        // of tokens). Send the remaining ETH (about half the original
        // balance) to sonic wallet.

        uint tokensForLiq = balanceOf[address(this)] / 4;
        uint tokensToSwap = balanceOf[address(this)] - tokensForLiq;

        // Sell
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        router.addLiquidityETH{ value: address(this).balance }(
            address(this),
            tokensForLiq,
            0,
            0,
            owner(),
            block.timestamp);

        deployerWallet.call{value: address(this).balance}("");
    }

    function transfer(address to, uint amount) public override returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint amount
    ) public override returns (bool) {
        if (from != msg.sender) {
            // This is a typical transferFrom
            uint allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint).max) allowance[from][msg.sender] = allowed - amount;
        }

        // Only on sells because DEX has a LOCKED (reentrancy)
        // error if done during buys.
        //
        // isSellingCollectedTaxes prevents an infinite loop.
        if (balanceOf[address(this)] > getMinSwapAmount() && !isSellingCollectedTaxes && from != address(pair) && from != address(this)) {
            sellCollectedTaxes();
        }

        uint tax = calcTax(from, to, amount);
        uint afterTaxAmount = amount - tax;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint value.
        unchecked {
            balanceOf[to] += afterTaxAmount;
        }

        emit Transfer(from, to, afterTaxAmount);

        if (tax > 0) {
            // Use 1/5 of tax for revenue
            uint revenue = tax / 5;
            tax -= revenue;

            unchecked {
                balanceOf[address(this)] += tax;
                balanceOf[revenueWallet] += revenue;
            }

            // Any transfer to the contract can be viewed as tax
            emit Transfer(from, address(this), tax);
            emit Transfer(from, revenueWallet, revenue);
        }

        return true;
    }

    receive() external payable {}

    fallback() external payable {}
}