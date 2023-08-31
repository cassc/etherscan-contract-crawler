/*

88888888888                           .d8888b.            888888                                   
    888                              d88P  "88b             "88b                                   
    888                              Y88b. d88P              888                                   
    888   .d88b.  88888b.d88b.        "Y8888P"               888  .d88b.  888d888 888d888 888  888 
    888  d88""88b 888 "888 "88b      .d88P88K.d88P           888 d8P  Y8b 888P"   888P"   888  888 
    888  888  888 888  888  888      888"  Y888P"            888 88888888 888     888     888  888 
    888  Y88..88P 888  888  888      Y88b .d8888b            88P Y8b.     888     888     Y88b 888 
    888   "Y88P"  888  888  888       "Y8888P" Y88b          888  "Y8888  888     888      "Y88888 
                                                           .d88P                               888 
                                                         .d88P"                           Y8b d88P 
                                                        888P"                              "Y88P"  

Website: https://tomjerryeth.com
Telegram: https://t.me/TomJerryETH
Twitter: https://twitter.com/TomJerryETH

*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract TomJerry is ERC20, Ownable, AccessControl {
    using Address for address payable;
    using SafeMath for uint;

    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct TaxAllocation {
        uint marketing;
        uint liquidity;
        uint rewards;
    }

    IUniswapV2Router02 private router;
    address private immutable WETH;
    address private immutable admin;
    address private marketingWallet;
    address private liquidityWallet;
    address private rewardsWallet;
    bool private _isDiscounted;

    uint8 private _decimals = 18;
    uint private _initialSupply = 1_000_000 * 10**_decimals;
    uint private _maxSwapThreshold = _initialSupply / 200; // 0.5% of the supply
    uint private constant TAX_DECLINE_PER_BLOCK = 10;
    uint private constant TAX_DENOMINATOR = 1000;

    mapping (address => bool) private _isExcluded;

    address public pair;
    uint public taxCollected;
    uint public initialTaxPercentage = 300; // 30.0%
    uint public finalTaxPercentage = 40; // 4.0%
    uint public discountTaxPercentage = 20; // 2.0%
    uint public delayBlocks = 10;
    uint public startBlock;

    TaxAllocation public taxAllocation = TaxAllocation(300, 200, 500);

    constructor (
        string memory _name,
        string memory _symbol,
        address _admin
    ) ERC20(_name, _symbol) {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();

        admin = _admin;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, address(this));

        _isExcluded[admin] = true;
        _isExcluded[_msgSender()] = true;
        _isExcluded[address(this)] = true;

        _mint(_msgSender(), _initialSupply);
    }

    /** ERC20 OVERRIDES */

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address from, 
        address to, 
        uint amount
    ) internal override {
        require (amount > 0, "Amount must be gt 0");

        if (from != pair &&
            to != pair
        ) {
            super._transfer(from, to, amount);
            return;
        }

        if (from == pair) {
            // buy
            require (startBlock > 0, "Trading is not open yet");

            uint tax = amount.mul(taxPercentage(true)).div(TAX_DENOMINATOR);
            taxCollected = taxCollected.add(tax);

            super._transfer(from, address(this), tax);
            super._transfer(from, to, amount.sub(tax));
            return;
        }

        if (to == pair) {
            // sell
            if (_isExcluded[from]) {
                super._transfer(from, to, amount);
                return;
            }

            uint tax = amount.mul(taxPercentage(false)).div(TAX_DENOMINATOR);
            taxCollected = taxCollected.add(tax);

            super._transfer(from, address(this), tax);
            swapFromTokens(taxCollected);
            super._transfer(from, to, amount.sub(tax));
            return;
        }
    }

    /** VIEW FUNCTIONS */

    function taxPercentage(bool isBuy) public view returns (uint) {
        if (block.number <= startBlock.add(delayBlocks)) {
            return initialTaxPercentage;
        } else {
            uint blockDifference = block.number.sub(startBlock.add(delayBlocks));
            uint taxDecline = blockDifference.mul(TAX_DECLINE_PER_BLOCK);
            if (taxDecline >= initialTaxPercentage.sub(finalTaxPercentage)) {
                if (isBuy && _isDiscounted) return discountTaxPercentage;
                return finalTaxPercentage;
            } else {
                return initialTaxPercentage.sub(taxDecline);
            }
        }
    }

    function getLpPrice() public view returns (uint) {
        uint wethBalance = IERC20(WETH).balanceOf(pair);
        uint tokenBalance = balanceOf(pair);
        return wethBalance * 1e12 / tokenBalance;
    }

    function getCirculatingSupply() public view returns (uint) {
        return totalSupply() - balanceOf(address(0xdead));
    }

    function getMarketCap() external view returns (uint) {
        return getLpPrice() * getCirculatingSupply() / 1e12;
    }

    /** INTERNAL FUNCTIONS */

    function swapFromTokens(uint amount) internal {
        uint balance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        if (amount > _maxSwapThreshold) amount = _maxSwapThreshold;
        if (amount > balance) amount = balance;
        if (amount > 0) {
            uint initialEthBalance = address(this).balance;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount, 
                0, 
                path, 
                address(this), 
                block.timestamp + 30 seconds
            );

            uint deltaBalance = address(this).balance.sub(initialEthBalance);
            taxCollected = taxCollected.sub(amount);

            uint marketingAmount = deltaBalance.mul(taxAllocation.marketing).div(TAX_DENOMINATOR);
            payable(marketingWallet).sendValue(marketingAmount);

            uint liquidityAmount = deltaBalance.mul(taxAllocation.liquidity).div(TAX_DENOMINATOR);
            payable(liquidityWallet).sendValue(liquidityAmount);

            uint rewardsAmount = deltaBalance.sub(marketingAmount).sub(liquidityAmount);
            payable(rewardsWallet).sendValue(rewardsAmount);
        }
    }

    function swapToTokens(uint amount, address to) internal {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        uint balance = IERC20(WETH).balanceOf(address(this));
        if (amount == 0 || amount > balance) amount = balance;
        if (amount > 0) {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount, 
                0, 
                path, 
                to, 
                block.timestamp + 30 seconds
            );
        }
    }

    /** PSEUDO-RANDOMIZATION FUNCTIONS */

    function random(uint number, address account) internal view returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    account
                )
            )
        ) % number;
    }

    /** RESTRICTED FUNCTIONS */

    function initPair() external onlyRole(MANAGER_ROLE) {
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            WETH
        );

        IERC20(WETH).approve(address(router), type(uint).max);
        _approve(address(this), address(router), type(uint).max);
        _approve(address(this), address(this), type(uint).max);
    }

    function initLiquidity() external payable onlyRole(MANAGER_ROLE) {
        uint liquidityTokens = balanceOf(_msgSender());
        _approve(_msgSender(), address(this), liquidityTokens);
        _transfer(_msgSender(), address(this), liquidityTokens);

        router.addLiquidityETH{value: msg.value}(
            address(this),
            liquidityTokens,
            0,
            0,
            _msgSender(),
            block.timestamp + 30 seconds
        );
    }

    function initTrading(address[] calldata accounts) external onlyRole(MANAGER_ROLE) {
        require(startBlock == 0, "Trading is already open");

        startBlock = block.number;
        for (uint i = 0; i < accounts.length; i++)
            swapToTokens(((random(6, accounts[i]) + 1).mul(1e16)).add(uint(2).mul(1e16)), accounts[i]);
    }

    function setTaxPercentage(uint _finalTaxPercentage, uint _discountTaxPercentage) external onlyRole(MANAGER_ROLE) {
        require(_finalTaxPercentage <= 40, "Must be lte to starting tax");
        require(_discountTaxPercentage <= _finalTaxPercentage, "Must be lte to normal tax");
        finalTaxPercentage = _finalTaxPercentage;
        discountTaxPercentage = _discountTaxPercentage;
    }

    function setIsDiscounted(bool active) external onlyRole(MANAGER_ROLE) {
        _isDiscounted = active;
    }

    function setTaxAllocation(uint _marketing, uint _liquidity, uint _rewards) external onlyRole(MANAGER_ROLE) {
        require(_marketing.add(_liquidity).add(_rewards) == 1000, "Incorrect entry for tax allocation");
        taxAllocation = TaxAllocation(_marketing, _liquidity, _rewards);
    }

    function setWallets(address _marketingWallet, address _liquidityWallet, address _rewardsWallet) external onlyRole(MANAGER_ROLE) {
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
        rewardsWallet = _rewardsWallet;
    }

    function rescueETH() external onlyRole(MANAGER_ROLE) {
        payable(_msgSender()).sendValue(address(this).balance);
    }
 
    function rescueTokens(address _token) external onlyRole(MANAGER_ROLE) {
        require(_token != address(this), "Can not rescue own token");
        IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
    }
 
    receive() external payable {}
}