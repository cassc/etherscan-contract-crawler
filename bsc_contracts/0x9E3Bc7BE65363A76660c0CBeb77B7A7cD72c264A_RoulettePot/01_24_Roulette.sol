/**
 *Submitted for verification at Etherscan.io on 2022-04-18
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '../interfaces/IPancakePair.sol';
import '../interfaces/IPancakeFactory.sol';
import '../interfaces/IPancakeRouter.sol';
import '../interfaces/IBNBP.sol';
import '../interfaces/IPRC20.sol';
import '../interfaces/IVRFConsumer.sol';
import '../interfaces/IPegSwap.sol';
import '../interfaces/IPotContract.sol';

contract RoulettePot is Ownable, ReentrancyGuard {
    uint256 public casinoCount;
    uint256 public betIds;
    uint256 totalBetSum;
    mapping(uint256 => Casino) public tokenIdToCasino;
    mapping(address => bool) public isStable;
    mapping(address => mapping(uint256 => BetInfo)) public userLastBetInfo;

    address public casinoNFTAddress;
    address public BNBPAddress;
    address public consumerAddress;
    address public potAddress;

    address constant wbnbAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // testnet: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd, mainnet: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address constant busdAddr = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // testnet: 0x4608Ea31fA832ce7DCF56d78b5434b49830E91B1, mainnet: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    address constant pancakeFactoryAddr = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73; // testnet: 0x6725F303b657a9451d8BA641348b6761A6CC7a17, mainnet: 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
    address constant pancakeRouterAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1, mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address constant coordinatorAddr = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE; // testnet: 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f, mainnet: 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE
    address constant linkTokenAddr = 0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD; // testnet: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06, mainnet: 0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD
    address constant pegSwapAddr = 0x1FCc3B22955e76Ca48bF025f1A6993685975Bb9e;
    address constant link677TokenAddr = 0x404460C6A5EdE2D891e8297795264fDe62ADBB75;
    uint256 constant subscriptionId = 664; // testnet: 2102, mainnet: 664
    struct Casino {
        address tokenAddress;
        string tokenName;
        uint256 liquidity;
        uint256 initialMaxBet;
        uint256 maxBet;
        uint256 minBet;
        uint256 fee;
        int256 profit;
        uint256 lastSwapTime;
    }

    struct BetInfo {
        bool isPending;
        uint256 requestId;
        Bet[] bets;
        uint256 tokenPrice;
    }

    struct Bet {
        /* 5: number, 4: even, odd, 3: 18s, 2: 12s, 1: row, 0: black, red */
        uint8 betType;
        uint8 number;
        uint256 amount;
    }

    event RouletteSpinned(
        uint256 tokenId,
        uint256 betId,
        address player,
        uint256 nonce,
        uint256 totalAmount,
        uint256 rewardAmount,
        uint256 totalUSD,
        uint256 rewardUSD,
        uint256 maximumReward
    );
    event TransferFailed(uint256 tokenId, address to, uint256 amount);
    event TokenSwapFailed(uint256 tokenId, uint256 balance, string reason, uint256 timestamp);

    constructor(
        address nftAddr,
        address _BNBPAddress,
        address _consumerAddress,
        address _potAddress
    ) {
        casinoNFTAddress = nftAddr;
        BNBPAddress = _BNBPAddress;
        consumerAddress = _consumerAddress;
        potAddress = _potAddress;
    }

    modifier onlyCasinoOwner(uint256 tokenId) {
        require(IERC721(casinoNFTAddress).ownerOf(tokenId) == msg.sender, 'Not Casino Owner');
        _;
    }

    /**
     * @dev sets token is stable or not
     */
    function setTokenStable(address tokenAddr, bool _isStable) external onlyOwner {
        isStable[tokenAddr] = _isStable;
    }

    /**
     * @dev returns list of casinos minted
     */
    function getCasinoList()
        external
        view
        returns (
            Casino[] memory casinos,
            address[] memory owners,
            uint256[] memory prices
        )
    {
        casinos = new Casino[](casinoCount);
        owners = new address[](casinoCount);
        prices = new uint256[](casinoCount);
        IERC721 nftContract = IERC721(casinoNFTAddress);

        for (uint256 i = 1; i <= casinoCount; i++) {
            casinos[i - 1] = tokenIdToCasino[i];
            owners[i - 1] = nftContract.ownerOf(i);
            if (casinos[i - 1].tokenAddress == address(0)) {
                prices[i - 1] = getBNBPrice();
            } else {
                prices[i - 1] = getTokenUsdPrice(casinos[i - 1].tokenAddress);
            }
        }
    }

    /**
     * @dev adds a new casino
     */
    function addCasino(
        uint256 tokenId,
        address tokenAddress,
        string calldata tokenName,
        uint256 maxBet,
        uint256 minBet,
        uint256 fee
    ) external {
        require(msg.sender == casinoNFTAddress, 'Only casino nft contract can call');

        Casino storage newCasino = tokenIdToCasino[tokenId];
        newCasino.tokenAddress = tokenAddress;
        newCasino.tokenName = tokenName;
        newCasino.initialMaxBet = maxBet;
        newCasino.maxBet = maxBet;
        newCasino.minBet = minBet;
        newCasino.fee = fee;
        newCasino.liquidity = 0;

        casinoCount++;
    }

    /**
     * @dev set max bet limit for casino
     */
    function setMaxBet(uint256 tokenId, uint256 newMaxBet) external onlyCasinoOwner(tokenId) {
        Casino storage casinoInfo = tokenIdToCasino[tokenId];
        require(newMaxBet <= casinoInfo.initialMaxBet, "Can't exceed initial max bet");

        casinoInfo.maxBet = newMaxBet;
    }

    /**
     * @dev set min bet limit for casino
     */
    function setMinBet(uint256 tokenId, uint256 newMinBet) external onlyCasinoOwner(tokenId) {
        Casino storage casinoInfo = tokenIdToCasino[tokenId];
        require(newMinBet <= casinoInfo.maxBet, 'min >= max');
        require(newMinBet > 0, 'min = 0');

        casinoInfo.minBet = newMinBet;
    }

    /**
     * @dev returns maximum reward amount for given bets
     */
    function getMaximumReward(Bet[] memory bets) public pure returns (uint256) {
        uint256 maxReward;
        uint8[6] memory betRewards = [2, 3, 3, 2, 2, 36];

        for (uint256 i = 0; i < 37; i++) {
            uint256 reward;

            for (uint256 j = 0; j < bets.length; j++) {
                if (_isInBet(bets[j], i)) {
                    reward += bets[j].amount * betRewards[bets[j].betType];
                }
            }
            if (maxReward < reward) {
                maxReward = reward;
            }
        }
        return maxReward;
    }

    /**
     * @dev returns whbnb Bet `b` covers the `number` or not
     */
    function _isInBet(Bet memory b, uint256 number) public pure returns (bool) {
        require(b.betType <= 5, 'Invalid bet type');
        require(b.number <= 37, 'Invalid betting number');

        if (number == 0 || number == 37) {
            if (b.betType == 5) {
                return b.number == number;
            } else {
                return false;
            }
        }

        if (b.betType == 5) {
            return (b.number == number); /* bet on number */
        } else if (b.betType == 4) {
            if (b.number == 0) return (number % 2 == 0); /* bet on even */
            if (b.number == 1) return (number % 2 == 1); /* bet on odd */
        } else if (b.betType == 3) {
            if (b.number == 0) return (number <= 18); /* bet on low 18s */
            if (b.number == 1) return (number >= 19); /* bet on high 18s */
        } else if (b.betType == 2) {
            if (b.number == 0) return (number <= 12); /* bet on 1st dozen */
            if (b.number == 1) return (number > 12 && number <= 24); /* bet on 2nd dozen */
            if (b.number == 2) return (number > 24); /* bet on 3rd dozen */
        } else if (b.betType == 1) {
            if (b.number == 0) return (number % 3 == 0); /* bet on top row */
            if (b.number == 1) return (number % 3 == 1); /* bet on middle row */
            if (b.number == 2) return (number % 3 == 2); /* bet on bottom row */
        } else if (b.betType == 0) {
            if (b.number == 0) {
                /* bet on black */
                if (number <= 10 || (number >= 19 && number <= 28)) {
                    return (number % 2 == 0);
                } else {
                    return (number % 2 == 1);
                }
            } else {
                /* bet on red */
                if (number <= 10 || (number >= 19 && number <= 28)) {
                    return (number % 2 == 1);
                } else {
                    return (number % 2 == 0);
                }
            }
        }
        return false;
    }

    /**
     * @dev returns a nonce between 0 ~ 36
     */
    function _getRandomNumber() internal view returns (uint256) {
        uint256 diff = block.difficulty;
        bytes32 hash = blockhash(block.number - 1);
        uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp, diff, hash))) % 38;

        return number;
    }

    /**
     * @dev returns total bet amount
     */
    function _getTotalBetAmount(Bet[] memory bets) internal pure returns (uint256) {
        /* 5: number, 4: even, odd, 3: 18s, 2: 12s, 1: row, 0: black, red */
        uint256[5] memory betCount;
        uint256 totalBetAmount;
        for (uint256 i = 0; i < bets.length; i++) {
            totalBetAmount += bets[i].amount;
            if (bets[i].betType < 5) {
                betCount[bets[i].betType]++;
            }
        }
        require(
            betCount[0] < 2 && betCount[1] < 3 && betCount[2] < 3 && betCount[3] < 2 && betCount[4] < 2,
            'Bet Restriction'
        );

        return totalBetAmount;
    }

    /**
     * @dev generate a random number and calculate total rewards
     */
    function _spinWheel(Bet[] memory bets, uint256 nonce) internal pure returns (uint256, uint256) {
        uint256 totalReward;
        uint8[6] memory betRewards = [2, 3, 3, 2, 2, 36];

        for (uint256 i = 0; i < bets.length; i++) {
            if (_isInBet(bets[i], nonce)) {
                totalReward += betRewards[bets[i].betType] * bets[i].amount;
            }
        }
        return (nonce, totalReward);
    }

    /**
     * @dev initialize user bet info to pending status
     */
    function _initializeBetInfo(
        uint256 tokenId,
        uint256 requestId,
        Bet[] calldata bets,
        uint256 tokenPrice
    ) internal {
        BetInfo storage info = userLastBetInfo[msg.sender][tokenId];

        delete info.bets;
        info.requestId = requestId;
        info.isPending = true;
        info.tokenPrice = tokenPrice;
        for (uint256 i = 0; i < bets.length; i++) {
            Bet memory bet = bets[i];
            info.bets.push(bet);
        }
    }

    /**
     * @dev initialize bet and request nonce to VRF
     *
     * NOTE this function only accepts erc20 tokens
     * @param tokenId tokenId of the Casino
     * @param bets array of bets
     */
    function initializeTokenBet(uint256 tokenId, Bet[] calldata bets) external nonReentrant returns (uint256) {
        require(userLastBetInfo[msg.sender][tokenId].isPending == false, 'Bet not finished');

        Casino storage casinoInfo = tokenIdToCasino[tokenId];
        require(casinoInfo.tokenAddress != address(0), "This casino doesn't support tokens");

        IPRC20 token = IPRC20(casinoInfo.tokenAddress);
        uint256 approvedAmount = token.allowance(msg.sender, address(this));
        uint256 totalBetAmount = _getTotalBetAmount(bets);
        uint256 maxReward = getMaximumReward(bets);
        uint256 tokenPrice = isStable[casinoInfo.tokenAddress] ? 10**18 : getTokenUsdPrice(casinoInfo.tokenAddress);
        uint256 totalUSDValue = (totalBetAmount * tokenPrice) / 10**token.decimals();

        require(token.balanceOf(msg.sender) >= totalBetAmount, 'Not enough balance');
        require(totalBetAmount <= approvedAmount, 'Not enough allowance');
        require(maxReward <= casinoInfo.liquidity + totalBetAmount, 'Not enough liquidity');
        require(totalUSDValue <= casinoInfo.maxBet * 10**18, "Can't exceed max bet limit");
        require(totalUSDValue >= casinoInfo.minBet * 10**18, "Can't be lower than min bet limit");

        token.transferFrom(msg.sender, address(this), totalBetAmount);

        IVRFv2Consumer vrfConsumer = IVRFv2Consumer(consumerAddress);
        uint256 requestId = vrfConsumer.requestRandomWords();
        _initializeBetInfo(tokenId, requestId, bets, tokenPrice);
        return requestId;
    }

    /**
     * @dev initialize bet and request nonce to VRF
     *
     * NOTE this function only accepts bnb
     * @param tokenId tokenId of the Casino
     * @param bets array of bets
     */
    function initializeEthBet(uint256 tokenId, Bet[] calldata bets) external payable returns (uint256) {
        BetInfo storage info = userLastBetInfo[msg.sender][tokenId];
        require(info.isPending == false, 'Bet not finished');

        Casino storage casinoInfo = tokenIdToCasino[tokenId];
        require(casinoInfo.tokenAddress == address(0), 'This casino only support bnb');

        IPRC20 busdToken = IPRC20(busdAddr);
        uint256 totalBetAmount = _getTotalBetAmount(bets);
        uint256 maxReward = getMaximumReward(bets);
        uint256 bnbPrice = getBNBPrice();
        uint256 totalUSDValue = (bnbPrice * totalBetAmount) / 10**18;

        require(msg.value == totalBetAmount, 'Not correct bet amount');
        require(maxReward <= casinoInfo.liquidity + totalBetAmount, 'Not enough liquidity');
        require(totalUSDValue <= casinoInfo.maxBet * 10**busdToken.decimals(), "Can't exceed max bet limit");
        require(totalUSDValue >= casinoInfo.minBet * 10**busdToken.decimals(), "Can't be lower than min bet limit");

        IVRFv2Consumer vrfConsumer = IVRFv2Consumer(consumerAddress);
        uint256 requestId = vrfConsumer.requestRandomWords();
        _initializeBetInfo(tokenId, requestId, bets, bnbPrice);
        return requestId;
    }

    /**
     * @dev retreive nonce and spin the wheel, return reward if user wins
     *
     * @param tokenId tokenId of the Casino
     */
    function finishBet(uint256 tokenId) external nonReentrant {
        BetInfo storage info = userLastBetInfo[msg.sender][tokenId];
        require(info.isPending == true, 'Bet not pending');

        (bool fulfilled, uint256[] memory nonces) = IVRFv2Consumer(consumerAddress).getRequestStatus(info.requestId);
        require(fulfilled == true, 'not yet fulfilled');

        Casino storage casinoInfo = tokenIdToCasino[tokenId];
        uint256 decimal = casinoInfo.tokenAddress == address(0) ? 18 : IPRC20(casinoInfo.tokenAddress).decimals();
        (uint256 nonce, uint256 totalReward) = _spinWheel(info.bets, nonces[0] % 38);
        uint256 totalBetAmount = _getTotalBetAmount(info.bets);
        uint256 maxReward = getMaximumReward(info.bets);
        uint256 totalUSDValue = (totalBetAmount * info.tokenPrice) / 10**decimal;
        uint256 totalRewardUSD = (totalReward * info.tokenPrice) / 10**decimal;

        betIds++;
        totalBetSum += totalBetAmount;
        info.isPending = false;

        if (totalReward > 0) {
            if (casinoInfo.tokenAddress != address(0)) {
                IERC20(casinoInfo.tokenAddress).transfer(msg.sender, totalReward);
            } else {
                bool sent = payable(msg.sender).send(totalReward);
                require(sent, 'send fail');
            }
        }
        casinoInfo.liquidity = casinoInfo.liquidity + totalBetAmount - totalReward;
        casinoInfo.profit = casinoInfo.profit + int256(totalBetAmount) - int256(totalReward);

        emit RouletteSpinned(
            tokenId,
            betIds,
            msg.sender,
            nonce,
            totalBetAmount,
            totalReward,
            totalUSDValue,
            totalRewardUSD,
            maxReward
        );
    }

    /**
     * @dev returns VRF nonce status for bet
     */
    function getBetResult(uint256 tokenId, address user) public view returns (bool, uint256) {
        BetInfo storage info = userLastBetInfo[user][tokenId];
        IVRFv2Consumer consumer = IVRFv2Consumer(consumerAddress);
        (bool fulfilled, uint256[] memory nonces) = consumer.getRequestStatus(info.requestId);
        return (fulfilled, nonces[0]);
    }

    /**
     * @dev adds liquidity to the casino pool
     * NOTE this is only for casinos that uses tokens
     */
    function addLiquidtyWithTokens(uint256 tokenId, uint256 amount) external onlyCasinoOwner(tokenId) {
        Casino storage casinoInfo = tokenIdToCasino[tokenId];
        require(casinoInfo.tokenAddress != address(0), "This casino doesn't support tokens");

        IERC20 token = IERC20(casinoInfo.tokenAddress);
        uint256 approvedAmount = token.allowance(msg.sender, address(this));

        require(approvedAmount >= amount, 'Not enough allowance');
        token.transferFrom(msg.sender, address(this), amount);
        casinoInfo.liquidity += amount;
    }

    /**
     * @dev adds liquidity to the casino pool
     * NOTE this is only for casinos that uses bnb
     */
    function addLiquidtyWithEth(uint256 tokenId, uint256 amount) external payable onlyCasinoOwner(tokenId) {
        Casino storage casinoInfo = tokenIdToCasino[tokenId];

        require(casinoInfo.tokenAddress == address(0), "This casino doesn't supports bnb");
        require(amount == msg.value, 'Not correct deposit balance');

        casinoInfo.liquidity += msg.value;
    }

    /**
     * @dev removes liquidity from the casino pool
     */
    function removeLiquidty(uint256 tokenId, uint256 amount) external onlyCasinoOwner(tokenId) {
        Casino storage casinoInfo = tokenIdToCasino[tokenId];
        require(
            int256(casinoInfo.liquidity - amount) >= casinoInfo.profit,
            'Cannot withdraw profit before it is fee taken'
        );
        require(casinoInfo.liquidity >= amount, 'Not enough liquidity');
        casinoInfo.liquidity -= amount;
        if (casinoInfo.tokenAddress != address(0)) {
            IERC20 token = IERC20(casinoInfo.tokenAddress);
            token.transfer(msg.sender, amount);
        } else {
            bool sent = payable(msg.sender).send(amount);
            if (!sent) {
                casinoInfo.liquidity += amount;
            }
        }
    }

    /**
     * @dev update casino's current profit and liquidity.
     */
    function _updateProfitInfo(
        uint256 tokenId,
        uint256 fee,
        uint256 calculatedProfit
    ) internal {
        Casino storage casinoInfo = tokenIdToCasino[tokenId];
        casinoInfo.liquidity -= fee;
        casinoInfo.profit -= int256(calculatedProfit);
        casinoInfo.lastSwapTime = block.timestamp;
    }

    /**
     * @dev get usd price of a token by usdt
     */
    function getTokenUsdPrice(address tokenAddress) public view returns (uint256) {
        if (isStable[tokenAddress]) return 10**18;

        IPancakeRouter02 router = IPancakeRouter02(pancakeRouterAddr);
        IPancakeFactory factory = IPancakeFactory(pancakeFactoryAddr);
        IPRC20 token = IPRC20(tokenAddress);
        address Token_BUSD_Pair = factory.getPair(tokenAddress, busdAddr);

        if (Token_BUSD_Pair != address(0)) {
            address[] memory path2 = new address[](2);
            path2[0] = tokenAddress;
            path2[1] = busdAddr;
            uint256[] memory amounts2 = router.getAmountsOut(10**token.decimals(), path2);
            return amounts2[1];
        }

        address BNB_Token_Pair = factory.getPair(tokenAddress, wbnbAddr);
        address BNB_BUSD_Pair = factory.getPair(wbnbAddr, busdAddr);

        require(BNB_Token_Pair != address(0), 'No pair between token and BNB');
        require(BNB_BUSD_Pair != address(0), 'No pair between BUSD and BNB');

        address[] memory path3 = new address[](3);
        path3[0] = tokenAddress;
        path3[1] = router.WETH();
        path3[2] = busdAddr;
        uint256[] memory amounts3 = router.getAmountsOut(10**token.decimals(), path3);

        return amounts3[2];
    }

    /**
     * @dev Gets current pulse price in comparison with BNB and USDT
     */
    function getBNBPrice() public view returns (uint256 price) {
        IPancakeRouter02 router = IPancakeRouter02(pancakeRouterAddr);
        IPancakeFactory factory = IPancakeFactory(pancakeFactoryAddr);
        IPancakePair pair = IPancakePair(factory.getPair(router.WETH(), busdAddr));
        IPRC20 busdToken = IPRC20(busdAddr);

        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        if (pair.token0() != busdAddr) {
            price = (Res1 * (10**busdToken.decimals())) / Res0;
        } else {
            price = (Res0 * (10**busdToken.decimals())) / Res1;
        }
    }

    /**
     * @dev swaps profit fees of casinos into BNBP
     */
    function swapProfitFees() external {
        IPancakeRouter02 router = IPancakeRouter02(pancakeRouterAddr);
        IPancakeFactory factory = IPancakeFactory(pancakeFactoryAddr);
        address BNBP_pair = factory.getPair(router.WETH(), BNBPAddress);

        require(BNBP_pair != address(0), 'No pair between BNBP and BNB');

        address[] memory path = new address[](2);
        uint256 totalBNBFee;
        uint256 BNBPPool = 0;

        // Swap each token to BNB
        for (uint256 i = 1; i <= casinoCount; i++) {
            Casino memory casinoInfo = tokenIdToCasino[i];
            IERC20 token = IERC20(casinoInfo.tokenAddress);

            if (casinoInfo.profit <= 0 || casinoInfo.liquidity == 0) continue;

            uint256 availableProfit = uint256(casinoInfo.profit);
            if (casinoInfo.liquidity < availableProfit) {
                availableProfit = casinoInfo.liquidity;
            }

            uint256 balance = (availableProfit * casinoInfo.fee) / 100;

            if (casinoInfo.tokenAddress == address(0)) {
                totalBNBFee += uint256(balance);
                _updateProfitInfo(i, uint256(balance), availableProfit);
                continue;
            }
            if (casinoInfo.tokenAddress == BNBPAddress) {
                BNBPPool += uint256(balance);
                _updateProfitInfo(i, uint256(balance), availableProfit);
                continue;
            }

            path[0] = casinoInfo.tokenAddress;
            path[1] = router.WETH();

            token.approve(address(router), balance);
            try router.swapExactTokensForETH(balance, 0, path, address(this), block.timestamp) returns (
                uint256[] memory swappedAmounts
            ) {
                _updateProfitInfo(i, uint256(swappedAmounts[0]), availableProfit);
                totalBNBFee += swappedAmounts[1];
            } catch Error(string memory reason) {
                emit TokenSwapFailed(i, balance, reason, block.timestamp);
            } catch (bytes memory reason) {
                emit TokenSwapFailed(i, balance, string(reason), block.timestamp);
            }
        }

        if (totalBNBFee > 0) {
            // Convert to LINK
            path[0] = router.WETH();
            path[1] = linkTokenAddr;

            uint256[] memory amounts = router.swapExactETHForTokens{ value: totalBNBFee / 2 }(
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 linkAmount = amounts[1];
            IERC20(linkTokenAddr).approve(pegSwapAddr, linkAmount);
            PegSwap(pegSwapAddr).swap(linkAmount, linkTokenAddr, link677TokenAddr);

            // Fund VRF subscription
            LinkTokenInterface(link677TokenAddr).transferAndCall(
                coordinatorAddr,
                linkAmount,
                abi.encode(subscriptionId)
            );

            // path[0] = router.WETH();
            path[1] = BNBPAddress;

            amounts = router.swapExactETHForTokens{ value: totalBNBFee - amounts[0] }(
                0,
                path,
                address(this),
                block.timestamp
            );
            BNBPPool += amounts[1];

            // add BNBP to tokenomics pool
            IERC20(BNBPAddress).approve(potAddress, BNBPPool);
            IPotLottery(potAddress).addAdminTokenValue(BNBPPool);
        }
    }

    receive() external payable {}
}