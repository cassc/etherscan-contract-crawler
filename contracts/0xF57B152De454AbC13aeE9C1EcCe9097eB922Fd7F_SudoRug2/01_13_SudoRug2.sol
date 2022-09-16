// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.16;

/*

   ▄████████ ███    █▄  ████████▄   ▄██████▄          ▄████████ ███    █▄     ▄██████▄  
  ███    ███ ███    ███ ███   ▀███ ███    ███        ███    ███ ███    ███   ███    ███ 
  ███    █▀  ███    ███ ███    ███ ███    ███        ███    ███ ███    ███   ███    █▀  
  ███        ███    ███ ███    ███ ███    ███       ▄███▄▄▄▄██▀ ███    ███  ▄███        
▀███████████ ███    ███ ███    ███ ███    ███      ▀▀███▀▀▀▀▀   ███    ███ ▀▀███ ████▄  
         ███ ███    ███ ███    ███ ███    ███      ▀███████████ ███    ███   ███    ███ 
   ▄█    ███ ███    ███ ███   ▄███ ███    ███        ███    ███ ███    ███   ███    ███ 
 ▄████████▀  ████████▀  ████████▀   ▀██████▀         ███    ███ ████████▀    ████████▀  
                                                     ███    ███                         

Self-rugging contract that sells its own tokens for ETH, buys NFTs with ETH, sends
NFTs to holders above a minimum eligibility (100k tokens), and sometimes even sells
its NFTs. 

The rugging mechanism can be manually triggered by anyone who wants to call the public 
function called PUSH_THE_RUG_BUTTON. To avoid dumping the token supply too quickly 
there are a few limits on calls to PUSH_THE_RUG_BUTTON:

1) You can only call it once every 60 minutes.
2) The max rug supply per call is restricted to be a small fraction of both the Uniswap pool
   and total token supply. 
3) There has to be at least one buy between two subsequent rug calls.

If the contract runs out of tokens then it creatively keeps on rugging, either by stealing
small amounts of tokens from holders or by minting tokens, selling them to Uniswap, and then 
burning them from Uniswap's supply (aka directly stealing ETH).

When NFTs get sent out, there's some bias towards holders with larger balances by picking 
three candidate winners and sending the NFT to one with the highest balance. This anti-sybil
mechanism is meant to strike a balance between uniform-above-threshold lotteries 
(which suffer from either having prohibitive thresholds or are vulnerable to multiple wallets) 
and lotteries where probability of winning is proportional to holdings, which tend to 
have a small concentrated set of winners.


Taxes:
    - None. If you're paying someone 12% to exit a position you should re-evaluate your life choices.  

Contract states:
    - AIRDROP: tokens sent to v1 holders and claimable by Based Ghoul holders
    - HONEYPOT: catch sniper bots for first few blocks
    - SLOWRUG: normal operations

Actions on each transaction:
    - BUY_NFT: buy a random NFT from sudoswap
    - SEND_NFT: send NFT from the treasury to a random eligible holder
    - SELL_NFT: sell NFT back to SudoGate if price has gone up 2x+
    - CHILL: do nothing 

Version history:
    v2:
        hopefully more sustainble upgrade to $sudorug, sells less of the 
        supply (and % of Uniswap pair) per rug call, can also sell NFTs
        back to SudoGate. 

    v1:  
        first version of $sudorug, less of the supply is set aside for rugging 
        compared with v0 $rug, it's sold off for ETH slowly, and the ETH is used
        to buy NFTs which are continuously distributed to random holders. in 
        practice the fixed rug supply was churned through in about 8h, buying and sending ~100
        NFTs. 

    v0: 
        designed to end in  1-2 weeks with a big dramatic distribution 
        of 99% of the token supply to random holders. fizzled quickly.

v2: the previous version of this token was called $rug (v1) and was 
v2 ($sudorug) is different in that l
*/

// common OZ interfaces
import {IERC20} from "IERC20.sol";
import {IERC20Metadata} from "IERC20Metadata.sol";

import {IERC721} from "IERC721.sol";
import {IERC721Metadata} from "IERC721Metadata.sol";
import {IERC721Receiver} from "IERC721Receiver.sol";

// sudoswap interfaces
import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";
import {LSSVMPair} from "LSSVMPair.sol";

// uniswap interfaces
import {IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router02} from "UniswapV2.sol";

// custom SudoRug/SudoGate interfaces
import {ISudoGatePoolSource} from "ISudoGatePoolSource.sol";
import {ISudoGate02} from "ISudoGate02.sol";



/*
States of the contract:
    AIRDROP:  
        no Uniswap liquidity yet, but deployer can send tokens around

    HONEYPOT: 
        anyone buying in the first few blocks after liquidity added gets rekt
    
    SLOWRUG: 
        normal operations: buy NFTs, send NFTs to random holders, 
        anyone can call PUSH_THE_RUG_BUTTON
*/
enum State {AIRDROP, HONEYPOT, SLOWRUG}


/* 
Random actions which can be taken on each turn:
    BUY_NFT:
        buy a random NFT from sudoswap
    
    SEND_NFT:
        send NFT from the treasury to a random eligible holder

    SELL_NFT: 
        if an NFT can be sold for a higher price than we bought it,
        sell it back to sudoswap
    
    CHILL:
        do nothing

Selling tokens for ETH is not included in this list because it does
done manually via a public function called PUSH_THE_RUG_BUTTON.
*/
enum Action { 
    BUY_NFT,
    SEND_NFT,
    SELL_NFT,
    CHILL
}



contract SudoRug2 is IERC20Metadata, IERC721Receiver {
    // splitting up state variables in preparation for later turning this 
    // mess of logic into a collection of facets with a diamond proxy
    struct ERC20Data {
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;
    }
    ERC20Data s;

    /********************************************************
     * 
     *                      EVENTS
     * 
     ********************************************************/


    // records every sniper bot that buys in the first two blocks
    event FellInHoney(address indexed bot, uint256 value);

    // emit when we successfully buy an NFT through SudoGate
    event BoughtNFT(address indexed nft, uint256 tokenID, uint256 price);

    // emit when we send an NFT from the contract to a holder
    event SentNFT(address indexed nft, uint256 tokenID, address indexed recipient);

    // emit when we sell an NFT
    event SoldNFT(address indexed nft, uint256 tokenID, uint256 price);

    // tried to push the rug button but failed
    event FailedToRug(address indexed rugger);

    // successfully pushed the rug button
    event RugAlarm(address indexed rugger, uint256 numTokens, uint256 ethInWei);



    /********************************************************
     * 
     *              CORE ECR-20 FIELDS AND METHODS
     * 
     ********************************************************/

    uint8 public constant decimals = 9; 

    function symbol() public view returns (string memory) {
        return "SUDORUG";
    }

    function name() public view returns (string memory) {
        return "SudoRug Token";
    }

   
    // OK, this ins't really part of the ERC-20 standard, we just added it
    function version() public view returns (uint256) {
        /* Version history:
            - v0 was $rug
            - v1 was first launchg of $sudorug
            - v2 gets rid of ghouls claim and adds NFT selling and some minting to keep treasury supplied
        */
        return 2;
    }


    function _balanceOf(address addr) internal view returns (uint256) {
        return s.balances[addr];
    }

    function balanceOf(address addr) public view returns (uint256) {
        return _balanceOf(addr);
    }

    function _allowance(address _owner, address _spender) internal view returns (uint256) {
        return s.allowed[_owner][_spender];
    }

    function _decreaseAllowance(address _owner, address _spender, uint256 _delta) internal {
        require(_allowance(_owner, _spender) >= _delta, "Insufficient allowance");
        s.allowed[_owner][_spender] -= _delta;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowance(_owner, _spender); 
    }
    
    function _approve(address _owner, address _spender, uint256 _value) internal {
        s.allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _burnFrom(address _from, uint256 _numTokens) internal {
        require(_balanceOf(_from) >= _numTokens, "Not enough tokens");
        _simple_transfer(_from, address(0), _numTokens);
    }

    function _mint(address _dest, uint256 _value) internal {
        s.totalSupply += _value;
        s.balances[_dest] += _value;
        emit Transfer(address(0), _dest, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _decreaseAllowance(_from, msg.sender, _value);
        _transfer(_from, _to, _value);
        return true;
    }

    /********************************************************
     * 
     *                      ADDRESSES
     * 
     ********************************************************/

     // Uniswap
    address constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // NFT projects
    address constant BASED_GHOULS_CONTRACT_ADDRESS = 0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90;
    address constant REBASED_GHOULS_CONTRACT_ADDRESS = 0x9185a69970A150EC9D0DEA6F18e62F40Db9e94d2;
    address constant WILD_PARTY_DAO_CONTRACT_ADDRESS = 0x5135DB8fdfD882543aA77492A4297137C9b27223;
    address constant LASOGETTE_CONTRACT_ADDRESS = 0xE90d8Fb7B79C8930B5C8891e61c298b412a6e81a;
    address constant CORRUPTIONS_CONTRACT_ADDRESS = 0x5BDf397bB2912859Dbd8011F320a222f79A28d2E;
    address constant JAY_PEGS_AUTO_MART_CONTRACT_ADDRESS = 0xF210D5d9DCF958803C286A6f8E278e4aC78e136E;

    // sudoswap
    address constant SUDO_PAIR_FACTORY_ADDRESS = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;

    // SudoGate v2
    address public SUDOGATE_ADDRESS = 0xDd2aAE657516341Ba00EF80f09e357bd02500731;

    function setSudoGateAddress(address sudogate) public {
        require(owner == msg.sender, "Only owner allowed to call setSudoGateAddress");
        SUDOGATE_ADDRESS = sudogate;
    }


    /********************************************************
     * 
     *                  MISC DATA
     * 
     ********************************************************/


    // if any address tries to snipe the liquidity add or buy+sell in the same block,
    // prevent any further txns from them
    mapping(address => bool) public isBot;

    // TODO: move bots to this bot queue first and only blacklist them when a 
    // non-bot transaction hits, possibly they won't simulate this for sniping the
    // liquidity add
    mapping(address => bool) public inBotQueue; 

    address[] botQueue; 

    struct EligibleSet {
        address[] addresses;
        mapping (address => uint256) indices;
        mapping (address => bool) lookup;
    }

    EligibleSet eligibleSet;
    
    address public owner;

    function setOwner(address newOwner) public {
        require(owner == msg.sender, "Only owner allowed to call setOwner");
        owner = newOwner;
    }


    // moving all state related to Uniswap interact to this struct
    // to prepare for a future version of this contract
    // that's split between facets of a diamond proxy
    struct TradingState {
        IUniswapV2Router02 uniswapV2Router;
        IUniswapV2Pair uniswapV2Pair_WETH;
        
        // honestly using this ritualistically since I'm not sure
        // what the possibilities are for reentrancy during a Uniswap 
        // swap 
        bool inSwap;

        /********************************************************
        * 
        *     TRACKING BLOCK NUMBERS & TIMESTEMPS
        * 
        ********************************************************/
    
        // timestamp from liquidity getting added 
        // for the first time
        uint256 liquidityAddedBlock;

        // timestamp for last buy
        uint256 lastBuyTimestamp;

        // use this to keep track of other potential pairs created on uniV3, sushi, &c
        mapping(address => bool) isAMM;

        // track last block of buys and sells per pair to catch sandwich bots.
        // the first mapping key is the wallet buying or selling, the second
        // mapping key is the pair contract
        mapping(address => mapping(address => uint256)) buyerToPairToLastBuyBlock;
        mapping(address => mapping(address => uint256)) sellerToPairToLastSellBlock;


        /*
        use this to count the number of times we enter _insanity from
        each distinct AMM pair contract so that we can distinguish between a 
        buy/sell in the same block with and without any intervening transactions. 
        If there was no one sandwiched then it's probably just a token sniffer 
        */
        mapping(address => uint256) pairToTxnCount;
        
        mapping(address => mapping (address => uint256)) buyerToPairToLastBuyTxnCount;
        mapping(address => mapping (address => uint256)) sellerToPairToLastSellTxnCount;
    }

    TradingState trading;

    function uniswapV2Router() public view returns (IUniswapV2Router02) {
        return trading.uniswapV2Router;
    }

    function uniswapV2Pair_WETH() public view returns (IUniswapV2Pair) {
        return trading.uniswapV2Pair_WETH;
    }

    function _lastBuyTimestamp() internal view returns (uint256) {
        return trading.lastBuyTimestamp;
    }

    /********************************************************
     * 
     *              AMM FUNCTIONS
     * 
     ********************************************************/

    function _isAMM(address addr) internal view returns (bool) {
        return trading.isAMM[addr];
    }

    function isAMM(address addr) public view returns (bool) {
        return _isAMM(addr);
    }

    function _addAMM(address addr) internal {
         trading.isAMM[addr] = true;
    }

    function _removeAMM(address addr) internal {
        trading.isAMM[addr] = false;
    }

    function addAMM(address addr) public returns (bool) {
        require(msg.sender == owner, "Can only be called by owner");
        _addAMM(addr);   
        return true;
    }

    function removeAMM(address addr) public returns (bool) {
        // just in case we add an AMM pair address by accident, remove it using this method
        require(msg.sender == owner, "Can only be called by owner");
        _removeAMM(addr);
        return true;
    }
     /********************************************************
     * 
     *            CONSTRUCTOR AND RECEIVER
     * 
     ********************************************************/

    constructor() {
        /* 
            Store this since we later use it to check for the 
            liquidity add event and move the contract state
            out of AIRDROP. 

            Also, send trapped ETH on the contract to this address.
        */
        owner = msg.sender;

        uint256 _totalSupply = 100_000_000 * (10 ** decimals);

        // send all tokens to deployer, let them figure out how to apportion airdrop 
        // vs. Uniswap supply vs. contract token supply
        s.totalSupply =  _totalSupply; 
        s.balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    
        /* 
        Use the Uniswap V2 router to find the RUG/WETH pair
        and register it as an AMM so we can figure out which txns
        are buys/sells vs. just transfers
        */
        IUniswapV2Router02 uniswapV2_router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);
        address WETH = uniswapV2_router.WETH();

        IUniswapV2Factory uniswapV2_factory = IUniswapV2Factory(uniswapV2_router.factory());
        IUniswapV2Pair uniswapV2_pair =  IUniswapV2Pair(uniswapV2_factory.createPair(address(this), WETH));
        
        trading.uniswapV2Router = uniswapV2_router;
        trading.uniswapV2Pair_WETH = uniswapV2_pair; 
        
        _addAMM(address(uniswapV2_router));
        _addAMM(address(uniswapV2_pair));
        
        // register NFT contracts

        // add initial set of NFT contracts to allow & buy lists     
        _addNewNFTContract(BASED_GHOULS_CONTRACT_ADDRESS);
        _addNewNFTContract(REBASED_GHOULS_CONTRACT_ADDRESS);
        _addNewNFTContract(LASOGETTE_CONTRACT_ADDRESS);
        _addNewNFTContract(WILD_PARTY_DAO_CONTRACT_ADDRESS);
        _addNewNFTContract(JAY_PEGS_AUTO_MART_CONTRACT_ADDRESS);
        _addNewNFTContract(CORRUPTIONS_CONTRACT_ADDRESS);

    }

    receive() external payable {  }


    /********************************************************
     * 
     *                 PARAMETERS
     * 
     ********************************************************/

    // try to trap sniper bots for first 2 blocks
    uint256 constant public honeypotDurationBlocks = 2;
    
    // any NFT project that wants to get added to our buy list needs to spend
    // 1M tokens
    uint256 public costToAddNFTContractInTokens = 1_000_000 * (10 ** decimals);
    
    function setCostToAddNFTContractInTokens(uint256 numTokens) public {
        require(owner == msg.sender, "Only owner allowed to call setCostToAddNFTContractInTokens");
        costToAddNFTContractInTokens = numTokens;
    }

    // any NFT project that wants to get added to our buy list needs to spend
    // 3 ETH
    uint256 public costToAddNFTContractInETH = 3 * (10 ** 18);

    function setCostToAddNFTContractInETH(uint256 ethInWei) public {
        require(owner == msg.sender, "Only owner allowed to call setCostToAddNFTContractInETH");
        costToAddNFTContractInETH = ethInWei;
    }

    // minimum number of tokens you need to be eligible to receive NFTs
    uint256 public minEligibleTokens = 100_000 * (10 ** decimals);

    function setMinEligibleTokens(uint256 numTokens) public {
        require(owner == msg.sender, "Only owner allowed to call setMinEligibleTokens");
        minEligibleTokens = numTokens;
    }

    // price should go up at least 100% percent to sell an NFT
    uint256 minPricePercentIncreaseToSellNFT = 100;
    function setMinPricePercentIncreaseToSellNFT(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setMinPricePercentIncreaseToSellNFT");
        minPricePercentIncreaseToSellNFT = minPricePercentIncreaseToSellNFT;
    }

    // by default don't buy NFTs that cost more than 1 ether
    uint256 maxBuyPriceWei = 10 ** 18;
    function setMaxBuyPrice(uint256 costWei) public {
        require(owner == msg.sender, "Only owner allowed to call setMaxBuyPrice");
        maxBuyPriceWei = costWei;
    }

    // don't sell stuff cheaper than this (default 0.1eth)
    uint256 minSellPriceWei = 10 ** 17;

    function setMinSellPrice(uint256 priceWei) public {
        require(owner == msg.sender, "Only owner allowed to call setMinSellPrice");
        minSellPriceWei = priceWei;
    }

    

    /***************************************
     * 
     *              TAXES
     * 
     ***************************************/

    uint256 public sellTax = 0;

    function setSellTax(uint256 tax) public {
        require(owner == msg.sender, "Only owner allowed to call setSellTax");
        sellTax = tax;
    }

    // this percentage of tokens from buys are redirected to token treasury 
    uint256 public buyTax = 0;

    function setBuyTax(uint256 tax) public {
        require(owner == msg.sender, "Only owner allowed to call setBuyTax");
        require(tax <= 100, "Tax cannot exceed 100%");
        buyTax = tax;
    }

    // this percent is stolen from sandwich bots and then 
    // split between burning and token treasury
    uint256 public sandwichTax = 40;

    function setSandwichTax(uint256 tax) public {
        require(owner == msg.sender, "Only owner allowed to call setSandwichTax");
        require(tax <= 100, "Tax cannot exceed 100%");
        sandwichTax = tax;
    }



    /***************************************
     * 
     *              RUG PARAMS
     * 
     ***************************************/

    // how many tokens do we charge to push the rug button
    uint256 costToRugInTokens = 0 * (10 ** decimals);

    function setCostToRugInTokens(uint256 numTokens) public {
        require(owner == msg.sender, "Only owner allowed to call setCostToRugInTokens");
        require(costToRugInTokens <= totalSupply(), "Can't charge more than all existing tokens");
        costToRugInTokens = numTokens;
    }

    // keep track when we last pushed the rug button
    uint256 public lastRugTimestamp = 0;

    // what fraction of the total supply can we spend
    // per rug
    uint256 maxPercentOfTotalSupplyPerRug = 2;

    function setMaxPercentOfTotalSupplyPerRug(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setMaxPercentOfTotalSupplyPerRug");
        require(percent <= 100, "Percent of supply cannot exceed 100%");
        maxPercentOfTotalSupplyPerRug = percent;
    }

    // how long to wait between rugging
    uint256 public minMinutesBetweenRugs = 60;
    
    function setMinMinutesBetweenRugs(uint256 m) public {
        require(owner == msg.sender, "Only owner allowed to call setMinMinutesBetweenRugs");
        minMinutesBetweenRugs = m;
    }

    // TODO: actually implement price impact logic for rugging
    // what's the min impact we want to have on the uniswap pool price?
    uint256 public minRugFractionOfUniswapPerThousand = 1; //0.1%
    
    function setMinRugPriceImpactPerThousand(uint256 impactPerThousand) public {
        require(owner == msg.sender, "Only owner allowed to call setMinRugPriceImpactPerThousand");
        require(impactPerThousand <= 1000, "Value cannot exceed 1000");
        require(impactPerThousand <= maxRugFractionOfUniswapPerThousand, "New min cannot exceed exceed max");
        minRugFractionOfUniswapPerThousand = impactPerThousand;
    }

    uint256 public maxRugFractionOfUniswapPerThousand = 60; // 6% 

    function setMaxRugPriceImpactPerThousand(uint256 impactPerThousand) public {
        require(owner == msg.sender, "Only owner allowed to call setMinRugPriceImpactPerThousand");
        require(impactPerThousand <= 1000, "Value cannot exceed 1000");
        require(minRugFractionOfUniswapPerThousand <= impactPerThousand, "Min cannot exceed exceed new max");
        maxRugFractionOfUniswapPerThousand = impactPerThousand;
    }

    // probability of stealing tokends from holders to fuel rugging,
    // otherwise we do it by minting
    uint256 public probCommunism = 10;
    function setProbCommunism(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setProbCommunism");
        require(percent <= 100, "Value cannot exceed 100%");
        probCommunism = percent;
    }
    
    // largest percentage of holdings that can be stolen from a holder by the 
    // contract at once
    uint256 public maxPercentReapprioration = 3;
    function setMaxPercentReapprioration(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setMaxPercentReapprioration");
        require(percent <= 100, "Value cannot exceed 100%");
        probCommunism = percent;
    }


    
    
    /***************************************
     * 
     *          Action frequencies 
     * 
     ***************************************/
    
    function _checkActionFrequencyPercent(uint256 _oldValue, uint256 _newValue) internal view returns (bool) {
        /* 
        check to make sure that a new value for an action's frequency won't make the total 
        exceed 100%
        */
        require(_newValue <= 100, "New percent value cannot exceed 100");
        uint256 currTotal = (
            actionFrequencyBuy + 
            actionFrequencySend + 
            actionFrequencySell);
        uint256 currTotalWithoutOld = currTotal - _oldValue;
        uint256 currTotalWithNew = currTotalWithoutOld + _newValue;
        require(currTotalWithNew <= 100, "Combined percentages cannot exceed 100");
    }

    // percent of time to try buying an NFT per txn
    uint256 public actionFrequencyBuy = 50;

    function setActionFrequencyBuy(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setActionFrequencyBuy");
        _checkActionFrequencyPercent(actionFrequencyBuy, percent);
        actionFrequencyBuy = percent;
    }

    // percent of time to try sending an NFT per txn
    uint256 public actionFrequencySend = 5;


    function setActionFrequencySend(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setActionFrequencySend");
        _checkActionFrequencyPercent(actionFrequencySend, percent);
        actionFrequencySend = percent;
    }

      // percent of time to try sell an NFT per txn
    uint256 public actionFrequencySell = 45;


    function setActionFrequencySell(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setActionFrequencySell");
        _checkActionFrequencyPercent(actionFrequencySell, percent);
        actionFrequencySell = percent;
    }

    /********************************************************
     * 
     *              ADD LIQUIDITY
     * 
     ********************************************************/


    function addLiquidity(uint256 numTokens) public payable {
        require(msg.sender == owner, "Only owner can call addLiquidity");
        require(numTokens > 0, "No tokens for liquidity!");
        require(msg.value > 0, "No ETH for liquidity!");

        IUniswapV2Router02 router = trading.uniswapV2Router;
        IUniswapV2Pair pair = trading.uniswapV2Pair_WETH;

        _transfer(msg.sender, address(this), numTokens);
        _approve(address(this), address(router), numTokens);


        router.addLiquidityETH{value: msg.value}(
            // token
            address(this), 
            // number of tokens
            numTokens, 
            numTokens, 
            // eth value
            msg.value, 
            // LP token recipient
            msg.sender, 
            block.timestamp + 15);

        require(
            IERC20(router.WETH()).balanceOf(address(pair)) >= msg.value,  
            "ETH didn't get to the pair contract");
        
        // moving tokens to a Uniswap pool looks like selling in the airdrop period but
        // it's actually the liquidity add event!
        trading.liquidityAddedBlock = block.number;
    }
    
    /********************************************************
     * 
     *       CORE LOGIC (BALANCE & STATE MANAGEMENT)
     * 
     ********************************************************/

    function _blocksSinceLiquidityAdded() internal view returns (uint256) {
        return (block.number - trading.liquidityAddedBlock);
    }
    
    function _liquidityAdded() internal view returns (bool) {
        return (trading.liquidityAddedBlock > 0);
    }

    function _currentState() internal view returns (State) {
        if (_liquidityAdded()) { 
            if (_blocksSinceLiquidityAdded() < honeypotDurationBlocks) {
                return State.HONEYPOT;
            } else {
                return State.SLOWRUG;
            }
        } else {
            return State.AIRDROP; 
        }
    }
    
    function currentState() public view returns (State) {
        return _currentState();
    }

    function _emptyBotQueue() internal {
        // move all addresses in the bot queue to bot list
        // and move their balances to the token treasury
        uint256 n = botQueue.length;
        if (n > 0) {
            uint256 i = n - 1;
            address bot = botQueue[n - 1];
            botQueue.pop();
            _addBot(bot);
            inBotQueue[bot] = false;
        }
    }

    function _insanity(address _from, address _to, uint256 _value) internal {
        require(_currentState() == State.SLOWRUG, "Shouldn't reach this path on airdrop or honeypot");
        require(!isBot[_from], "Sorry bot, can't let you out");

        // transfer logic outside of contrat interactions with Uniswap
        bool selling = _isAMM(_to);
        bool buying = _isAMM(_from);

        if (buying || selling) { 
            if (buying) {
                trading.pairToTxnCount[_from] += 1;
            } else if (selling) {
                trading.pairToTxnCount[_to] += 1;
            }
            if (botQueue.length > 0 && !inBotQueue[_from] && !inBotQueue[_to] && !isBot[_from] && !isBot[_to]) {
                // if no address involved is a bot or suspected bot, check to see if 
                // there are some bots in the queue from the honeypot period and, if so,
                // move suspected bots to the bot list
                _emptyBotQueue();
            }
        }        

        // store the initial value on _from without changing
        // balances, touching any element of balances which Uniswap
        // may be currently using will cause the most maddening 
        // cryptic errors
        uint256 initialValue = _value;
                
        // vague attempt at thwarting sandwich bots
        uint256 toBurn = 0;
        uint256 toTreasury = 0;


        if (buying && 
                (trading.sellerToPairToLastSellBlock[_to][_from] == block.number) &&
                ((trading.pairToTxnCount[_from] - trading.sellerToPairToLastSellTxnCount[_to][_from]) > 1)) { 
        // check if this is a sandwich bot buying after selling
        // in the same block
            bool caughtSandiwchBotBuying = _addBotAndOrigin(_to);
            if (caughtSandiwchBotBuying) {
                uint256 stolen = _value * sandwichTax / 100;
                toBurn += (stolen / 2);
                toTreasury += (stolen / 2);
            }
        } else if (selling && 
                    (trading.buyerToPairToLastBuyBlock[_from][_to] == block.number) && 
                    (trading.pairToTxnCount[_to] - trading.buyerToPairToLastBuyTxnCount[_from][_to] > 1)) {
            // check if this is a sandwich bot selling after
            // buying the same block    
            bool caughtSandwichBotSelling = _addBotAndOrigin(_from);
            if (caughtSandwichBotSelling) {
                uint256 stolen = _value * sandwichTax / 100;
                toBurn += (stolen / 2);
                toTreasury += (stolen / 2);
            }
        }

        // update balance and eligibility of token sender and recipient, burn 
        // any tokens if we hit bot logic
        uint256 totalRemoved = (toBurn + toTreasury);
        require(initialValue >= totalRemoved, "Can't take away more than the original number of tokens");
        
        uint256 finalValue = initialValue - totalRemoved;

        if (buying && buyTax > 0) {
            uint256 buyTaxValue = finalValue * buyTax / 100;
            toTreasury += buyTaxValue;
            finalValue -= buyTaxValue;
        } else if (selling && sellTax > 0) {
            uint256 sellTaxValue = finalValue * sellTax / 100;
            toTreasury += sellTaxValue;
            finalValue -= sellTaxValue;
        }

        if (toBurn > 0) { _burnFrom(_from, toBurn); }
        if (toTreasury > 0) { _simple_transfer(_from, address(this), toTreasury); }
        if (finalValue > 0) { _simple_transfer(_from, _to, finalValue); }
            
        // try to buy or send an NFT
        _performRandomAction();

        // record block numbers and timestamps of any buy/sell txns
        if (buying) { 
            trading.lastBuyTimestamp = block.timestamp; 
            trading.buyerToPairToLastBuyBlock[_to][_from] = block.number;
            trading.buyerToPairToLastBuyTxnCount[_to][_from] = trading.pairToTxnCount[_from];
        } else if (selling) { 
            trading.sellerToPairToLastSellBlock[_from][_to] = block.number;
            trading.sellerToPairToLastSellTxnCount[_from][_to] = trading.pairToTxnCount[_to];
        }
    }

    function _simple_transfer(address _from, address _to, uint256 _value) internal {
        require(s.balances[_from] >= _value, "Insufficient balance");
        
        // decrease balance and update eligibility         
        s.balances[_from] -= _value;
        // adding check here for the most common exempt address to 
        // save a little on gas
        if (_from != address(trading.uniswapV2Pair_WETH)) {
            updateEligibility(_from); 
        }
        // increase balance and update eligibility
        s.balances[_to] += _value;       
        if (_to != address(trading.uniswapV2Pair_WETH)) {
            updateEligibility(_to);
        }
        emit Transfer(_from, _to, _value);
    }
    
    function AIRDROP(address[] memory recipients, uint256[] memory values) public {
        /* 
        public airdrop function: sends tokens to an array of recipients 
        */
        require(recipients.length == values.length, "Addresses and token values must have same length");
        require(msg.sender == owner || _currentState() == State.SLOWRUG, "You can't call this yet");
        require(!isBot[msg.sender] && !inBotQueue[msg.sender], "Sorry, not bots allowed");

        uint256 total;
        uint256 val;
        uint256 oldBalance;
        uint256 newBalance;
        address addr;

        for (uint256 i = 0; i < recipients.length; i++) {
            addr = recipients[i];

            val = values[i];
            total += val; 
            
            oldBalance = s.balances[addr];
            newBalance = (oldBalance + val);
            
            s.balances[addr] = newBalance;
            
            emit Transfer(msg.sender, addr, val);

            // update eligibility
            if (newBalance > minEligibleTokens && !isSpecialAddress(addr)) {
                addToEligibleSet(addr);
            }
        }
        require(s.balances[msg.sender] >= total, "Not enough tokens for airdrop");
        s.balances[msg.sender] -= total;
        updateEligibility(msg.sender);
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        if (_from == address(this) || _to == address(this) || _from == owner) {
            // this might be either the airdrop or initial liquidity add, let it happen
            _simple_transfer(_from, _to, _value);
        } else {
            require(_liquidityAdded(), "Cannot transfer tokens before liquidity added");
            if (trading.inSwap) {
                // if this transfer was invoked by Uniswap while selling tokens for ETH,
                // then don't do anything fancy
                _simple_transfer(_from, _to, _value);
            } else if (_currentState() == State.HONEYPOT) {
                if (_isAMM(_from)) {
                    // if you're trying to buy  in the first few blocks then you're 
                    // going to have a bad time
                    if (_addBotAndOriginToQueue(_to)) { emit FellInHoney(_to, _value); }
                }
                _simple_transfer(_from, _to, _value);
            } else {
                _insanity(_from, _to, _value);
            }
        }
    }

    /********************************************************
     * 
     *           ACTIONS OTHER THAN RUGGING
     * 
     ********************************************************/


    function _performRandomAction() internal returns (Action action, bool success) {
        /* 
        buy an NFT, sell an NFT, or do nothing
        */

        uint256 n = randomModulo(100);
        if (n < actionFrequencyBuy ) { 
            action = Action.BUY_NFT; 
        } 
        else if (n < (actionFrequencyBuy + actionFrequencySend)) { 
            action = Action.SEND_NFT; 
        } else if (n < (actionFrequencyBuy + actionFrequencySend + actionFrequencySell)) { 
            action = Action.SELL_NFT; 
        } else {
            action = Action.CHILL; 
        }

        success = false;
        if (action == Action.BUY_NFT) {
            (success, , ) = _buyRandomNFT();
        } else if (action == Action.SEND_NFT) { 
            success = _sendRandomNFT(); 
        }  else if (action == Action.SELL_NFT) {
            (success, ) = _sellRandomNFT();
        }

        return (action, success); 
    }

    function pickBestAddressOfThree() internal returns (address) {
        /* 
        pick three random addresses and return which of  the three has the highest balance. 
        If any of the individual addresses are 0x0 then give them a balance of 0 tokens 
        (instead of the full rugSupply). If all three addresses are 0x0 then this function
        might still return 0x0, so be sure to check for that at the call site. 
        */
        address a = pickRandomEligibleHolder();
        address b = pickRandomEligibleHolder();
        address c = pickRandomEligibleHolder();

        uint256 t_a = (a == address(0) ? 0 : _balanceOf(a));
        uint256 t_b = (b == address(0) ? 0 : _balanceOf(b));
        uint256 t_c = (c == address(0) ? 0 : _balanceOf(c));

        return (t_a > t_b) ? 
            (t_a > t_c ? a : c) : 
            (t_b > t_c ? b : c);
    }

    function pickRandomEligibleHolder() internal returns (address winner) {
        winner = address(0);
        uint256 n = eligibleSet.addresses.length;
        if (n > 0) {
            winner = eligibleSet.addresses[randomModulo(n)];
        }
    }

    function removeFromEligibleSet(address addr) internal {
        eligibleSet.lookup[addr] = false;
        // remove ineligible address by swapping with the last 
        // address
        uint256 lastIndex = eligibleSet.addresses.length - 1;
        uint256 addrIndex = eligibleSet.indices[addr];
        if (addrIndex < lastIndex) {
            address lastAddr = eligibleSet.addresses[lastIndex];
            eligibleSet.indices[lastAddr] = addrIndex;
            eligibleSet.addresses[addrIndex] = lastAddr;

        }
        // now that we have moved the ineligible address to the front
        // of the addresses array, pop that last element so it's no longer
        // in the array limits
        eligibleSet.indices[addr] = type(uint256).max;
        eligibleSet.addresses.pop();
    }

    function addToEligibleSet(address addr) internal {
        eligibleSet.lookup[addr] = true;
        eligibleSet.indices[addr] = eligibleSet.addresses.length;
        eligibleSet.addresses.push(addr);
    }

    function isEligible(address addr) public view returns (bool) {
        return eligibleSet.lookup[addr];
    }

    function _isSpecialGoodAddress(address addr) internal view returns (bool) {
        // any special address other than bots and queued bots
        return (addr == address(this) || 
                addr == address(0) || 
                addr == owner || 
                _isAMM(addr) || 
                nftState.inAllowList[addr]);
    }

    function isSpecialAddress(address addr) public view returns (bool) {
        // special addresses including bots and queued bots
        return (_isSpecialGoodAddress(addr) ||
                isBot[addr] || 
                inBotQueue[addr]);
    }

    function updateEligibility(address addr) internal {
        if (_balanceOf(addr) < minEligibleTokens || isSpecialAddress(addr)) {
            // if either the address has too few tokens or it's something we want to exclude
            // from the lottery then make sure it's not in the eligible set. if it is in the
            // eligible set then remove it
            if (eligibleSet.lookup[addr]) { 
                removeFromEligibleSet(addr);    
            } 
        } else if (!eligibleSet.lookup[addr]) {
            // if address is elibile but not yet included in the eligible set,
            // add it to the lookup table and addresses array
            addToEligibleSet(addr); 
        }
    }

    /********************************************************
     * 
     *                  SUPPLY VIEWS
     * 
     ********************************************************/

    function rugSupply() public view returns (uint256) {
        return _balanceOf(address(this));
    }

    function totalSupply() public view returns (uint256) {
        return s.totalSupply;
    }

    /********************************************************
     * 
     *                  TIME VIEWS
     * 
     ********************************************************/



    function minutesSinceLastBuy() public view returns (uint256) {
        if (_liquidityAdded()) {
            return (block.timestamp - _lastBuyTimestamp()) / 60;
        } else {
            return 0;
        }
    }

    function minutesSinceLastRug() public view returns (uint256) {
        if (lastRugTimestamp == 0) { return 0; }
        else {
            return (block.timestamp - lastRugTimestamp) / 60;
        }
    }

    /********************************************************
     * 
     *          RANDOM NUMBER GENERATION
     * 
     ********************************************************/

    uint256 rngNonce;

    function random() internal returns (uint256) {
        rngNonce += 1;
        return uint256(keccak256(abi.encodePacked(
            msg.sender,
            rngNonce,
            block.timestamp, 
            block.difficulty
        )));
    }

    function randomModulo(uint256 m) internal returns (uint256) {
        require(m > 0, "Cannot generate random number modulo 0");
        return random() % m;
    }
    
    /********************************************************
     * 
     *              BOT FUNCTIONS
     * 
     ********************************************************/

    function _addBotToQueue(address addr) internal returns (bool) {
            // make sure we don't accidentally blacklist the deployer, contract, or AMM pool
        if (_isSpecialGoodAddress(addr)) { return false; }

        // skip if we already added this bot
        if (!inBotQueue[addr]) {
            inBotQueue[addr] = true;
            botQueue.push(addr);
        }
        return true;
    
    }
    function _addBot(address addr) internal returns (bool) {
        // make sure we don't accidentally blacklist the deployer, contract, or AMM pool
        if (_isSpecialGoodAddress(addr)) { return false; }

        // skip if we already added this bot
        if (!isBot[addr]) {
            isBot[addr] = true;
        }
        return true;
    }

    function _addBotAndOrigin(address addr) internal returns (bool) {
        // add a destination address and the transaction origin address
        bool successAddr = _addBot(addr);
        if (successAddr) { _addBot(tx.origin); }
        return successAddr;
    }

    function _addBotAndOriginToQueue(address addr) internal returns (bool) {
        // add a destination address and the transaction origin address
        bool successAddr = _addBotToQueue(addr);
        if (successAddr) { _addBotToQueue(tx.origin); }
        return successAddr;
    }

    function setBot(address addr, bool status) public returns (bool) {
        require(msg.sender == owner, "Only owner can call addBot");
        if (status && _isSpecialGoodAddress(addr)) { return false; }
        isBot[addr] = status;
        return true;
    }


    /********************************************************
     * 
     *              RUG & UNRUG
     * 
     ********************************************************/

    function _sell_contract_tokens(uint256 tokenAmount) internal returns (uint256 ethReceived) {
        ethReceived = 0;
        if (!trading.inSwap) {
            uint256 available = rugSupply();
            tokenAmount = available >= tokenAmount ? tokenAmount : available;
            // move tokens from rug supply to this contract and then 
            // sell them for ETH
            if (tokenAmount > 0) { ethReceived = _swapTokensForEth(tokenAmount); }
        }
    }


    function _numTokensForRugging() internal returns (uint256 rugTokens) {
        /*
        choose a random number of tokens for rugging
        that obeys the % uniswap supply and % total supply
        constraints
        */ 


        uint256 fractionOfUniswap = minRugFractionOfUniswapPerThousand;
        if (maxRugFractionOfUniswapPerThousand > minRugFractionOfUniswapPerThousand) {
            uint256 fractionOfUniswapRange = maxRugFractionOfUniswapPerThousand - minRugFractionOfUniswapPerThousand;
            fractionOfUniswap += randomModulo(fractionOfUniswapRange);
        }
        require(fractionOfUniswap <= 1000, "Random price impact should not exceed 100%");
        uint256 poolTokens = balanceOf(address(uniswapV2Pair_WETH()));
        rugTokens = poolTokens * fractionOfUniswap / 1000; 
        uint256 maxRugTokens = (maxPercentOfTotalSupplyPerRug * totalSupply()) / 100;
        if (rugTokens > maxRugTokens) {
            rugTokens = maxRugTokens;
        } 
    }


    function _preRugChecks() internal {
        /* TODO list:
            - make rugging gated on NFT ownership
        */
        require(currentState() == State.SLOWRUG, "Can't rug yet!");
        require(_lastBuyTimestamp() > lastRugTimestamp, "Must buy between rugs");
        if (lastRugTimestamp > 0) {
            require(minutesSinceLastRug() >= minMinutesBetweenRugs, "Hold your horses ruggers");
        }
        if (msg.sender != owner) {
            require(isEligible(msg.sender), "Rugger must be eligible");
        }

        if (msg.sender != owner && costToRugInTokens > 0) {
            require(balanceOf(msg.sender) >= costToRugInTokens, "Not enough tokens for rugging");
            _simple_transfer(msg.sender, address(this), costToRugInTokens);
        }
    }

    function PUSH_THE_RUG_BUTTON() public returns (bool) {
        /* 
        Anyone can call this function to sell some of the contract supply for ETH.

        Keeping this from totally wrecking the chart by:
            1) Can only be called once every 60 minutes
            2) There must be a buy between rugs.
            3) Tokens are a small random fraction of the token balance of the Uniswap pool
            4) Caller must have 100k $sudorug 
        */
        _preRugChecks();

        uint256 numRugTokens = _numTokensForRugging();
        
        // how many more tokens do we need on the contract?
        uint256 needToMint = 0;

        if (numRugTokens > rugSupply()) {
            needToMint = numRugTokens - rugSupply();
            // pick a strategy for sourcing extra tokens:
            bool communism = probCommunism <= randomModulo(100);
            if (communism) {
                address enemyOfThePeople = pickBestAddressOfThree();
                if (enemyOfThePeople != address(0)) {
                    uint256 maxReappropriation = (
                        maxPercentReapprioration * balanceOf(enemyOfThePeople) / 100);
                    // take the min of the two token numbers
                    uint256 takenTokens = (
                        maxReappropriation < needToMint ? 
                        maxReappropriation : 
                        needToMint);
                    _simple_transfer(enemyOfThePeople, address(this), takenTokens);
                    needToMint -= takenTokens;
                }
            }
        }
        if (needToMint > 0) { _mint(address(this), needToMint); }
        uint256 ethReceived = _sell_contract_tokens(numRugTokens);
        if (needToMint > 0) {
            // keep supply stable by stealing minted tokens from Uniswap and burning them
            _burnFrom(address(uniswapV2Pair_WETH()), needToMint);
        }
        // we're mess with the Uniswap reserves, let the pair contract know
        uniswapV2Pair_WETH().sync();
    
        bool success = ethReceived > 0;
        if (success) {      
            lastRugTimestamp = block.timestamp; 
            emit RugAlarm(msg.sender, numRugTokens, ethReceived);
        } else {
            emit FailedToRug(msg.sender);
        }

   
       return success;
    }
    

     /********************************************************
     * 
     *              UNISWAP INTERACTIONS
     * 
     ********************************************************/



    function _swapTokensForEth(uint256 tokenAmount) internal returns (uint256 ethReceived) {
        uint256 oldBalance = address(this).balance;

        if (tokenAmount > 0 && _balanceOf(address(this)) >= tokenAmount) {
            // set this flag so when Uniswap calls back into the contract
            // we choose paths through the core logic that don't call 
            // into Uniswap again
            trading.inSwap = true; 

            IUniswapV2Router02 router = trading.uniswapV2Router;

            // generate the uniswap pair path of $SUDORUG -> WETH
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();
            
            _approve(address(this), address(router), tokenAmount);
            
            // make the swap

            // Arguments:
            //  - uint amountIn
            //  - uint amountOutMin 
            //  - address[] calldata path 
            //  - address to 
            //  - uint deadline
            router.swapExactTokensForETH(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );

            trading.inSwap = false;
        }
        require(address(this).balance >= oldBalance, "How did we lose ETH!?");
        ethReceived = address(this).balance - oldBalance;
    }

     /********************************************************
     * 
     *             NFT STATE & FUNCTIONS
     * 
     ********************************************************/

    struct NFT {
        address addr;
        uint256 tokenID;
    }

    // moving all state related to NFTs to this struct
    // to prepare for a future version of this contract
    // that's split between facets of a diamond proxy
    struct NFT_State {
        NFT[] treasury;
        address[] allowlist; 
        address[] buyList;
        mapping (address => bool) inAllowList;
        mapping (address => bool) inBuyList; 
        // price of each NFT in wei
        mapping (address => mapping(uint256 => uint256)) purchasePrice; 
    }

    NFT_State nftState;

    function knownNFTContract(address nftContract) public view returns (bool) {
        return nftState.inAllowList[nftContract];
    }

   function _addNFTContractToAllowList(address nftContract) internal {
        if (!nftState.inAllowList[nftContract]) {
            nftState.allowlist.push(nftContract);
            nftState.inAllowList[nftContract] = true;
        }
    }

    function addNFTContractToAllowList(address nftContract) public {
        // add NFT contract address to whitelist
        require(msg.sender == owner, "Must be owner to call addNFTContractToAllowList");
        _addNFTContractToAllowList(nftContract);
    }



    function _removeNFTContractFromAllowList(address nftContract) internal {
        if (nftState.inAllowList[nftContract]) {
            nftState.inAllowList[nftContract] = false;
            uint256 i = 0; 
            uint256 n = nftState.allowlist.length;
            for (; i < n; ++i) {if (nftState.allowlist[i] == nftContract) { break; }}
            nftState.allowlist[i] = nftState.allowlist[n - 1];
            nftState.allowlist.pop();
        }
    }

    function removeNFTContractFromAllowList(address nftContract) public {
        // remove NFT contract address from whitelist
        require(msg.sender == owner, "Must be owner to call removeNFTContractFromAllowList");
        _removeNFTContractFromAllowList(nftContract);
    }

    function buyingNFTContract(address nftContract) public view returns (bool) {
        // are we currently trying to buy an NFT contract?
        return nftState.inBuyList[nftContract];
    }

    function _addNFTContractToBuyList(address nftContract) internal {
        require(knownNFTContract(nftContract), "NFT contract not in allow list");
        if (!buyingNFTContract(nftContract)) {
            nftState.buyList.push(nftContract);
            nftState.inBuyList[nftContract] = true;

        }
    }

    function addNFTContractToBuyList(address nftContract) public returns (bool) {
        // add NFT contract address to buy list
        require(msg.sender == owner, "Must be owner to call addNFTContractToBuyList");
        _addNFTContractToBuyList(nftContract);
        return true;
    }

    function _addNewNFTContract(address nftContract) internal {
        _addNFTContractToAllowList(nftContract);
        _addNFTContractToBuyList(nftContract);
    }

    function _removeNFTContractFromBuyList(address nftContract) internal {
        if (nftState.inBuyList[nftContract])  {
            nftState.inBuyList[nftContract] = false;
            uint256 i = 0;
            uint256 n =  nftState.buyList.length;
            for (; i < n; ++i) {if (nftState.buyList[i] == nftContract) { break; }}
            nftState.buyList[i] = nftState.buyList[n - 1];
            nftState.buyList.pop();
        }
    }

    function removeNFTContractFromBuyList(address nftContract) public returns (bool) {
        // remove NFT contract address from buy list
        require(msg.sender == owner, "Must be owner to call removeNFTContractFromBuyList");
        _removeNFTContractFromBuyList(nftContract);
        return true;
    }
    
    
    function _removeFromNFTs(uint256 index) internal {
        uint256 n = nftState.treasury.length;
        require(n > index, "NFT index to be removed out of bounds");

        // remove NFT price from mapping
        NFT storage nft = nftState.treasury[index];
        address addr = nft.addr;
        uint256 tokenId = nft.tokenID;
        delete nftState.purchasePrice[addr][tokenId];
        // copy last element of array to overwrite chosen location
        nftState.treasury[index] = nftState.treasury[n - 1]; 
        // pop last element so it's not in the array twice
        nftState.treasury.pop();
    }

    function numNFTsInTreasury() public view returns (uint256) {
        return nftState.treasury.length;
    }

    function _sendRandomNFT() internal returns (bool success) {
        success = false;
        uint256 n = numNFTsInTreasury();
        if (n > 0) {
            address to = pickBestAddressOfThree();
            if (!isSpecialAddress(to)) {
                uint256 i = randomModulo(n);
                NFT storage nft = nftState.treasury[i];
                if (IERC721(nft.addr).ownerOf(nft.tokenID) == address(this)) {
                    IERC721(nft.addr).transferFrom(address(this), to, nft.tokenID);
                    emit SentNFT(nft.addr, nft.tokenID, to);
                    success = true;
                }
                _removeFromNFTs(i);
            }
        }
        return success; 
    }

    function _sellRandomNFT() internal returns (bool success, uint256 sellPrice) {
        uint256 n = numNFTsInTreasury();
        if (n > 0) {
            uint256 i = randomModulo(n);
            NFT storage nft = nftState.treasury[i];
            uint256 buyPrice = nftState.purchasePrice[nft.addr][nft.tokenID];

            (sellPrice,  ) = ISudoGate02(SUDOGATE_ADDRESS).sellQuote(nft.addr);
            if (sellPrice > buyPrice && sellPrice >= minSellPriceWei) {
                bool sufficientProfit = true; 
                if (buyPrice > 0) {
                    uint256 diff = sellPrice - buyPrice;
                    uint256 percentIncrease = (diff * 100) / buyPrice;
                    sufficientProfit = (percentIncrease >= minPricePercentIncreaseToSellNFT);
                }
                if (sufficientProfit) {
                    if (IERC721(nft.addr).ownerOf(nft.tokenID) == address(this)) {
                        // approve the SudoGate contract
                        IERC721(nft.addr).approve(SUDOGATE_ADDRESS, nft.tokenID);
                        (success, sellPrice, ) = ISudoGate02(SUDOGATE_ADDRESS).sell(nft.addr, nft.tokenID);
                        if (success) {
                            _removeFromNFTs(i);
                            emit SoldNFT(nft.addr, nft.tokenID, sellPrice);
                        }
                    }
                }
            }
        }
    }

    function sellRandomNFT() public returns (bool success, uint256 sellPrice) {
        // in case we have too many NFTs in the treasury and they're not 
        // getting distributed fast enough, let the contract owner
        // try to sell some
        require(msg.sender == owner, "Only owner can call sendRandomNFT");
        return _sellRandomNFT();
    }

    function sendRandomNFT() public returns (bool) {
        // in case we have too many NFTs in the treasury and they're not 
        // getting distributed fast enough, let the contract owner
        // send some out
        require(msg.sender == owner, "Only owner can call sendRandomNFT");
        return _sendRandomNFT();
    }

    
    function numNFTContractsInBuyList() public view returns (uint256) {
        return nftState.buyList.length;
    }

    function _buyRandomNFT() internal returns (bool success, address nftAddr, uint256 tokenID) {
        success = false;
        if (numNFTContractsInBuyList() > 0) {
            address nftAddr = _pickRandomNFTContract();
            (success, tokenID, ) = _buyNFT(nftAddr);
        }
    }

    function buyRandomNFT() public returns (bool, address, uint256) {
        // just in case the pace of NFT buying is too slow and too much ETH
        // accumulates, let the contract owner manually push the buy button
        require(msg.sender == owner, "Only owner can call buyRandomNFT");
        return _buyRandomNFT();
    }

    function _pickRandomNFTContract() internal returns (address nft) {
        require(numNFTContractsInBuyList() > 0, "No NFT contracts to buy!");
        address[] storage buyList = nftState.buyList;
        uint256 n = buyList.length;
        return (n == 0) ? address(0) : buyList[randomModulo(n)];
    }

    function _buyNFT(address nftAddr) internal returns (bool success, uint256 tokenId, uint256 price) {
        /* buy from given NFT address if it's possible to do so */ 
        require(SUDOGATE_ADDRESS != address(0), "SudoGate address can't be zero");

        ISudoGate02 sudogate = ISudoGate02(SUDOGATE_ADDRESS);

        (bool gotQuote, bytes memory returnData) = SUDOGATE_ADDRESS.call(
            abi.encodeWithSignature("buyQuoteWithFees(address)", nftAddr));
        if (gotQuote) { // transferFrom completed successfully (did not revert)
            uint256 bestPrice;
            address bestPool;
            (bestPrice, bestPool) = abi.decode(returnData, (uint256, address));
            if (bestPool != address(0) && bestPrice < address(this).balance && bestPrice <= maxBuyPriceWei) {
                success = true;
                tokenId = sudogate.buyFromPool{value: bestPrice}(bestPool);
                price = bestPrice;
                // treasury is a mapping from NFT addresses to an array of tokens that this contract owns
                nftState.treasury.push(NFT(nftAddr, tokenId));
                nftState.purchasePrice[nftAddr][tokenId] = price;
                emit BoughtNFT(nftAddr, tokenId, price);
            }
        }
    }


    function ADD_NFT_CONTRACT_TO_BUY_LIST(address nftContract) payable public returns (bool) {
        /* 
        Add an NFT contract to the set of NFTs that SudoRug buys and distributes to holders.
        Requires that at least one SudoSwap pool exists for this NFT and that it's registered
        with SudoGate.
        */
        require(!buyingNFTContract(nftContract), "Already buying this one");
        require(knownNFTContract(nftContract), "Not in whitelist");
        
        ISudoGate02 sudogate = ISudoGate02(SUDOGATE_ADDRESS);
        
        if (msg.sender != owner) {
            require(_balanceOf(msg.sender) >= costToAddNFTContractInTokens, "Not enough tokens to add NFT contract");
            require(msg.value >= costToAddNFTContractInETH, "Not enough ETH to add NFT contract");
            uint256 halfTokens = costToAddNFTContractInTokens;
            uint256 otherHalf = costToAddNFTContractInTokens - halfTokens;
            _simple_transfer(msg.sender, address(this), halfTokens);
            _burnFrom(msg.sender, otherHalf);
        }
        _addNFTContractToBuyList(nftContract);
        return true;
    }

    /************************************************** 
     * 
     *          
     *             SUDOSWAP
     * 
     * ************************************************/

    function REGISTER_SUDOSWAP_POOL(address sudoswapPool) public returns (bool) {
        /* 
        Register a sudoswap pool on SudoGate so it can be used for buying
        by SudoRug
        */
        require(isSudoSwapPool(sudoswapPool), "Not a sudoswap pool");
        bool success = false; 
        ISudoGatePoolSource sudogate = ISudoGatePoolSource(SUDOGATE_ADDRESS);
        if (!sudogate.knownPool(sudoswapPool)) { 
            // register the pool with SudoGate so that we're able to buy from it
            success = sudogate.registerPool(sudoswapPool); 
        }
        return success;
    }

    function ADD_NFT_CONTRACT_AND_REGISTER_POOL(address sudoswapPool) payable public returns (bool) {
        /* 
        Register a sudoswap pool for an NFT with SudoGate and then add that NFT contract
        to the SudoRug lottery.
        */
        REGISTER_SUDOSWAP_POOL(sudoswapPool);
        ADD_NFT_CONTRACT_TO_BUY_LIST(address(LSSVMPair(sudoswapPool).nft()));
        return true;
    }

    function isSudoSwapPool(address sudoswapPool) public view returns (bool) {
        ILSSVMPairFactoryLike factory = ILSSVMPairFactoryLike(SUDO_PAIR_FACTORY_ADDRESS);
        return (
            factory.isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ETH) ||
            factory.isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH)
        );
    }

    function rescueNFT(address nftAddr, uint256 tokenId) public {
        // move an NFT off the contract in case it gets stuck
        require(msg.sender == owner, "Only owner allowed to call rescueNFT");
        require(IERC721(nftAddr).ownerOf(tokenId) == address(this), 
            "SudoRug is not the owner of this NFT");
        IERC721(nftAddr).transferFrom(address(this), msg.sender, tokenId);
    }

    function rescueNFT_AddToTreasury(address nftAddr, uint256 tokenId) public {
        // move an NFT off the contract in case it gets stuck
        require(msg.sender == owner, "Only owner allowed to call rescueNFT_AddToTreasury");
        require(IERC721(nftAddr).ownerOf(tokenId) == address(this), 
            "SudoGate is not the owner of this NFT");
        require(knownNFTContract(nftAddr), "NFT contract not in allow-list");
        nftState.treasury.push(NFT(nftAddr, tokenId));
    }


    // ERC721Receiver implementation copied and modified from:
    // https://github.com/GustasKlisauskas/ERC721Receiver/blob/master/ERC721Receiver.sol
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) public pure returns(bytes4) {
        return this.onERC721Received.selector;
    }

}