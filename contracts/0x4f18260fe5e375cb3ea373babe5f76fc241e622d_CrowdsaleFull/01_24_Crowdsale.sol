// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@amxx/hre/contracts/tokens/utils/Balances.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./modules/ERC20Buyable.sol";
import "./modules/ERC20Vesting.sol";


contract CrowdsaleFull is ERC20Buyable, ERC20Vesting {
    using Balances for Balances.Fungible;

    uint256 public immutable buyInMinimum;
    uint64  public immutable saleStart;
    uint64  public immutable saleStop;

    Balances.Fungible private _bonus;

    event AffiliationBonus(address indexed affiliate, address indexed user, uint256 affiliateAmount, uint256 userAmount);

    modifier onlyDuringSale() {
        require(block.timestamp >= saleStart && block.timestamp < saleStop, "sale not active");
        _;
    }

    modifier onlyAfterSale() {
        require(block.timestamp >= saleStop, "sale not over");
        _;
    }

    constructor(
        ISwapRouter uniswapRouter_,
        IQuoter     uniswapQuoter_,
        IERC20      USDC_,
        IERC20      token_,
        uint256     rate_,
        uint64      saleStart_,
        uint64      saleDuration_,
        uint64      vestingStart_,
        uint64      cliffDuration_,
        uint64      vestingDuration_,
        uint256     buyInMinimum_
    )
        ERC20("FeelingMeta Crowdsale - Phase 1", "xFM #1")
        SwapToUSDC(uniswapRouter_, uniswapQuoter_, USDC_)
        ERC20Buyable(rate_)
        ERC20Vesting(token_, vestingStart_, vestingStart_ + vestingDuration_, vestingStart_ + cliffDuration_)
    {
        saleStart    = saleStart_;
        saleStop     = saleDuration_ == 0 ? type(uint64).max : saleStart_ + saleDuration_;
        buyInMinimum = buyInMinimum_;
    }

    function bonusOf(address user_) public view returns (uint256) {
        return _bonus.balanceOf(user_);
    }

    function totalBonus() public view returns (uint256) {
        return _bonus.totalSupply();
    }

    /// Restrict deposit time
    function deposit(
        address receiver_,
        uint256 amountIn_,
        uint256 minimumTokenOut_,
        bytes memory path_
    )
        public
        payable
        virtual
        onlyDuringSale()
        returns (uint256)
    {
        uint256 remaining = token.balanceOf(address(this)) - totalSupply();
        require(remaining > 0, "Sold out");
        uint256 amount = _deposit(receiver_, amountIn_, minimumTokenOut_, cost(remaining), path_);
        require(amount == remaining || amount >= buyInMinimum, "Minimum buy-in not reached");

        // If payment in ether, and remaining value
        if (msg.value > 0 && address(this).balance > 0) {
            // sending it back to the caller
            Address.sendValue(payable(msg.sender), address(this).balance);
        }

        return amount;
    }

    function depositWithAffiliate(
        address receiver_,
        address affiliate_,
        uint256 amountIn_,
        uint256 minimumTokenOut_,
        bytes memory path_
    )
        public
        payable
        virtual
        returns (uint256)
    {
        uint256 amount = deposit(receiver_, amountIn_, minimumTokenOut_, path_);

        _bonus.mint(receiver_,  amount *  5 / 100);
        _bonus.mint(affiliate_, amount * 15 / 100);
        emit AffiliationBonus(affiliate_, receiver_, amount * 15 / 100, amount *  5 / 100);

        return amount;
    }

    function drain(IERC20 token_, address receiver_) public onlyOwner() {
        require(token != token_);
        SafeERC20.safeTransfer(token_, receiver_, token_.balanceOf(address(this)));
    }

    function burnExtra() public onlyAfterSale() {
        ERC20Burnable(address(token)).burn(token.balanceOf(address(this)) + totalReleased() - totalSupply());
    }

    /// overrides
    function _transfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Vesting) {
        super._transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual override {
        super._mint(to, amount);
        require(totalSupply() <= token.balanceOf(address(this)), "Sold out");
    }
}