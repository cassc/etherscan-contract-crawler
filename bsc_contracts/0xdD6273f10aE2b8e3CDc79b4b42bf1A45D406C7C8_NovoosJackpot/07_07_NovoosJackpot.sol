// SPDX-License-Identifier: MIT

/*
 * This contract and all other contracts, inclusive of dApps and any other platform is developed and maintained by Novoos
 * Novoos Ecosystem
 * Telegram: https://t.me/novoosecosystem
 * Website: https://novoos.net
 * Github: https://github.com/Novoos
 * 
 * The NAC follows strict recommendations made by OpenZeppelin, this assists in minimizing risk because the libraries of the NAC smart contracts have already been tested against vulnerabilities, bugs
 * and security issues and therefore includes the most used implementations of ERC standards. 
 *
 * This is the $NOVO Jackpots contract
 * 
███╗░░██╗░█████╗░██╗░░░██╗░█████╗░░█████╗░░██████╗
████╗░██║██╔══██╗██║░░░██║██╔══██╗██╔══██╗██╔════╝
██╔██╗██║██║░░██║╚██╗░██╔╝██║░░██║██║░░██║╚█████╗░
██║╚████║██║░░██║░╚████╔╝░██║░░██║██║░░██║░╚═══██╗
██║░╚███║╚█████╔╝░░╚██╔╝░░╚█████╔╝╚█████╔╝██████╔╝
╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░╚═════╝░

███████╗░█████╗░░█████╗░░██████╗██╗░░░██╗░██████╗████████╗███████╗███╗░░░███╗
██╔════╝██╔══██╗██╔══██╗██╔════╝╚██╗░██╔╝██╔════╝╚══██╔══╝██╔════╝████╗░████║
█████╗░░██║░░╚═╝██║░░██║╚█████╗░░╚████╔╝░╚█████╗░░░░██║░░░█████╗░░██╔████╔██║
██╔══╝░░██║░░██╗██║░░██║░╚═══██╗░░╚██╔╝░░░╚═══██╗░░░██║░░░██╔══╝░░██║╚██╔╝██║
███████╗╚█████╔╝╚█████╔╝██████╔╝░░░██║░░░██████╔╝░░░██║░░░███████╗██║░╚═╝░██║
╚══════╝░╚════╝░░╚════╝░╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝
 * 
 * Novoos Ecosystem implements upgradable contracts as they are more efficient and cost-effective inlcuding but not limited to:
 * Continuous Seamless Enhancements
 * No Relaunches
 * No migrations 
 * No Downtime
 * No Negative Effect for investors
 * 
 * This is the $NOVO Jackpots contract
 */

pragma solidity >=0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

error Failed_To_Transfer_Token_To_Bank();

contract NovoosJackpot is Initializable, KeeperCompatibleInterface {
    uint public jackpot;
    uint public startHourTime;
    uint public endHourTime;
    address payable public lastBuyer;
    address public prevLastBuyerWon;
    uint public prevLastBuyerWonTime;
    uint public prevLastBuyerWonAmount;
    address public owner;
    mapping(address => uint) public buyers; // For historical reasons
    address payable public bigBuyer;
    uint public bigBuyAmount;
    uint public bigBuyTime; // 00:00 UTC Start and End
    uint public jackpotLimit;
    address public _uniswapV2Router; // Constant
    address public _uniswapV2Pair; // Constant
    address public WBNB;
    address public tokenAddress;
    uint public bigBuyPercentage;
    uint public bigBuyMarketingPercentage; //10%
    uint public bigBuyInsurancePercentage; //5%

    uint public oneHourPercentage;
    uint public oneHourMarketingPercentage; //7%
    uint public oneHourInsurancePercentage; //5%

    uint public buyBackPercentage; //25%
    uint public marketingHitPercentage; //15%
    uint public developmentHitPercentage; // 10%

    address payable public marketingAddress;
    address payable public insuranceAndRewardAddress;
    address payable public developmentAddress;

    address public prevLastBigBuyerWon;
    uint public prevLastBigBuyerWonTime;
    uint public prevLastBigBuyerWonAmount;

    address public vrfOwner;

    fallback() external payable {}

    receive() external payable {}

    modifier limited() {
        require(owner == msg.sender , "Only owner can call this function");
        _;
    }

    modifier onlyToken() {
        require(
            tokenAddress == msg.sender ,
            "Only main token can call this function"
        );
        _;
    }

    modifier owners() {
        require(owner == msg.sender || vrfOwner == msg.sender , "Only owner can call this function");
        _;
    }



   function initialize(address owner_) public initializer {
        owner = owner_;
        bigBuyTime = 1677085200; // 00:00 UTC
        jackpotLimit = 10000000000000000000000;
        _uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _uniswapV2Pair = address(0x724CB49d6e7da65Daf3edBED40a45B4FE49D0D67);
        WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        tokenAddress = address(0x520f97696d4802956bE45006241b349ED0Efbd90);

        bigBuyPercentage = 2500; //25% (Subject to change for marketing and other related purposes)
        bigBuyMarketingPercentage = 1000; //10% (Subject to change for marketing and other related purposes)
        bigBuyInsurancePercentage = 500; //5% (Subject to change for marketing and other related purposes)

        oneHourPercentage = 2000; //20% (Subject to change for marketing and other related purposes)
        oneHourMarketingPercentage = 700; //7% (Subject to change for marketing and other related purposes)
        oneHourInsurancePercentage = 500; //5% (Subject to change for marketing and other related purposes)

        buyBackPercentage = 2500; //25% (Subject to change for marketing and other related purposes)
        marketingHitPercentage = 1500; //15% (Subject to change for marketing and other related purposes)
        developmentHitPercentage = 1000; // 10% (Subject to change for marketing and other related purposes)

        marketingAddress = payable(0xeEE5Eb161aBEa5afe61c6DE4b8231Db29acc3a7f);
        insuranceAndRewardAddress = payable(
            0x29B4920AA795899aeFB0514BC273bb040F4AcDD4
        );
        developmentAddress = payable(
            0x4c3935Cf504FB36e65015B7Af5bE0963C8Fb0339
        );
    }

    // Function triggered when a user buys $NOVO tokens
    function userBuy(address _buyer, uint amount) external onlyToken {
        startHourTime = block.timestamp;
        endHourTime = startHourTime + 1 hours;
        buyers[_buyer] = amount;
        lastBuyer = payable(_buyer);
        if (amount >= bigBuyAmount) {
            bigBuyAmount = amount;
            bigBuyer = payable(_buyer);
        }
        // if((address(this).balance+msg.value) >= jackpotLimit) {
        //     maxAccumulated();
        // }
    }

    function deposit() external payable onlyToken {
        if ((address(this).balance + msg.value) >= jackpotLimit) {
            // If jackpot target of $10,000 is reached (Subject to change for marketing and other related purposes)
            maxAccumulated();
        }
    }

    //Function Triggered if jackpot>=10k (Subject to change for marketing and other related purposes)
    function maxAccumulated() internal {
        //Function to buy $NOVO tokens for 25% of Jackpot (Subject to change for marketing and other related purposes)
        buyMainToken();

        (bool success, ) = marketingAddress.call{
            value: (address(this).balance * marketingHitPercentage) / 10000
        }("");

        require(success, "Failed to send marketing wallet");

        (bool success1, ) = developmentAddress.call{
            value: (address(this).balance * developmentHitPercentage) / 10000
        }("");

        require(success1, "Failed to send development wallet");
    }

    // The function to buy $NOVO tokens for 25% of the jackpot if jackpot is >= $10,000 (Subject to change for marketing and other related purposes)
    function buyMainToken() private {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = tokenAddress;

        // Process the swap And Tansfer the $NOVO token to the NovoPad Insurance & Reward Address
        IUniswapV2Router02(_uniswapV2Router)
            .swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: (address(this).balance * buyBackPercentage) / 10000
        }(0, path, insuranceAndRewardAddress, block.timestamp);

        // uint bal=IBEP20(tokenAddress).balanceOf(address(this));
        // (bool success)=IBEP20(tokenAddress).transfer(bankAddress, bal);
        // if(!success){
        //     revert Failed_To_Transfer_Token_To_Bank();
        // }
    }

    // This function triggers when 1 hour has passed since the last buy
    function sendOneHourReward() public owners {
        require(lastBuyer != address(0), "No Buyer yet!");
        require(block.timestamp >= endHourTime, "One hour is not passed yet!");
        uint _amount = (address(this).balance * oneHourPercentage) / 10000;
        address payable lB = lastBuyer;
        lastBuyer = payable(address(0));
        prevLastBuyerWon = lB;
        prevLastBuyerWonTime = block.timestamp;
        prevLastBuyerWonAmount = _amount;
        (bool success, ) = lB.call{value: _amount}("");
        require(success, "Failed to send lastBuyer");

        (bool success1, ) = insuranceAndRewardAddress.call{
            value: (address(this).balance * oneHourInsurancePercentage) / 10000
        }("");
        require(success1, "Failed to send insuranceAndRewardAddress");

        (bool success2, ) = marketingAddress.call{
            value: (address(this).balance * oneHourMarketingPercentage) / 10000
        }("");
        require(success2, "Failed to send marketingAddress");
    }

    // This function triggers when the time is 00:00 UTC
    function sendBigBuyReward() public owners {
        require(block.timestamp >= bigBuyTime, "Time is not 00:00 UTC yet!");
        uint _amount = (address(this).balance * bigBuyPercentage) / 10000;
        if (bigBuyer != address(0)) {
            prevLastBigBuyerWon = bigBuyer;
            bigBuyer = payable(address(0));
            (bool success, ) = prevLastBigBuyerWon.call{value: _amount}("");
            require(success, "Failed to send bigBuyer");
        } else {
            prevLastBigBuyerWon = marketingAddress;
            (bool success, ) = marketingAddress.call{value: _amount}("");
            require(success, "Failed to send marketingAddress");
        }

        (bool success1, ) = insuranceAndRewardAddress.call{
            value: (address(this).balance * bigBuyInsurancePercentage) / 10000
        }("");
        require(success1, "Failed to send insuranceAndRewardAddress");

        (bool success2, ) = marketingAddress.call{
            value: (address(this).balance * bigBuyMarketingPercentage) / 10000
        }("");
        require(success2, "Failed to send marketingAddress");

        prevLastBigBuyerWonTime = block.timestamp;
        prevLastBigBuyerWonAmount = _amount;
        bigBuyAmount = 0;
        bigBuyTime += 24 hours;

    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded =
            (block.timestamp >= bigBuyTime) || //24 hour check for the largest buy
            (block.timestamp >= endHourTime  && lastBuyer != address(0)); //Hourly check for the last buy
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //24 hour check  for the largest buy
        if (block.timestamp >= bigBuyTime) {
            sendBigBuyReward();
        }
        //Hourly check for the last buy
        if (block.timestamp >= endHourTime && lastBuyer != address(0)) {
            sendOneHourReward();
        }
    }

    function setBigBuyTime(uint _bigBuyTime) public limited {
        bigBuyTime = _bigBuyTime;
    }

    function setJackpotLimit(uint _jackpotLimit) public limited {
        jackpotLimit = _jackpotLimit;
    }

    function setRouterAndPairAddress(
        address uniswapV2Router,
        address uniswapV2Pair
    ) public limited {
        _uniswapV2Router = uniswapV2Router;
        _uniswapV2Pair = uniswapV2Pair;
    }

    function setTokenAddress(address _tokenAddress) public limited {
        tokenAddress = _tokenAddress;
    }

    function setBigBuyPercentage(uint _bigBuyPercentage) public limited {
        bigBuyPercentage = _bigBuyPercentage * 100;
    }

    function setBigBuyMarketingPercentage(
        uint _bigBuyMarketingPercentage
    ) public limited {
        bigBuyMarketingPercentage = _bigBuyMarketingPercentage * 100;
    }

    function setBigBuyInsurancePercentage(
        uint _bigBuyInsurancePercentage
    ) public limited {
        bigBuyInsurancePercentage = _bigBuyInsurancePercentage * 100;
    }

    function setOneHourPercentage(uint _oneHourPercentage) public limited {
        oneHourPercentage = _oneHourPercentage * 100;
    }

    function setOneHourMarketingPercentage(
        uint _oneHourMarketingPercentage
    ) public limited {
        oneHourMarketingPercentage = _oneHourMarketingPercentage * 100;
    }

    function setOneHourInsurancePercentage(
        uint _oneHourInsurancePercentage
    ) public limited {
        oneHourInsurancePercentage = _oneHourInsurancePercentage * 100;
    }

    function setBuyBackPercentage(uint _buyBackPercentage) public limited {
        buyBackPercentage = _buyBackPercentage * 100;
    }

    function setMarketingHitPercentage(
        uint _marketingHitPercentage
    ) public limited {
        marketingHitPercentage = _marketingHitPercentage * 100;
    }

    function setDevelopmentHitPercentage(
        uint _developmentHitPercentage
    ) public limited {
        developmentHitPercentage = _developmentHitPercentage * 100;
    }

    function setMarketingAddress(
        address payable _marketingAddress
    ) public limited {
        marketingAddress = _marketingAddress;
    }

    function setInsuranceAndRewardAddress(
        address payable _insuranceAndRewardAddress
    ) public limited {
        insuranceAndRewardAddress = _insuranceAndRewardAddress;
    }

    function setDevelopmentAddress(
        address payable _developmentAddress
    ) public limited {
        developmentAddress = _developmentAddress;
    }

    function setPairAddress(address _pairAddress) public limited {
        _uniswapV2Pair = _pairAddress;
    }

    function balance() public view returns (uint) {
        return address(this).balance;
    }

    function transferOwnership(address _owner) external limited {
        owner = _owner;
    }

    function setVrfOwnership(address _owner) external limited {
        vrfOwner = _owner;
    }
}