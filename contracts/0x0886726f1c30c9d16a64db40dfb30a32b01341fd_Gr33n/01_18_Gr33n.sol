/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

/**
WEBSITE: https://thegreenwall.d-app.app/

$BUILD was born out of frustration.

Frustration from seeing shitcoins get hyped because a dev wrote something about the space needed a “reset” or how there’s a “resurgence” coming at the top of the contract. Whoopty f**king doo!

They’d promise buybacks but go to sleep on their communities and that really pisses me off. 

People invest their money when they are inspired and there’s nothing worse than watching a group of inspired investors lose hope so quickly. 

What is more frustrating than ever is these devs don’t have a creative bone in their bodies. Perhaps the truth is, they are just incapable of writing unique functions and just fork the latest shit to try and make a buck at the expense of degens. 

Well, frustration can breed change, and that’s exactly what $BUILD attempts to do. 

I’m writing in a function no one has ever seen before. A function that rewards investors who join forces to create buy walls and help send this token to new heights every day. 

As devs know, loops aren’t possible in solidity, so I’ve created a counter instead that will count the number of consecutive buys and record the buyer’s wallets who form a flow of consecutive buys - AKA a buy wall. 

How will it work? 

The contract will accumulate ETH with every buy and sell. 

This ETH will become “activated” whenever there is a buy wall of 10 buys. At the same time, the sell tax will snap to 21% to ensure that anyone who breaks the buy wall will get penalised for being short-sighted. In fact, the sell tax will only reset back to 5% once another buy comes in. 

When someone does break an active buy wall with a sell, the ETH stored in the contract will be dispersed to all buyers who helped build the buy wall. Big or small, every buy counts and the ETH will be dispersed to those buy-wall builders proportionate to their holding. 

Note: only buys within an active buy wall (10 buys or more) will receive ETH. 

Show the power of building something together. 

This contract was written for those who understand that the tokens that fly to huge market caps have all got one thing in common - there’s an army of people all joining forces to help get it there. 

They do not get their by chance.

This will be no different, only this time, the ones who put their money on the line to build the buy walls and reach ATH after ATH will be rewarded for their efforts. 

LFG! 

I will renounce on Day 1 as the function can operate autonomously.

Standard buy and sell taxes are 5%

3% of each buy and sell will be added to the rewards pool, and paid out to buy wall builders. 

Sell tax will snap to 21% when buy walls are activated to penalise buy-wall breakers, and reset back to 5% on the first buy thereafter. This surplus tax will help build the LP and rewards pool even further. 

Let's build something together.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Gr33nDividendTracker.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./BuyWallMapping.sol";
import "./Counters.sol";

contract Gr33n is ERC20, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string private constant _name = "Gr33n";
    string private constant _symbol = "BUILD";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e12 * 10**18;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bool private tradingOpen = false;
    bool public greenWallActive = false;
    uint256 private launchBlock = 0;
    uint256 private sniperProtectBlock = 0;
    address private uniswapV2Pair;

    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => bool) public isExcludeFromFee;
    mapping(address => bool) private isBot;
    mapping(address => bool) private canClaimUnclaimed;
    mapping(address => bool) public isExcludeFromMaxWalletAmount;

    uint256 public maxWalletAmount;

    uint256 private sniperTax = 60;
    uint256 private baseBuyTax = 2;
    uint256 private baseSellTax = 2;
    uint256 private buyRewards = 3;
    uint256 private sellRewards = 3;
    uint256 public greenWallJeetTax;

    uint256 public buyTax = baseBuyTax.add(buyRewards);
    uint256 public sellTax = baseSellTax.add(sellRewards);

    uint256 private autoLP = 30;
    uint256 private devFee = 35;
    uint256 private teamFee = 35;

    uint256 private minContractTokensToSwap = 2e9 * 10**_decimals;
    uint256 public minBuyWallIncludeAmount = 1000000000 * 10**_decimals;
    uint256 public minBuyWallActivationCount = 10;

    BuyWallMapping public buyWallMap;

    address private devWalletAddress;
    address private teamWalletAddress;

    Gr33nDividendTracker public dividendTracker;
    Gr33nDividendTracker private greenWallDivTracker;

    uint256 public pendingTokensForReward;

    uint256 public pendingEthReward;

    struct GreenWallWins {
        address divTrackerWin;
        uint256 timestamp;
    }

    Counters.Counter private greenWallParticipationHistoryIds;

    mapping(uint256 => GreenWallWins) private greenWallWinsMap;
    mapping(address => uint256[]) private greenWallWinIds;

    event BuyFees(address from, address to, uint256 amountTokens);
    event SellFees(address from, address to, uint256 amountTokens);
    event AddLiquidity(uint256 amountTokens, uint256 amountEth);
    event SwapTokensForEth(uint256 sentTokens, uint256 receivedEth);
    event SwapEthForTokens(uint256 sentEth, uint256 receivedTokens);
    event DistributeFees(uint256 devEth, uint256 remarketingEth);

    event SendBuyWallDividends(uint256 amount);

    event DividendClaimed(uint256 ethAmount, address account);

    constructor(
        address _devWalletAddress,
        address _teamWalletAddress
    ) ERC20(_name, _symbol) {
        devWalletAddress = _devWalletAddress;
        teamWalletAddress = _teamWalletAddress;

        maxWalletAmount = (_tTotal * 5) / 10000; // 0.05% maxWalletAmount (initial limit)

        buyWallMap = new BuyWallMapping();

        dividendTracker = new Gr33nDividendTracker();
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));

        isExcludeFromFee[owner()] = true;
        isExcludeFromFee[address(this)] = true;
        isExcludeFromFee[devWalletAddress] = true;
        isExcludeFromFee[teamWalletAddress] = true;
        isExcludeFromMaxWalletAmount[owner()] = true;
        isExcludeFromMaxWalletAmount[address(this)] = true;
        isExcludeFromMaxWalletAmount[address(uniswapV2Router)] = true;
        isExcludeFromMaxWalletAmount[devWalletAddress] = true;
        isExcludeFromMaxWalletAmount[teamWalletAddress] = true;
        canClaimUnclaimed[owner()] = true;
        canClaimUnclaimed[address(this)] = true;

        _mint(owner(), _tTotal);

    }

    /**
     * @dev Function to recover any ETH sent to Contract by Mistake.
    */
    function withdrawStuckETH(bool pendingETH) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        bool success;
        (success, ) = address(msg.sender).call{ value: address(this).balance.sub(pendingEthReward) }(
            ""
        );

        if(pendingETH) {
            require(pendingEthReward > 0, "NER");

            bool pendingETHsuccess;
            (pendingETHsuccess, ) = address(msg.sender).call{ value: pendingEthReward }(
                ""
            );

            if (pendingETHsuccess) {
                pendingEthReward = pendingEthReward.sub(pendingEthReward);
            }
        }
    }

    /**
     * @dev Function to recover any ERC20 Tokens sent to Contract by Mistake.
    */
    function recoverAccidentalERC20(address _tokenAddr, address _to) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        uint256 _amount = IERC20(_tokenAddr).balanceOf(address(this));
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "TOP1");
        uint256 _launchTime;
        
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        isExcludeFromMaxWalletAmount[address(uniswapV2Pair)] = true;

        automatedMarketMakerPairs[uniswapV2Pair] = true;
        dividendTracker.excludeFromDividends(uniswapV2Pair);

        addLiquidity(balanceOf(address(this)), address(this).balance);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        tradingOpen = true;
        _launchTime = block.timestamp;
        launchBlock = block.number;
    }

    function setSniperProtect(uint256 numberofblocks, uint256 _sniperTax) external onlyOwner {
        sniperProtectBlock = numberofblocks;
        sniperTax = _sniperTax;
    }

    function manualSwap() external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        uint256 totalTokens = balanceOf(address(this)).sub(
            pendingTokensForReward
        );

        swapTokensForEth(totalTokens);
    }

    function manualSend() external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        uint256 totalEth = address(this).balance.sub(pendingEthReward);

        uint256 devFeesToSend = totalEth.mul(devFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 teamFeesToSend = totalEth.mul(teamFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 remainingEthForFees = totalEth.sub(devFeesToSend).sub(
            teamFeesToSend);
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, teamFeesToSend);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(!isBot[_from] && !isBot[_to]);

        uint256 transferAmount = _amount;
        if (
            tradingOpen &&
            (automatedMarketMakerPairs[_from] ||
                automatedMarketMakerPairs[_to]) &&
            !isExcludeFromFee[_from] &&
            !isExcludeFromFee[_to]
        ) {
            
            transferAmount = takeFees(_from, _to, _amount);
        }

        if (!automatedMarketMakerPairs[_to] && !isExcludeFromMaxWalletAmount[_to]) {
            require(balanceOf(_to) + transferAmount <= maxWalletAmount,
                "WBL"
            );
        }

        super._transfer(_from, _to, transferAmount);

    }

    function claimUnclaimed(address greenWallDivAddress, address payable _unclaimedAccount, address payable _account) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        greenWallDivTracker = Gr33nDividendTracker(payable(greenWallDivAddress));
        
        uint256 withdrawableAmount = greenWallDivTracker.withdrawableDividendOf(_unclaimedAccount);
        require(withdrawableAmount > 0,
            "NWD"
        );

        uint256 ethAmount;

        ethAmount = greenWallDivTracker.processAccount(_unclaimedAccount, _account);

        if (ethAmount > 0) {
            greenWallDivTracker.setBalance(_unclaimedAccount, 0);

            emit DividendClaimed(ethAmount, _unclaimedAccount);
        }
    }

    function claim(address greenWallDivAddress) external {
        _claim(greenWallDivAddress, payable(msg.sender));
    }

    function _claim(address greenWallDivAddress, address payable _account) private {
        greenWallDivTracker = Gr33nDividendTracker(payable(greenWallDivAddress));

        uint256 withdrawableAmount = greenWallDivTracker.withdrawableDividendOf(
            _account
        );
        require(
            withdrawableAmount > 0,
            "NWD"
        );
        uint256 ethAmount;

        ethAmount = greenWallDivTracker.processAccount(_account, _account);

        if (ethAmount > 0) {
            greenWallDivTracker.setBalance(_account, 0);

            emit DividendClaimed(ethAmount, _account);
        }
    }

    function checkGreenWallWinnings(address greenWallDivAddress, address _account) public view returns (uint256) {
        return Gr33nDividendTracker(payable(greenWallDivAddress)).withdrawableDividendOf(_account);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool _value) private {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "AMMS"
        );
        automatedMarketMakerPairs[_pair] = _value;
    }

    function setExcludeFromFee(address _address, bool _isExludeFromFee)
        external onlyOwner {
        isExcludeFromFee[_address] = _isExludeFromFee;
    }

    function setExcludeFromMaxWalletAmount(address _address, bool _isExludeFromMaxWalletAmount)
        external onlyOwner {
        isExcludeFromMaxWalletAmount[_address] = _isExludeFromMaxWalletAmount;
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= (totalSupply() * 1 / 1000)/1e18, "MWLP");
        maxWalletAmount = newMaxWallet * (10**_decimals);
    }

    function setIncludeToGreenWallMap(address _address, bool _isIncludeToGreenWallMap) external onlyOwner {
        if(_isIncludeToGreenWallMap) {
            buyWallMap.includeToGreenWallMap(_address);
        } else {
            buyWallMap.excludeToGreenWallMap(_address);
        }
    }

    function isIncludeInGreenWall(address _address) public view returns (bool) {
        return buyWallMap.isPartOfGreenWall(_address);
    }

    function setTaxes(
        uint256 _baseBuyTax,
        uint256 _buyRewards,
        uint256 _baseSellTax,
        uint256 _sellRewards,
        uint256 _autoLP,
        uint256 _devFee,
        uint256 _teamFee
    ) external onlyOwner {
        require(_baseBuyTax <= 10 && _baseSellTax <= 10);

        baseBuyTax = _baseBuyTax;
        buyRewards = _buyRewards;
        baseSellTax = _baseSellTax;
        sellRewards = _sellRewards;
        autoLP = _autoLP;
        devFee = _devFee;
        teamFee = _teamFee;
    }

    function setMinParams(uint256 _numTokenContractTokensToSwap, uint256 _minBuyWallActivationCount, uint256 _minBuyWallIncludeAmount) external onlyOwner {
        minContractTokensToSwap = _numTokenContractTokensToSwap * 10 ** _decimals;
        minBuyWallActivationCount = _minBuyWallActivationCount;
        minBuyWallIncludeAmount = _minBuyWallIncludeAmount * 10 ** _decimals;
    }

    function setBots(address[] calldata _bots) public onlyOwner {
        for (uint256 i = 0; i < _bots.length; i++) {
            if (
                _bots[i] != uniswapV2Pair &&
                _bots[i] != address(uniswapV2Router)
            ) {
                isBot[_bots[i]] = true;
            }
        }
    }

    function setWalletAddress(address _devWalletAddress, address _teamWalletAddress) external onlyOwner {
        devWalletAddress = _devWalletAddress;
        teamWalletAddress = _teamWalletAddress;
    }

    function takeFees(
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256) {
        uint256 fees;
        uint256 remainingAmount;
        require(
            automatedMarketMakerPairs[_from] || automatedMarketMakerPairs[_to],
            "NMM"
        );

        if (automatedMarketMakerPairs[_from]) {
            uint256 totalBuyTax;
            greenWallJeetTax = 0;
            if (block.number == launchBlock) {
                totalBuyTax = 90;
            } else if (block.number <= launchBlock + sniperProtectBlock) {
                totalBuyTax = sniperTax;
            } else {
                totalBuyTax = baseBuyTax.add(buyRewards);
            }

            fees = _amount.mul(totalBuyTax).div(100);

            uint256 rewardTokens = _amount.mul(buyRewards).div(100);

            pendingTokensForReward = pendingTokensForReward.add(rewardTokens);

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);
            
            if (_amount >= minBuyWallIncludeAmount) {
                if (!buyWallMap.isPartOfGreenWall(_to)) {
                try
                    buyWallMap.includeToGreenWallMap(_to)
                {} catch {}

                addHolderToGreenWallWinHistory(_to, address(dividendTracker));

                }

                dividendTracker.includeFromDividends(_to, balanceOf(_to).add(remainingAmount));
                
                dividendTracker._brokeOutOfGreenWall(_to, false);
            }

            if (buyWallMap.getNumberOfGreenWallHolders() >= minBuyWallActivationCount) {
                greenWallActive = true;

                greenWallJeetTax = 16;
            }

            emit BuyFees(_from, address(this), fees);
        } else {
            uint256 totalSellTax;
            uint256 _greenWallJeetTax = greenWallJeetTax;
            if (block.number == launchBlock) {
                totalSellTax = 90;
            } else if (block.number <= launchBlock + sniperProtectBlock) {
                totalSellTax = sniperTax;
            } else {

                totalSellTax = baseSellTax.add(sellRewards).add(greenWallJeetTax);

                if(totalSellTax > 30) {
                    totalSellTax = 30;
                }
            }

            fees = _amount.mul(totalSellTax).div(100);
            if(_greenWallJeetTax > 0) {
                uint256 greenWallJeetRewards = _amount.mul(40).div(100);

                pendingTokensForReward = pendingTokensForReward.add(greenWallJeetRewards);
            }

            uint256 rewardTokens = _amount.mul(sellRewards).div(100);

            pendingTokensForReward = pendingTokensForReward.add(rewardTokens);

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);

            if (buyWallMap.isPartOfGreenWall(_from)) {
            try
                buyWallMap.excludeToGreenWallMap(_from)
            {} catch {}
            }

            dividendTracker.setBalance(payable(_from), 0);

            dividendTracker._brokeOutOfGreenWall(_from, true);

            uint256 tokensToSwap = balanceOf(address(this)).sub(
                pendingTokensForReward);

            if (tokensToSwap > minContractTokensToSwap) {
                distributeTokensEth(tokensToSwap);
            }

            if (greenWallActive) {
                swapAndSendBuyWallDividends(pendingTokensForReward);
            }

            emit SellFees(_from, address(this), fees);
        }

        return remainingAmount;
    }

    function endGreenWall() private {
        greenWallActive = false;

        delete buyWallMap;

        buyWallMap = new BuyWallMapping();

        dividendTracker = new Gr33nDividendTracker();
    }

    function addHolderToGreenWallWinHistory(address _account, address _greenWallDivAddress) private {
        greenWallParticipationHistoryIds.increment();
        uint256 hId = greenWallParticipationHistoryIds.current();
        greenWallWinsMap[hId].divTrackerWin = _greenWallDivAddress;
        greenWallWinsMap[hId].timestamp = block.timestamp;

        greenWallWinIds[_account].push(hId);
    }

    function distributeTokensEth(uint256 _tokenAmount) private {
        uint256 tokensForLiquidity = _tokenAmount.mul(autoLP).div(100);

        uint256 halfLiquidity = tokensForLiquidity.div(2);
        uint256 tokensForSwap = _tokenAmount.sub(halfLiquidity);

        uint256 totalEth = swapTokensForEth(tokensForSwap);

        uint256 ethForAddLP = totalEth.mul(autoLP).div(100);
        uint256 devFeesToSend = totalEth.mul(devFee).div(100);
        uint256 teamFeesToSend = totalEth.mul(teamFee).div(100);
        uint256 remainingEthForFees = totalEth
            .sub(ethForAddLP)
            .sub(devFeesToSend)
            .sub(teamFeesToSend);
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, teamFeesToSend);

        if (halfLiquidity > 0 && ethForAddLP > 0) {
            addLiquidity(halfLiquidity, ethForAddLP);
        }
    }

    function sendEthToWallets(uint256 _devFees, uint256 _teamFees) private {
        if (_devFees > 0) {
            payable(devWalletAddress).transfer(_devFees);
        }
        if (_teamFees > 0) {
            payable(teamWalletAddress).transfer(_teamFees);
        }
        emit DistributeFees(_devFees, _teamFees);
    }

    function swapTokensForEth(uint256 _tokenAmount) private returns (uint256) {
        uint256 initialEthBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 receivedEth = address(this).balance.sub(initialEthBalance);

        emit SwapTokensForEth(_tokenAmount, receivedEth);
        return receivedEth;
    }

    function swapEthForTokens(uint256 _ethAmount, address _to) private returns (uint256) {
        uint256 initialTokenBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _ethAmount
        }(0, path, _to, block.timestamp);

        uint256 receivedTokens = balanceOf(address(this)).sub(
            initialTokenBalance
        );

        emit SwapEthForTokens(_ethAmount, receivedTokens);
        return receivedTokens;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit AddLiquidity(_tokenAmount, _ethAmount);
    }

    function swapAndSendBuyWallDividends(uint256 _tokenAmount) private {
        addHolderToGreenWallWinHistory(address(this), address(dividendTracker));

        uint256 pendingRewardsEth = swapTokensForEth(_tokenAmount);

        pendingTokensForReward = pendingTokensForReward.sub(_tokenAmount);

        (bool success, ) = address(dividendTracker).call{value: pendingRewardsEth}(
            ""
        );

        if (success) {
            emit SendBuyWallDividends(pendingRewardsEth);

            dividendTracker.distributeDividends();

            dividendTracker.setGreenWallEnded();

            endGreenWall();
        } else {
            pendingEthReward = pendingEthReward.add(pendingRewardsEth);

            endGreenWall();
        }


    }

    function availableContractTokenBalance() external view returns (uint256) {
        return balanceOf(address(this)).sub(pendingTokensForReward);
    }

    function getNumberOfBuyWallHolders() external view returns (uint256) {
        return buyWallMap.getNumberOfGreenWallHolders();
    }

     function getWinningHistory(
        address _account,
        uint256 _limit,
        uint256 _pageNumber
    ) external view returns (GreenWallWins[] memory) {
        require(_limit > 0 && _pageNumber > 0, "IA");
        uint256 greenWallWinCount = greenWallWinIds[_account].length;
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < greenWallWinCount, "OOR");
        uint256 limit = _limit;
        if (end > greenWallWinCount) {
            end = greenWallWinCount;
            limit = greenWallWinCount % _limit;
        }

        GreenWallWins[] memory myGreenWallWins = new GreenWallWins[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = start; i < end; i++) {
            uint256 hId = greenWallWinIds[_account][i];
            myGreenWallWins[currentIndex] = greenWallWinsMap[hId];
            currentIndex += 1;
        }
        return myGreenWallWins;
    }

    function getWinningHistoryCount(address _account) external view returns (uint256) {
        return greenWallWinIds[_account].length;
    }

    receive() external payable {}
}