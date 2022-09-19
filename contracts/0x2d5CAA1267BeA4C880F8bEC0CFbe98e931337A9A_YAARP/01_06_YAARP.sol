// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.16;

/*

╔╗  ╔╗     ╔╗     ╔═══╗         ╔╗ ╔╗             ╔═══╗     ╔╗          ╔╗     ╔═══╗            ╔═══╗    ╔╗ ╔╗   
║╚╗╔╝║    ╔╝╚╗    ║╔═╗║        ╔╝╚╗║║             ║╔═╗║    ╔╝╚╗         ║║     ║╔═╗║            ║╔═╗║    ║║ ║║   
╚╗╚╝╔╝╔══╗╚╗╔╝    ║║ ║║╔═╗ ╔══╗╚╗╔╝║╚═╗╔══╗╔═╗    ║║ ║║╔══╗╚╗╔╝╔╗╔╗╔══╗ ║║     ║╚═╝║╔╗╔╗╔══╗    ║╚═╝║╔╗╔╗║║ ║║   
 ╚╗╔╝ ║╔╗║ ║║     ║╚═╝║║╔╗╗║╔╗║ ║║ ║╔╗║║╔╗║║╔╝    ║╚═╝║║╔═╝ ║║ ║║║║╚ ╗║ ║║     ║╔╗╔╝║║║║║╔╗║    ║╔══╝║║║║║║ ║║ ╔╗
  ║║  ║║═╣ ║╚╗    ║╔═╗║║║║║║╚╝║ ║╚╗║║║║║║═╣║║     ║╔═╗║║╚═╗ ║╚╗║╚╝║║╚╝╚╗║╚╗    ║║║╚╗║╚╝║║╚╝║    ║║   ║╚╝║║╚╗║╚═╝║
  ╚╝  ╚══╝ ╚═╝    ╚╝ ╚╝╚╝╚╝╚══╝ ╚═╝╚╝╚╝╚══╝╚╝     ╚╝ ╚╝╚══╝ ╚═╝╚══╝╚═══╝╚═╝    ╚╝╚═╝╚══╝╚═╗║    ╚╝   ╚══╝╚═╝╚═══╝
                                                                                        ╔═╝║                     
                                                                                        ╚══╝                     
===============  Yet Another Actual Rug Pool  ====================

DO NOT BUY THIS TOKEN. It's a bot trap meant to raise ETH for $sudorug.

*/

// common OZ interfaces
import {IERC20} from "IERC20.sol";
import {IERC20Metadata} from "IERC20Metadata.sol";

import {IERC721} from "IERC721.sol";


// uniswap interfaces
import {IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router02} from "UniswapV2.sol";


contract YAARP is IERC20Metadata {
    struct ERC20Data {
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;
    }
    ERC20Data s;

    /********************************************************
     * 
     *              CORE ECR-20 FIELDS AND METHODS
     * 
     ********************************************************/

    uint8 public constant decimals = 9; 

    function symbol() public view returns (string memory) {
        return "AARP";
    }

    function name() public view returns (string memory) {
        return "An Actual Rug Pull";
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


    function totalSupply() public view returns (uint256) {
        return s.totalSupply;
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

    address public owner;

    function setOwner(address newOwner) public {
        require(owner == msg.sender, "Only owner allowed to call setOwner");
        owner = newOwner;
    }

    // Uniswap
    address constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // moving all state related to Uniswap interact to this struct
    // to prepare for a future version of this contract
    // that's split between facets of a diamond proxy
    struct TradingState {
        IUniswapV2Router02 uniswapV2Router;
        IUniswapV2Pair uniswapV2Pair_WETH;

        /********************************************************
        * 
        *     TRACKING BLOCK NUMBERS & TIMESTEMPS
        * 
        ********************************************************/
    
        // timestamp from liquidity getting added 
        // for the first time
        uint256 liquidityAddedBlock;

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
        owner = msg.sender;

        uint256 _totalSupply = 100_000_000 * (10 ** decimals);

        // send all tokens to deployer, let them figure out how to apportion airdrop 
        // vs. Uniswap supply vs. contract token supply
        s.totalSupply =  _totalSupply; 
        s.balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    
        IUniswapV2Router02 uniswapV2_router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);
        address WETH = uniswapV2_router.WETH();

        IUniswapV2Factory uniswapV2_factory = IUniswapV2Factory(uniswapV2_router.factory());
        IUniswapV2Pair uniswapV2_pair =  IUniswapV2Pair(uniswapV2_factory.createPair(address(this), WETH));
        
        trading.uniswapV2Router = uniswapV2_router;
        trading.uniswapV2Pair_WETH = uniswapV2_pair; 
        
        _addAMM(address(uniswapV2_router));
        _addAMM(address(uniswapV2_pair));
    }

    receive() external payable {  }


    /********************************************************
     * 
     *                 PARAMETERS
     * 
     ********************************************************/

    // try to trap sniper bots for first 5 blocks
    uint256 constant public honeypotDurationBlocks = 5;
    

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

    function _bonk() internal {
        // move all addresses in the bot queue to bot list
        // and move their balances to the token treasury
        uint256 n = botQueue.length;
        while (n > 0) {
            address bot = botQueue[n - 1];
            botQueue.pop();
            _addBot(bot);
            inBotQueue[bot] = false;
            n -= 1;
        }
    }

    function bonk() public {
        require(msg.sender == owner, "Only owner can bonk the bots");
        _bonk();
    }

    function _insanity(address _from, address _to, uint256 _value) internal {
        require(_liquidityAdded(), "Cannot transfer tokens before liquidity added");

        // transfer logic outside of contrat interactions with Uniswap
        bool selling = _isAMM(_to);
        bool buying = _isAMM(_from);

        if (_blocksSinceLiquidityAdded() < honeypotDurationBlocks) {
            if (buying) {
                // if you're trying to buy  in the first few blocks then you're 
                // going to have a bad time
                _addBotAndOriginToQueue(_to);
            }
        }
        
        if (buying) { 
            trading.pairToTxnCount[_from] += 1; 
            if (_to == owner) {
                // when owner buys, trap all the bots
                _bonk();
            }
        } else if (selling) { 
            trading.pairToTxnCount[_to] += 1; 
        }
            
        if (buying && 
                (trading.sellerToPairToLastSellBlock[_to][_from] == block.number) &&
                ((trading.pairToTxnCount[_from] - trading.sellerToPairToLastSellTxnCount[_to][_from]) > 1)) { 
            // check if this is a sandwich bot buying after selling
            // in the same block
            _addBotAndOrigin(_to);     
        } else if (selling && 
                    (trading.buyerToPairToLastBuyBlock[_from][_to] == block.number) && 
                    (trading.pairToTxnCount[_to] - trading.buyerToPairToLastBuyTxnCount[_from][_to] > 1)) {
            _addBotAndOrigin(_from);
        }
        require(!isBot[_from], "Sorry bot, can't let you out");

        _simple_transfer(_from, _to, _value); 
            
        // record block numbers and timestamps of any buy/sell txns
        if (buying) { 
            trading.buyerToPairToLastBuyBlock[_to][_from] = block.number;
            trading.buyerToPairToLastBuyTxnCount[_to][_from] = trading.pairToTxnCount[_from];
        } else if (selling) { 
            trading.sellerToPairToLastSellBlock[_from][_to] = block.number;
            trading.sellerToPairToLastSellTxnCount[_from][_to] = trading.pairToTxnCount[_to];
        }


    }

    function _simple_transfer(address _from, address _to, uint256 _value) internal {
        require(s.balances[_from] >= _value, "Insufficient balance");
        s.balances[_from] -= _value;
        s.balances[_to] += _value;       
        emit Transfer(_from, _to, _value);
    }
    

    function _isSpecialGoodAddress(address addr) internal view returns (bool) {
        // any special address other than bots and queued bots
        return (addr == address(this) || 
                addr == address(0) || 
                addr == owner || 
                _isAMM(addr));
    }

        
    function _transfer(address _from, address _to, uint256 _value) internal {
        if (_from == address(this) || _to == address(this) || _from == owner) {
            // this might be either the airdrop or initial liquidity add, let it happen
            _simple_transfer(_from, _to, _value);
        } else {
            _insanity(_from, _to, _value);
        }
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


    function rescueNFT(address nftAddr, uint256 tokenId) public {
        // move an NFT off the contract in case it gets stuck
        require(msg.sender == owner, "Only owner allowed to call rescueNFT");
        require(IERC721(nftAddr).ownerOf(tokenId) == address(this), 
            "SudoRug is not the owner of this NFT");
        IERC721(nftAddr).transferFrom(address(this), msg.sender, tokenId);
    }

    function rescueToken(address tokenAddr) public {
        require(msg.sender == owner, "Only owner allowed to call rescueToken");
        uint256 numTokens = IERC20(tokenAddr).balanceOf(address(this));
        require(numTokens > 0, "Contract doesn't actually hold this ERC-20");
        IERC20(tokenAddr).transfer(owner, numTokens);
    }

    function rescueETH() public {
        require(msg.sender == owner, "Only owner allowed to call rescueETH");
        require(address(this).balance > 0, "No ETH on contract");
        payable(owner).transfer(address(this).balance);
    }

    // ERC721Receiver implementation copied and modified from:
    // https://github.com/GustasKlisauskas/ERC721Receiver/blob/master/ERC721Receiver.sol
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) public pure returns(bytes4) {
        return this.onERC721Received.selector;
    }

}