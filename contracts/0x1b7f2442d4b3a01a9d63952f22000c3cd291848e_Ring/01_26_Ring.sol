// SPDX-License-Identifier: MIT

/*

RING SOCIALS:

    Telegram: https://t.me/TheRingToken
    Website: https://www.theringstoken.com/
    Twitter: https://twitter.com/TheRingToken

HUGE THANKS TO ASHONCHAIN

In order to build this contract, we hired AshOnChain, freelance solidity developer.
If you want to hire AshOnChain for your next token or NFT contract, you can reach out here:

https://t.me/ashonchain
https://twitter.com/ashonchain

*/

pragma solidity ^0.8.4;

import "./RingDividendTracker.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./MaxWalletCalculator.sol";
import "./RingStorage.sol";
import "./ERC20.sol";

contract Ring is ERC20, Ownable {
    using SafeMath for uint256;
    using RingStorage for RingStorage.Data;
    using Fees for Fees.Data;
    using Game for Game.Data;
    using Referrals for Referrals.Data;
    using Transfers for Transfers.Data;

    address constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    RingStorage.Data private _storage;

    uint256 public constant MAX_SUPPLY = 1000000 * (10**18);


    event ClaimTokens(
        address indexed account,
        uint256 amount
    );

    event StepInTheWell(
        address indexed account,
        uint256 amount,
        bool isReinvest
    );

    constructor() ERC20("RING", "$RING") {
        _mint(address(this), MAX_SUPPLY);
        _transfer(address(this), owner(), MAX_SUPPLY / 4);
        _storage.init(owner());
    }

    receive() external payable {

  	}

    function withdraw() external onlyOwner {
        require(_storage.startTime == 0);

        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Could not withdraw funds");
    }

    function dividendTracker() external view returns (address) {
        return address(_storage.dividendTracker);
    }

    function pair() external view returns (address) {
        return address(_storage.pair);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        //Piggyback off approvals to burn tokens
        burnLiquidityTokens();
        return super.approve(spender, amount);
    }

    function updateFeeSettings(uint256 baseFee, uint256 maxFee, uint256 sellImpact, uint256 timeImpact) external onlyOwner {
        _storage.fees.updateFeeSettings(baseFee, maxFee, sellImpact, timeImpact);
    }

    function updateReinvestBonus(uint256 bonus) public onlyOwner {
        _storage.fees.updateReinvestBonus(bonus);
    }

    function updateFeeDestinationPercents(uint256 dividendsFactor, uint256 liquidityFactor, uint256 marketingFactor, uint256 burnFactor, uint256 teamFactor, uint256 devFactor) public onlyOwner {
        _storage.fees.updateFeeDestinationPercents(dividendsFactor, liquidityFactor, marketingFactor, burnFactor, teamFactor, devFactor);
    }

    function updateGameRewardFactors(uint256 biggestBuyerRewardFactor, uint256 lastBuyerRewardFactor) public onlyOwner {
        _storage.game.updateGameRewardFactors(biggestBuyerRewardFactor, lastBuyerRewardFactor);
    }

    function updateGameParams(uint256 gameMinimumBuy, uint256 gameLength, uint256 gameTimeIncrease) public onlyOwner {
        _storage.game.updateGameParams(gameMinimumBuy, gameLength, gameTimeIncrease);
    }



    function updateReferrals(uint256 referralBonus, uint256 referredBonus, uint256 tokensNeeded) public onlyOwner {
        _storage.referrals.updateReferralBonus(referralBonus);
        _storage.referrals.updateReferredBonus(referredBonus);
        _storage.referrals.updateTokensNeededForReferralNumber(tokensNeeded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _storage.excludeFromFees(account, excluded);
    }

    function excludeFromDividends(address account) public onlyOwner {
        _storage.dividendTracker.excludeFromDividends(account);
    }

    function setSwapTokensParams(uint256 atAmount, uint256 maxAmount) external onlyOwner {
        _storage.setSwapTokensParams(atAmount, maxAmount);
    }

    function manualSwapAccumulatedFees() external onlyOwner {
        _storage.fees.swapAccumulatedFees(_storage, balanceOf(address(this)));
    }

    function getData(address account) external view returns (uint256[] memory dividendInfo, uint256 referralCode, int256 buyFee, uint256 sellFee, address biggestBuyerCurrentGame, uint256 biggestBuyerAmountCurrentGame, uint256 biggestBuyerRewardCurrentGame, address lastBuyerCurrentGame, uint256 lastBuyerRewardCurrentGame, uint256 gameEndTime, uint256 blockTimestamp) {
        return _storage.getData(account, getLiquidityTokenBalance());
    }

    function getLiquidityTokenBalance() private view returns (uint256) {
        return balanceOf(address(_storage.pair));
    }

    function claimDividends(bool enterTheRing, uint256 minimumAmountOut) external returns (bool) {
		return _storage.dividendTracker.claimDividends(
            msg.sender, enterTheRing, minimumAmountOut);
    }

    function burnLiquidityTokens() public {
        uint256 burnAmount = _storage.burnLiquidityTokens(getLiquidityTokenBalance());

        if(burnAmount == 0) {
            return;
        }

        _burn(address(_storage.pair), burnAmount);
        _storage.pair.sync();
    }

    function zapInTheWellEther(address recipient, uint256 minimumAmountOut) external payable {
        require(msg.value >= 0.000001 ether);
        require(_storage.startTime > 0);
        require(!Transfers.codeRequiredToBuy(_storage.startTime));

        burnLiquidityTokens();
        handleGame();

        uint256 etherBalanceBefore = address(this).balance - msg.value;
        uint256 tokenBalanceBefore = balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = _storage.router.WETH();
        path[1] = address(this);

        uint256 swapEther = msg.value / 2;
        uint256 addEther = msg.value - swapEther;

        uint256 accountTokenBalance = balanceOf(msg.sender);

        _storage.zapping = true;

        _storage.router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapEther}(
            minimumAmountOut,
            path,
            msg.sender,
            block.timestamp
        );

        uint256 accountGain = balanceOf(msg.sender) - accountTokenBalance;

        super._transfer(msg.sender, address(this), accountGain);

        uint256 addTokens = balanceOf(address(this)) - tokenBalanceBefore;

        _stepInWithLiquidity(recipient, addEther, addTokens);
        _returnExcess(recipient, etherBalanceBefore);

        _storage.zapping = false;
    }


    function _stepInWithLiquidity(address account, uint256 etherAmount, uint256 tokenAmount) private {
        _approve(address(this), address(_storage.router), type(uint).max);

        uint256 liquidityTokensBefore = _storage.pair.balanceOf(deadAddress);

        _storage.router.addLiquidityETH{value: etherAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );

        uint256 liquidityTokensAdded = _storage.pair.balanceOf(deadAddress) - liquidityTokensBefore;

        bool isReinvest = false;

        if(msg.sender == address(_storage.dividendTracker)) {
            liquidityTokensAdded += liquidityTokensAdded * _storage.fees.reinvestBonus / Fees.FACTOR_MAX;

            isReinvest = true;
        }

        _storage.dividendTracker.increaseBalance(account, liquidityTokensAdded);
        emit StepInTheWell(account, liquidityTokensAdded, isReinvest);
    }

    function _returnExcess(address account, uint256 etherBalanceBefore) private {
        if(address(this).balance > etherBalanceBefore) {
            (bool success,) = account.call{value: address(this).balance - etherBalanceBefore}("");
            require(success, "Could not return funds");
        }
    }

    function setPrivateSaleParticipants(address[] memory privateSaleParticipants, uint256 amountInFullTokens) public onlyOwner {
        for(uint256 i = 0; i < privateSaleParticipants.length; i++) {
            address participant = privateSaleParticipants[i];

            if(!_storage.privateSaleAccount[participant]) {
                _storage.privateSaleAccount[participant] = true;
                super._transfer(owner(), participant, amountInFullTokens * 10**18);
            }
        }
    }

    function start() external onlyOwner {
        require(_storage.startTime == 0);

        _approve(address(this), address(_storage.router), type(uint).max);

        _storage.router.addLiquidityETH {
            value: address(this).balance
        } (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        _storage.startGame();
    }

    function takeFees(address from, uint256 amount, uint256 feeFactor) private returns (uint256) {
        uint256 fees = Fees.calculateFees(amount, feeFactor);
        amount = amount.sub(fees);
        super._transfer(from, address(this), fees);
        return amount;
    }

    function mintFromLiquidity(address account, uint256 amount) private {
        if(amount == 0) {
            return;
        }
        _storage.liquidityTokensAvailableToBurn += amount;
        _mint(account, amount);
    }

    function handleGame() public {
        uint256 liquidityTokenBalance = getLiquidityTokenBalance();

        (address biggestBuyer, uint256 amountWonBiggestBuyer, address lastBuyer, uint256 amountWonLastBuyer) = _storage.game.handleGame(liquidityTokenBalance);

        if(biggestBuyer != address(0))  {
            mintFromLiquidity(biggestBuyer, amountWonBiggestBuyer);
            _storage.handleNewBalanceForReferrals(biggestBuyer, balanceOf(biggestBuyer));
        }

        if(lastBuyer != address(0))  {
            mintFromLiquidity(lastBuyer, amountWonLastBuyer);
            _storage.handleNewBalanceForReferrals(lastBuyer, balanceOf(lastBuyer));
        }
    }

    function maxWallet() public view returns (uint256) {
        return MaxWalletCalculator.calculateMaxWallet(MAX_SUPPLY, _storage.startTime);
    }

    function executePossibleSwap(address from, address to, uint256 amount) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= _storage.swapTokensAtAmount;

        if(from != owner() && to != owner()) {
            if(
                to != address(this) &&
                to != address(_storage.pair) &&
                to != address(_storage.router)
            ) {
                require(balanceOf(to) + amount <= maxWallet());
            }

            if(
                canSwap &&
                !_storage.swapping &&
                !_storage.zapping &&
                to == address(_storage.pair) &&
                _storage.startTime > 0 &&
                block.timestamp >_storage.startTime
            ) {
                _storage.swapping = true;

                uint256 swapAmount = contractTokenBalance;

                if(swapAmount > _storage.swapTokensMaxAmount) {
                    swapAmount = _storage.swapTokensMaxAmount;
                }

                uint256 burn = swapAmount * _storage.fees.burnFactor / Fees.FACTOR_MAX;

                if(burn > 0) {
                    swapAmount -= burn;
                    _burn(address(this), burn);
                }

                _approve(address(this), address(_storage.router), type(uint).max);

                _storage.fees.swapAccumulatedFees(_storage, swapAmount);

                _storage.swapping = false;
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(_storage.privateSaleAccount[from]) {
            uint256 movable = _storage.getPrivateSaleMovableTokens(from);
            require(movable >= amount, "Moving tokens too fast");
            _storage.privateSaleTokensMoved[from] += amount;
        }

        executePossibleSwap(from, to, amount);

        bool takeFee = !_storage.swapping &&
                        !_storage.isExcludedFromFees[from] &&
                        !_storage.isExcludedFromFees[to];

        int256 transferFees = 0;

        if(from != owner() && to != owner()) {
            handleGame();
        }

        if(takeFee) {
            address referrer = _storage.referrals.getReferrerFromTokenAmount(amount);

            if(!_storage.referrals.isValidReferrer(referrer, balanceOf(referrer), to)) {
                referrer = address(0);
            }

            (uint256 fees,
            uint256 buyerMint,
            uint256 referrerMint) =
            _storage.transfers.handleTransferWithFees(_storage, from, to, amount, referrer);

            transferFees = int256(fees) - int256(buyerMint);

            if(fees > 0) {
                amount -= fees;
                super._transfer(from, address(this), fees);
            }

            if(buyerMint > 0) {
                mintFromLiquidity(to, buyerMint);
            }

            if(referrerMint > 0) {
                mintFromLiquidity(referrer, referrerMint);
            }
        }

        super._transfer(from, to, amount);

        _storage.handleNewBalanceForReferrals(to, balanceOf(to));
    }
}