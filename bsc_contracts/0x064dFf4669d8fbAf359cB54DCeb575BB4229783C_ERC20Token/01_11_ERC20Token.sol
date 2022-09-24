//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ERC20Token is ERC20, Ownable {
    string private _name;
    string private _symbol;

    address public uniswapV2Pair;
    address public tokenUSDT;
    address public feeBuyPayee;
    address public feeSellPayee;
    address public feeTransferPayee;
    address public feePtotectPayee;
    bool public isFeeGlobal = true;
    uint256 public feeBuyPercent = 3;
    uint256 public feeSellPercent = 5;
    uint256 public feeTransferPercent = 3;
    uint256 public feeProtectPercent = 0;
    uint256 public forceHold = 1;
    uint256 public dateLatest;
    uint256 public priceYesterday;
    uint256 public priceLatest;
    mapping(uint256 => uint256) public feeProMap;
    mapping(address => bool) public noFeeMap;
    mapping(address => bool) public mintMap;

    function _feeSell(
        address from,
        uint256 amount,
        uint256 amountBase
    ) private returns (uint256) {
        uint256 feeSell = (amountBase * feeSellPercent) / 100;
        if (feeSellPayee == address(0x0)) super._burn(from, feeSell);
        else super._transfer(from, feeSellPayee, feeSell);
        return amount - feeSell;
    }

    function _feeBuy(
        address from,
        uint256 amount,
        uint256 amountBase
    ) private returns (uint256) {
        uint256 feeBuy = (amountBase * feeBuyPercent) / 100;
        if (feeBuyPayee == address(0x0)) super._burn(from, feeBuy);
        else super._transfer(from, feeBuyPayee, feeBuy);
        return amount - feeBuy;
    }

    function _feeTransfer(
        address from,
        uint256 amount,
        uint256 amountBase
    ) private returns (uint256) {
        uint256 feeTransfer = (amountBase * feeTransferPercent) / 100;
        if (feeTransferPayee == address(0x0)) super._burn(from, feeTransfer);
        else super._transfer(from, feeTransferPayee, feeTransfer);

        return amount - feeTransfer;
    }

    function _feeProtect(
        address from,
        uint256 amount,
        uint256 amountBase
    ) private returns (uint256) {
        uint256 feeProtect = (amountBase * feeProtectPercent) / 100;
        if (feePtotectPayee == address(0x0)) super._burn(from, feeProtect);
        else super._transfer(from, feePtotectPayee, feeProtect);
        return amount - feeProtect;
    }

    function _holdForce(uint256 amount, uint256 amountBase)
        private
        view
        returns (uint256)
    {
        uint256 amountHold = (amountBase * forceHold) / 10000;
        return amount - amountHold;
    }

    function _priceProtect() private {
        uint256 dateNow = block.timestamp / 86400;
        if (dateNow > dateLatest) {
            priceYesterday = priceLatest;
            feeProtectPercent = 0;
            dateLatest = dateNow;
        }
        priceLatest = getPirce();
        if ((priceYesterday * 90) / 100 <= priceLatest) {
            feeProtectPercent = 0;
        } else if (
            (priceYesterday * 80) / 100 <= priceLatest &&
            priceLatest < (priceYesterday * 90) / 100
        ) {
            feeProtectPercent = feeProMap[0];
        } else if (
            (priceYesterday * 70) / 100 <= priceLatest &&
            priceLatest < (priceYesterday * 80) / 100
        ) {
            feeProtectPercent = feeProMap[1];
        } else if (priceLatest < (priceYesterday * 70) / 100) {
            feeProtectPercent = feeProMap[2];
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 amountBase = amount;
        if (isFeeGlobal) {
            if (from != uniswapV2Pair && to != uniswapV2Pair) {
                if (!noFeeMap[from])
                    amount = _feeTransfer(from, amount, amountBase);
            } else {
                _priceProtect();
                if (to == uniswapV2Pair) {
                    if (!noFeeMap[from])
                        amount = _feeSell(from, amount, amountBase);
                    if (!noFeeMap[from] && feeProtectPercent > 0)
                        amount = _feeProtect(from, amount, amountBase);
                    if (forceHold > 0) {
                        amount = _holdForce(amount, amountBase);
                    }
                } else if (from == uniswapV2Pair) {
                    if (!noFeeMap[to])
                        amount = _feeBuy(from, amount, amountBase);
                }
            }
        }
        return super._transfer(from, to, amount);
    }

    constructor() ERC20("FRRE ELF", "FEEF") {
        noFeeMap[msg.sender] = true;
        mintMap[msg.sender] = true;
        feeBuyPayee = msg.sender;
        tokenUSDT = 0x55d398326f99059fF775485246999027B3197955;

        feeProMap[0] = 5;
        feeProMap[1] = 15;
        feeProMap[2] = 25;

        mint(msg.sender, uint256(50000000000000000000000000));
    }

    function setNoFeeMap(address _address, bool _bool) public onlyOwner {
        noFeeMap[_address] = _bool;
    }

    function setForceHold(uint256 _forceHold) public onlyOwner {
        forceHold = _forceHold;
    }

    function setDateLatest(uint256 _dateLatest) public onlyOwner {
        dateLatest = _dateLatest;
    }

    function setPriceYesterday(uint256 _priceYesterday) public onlyOwner {
        priceYesterday = _priceYesterday;
    }

    function setFeeProtectPercent(uint256 _feeProtectPercent) public onlyOwner {
        feeProtectPercent = _feeProtectPercent;
    }

    function setTokenUSDT(address _tokenUSDT) public onlyOwner {
        tokenUSDT = _tokenUSDT;
    }

    function setName(string calldata name) public onlyOwner {
        _name = name;
    }

    function setSymbol(string calldata symbol) public onlyOwner {
        _symbol = symbol;
    }

    function setFeeTransferPayee(address _feeTransferPayee) public onlyOwner {
        feeTransferPayee = _feeTransferPayee;
    }

    function setFeeSellPayee(address _feeSellPayee) public onlyOwner {
        feeSellPayee = _feeSellPayee;
    }

    function setFeeBuyPayee(address _feeBuyPayee) public onlyOwner {
        feeBuyPayee = _feeBuyPayee;
    }

    function setFeeProtectPayee(address _feeProtectPayee) public onlyOwner {
        feePtotectPayee = _feeProtectPayee;
    }

    function setTimesProtectMapItem(
        uint256 _timesProtectIndex,
        uint256 _feeProtectPercent
    ) public onlyOwner {
        feeProMap[_timesProtectIndex] = _feeProtectPercent;
    }

    function setFeeGlobal(bool _isFeeGlobal) public onlyOwner {
        isFeeGlobal = _isFeeGlobal;
    }

    function setFeeBuyPercent(uint256 _feeBuyPercent) public onlyOwner {
        feeBuyPercent = _feeBuyPercent;
    }

    function setFeeSellPercent(uint256 _feeSellPercent) public onlyOwner {
        feeSellPercent = _feeSellPercent;
    }

    function setFeeTransferPercent(uint256 _feeTransferPercent)
        public
        onlyOwner
    {
        feeTransferPercent = _feeTransferPercent;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) public onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setMintMap(address _address, bool _isMint) public onlyOwner {
        mintMap[_address] = _isMint;
    }

    function mint(address _to, uint256 _amount) public {
        require(mintMap[msg.sender], "Only minter can mint");
        _mint(_to, _amount);
    }

    function getPirce() public view returns (uint256) {
        IERC20 usdt = IERC20(tokenUSDT);
        uint256 lpUSDT = usdt.balanceOf(uniswapV2Pair);
        uint256 lpTHIS = super.balanceOf(uniswapV2Pair);
        return ((lpUSDT + 1) * 10**super.decimals()) / (lpTHIS + 1);
    }

    function getBalanceOfUSDT() public view returns (uint256) {
        IERC20 usdt = IERC20(tokenUSDT);
        return usdt.balanceOf(uniswapV2Pair);
    }

    function getBalanceOfTHIS() public view returns (uint256) {
        return super.balanceOf(uniswapV2Pair);
    }

    function getDateNow() public view returns (uint256) {
        return block.timestamp / 86400;
    }
}