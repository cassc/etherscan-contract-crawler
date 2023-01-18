// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract Test is ERC20, Ownable {

    uint256 private initialSupply = 100_000_000_000 * (10 ** 18);

    uint256 public constant taxLimit = 10;
    uint256 public taxSell = 10;
    
    uint256 private constant denominator = 100;
    bool public tradingEnabled = false;
    
    mapping(address => bool) public excludedList;

    mapping(address => bool) public sniperList;
    uint256 private sniperTaxSell = 10;
    uint256 private sniperTaxBuy = 10;

    IUniswapV2Router02 public router;
    address public tokenPairAddr;

    address public marketingWalletAddr;


    event Rewarded(address indexed player, uint256 appTokens, uint256 realTokens);
    event AppScoreAdded(address indexed player, uint256 appTokens);

    constructor(address _routerAddr, address _marketingWalletAddr) ERC20("Test Token", "TST")
    {
        addExcluded(msg.sender);
        addExcluded(marketingWalletAddr);
        addExcluded(address(this));

        IUniswapV2Router02 _router = IUniswapV2Router02(_routerAddr);
        address _tokenPairAddr = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        tokenPairAddr = _tokenPairAddr;
        marketingWalletAddr = _marketingWalletAddr;

        _mint(msg.sender, initialSupply);
    }

    receive() external payable {}

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        tradingEnabled = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {
        // skip for initial presale transfer
        if(!tradingEnabled && (sender == tokenPairAddr || recipient == tokenPairAddr)) {
            revert("Trading not yet enabled!");
        }

        if (isExcluded(sender) || isExcluded(recipient) || recipient == marketingWalletAddr) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 baseUnit = amount / denominator;
        uint256 tax = 0;

        if (isSniper(sender) || isSniper(recipient)) {
            if (sender == tokenPairAddr) {
                tax = baseUnit * sniperTaxBuy;
            } else {
                tax = baseUnit * sniperTaxSell;
            }
        } else if (recipient == tokenPairAddr) {
            tax = baseUnit * taxSell;
        }

        if (tax > 0) {
            _transfer(sender, marketingWalletAddr, tax);
        }

        amount -= tax;

        super._transfer(sender, recipient, amount);
    }

    function setTax(uint256 _sell) public onlyOwner {
        require(_sell <= taxLimit, "ERC20: sell tax higher than tax limit");
        taxSell = _sell;
    }

    function setSniperTax(uint256 _buy, uint256 _sell) public onlyOwner {
        require(_buy <= 100 && _sell <= 100, "ERC20: sniper tax higher than tax limit");
        sniperTaxBuy = _buy;
        sniperTaxSell = _sell;
    }

    function setMarketingWalletAddr(address _addr) external onlyOwner {
        marketingWalletAddr = _addr;
        excludedList[_addr] = true;
    }

    function addExcluded(address account) public onlyOwner {
        require(!isExcluded(account), "ERC20: Account is already excluded");
        excludedList[account] = true;
    }

    function removeExcluded(address account) public onlyOwner {
        require(isExcluded(account), "ERC20: Account is not excluded");
        excludedList[account] = false;
    }

    function addSnipers(address[] memory _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            if (!sniperList[_addrs[i]]) {
                sniperList[_addrs[i]] = true;
            }
        }
    }

    function removeSnipers(address[] memory _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            if (sniperList[_addrs[i]]) {
                sniperList[_addrs[i]] = false;
            }
        }
    }

    function isExcluded(address account) public view returns (bool) {
        return excludedList[account];
    }

    function isSniper(address account) public view returns (bool) {
        return sniperList[account];
    }
}