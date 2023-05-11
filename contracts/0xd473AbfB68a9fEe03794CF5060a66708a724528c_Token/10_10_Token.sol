pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IDEXRouter.sol";
import "./IDEXFactory.sol";
import "./ISpinGame.sol";

contract Token is Ownable, ERC20 {
    // Constants
    address constant ZERO_ADDRESS = address(0);
    uint8 constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 10 ** 9 * 10 ** DECIMALS;

    // Dependencies
    IDEXRouter router;
    ISpinGame spinGame;

    // Configuration
    mapping(address => bool) public blacklist;
    mapping(address => bool) public txExempt;
    mapping(address => bool) public feeExempt;

    address public presaleAddress;

    uint256 public maxBalance;
    uint256 public maxBuy;
    uint256 public maxSell;

    address payable marketingWalletAddress;

    FeeSet public buyFees;
    FeeSet public sellFees;

    // State variables
    bool public hasLaunched = false;
    address public pairAddress;

    bool areFeesBeingProcessed;
    bool public isFeeProcessingEnabled;
    uint256 public feeProcessingThreshold;

    // Structs
    struct FeeSet {
        uint256 jackpotFee;
        uint256 marketingFee;
    }

    // Events
    event Launched();

    constructor(string memory NAME, string memory SYMBOL, address routerAddress) ERC20(NAME, SYMBOL) {
        router = IDEXRouter(routerAddress);

        setIsAccountExcluded(owner(), true);
        setIsAccountExcluded(address(57005), true);
        setIsAccountExcluded(address(0), true);

        // initialize pair
        pairAddress = IDEXFactory(router.factory()).createPair(address(this), router.WETH());

        // _mint is an internal function in ERC20.sol that is only called here,
        // and CANNOT be called ever again
        _mint(owner(), INITIAL_SUPPLY);
    }

    function getSumOfFeeSet(FeeSet memory set) private pure returns (uint256) {
        return set.jackpotFee + set.marketingFee;
    }

    function setSpinGameAddress(address value) external onlyOwner {
        spinGame = ISpinGame(value);
        setIsAccountExcluded(address(spinGame), true);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "Token#_transfer: transfer from the zero address");
        require(to != address(0), "Token#_transfer: transfer to the zero address");
        require(!blacklist[from] && !blacklist[to], "Token#_transfer: blacklisted");

        // gas optimization
        if (amount == 0) {
            super._transfer(from, to, amount);
            return;
        }

        // ensure fee processing works correctly
        if (areFeesBeingProcessed) {
            super._transfer(from, to, amount);
            return;
        }

        // launch when the presale adds LP
        if (!hasLaunched && from == presaleAddress && to == pairAddress) {
            launch();

            super._transfer(from, to, amount);
            return;
        }

        // determine transaction state
        bool isBuying = from == pairAddress;
        bool isSelling = to == pairAddress;
        bool isSpecial = from == address(spinGame) || from == presaleAddress;

        // process fees stored in contract
        uint256 balance = balanceOf(address(this));
        if (hasLaunched && isFeeProcessingEnabled && balance >= feeProcessingThreshold && !isBuying) {
            areFeesBeingProcessed = true;
            _processFees(balance > maxSell ? maxSell : balance);
            areFeesBeingProcessed = false;
        }

        // collect fees from the transfer if the coin has launched and neither party is fee-exempt
        if (hasLaunched && !feeExempt[from] && !feeExempt[to]) {
            uint256 feePercent = getSumOfFeeSet(isBuying ? buyFees : sellFees);

            if (feePercent > 0) {
                uint256 fees = amount * feePercent / 100;
                amount -= fees;
                super._transfer(from, address(this), fees);
            }
        }

        // transaction validations
        if (maxBalance > 0 && maxBuy > 0 && maxSell > 0 && hasLaunched && !isSpecial) {
            // max wallet
            if (!isSelling && !txExempt[to]) {
                require(balanceOf(to) + amount <= maxBalance, "Recipient will hit the max balance as a result of this transaction");
            }

            // max buy / sell
            if ((isBuying || isSelling) && !txExempt[from] && !txExempt[to]) {
                require(amount <= (isBuying ? maxBuy : maxSell), "You have reached the max buy or sell");
            }
        }

        // transfer remaining amount after any modifications
        super._transfer(from, to, amount);
    }

    function _processFees(uint256 amount) private {
        uint256 feeSum = getSumOfFeeSet(sellFees);
        if (feeSum == 0) return;

        // swap
        swapExactTokensForETH(amount);

        // calculate correct amounts to send out
        uint256 amountEth = address(this).balance;
        uint256 amountForJackpot = amountEth * sellFees.jackpotFee / feeSum;
        uint256 amountForMarketing = amountEth - amountForJackpot;

        // send out fees
        if (amountForJackpot > 0 && address(spinGame) != ZERO_ADDRESS) {
            spinGame.deposit{value: amountForJackpot}();
        }

        if (amountForMarketing > 0 && marketingWalletAddress != ZERO_ADDRESS) {
            marketingWalletAddress.transfer(amountForMarketing);
        }
    }

    function swapExactTokensForETH(uint256 amountIn) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountIn);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, address(this), block.timestamp);
    }

    function launch() private {
        require(!hasLaunched, "Token#launch: already launched");

        hasLaunched = true;

        emit Launched();
    }

    function setIsAccountBlacklisted(address account, bool value) public onlyOwner {
        blacklist[account] = value;
    }

    function setIsAccountExcluded(address account, bool value) public onlyOwner {
        txExempt[account] = value;
        feeExempt[account] = value;
    }

    function setPresaleAddress(address account) external onlyOwner {
        presaleAddress = account;
    }

    function setMarketingWalletAddress(address payable value) external onlyOwner {
        marketingWalletAddress = value;
        setIsAccountExcluded(marketingWalletAddress, true);
    }

    function setFees(bool areBuyFees, uint256 jackpotFee, uint256 marketingFee) external onlyOwner {
        require((jackpotFee + marketingFee) <= 20, "Cannot set fees to above a combined total of 20%");

        FeeSet memory fees = FeeSet({
            jackpotFee: jackpotFee,
            marketingFee: marketingFee
        });

        if (areBuyFees) {
            buyFees = fees;
        } else {
            sellFees = fees;
        }
    }

    function setMaxes(uint256 _maxBalance, uint256 _maxBuy, uint256 _maxSell) external onlyOwner {
        maxBalance = _maxBalance;
        maxBuy = _maxBuy;
        maxSell = _maxSell;
    }

    function setIsFeeProcessingEnabled(bool value) external onlyOwner {
        isFeeProcessingEnabled = value;
    }

    function setFeeProcessingThreshold(uint256 value) external onlyOwner {
        feeProcessingThreshold = value;
    }

    receive() external payable {}
}