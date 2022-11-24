// SPDX-License-Identifier: MIT

/*
OCFI SOCIALS:

    Telegram: https://t.me/OCFI_Official
    Website: https://www.octofi.io
    Twitter: https://twitter.com/realoctofi
*/

pragma solidity ^0.8.4;

import "./OcfiDividendTracker.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./MaxWalletCalculator.sol";
import "./OcfiStorage.sol";
import "./ERC20.sol";

contract Ocfi is ERC20, Ownable {
    using SafeMath for uint256;
    using OcfiStorage for OcfiStorage.Data;
    using OcfiFees for OcfiFees.Data;
    using OcfiReferrals for OcfiReferrals.Data;
    using OcfiTransfers for OcfiTransfers.Data;

    OcfiStorage.Data private _storage;

    uint256 public constant MAX_SUPPLY = 1000000 * (10**18);

    modifier onlyDividendTracker() {
        require(address(_storage.dividendTracker) == _msgSender(), "caller is not the dividend tracker");
        _;
    }

    constructor() ERC20("OCFI", "$OCFI") payable {
        _mint(address(this), MAX_SUPPLY);
        _storage.init(owner());
        _transfer(address(this), owner(), MAX_SUPPLY * 415 / 1000);
        _transfer(address(this), address(_storage.dividendTracker), MAX_SUPPLY * 85 / 1000);
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
    
    function customContract() external view returns (address) {
        return address(_storage.customContract);
    }

    function startTime() external view returns (uint256) {
        return _storage.startTime;
    }

    function updateMarketingWallet(address account) public onlyOwner {
        _storage.updateMarketingWallet(account);
    }

    function updateTeamWallet(address account) public onlyOwner {
        _storage.updateTeamWallet(account);
    }

    function updateDevWallet(address account) public {
        require(account != address(0));
        require(_msgSender() == _storage.devWallet);
        _storage.updateDevWallet(account);
    }

    function updateDividendTrackerContract(address payable dividendTrackerContract) public onlyOwner {
        _storage.updateDividendTrackerContract(dividendTrackerContract, owner());
    }

    function updateNftContract(address newNftContract) public onlyOwner {
        _storage.updateNftContract(newNftContract);
    }

    function updateCustomContract(address newCustomContract, bool excludeContractFromDividends) public onlyOwner {
        _storage.updateCustomContract(newCustomContract, excludeContractFromDividends);
    }

    function updatePresaleContract(address presaleContract) public onlyOwner {
        _storage.updatePresaleContract(presaleContract);
    }

    function updateFeeSettings(uint256 baseFee, uint256 maxFee, uint256 minFee, uint256 sellFee, uint256 buyFee, uint256 sellImpact, uint256 timeImpact) external onlyOwner {
        _storage.fees.updateFeeSettings(baseFee, maxFee, minFee, sellFee, buyFee, sellImpact, timeImpact);
    }

    function updateReinvestBonus(uint256 bonus) public onlyOwner {
        _storage.fees.updateReinvestBonus(bonus);
    }

    function updateFeeDestinationPercents(uint256 dividendsFactor, uint256 nftDividendsFactor, uint256 liquidityFactor, uint256 customContractFactor, uint256 burnFactor, uint256 marketingFactor, uint256 teamFactor, uint256 devFactor) public onlyOwner {
        _storage.fees.updateFeeDestinationPercents(_storage, dividendsFactor, nftDividendsFactor, liquidityFactor, customContractFactor, burnFactor, marketingFactor, teamFactor, devFactor);
    }

    function updateReferrals(uint256 referralBonus, uint256 referredBonus, uint256 tokensNeeded) public onlyOwner {
        _storage.referrals.updateReferralBonus(referralBonus);
        _storage.referrals.updateReferredBonus(referredBonus);
        _storage.referrals.updateTokensNeededForReferralNumber(tokensNeeded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _storage.fees.excludeFromFees(account, excluded);
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

    function getData(address account) external view returns (uint256[] memory dividendInfo, uint256[] memory customContractInfo, uint256 reinvestBonus, uint256 referralCode,  uint256[] memory fees, uint256 blockTimestamp) {
        return _storage.getData(account);
    }

    function getCurrentFees() external view returns (uint256[] memory) {
        return _storage.fees.getCurrentFees(_storage);
    }

    function getLiquidityTokenBalance() private view returns (uint256) {
        return balanceOf(address(_storage.pair));
    }

    function claimDividends(bool reinvest) external returns (bool) {
		return _storage.dividendTracker.claimDividends(msg.sender, reinvest);
    }

    function reinvestDividends(address account) external payable onlyDividendTracker {
        address[] memory path = new address[](2);
        path[0] = _storage.router.WETH();
        path[1] = address(this);

        uint256 balanceBefore = balanceOf(account);

        _storage.router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            account,
            block.timestamp
        );

        uint256 balanceAfter = balanceOf(account);

        if(balanceAfter > balanceBefore) {
            uint256 gain = balanceAfter - balanceBefore;

            uint256 bonus = _storage.fees.calculateReinvestBonus(gain);

            if(bonus > balanceOf(address(_storage.dividendTracker))) {
                bonus = balanceOf(address(_storage.dividendTracker));
            }

            if(bonus > 0) {
                super._transfer(address(_storage.dividendTracker), account, bonus);
                _storage.dividendTracker.updateAccountBalance(account);
            }
        }
    }


    function start() external onlyOwner {
        require(_storage.startTime == 0);
        _storage.startTime = block.timestamp;

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
    }


    function takeFees(address from, uint256 amount, uint256 feeFactor) private returns (uint256) {
        uint256 fees = OcfiFees.calculateFees(amount, feeFactor);
        amount = amount.sub(fees);
        super._transfer(from, address(this), fees);
        return amount;
    }

    function maxWallet() public view returns (uint256) {
        return MaxWalletCalculator.calculateMaxWallet(MAX_SUPPLY, _storage.startTime);
    }

    function executePossibleFeeSwap(address from, address to, uint256 amount) private {
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
                to == address(_storage.pair) &&
                _storage.startTime > 0 &&
                block.timestamp > _storage.startTime
            ) {
                _storage.swapping = true;

                uint256 swapAmount = contractTokenBalance;

                if(swapAmount > _storage.swapTokensMaxAmount) {
                    swapAmount = _storage.swapTokensMaxAmount;
                }

                uint256 burn = swapAmount * _storage.fees.burnFactor / OcfiFees.FACTOR_MAX;

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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        _storage.beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));

        if(_storage.startTime == 0) {
            require(from == address(this) ||
                    from == owner() ||
                    from == _storage.presaleContract,
                    "Only contract, owner, or presale contract can transfer tokens before start");
        }

        if(amount == 0 || from == to) {
            super._transfer(from, to, amount);
            return;
        }

        executePossibleFeeSwap(from, to, amount);

        bool takeFee = _storage.shouldTakeFee(from, to);
        
        uint256 originalAmount = amount;
        uint256 transferFees = 0;

        address referrerRewarded;

        if(takeFee) {
            address referrer = _storage.referrals.getReferrerFromTokenAmount(amount);

            if(!_storage.referrals.isValidReferrer(referrer, balanceOf(referrer), to)) {
                referrer = address(0);
            }

            (uint256 fees,
            uint256 referrerReward) =
            _storage.transfers.handleTransferWithFees(_storage, from, to, amount, referrer);

            transferFees = fees;

            if(referrerReward > 0) {
                if(referrerReward > fees) {
                    referrerReward = fees;
                }

                fees -= referrerReward;
                amount -= referrerReward;

                super._transfer(from, referrer, referrerReward);

                referrerRewarded = referrer;
            }

            if(fees > 0) {
                amount -= fees;
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);

        _storage.handleNewBalanceForReferrals(to, balanceOf(to));

        _storage.dividendTracker.updateAccountBalance(from);
        _storage.dividendTracker.updateAccountBalance(to);
        if(referrerRewarded != address(0)) {
            _storage.dividendTracker.updateAccountBalance(referrerRewarded);
        }

        uint256 fromBalance = balanceOf(from);
        uint256 toBalance = balanceOf(to);
        
        _storage.handleTransfer(from, to, fromBalance, toBalance, originalAmount, transferFees);
    }
}