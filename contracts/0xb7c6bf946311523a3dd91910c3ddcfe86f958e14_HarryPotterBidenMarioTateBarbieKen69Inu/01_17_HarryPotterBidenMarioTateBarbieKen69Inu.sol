/*
    HarryPotterBidenMarioTateBarbieKen69Inu
    $LINK

    Website: https://harrypotterbidenmariotatebarbieken69inu.com/
    Twitter: https://twitter.com/Cashtag_LINK
    Telegram: https://t.me/cashtag_LINK
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

contract HarryPotterBidenMarioTateBarbieKen69Inu is ERC20, Ownable, AccessControl {
    using Address for address payable;
    using SafeMath for uint;

    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IUniswapV2Router02 private router;
    address private immutable WETH;
    address private immutable admin;
    address private immutable fund;
    uint private _decimals = 9;
    uint private _initialSupply = 1_000_000_000 * 10**_decimals;
    uint private _swapThreshold = _initialSupply / 1000; // 0.1% of the supply
    uint private _taxDenominator = 1000;

    mapping (address => bool) private _isExcluded;

    address public pair;
    uint public taxCollected;
    uint public initialTaxPercentage = 550; // 55.0%
    uint public taxPercentage = 10; // 1.0%
    uint public delayBlocks = 20;
    uint public startBlock;

    constructor () ERC20("HarryPotterBidenMarioTateBarbieKen69Inu", "LINK") {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();

        admin = address(0x0cbE4DCF6DbC11A6374eD009738A4CAA667676f6);
        fund = address(0x9de2269317C37b1B4746192c8beC7627b0B1F212);

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
        return 9;
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
            require (startBlock > 0, "Trading is not open yet");

            uint tax = amount.mul((startBlock.add(delayBlocks) < block.number) ? taxPercentage : initialTaxPercentage).div(_taxDenominator);
            taxCollected = taxCollected.add(tax);

            super._transfer(from, address(this), tax);
            super._transfer(from, to, amount.sub(tax));
            return;
        }

        if (to == pair) {
            if (_isExcluded[from]) {
                super._transfer(from, to, amount);
                return;
            }

            uint tax = amount.mul((startBlock.add(delayBlocks) < block.number) ? taxPercentage : initialTaxPercentage).div(_taxDenominator);
            taxCollected = taxCollected.add(tax);

            super._transfer(from, address(this), tax);
            swapFromTokens(taxCollected, fund);
            super._transfer(from, to, amount.sub(tax));
            return;
        }
    }

    /** INTERNAL FUNCTIONS */

    function swapFromTokens(uint amount, address to) internal {
        uint balance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        if (amount > _swapThreshold) amount = _swapThreshold;
        if (amount > balance) amount = balance;
        if (amount > 0) {
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount, 
                0, 
                path, 
                to, 
                block.timestamp + 30 seconds
            );

            taxCollected = taxCollected.sub(amount);
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
        uint balance = balanceOf(_msgSender());
        _approve(_msgSender(), address(this), balance);
        _transfer(_msgSender(), address(this), balance);

        router.addLiquidityETH{value: msg.value}(
            address(this),
            balance,
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

    function rescueETH() external onlyRole(MANAGER_ROLE) {
        payable(_msgSender()).transfer(address(this).balance);
    }
 
    function rescueTokens(address _token) external onlyRole(MANAGER_ROLE) {
        require(_token != address(this), "Can not rescue own token!");
        IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
    }
 
    receive() external payable {}
}