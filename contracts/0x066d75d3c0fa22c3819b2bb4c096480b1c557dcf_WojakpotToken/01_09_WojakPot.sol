// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

///@dev uniswap Factory interface to call createPair in constructor
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

///@dev uniswap router interface to call swapTokensForETH and getting WETH, factory value
interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

///@dev wrapper to handle the rewardPool
///@notice rewardFundHandler is a wrapper smartcontract to manage reward pool funds,
/// 95% of funds will be sent to winner and 5% to fee wallet to keep the 
/// chainlink vrf working. (5% fee is deducted in eth, which owner can use 
/// to buy LINK token and fill the Subscription). 

contract rewardFundHanlder is Ownable {
     uint256 public totalDistributed; //keep track of total rewards distributed till date
     address public wallet = address(0xa9a72d15842A239B0D2fD62009239D77abCb7857);  // fee wallet
     

  ///@dev send rewards to the winner
  ///@param winner: address of winner, which will be set by token contract 
  /// itself, as per chainlink VRF outcome.
  function sendRewardToWinner (address winner) external onlyOwner {
    uint256 balance = address(this).balance;
    uint256 winnerPart = (balance * 95) /100; //95% goes to winner
    uint256 chainlinkFee = balance - winnerPart; // 5% will be used to cover up chainlink VRF gas
    (bool sent,) = winner.call{value: winnerPart} ("");
    require (sent, "reward transfer failed");
    (bool cFee,) = wallet.call{value: chainlinkFee}("");
    require(cFee, "chainlink fee transfer failed");
    totalDistributed += balance;
  }

  ///@dev update the fee wallet to new one
  ///@param _newWallet: new wallet address to receive the fees.
  function updateWallet (address _newWallet) external onlyOwner {
    require (_newWallet != address(0), "can't be a zero address");
    wallet = _newWallet;
  }

  

  ///@notice receive any external eth
  receive() external payable {}

}

///@title WojakpotToken
///@notice An ERC20 token implementing buy/sell fee and reward mechanism for traders
///@dev contract uses Chainlink VRF V2 to generate randomness 
///@dev Chainlink VRF V2 -- 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
///@dev make sure owner has set subscription id and it's live. 
///@dev subscription should be funded enough to call pick winner successfully

contract WojakpotToken is ERC20, Ownable, VRFConsumerBaseV2, ReentrancyGuard {
                
                ///dex and wallet related variables//
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0x000000000000000000000000000000000000dEaD);
            
    bool private swapping;
    address public marketingAndTeamWallet;
    rewardFundHanlder private rewardFundManager;
    address public rewardHandlingWrapper;

    uint256 public swapTokensAtAmount;
    bool public tradingActive = false;
              
              ///fees///
    uint256 public marketingAndTeamFeeBuy;
    uint256 public rewardFeeBuy;

    uint256 public marketingAndTeamFeeSell;
    uint256 public rewardFeeSell;

    uint256 private totalBuyFee;
    uint256 private totalSellFee;


     ///reward related variables///
    uint256 public lastDistributed;
    uint256 public minHoldingAmount;
    uint256 private requestID;
    uint256 public INTERVAL = 86400 seconds; // 1 Day
    


           /// winners, users and recent winner variables///
    address [] public winners;
    address[] public _participants;
    address public recentWinner;
    

               ///Chainlink vrf v2 setup///
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    

                ///mappings///   

    mapping(address => bool) private _isExcludedFromFees; // manage excluding of address from fee
    mapping(address => bool) public _isExcludedFromRewardPool; // managing the excluding of user from reward pool
    mapping(address => bool) public isEligible; // true if user is in list, false if not
    mapping(address => uint256) public participantIndex; //index of user in list
    mapping(address => bool) public marketMakerPairs; // pairs for token

    
               ///Events///

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event marketingAndTeamWalletsUpdated(
        address indexed marketingAndTeamWallet
    );

    event WinnerPicked(address indexed user, uint256 ethAmount);

    event NewPairAdded (address indexed newPair);

    event TokensClaimed (address indexed token, uint256 amount);
    event EthClaimed (address indexed wallet, uint256 amount);
    event TradingEnabled (uint256 indexed startTime);
    event SwapAmountUpdated(uint256 indexed amount);
    event BuyFeesUpdated (uint256 indexed marketingAndTeamFee, uint256 indexed rewardPoolFee);
    event SellFeesUpdated (uint256 indexed marketingAndTeamFee, uint256 indexed rewardPoolFee);
    event RewardFeeWalletUpdated (address indexed feeWallet);
    event IntervalUpdated(uint256 indexed newInterval);

    constructor(uint64 _subscriptionID) ERC20("Wojakpot", "WJP") VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909) {
                          

                           ///VRF setup///
        i_vrfCoordinator = VRFCoordinatorV2Interface(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
        i_keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; //200 gwei keyhash
        i_subscriptionId = _subscriptionID; // you can create one on https://vrf.chain.link/
        i_callbackGasLimit = 300000;

                           ///Uniswap Setup///
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
           0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D  // Uniswap V2 Router
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        marketMakerPairs[address(uniswapV2Pair)] = true;
        rewardFundManager = new rewardFundHanlder();  
        rewardHandlingWrapper = address(rewardFundManager);  

                        ///Token Config///
        uint256 totalSupply = 1000000000 * 1e9; // 1 billion supply

        swapTokensAtAmount = 100000 * 1e9; //swap tax for eth when collected tokens are 100000 or more
        minHoldingAmount = 100000 * 1e9; // 100000 tokens to become eligible for reward pool

        marketingAndTeamFeeSell = 10; //1%
        rewardFeeSell = 20; // 2%
        totalSellFee = marketingAndTeamFeeSell + rewardFeeSell;

        marketingAndTeamFeeBuy = 10; // 1%
        rewardFeeBuy = 20; //2%

        totalBuyFee = marketingAndTeamFeeBuy + rewardFeeBuy;

        marketingAndTeamWallet = address(0x6B9D2d366FAEC27012cB650a6Ff9d58603Fc261E); // marketing wallet


        // exclude from paying fees
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[marketingAndTeamWallet] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[deadAddress] = true;
       

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    ///@dev  enabled trading, once enabled can't be reversed
    function enableTrading() external onlyOwner {
        require(!tradingActive, "trading is already live");
        tradingActive = true;
        lastDistributed = block.timestamp;
        emit TradingEnabled(lastDistributed);
    }


    ///@dev change the minimum amount of tokens to sell from fees
    ///@param newAmount: new amount for swapping tokens to eth
    /// requirements --
    /// must be greator than equal to 1000 tokens and less
    /// than 0.5% of the supply
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= 1000 * 1e9,
            "Swap amount cannot be lower than 1000 tokens."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        emit SwapAmountUpdated (newAmount);
        return true;
        
    }

    ///@dev update the fees for sell tax
    ///@param marketingAndTeam: set new marketingAndTeam fees for sell
    ///@param rewardPool: set new reward fees for sell
    ///@notice As divisor is 1000 for calculation, so 5 means 0.5% and 10 means 1%
    function updateSellFees(
        uint256 marketingAndTeam,
        uint256 rewardPool
    ) external onlyOwner {
        marketingAndTeamFeeSell = marketingAndTeam;
        rewardFeeSell = rewardPool;
        totalSellFee = marketingAndTeamFeeSell + rewardFeeSell;
        require(totalSellFee >= 10 && totalSellFee <= 50, "Sell tax too high");
        emit SellFeesUpdated(marketingAndTeam, rewardPool);
    }
    

    ///@dev update the fees for buy tax
    ///@param marketingAndTeam: set new marketingAndTeam fees for buy
    ///@param rewardPool: set new reward fees for buy
    ///@notice As divisor is 1000 for calculation, so 5 means 0.5% and 10 means 1%
     function updateBuyFees(
        uint256 marketingAndTeam,
        uint256 rewardPool
    ) external onlyOwner {
        marketingAndTeamFeeBuy = marketingAndTeam;
        rewardFeeBuy = rewardPool;
        totalBuyFee = marketingAndTeamFeeBuy + rewardFeeBuy;
        require( totalBuyFee >= 10 && totalBuyFee <= 50, "Buy tax too high");
        emit BuyFeesUpdated(marketingAndTeam, rewardPool);
    }

    ///@dev manage the users address for having fees or not
    ///@param account: user address which will be excluded or included
    ///@param excluded: boolean value, true means excluded from fees, false means included in fees 
    function excludeFromFees(address account, bool excluded) external onlyOwner {
       require(account != address(0), "zero address not allowed"); 
       if (excluded) {
           require (!_isExcludedFromFees[account],"account is already excluded from fees");
        }
       if (!excluded) {
           require(_isExcludedFromFees[account],"account is already included in fees");
        }
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, _isExcludedFromFees[account]);
    }

    ///@dev update marketing wallet address
    ///@param newWallet: new address to receive marketing fess
    function updateMarketingWallet(address newWallet)
        external
        onlyOwner
    {
       require(newWallet != address(0), "address zero not allowed");
       require (!isContract(newWallet),"Contract not allowed");
        marketingAndTeamWallet = newWallet;
         emit marketingAndTeamWalletsUpdated(newWallet);
    }

    ///@notice check if a address is contract or not
    function isContract(address addr) private view returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
       return size > 0;
     }

    ///@dev udpate the fee wallet to cover the chainlink fee
    ///@param wallet: new wallet to receive 5% eth when winner is picked
    function updateFeeWallet (address wallet) external onlyOwner {
        require(wallet != address(0), "address zero not allowed");
        require (!isContract(wallet),"contract not allowed");
        rewardFundManager.updateWallet(wallet);
        emit RewardFeeWalletUpdated (wallet);
    }


    ///@dev claim any tokens from token contract
    ///@param token: token address to be rescued.
    ///Requirements: 
    ///Can't claim native tokens
    function claimStuckedERC20(address token) external onlyOwner {
        require (token != address(this), "can't take out native token");
        uint256 amount = IERC20(token).balanceOf(address(this));
        if(amount > 0){
        IERC20(token).transfer(owner(), amount);
        emit TokensClaimed(token, amount);
        }
    }

    ///@dev claim any dust or external ether from the token contract
    function claimETH () external onlyOwner {
        uint256 amount = address(this).balance;
     (bool sent,)= owner().call{value: amount}("");
     require (sent, "ETH transfer failed");
     emit EthClaimed(owner(), amount);
    }
    
    

    ///@notice Returns if an account is excluded from fees/limits or not
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    ///@dev add or remove new pairs for token
    ///@param newPair: new pair address to be added or removed
    ///@param value: true to add, false to remove.
    /// Requirements --
    /// can't remove the main pair.
    function manageMarketMakerPair (address newPair, bool value) external onlyOwner {
        require (newPair != address(uniswapV2Pair), "can't remove main pair");
        marketMakerPairs[newPair] = value;
        if(value == true) {
            emit NewPairAdded(newPair);
        }
    }

    ///@notice transfer function to determine if it's a buy or sell
    /// or just a transfer. and implements maxWallet, maxTx accordingly.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0x000000000000000000000000000000000000dEaD) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

            }


        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            marketMakerPairs[to] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (marketMakerPairs[to] && totalSellFee > 0) {
                fees = (amount * totalSellFee) / 1000;
            }
            // on buy
            if (marketMakerPairs[from] && totalBuyFee > 0) {
                fees = (amount * totalBuyFee) / 1000;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }
        
        

        super._transfer(from, to, amount);

                             /// adding and removing participants for reward Pool logic
         if (!_isExcludedFromRewardPool[from] && balanceOf(from) < minHoldingAmount && isEligible[from]){ 
            removeholderFromList(from);
             }
             
         if (!_isExcludedFromRewardPool[to] && balanceOf(to) >= minHoldingAmount && !isEligible[to] && !marketMakerPairs[to] && to!=deadAddress && to!= address(0)){ 
            addHolderToList(to); 
            }
    }

      ///@dev pick winner, can be called by anyone, chainlink automation
      /// requirements --
      /// rewardPool balance  should be greator than 0.
      ///check if time b/w last reward distribution and now is more than INTERVAL, pickWinner
      function pickWinner () public nonReentrant{
        require (address(rewardFundManager).balance > 0, "reward pool don't have enough eth");
        require (block.timestamp - lastDistributed > INTERVAL, "Enough time has not been passed yet");
        uint256 reward = rewardHandlingWrapper.balance;
        _pickWinner();
         lastDistributed = block.timestamp;
         address winner = recentWinner;
         emit WinnerPicked(winner, reward);
         
      }

                       
                       ///                       ///
                      ///   INTERNAL FUNCTIONS  ///  
                     ///                       ///

    ///@notice request  chainlink coordinator for randomness
    function _pickWinner () internal {
        requestID = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId, // contract that will fund subscription requests
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    ///@notice value returned by chainlink coordinator is used to decided the winner
    /// and winner got paid.
     function fulfillRandomWords(
        uint256, /*request_id */
        uint256[] memory randomWords
    ) internal override {
        uint256 indexWinner = randomWords[0] % _participants.length;
        address recentWinnerChoosen = _participants[indexWinner];
        recentWinner = recentWinnerChoosen;
        rewardFundManager.sendRewardToWinner(recentWinner);
        
    }

    
     function addHolderToList(address holder) internal {
        participantIndex[holder] = _participants.length;
        _participants.push(holder);
        isEligible[holder] = true;
    }

    function removeholderFromList(address holder) internal {
        _participants[participantIndex[holder]] = _participants[_participants.length-1];
        participantIndex[_participants[_participants.length-1]] = participantIndex[holder];
        _participants.pop();
        isEligible[holder] = false;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

     /// manage the swap the tax tokens for eth and send to marketing wallet, rewardPool
     /// as per there share.
    function swapBack() public {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }
        uint256 oldBalance = address(this).balance;
        swapTokensForETH(contractBalance);
        uint256 newBalance = address(this).balance - oldBalance;
        uint256 marketingAndTeamShare = (newBalance * (marketingAndTeamFeeBuy + marketingAndTeamFeeSell)) / (totalBuyFee+totalSellFee);
        uint256 rewardShare = newBalance - marketingAndTeamShare;
        
        (bool success,) = marketingAndTeamWallet.call{value: marketingAndTeamShare}("");
        (bool success1,) = rewardHandlingWrapper.call{value: rewardShare}("");
        require (success, "eth to marketing wallet failed");
        require (success1, "eth to reward pool failed");
       


    }

    ///@notice returns total eth distributed till date (it includes fees as well)
    function totalDistributedTillDate () public view returns (uint256) {
        return rewardFundManager.totalDistributed();
    }
    
    ///@dev set minimum time interval b/w picking winner again
    ///@param newInterval: input in days, 1 means 1 days
    ///requirements --
    /// value should be b/w 1 and 30.
    function setInterval (uint256 newInterval) external onlyOwner {
        require (newInterval > 1 seconds && newInterval <= 2592000 seconds, "interval should be b/w 1 sec to 30 days");
        INTERVAL = newInterval * 1 seconds;
        emit IntervalUpdated (newInterval);
    }


}