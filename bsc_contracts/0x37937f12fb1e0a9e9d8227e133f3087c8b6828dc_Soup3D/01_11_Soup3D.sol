pragma solidity ^0.6.0;

import "./library/SafeMath.sol";
import "./library/UintCompressor.sol";
import "./library/KeysCalcLong.sol";
import "./library/Datasets.sol";
import "./library/Utils.sol";
import "./library/ReentrancyGuard.sol";
import "./library/IERC20Burnable.sol";
import "./library/IERC20.sol";
import "./Uniswapv2Interface.sol";
import './library/IWETH.sol';

contract Soup3D is ReentrancyGuard {
    using SafeMath for *;
    using KeysCalcLong for uint256;
	
    string constant public name = "Soup3D";

    // config
    uint256 constant private rndInit_ = 1 hours;         // round timer starts at this
    uint256 constant private rndInc_ = 10 seconds;       // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 24 hours;         // max length a round timer can be
    uint256 constant private burnFundFee = 5;     // represent the key proceeds allocation percentage to the dev fund
    uint256 constant private initialBurnFee = 5;  // represent the key proceeds allocation percentage that will be burn
       
    uint256 constant private playerFees = 53;  // represent the key proceeds allocation percentage to current players
    uint256 public potWinnerShare = 80;  // represent the pot allocation percentage to winner

    IERC20 public WBNB_;
    IERC20Burnable public primaryToken_; // primary token accepted for Soup3D
    UniswapRouterV2 public router_;      // pancake router

    uint256 public rID_;      // round id number / total rounds that have happened
    uint256 public burnFund_; // burn fund
    address public owner_; 

    mapping(address => bool) whitelist_; // tokens that are whitelisted for Soup3D
    mapping (address => Datasets.Player) public plyr_;   // (pID => data) player data
    mapping (address => mapping (uint256 => Datasets.PlayerRounds)) public plyrRnds_; 
    mapping (uint256 => Datasets.Round) public round_;   // (rID => data) round data

    constructor()
        public
    {
        owner_ = msg.sender;
    }

    fallback() external payable {}

    // modifiers
    /**
     * @dev used to make sure no one can interact with contract until it has 
     * been activated. 
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet"); 
        _;
    }
    
    /**
     * @dev prevents contracts from interacting with soup3d 
     */
    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx 
     */
    modifier isWithinLimits(uint256 _value) {
        requireIsWithinLimits(_value);
        _;
    }

    function requireIsWithinLimits(uint256 _value) pure private {
        require(_value >= 1000000000, "min 0.000000001"); // 0.000000001
        require(_value <= 100000000000000000000000, "max 100000"); // 100000
    }
    
    // external functions

    /**
     * @dev swaps burn fund to SOUP and burn
     */
    function burnFunds(uint256 _amount, uint256 _minAmountOut, address[] calldata _swapPath)
        external
        nonReentrant
    {
        require(msg.sender == owner_, "only owner");
        require(_swapPath[_swapPath.length - 1] == address(primaryToken_), "invalid path output");
        require(_swapPath[0] == address(WBNB_), "invalid path input");

        burnFund_ = burnFund_.sub(_amount);

        uint256 deadline = block.timestamp.add(360);
        uint256[] memory amounts = router_.swapExactTokensForTokens(
            _amount,
            _minAmountOut,
            _swapPath,
            address(this),
            deadline
        );
        uint256 _value = amounts[amounts.length - 1];
        primaryToken_.burn(_value);
    }

    /**
     * @dev sets the uniswap router for Soup3D
     */
    function setRouter(address _routerAddress) private nonReentrant {
        router_ = UniswapRouterV2(_routerAddress);
    }

    /**
     * @dev sets the wbnb address for Soup3D
     */
    function setWBNB(address _wbnbAddress) private nonReentrant {
        WBNB_ = IERC20(_wbnbAddress);
    }

    /**
     * @dev sets the primary token used for Soup3D purchases
     */
    function setPrimaryToken(address _primaryTokenAddress) private nonReentrant {
        primaryToken_ = IERC20Burnable(_primaryTokenAddress);
    }

    /**
     * @dev sets share of the pot the winner takes home
     */
    function setPotWinnerShare(uint256 _potWinnerShare) public nonReentrant {
        require(msg.sender == owner_, "only owner");
        require(_potWinnerShare >= 80, "min 80"); // 80%
        require(_potWinnerShare <= 100, "max 100"); // 100%
        potWinnerShare = _potWinnerShare;
    }

    /**
     * @dev whitelist BEP20 token for Soup3D
     */
    function addWhitelist(address _tokenContract) public nonReentrant {
        require(msg.sender == owner_, "only owner");
        require(whitelist_[_tokenContract] != true, "token already whitelisted");
        // approve this contract for infinite amount to call trading router contract
        Utils.approveTokenTransfer(_tokenContract, address(router_), 2**256 - 1);
        whitelist_[_tokenContract] = true;
    }

    /**
     * @dev converts all incoming coins to keys.
     * _initialBurnFee amount will be locked in the contract instead of burnt to support non Burnable BEP20 tokens
     */
    function buyXidBep20(address _tokenContract, uint256 _amountIn, uint256 _minAmountOut, address[] calldata _swapPath)
        isActivated()
        isHuman()
        external
        nonReentrant
    {   
        require(_swapPath.length > 1, "invalid path length");
        require(whitelist_[_tokenContract] == true, "token not whitelisted");
        require(_swapPath[_swapPath.length - 1] == address(WBNB_), "invalid path output");

        // calculate burn amount
        // setup local rID 
        uint256 _rID = rID_;
        uint256 _initialBurnFee = initialBurnFee;
        if (round_[_rID].pot > 500000000000000000000) { // 500 BNB
            _initialBurnFee = initialBurnFee / 2;
        }

        uint256 _burnAmount = (_amountIn.mul(_initialBurnFee)).div(100);

        // transfer bep20 tokens to contract
        Utils.transferTokensIn(msg.sender, _tokenContract, _amountIn);

        // update _amountIn
        _amountIn = _amountIn.sub(_burnAmount);

        uint256 deadline = block.timestamp.add(360);
        uint256 wbnbBalanceBefore = WBNB_.balanceOf(address(this));

        router_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _minAmountOut,
            _swapPath,
            address(this),
            deadline
        );

        uint256 wbnbBalanceAfter = WBNB_.balanceOf(address(this));
        uint256 value = wbnbBalanceAfter.sub(wbnbBalanceBefore);
        
        requireIsWithinLimits(value); // check again its within limits, if not revert

        // buy core 
        buyCore(msg.sender, value);
    }

    /**
     * @dev essentially the same as buy, but instead of you sending ether 
     * from your wallet, it uses your unwithdrawn earnings.
     * @param _eth amount of earnings to use (remainder returned to gen vault)
     */
    function reLoadXid(uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        nonReentrant
        external
    {
        // reload core
        reLoadCore(msg.sender, _eth);
    }

    /**
     * @dev withdraws all of your earnings.
     */
    function withdraw()
        isActivated()
        isHuman()
        nonReentrant
        external
    {
        // setup local rID 
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // setup temp var for player eth
        uint256 _eth;
        
        // check to see if round has ended and no one has run round end yet
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].addr != address(0))
        {
            // end the round (distributes pot)
			round_[_rID].ended = true;
            
			// get their earnings
            _eth = withdrawEarnings(msg.sender);
            
            // give bnb
            if (_eth > 0)
                WBNB_.withdraw(_eth);
                (bool success, ) = msg.sender.call{value: _eth}(new bytes(0));
                require(success, 'safeTransferETH: BNB transfer failed');
            
        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(msg.sender);
            
            // give bnb
            if (_eth > 0)
                WBNB_.withdraw(_eth);
                (bool success, ) = msg.sender.call{value: _eth}(new bytes(0));
                require(success, 'safeTransferETH: BNB transfer failed');
        }
    }
    
    // views

    function isWhitelisted(address _tokenContract) public view returns(bool) {
        return whitelist_[_tokenContract];
    }

    function viewRouter() public view returns(address) {
        return address(router_);
    }

    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].addr == address(0))))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // init
    }
    
    /**
     * @dev returns time left
     * @return time left in seconds
     */
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt).sub(_now) );
        else
            return(0);
    }
    
    /**
     * @dev returns player earnings per vaults 
     * @return winnings vault
     * @return general vault
     */
    function getPlayerVaults(address _pID)
        public
        view
        returns(uint256 ,uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].addr != address(0))
        {
            // if player is winner 
            if (round_[_rID].addr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(potWinnerShare)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   )
                );
            // if player is not the winner
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  )
                );
            }
            
        // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd))
            );
        }
    }
    
    /**
     * solidity hates stack limits.  this lets us avoid that hate 
     */
    function getPlayerVaultsHelper(address _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(  ((((round_[_rID].mask)).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }
    
    /**
     * @dev returns all current round info needed for front end
     * @return round id 
     * @return total keys for round 
     * @return time round ends
     * @return time round started
     * @return current pot 
     * @return total bnb spent
     * @return current lead address
     */
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, address)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        return
        (
            _rID,                           //1
            round_[_rID].keys,              //2
            round_[_rID].end,               //3
            round_[_rID].strt,              //4
            round_[_rID].pot,               //5
            round_[_rID].eth,               //6 
            round_[_rID].addr               //7 
        );
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will 
     * use msg.sender 
     * @param _addr address of the player you want to lookup 
     * @return keys owned (current round)
     * @return winnings vault
     * @return general vault 
	 * @return player round eth
     */
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        
        return
        (
            plyrRnds_[_addr][_rID].keys,                                            //0
            plyr_[_addr].win,                                                       //1
            (plyr_[_addr].gen).add(calcUnMaskedEarnings(_addr, plyr_[_addr].lrnd)), //2
            plyrRnds_[_addr][_rID].eth                                              //3
        );
    }


    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not
     */
    function buyCore(address _pID, uint256 value)
        private
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // if round is active
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].addr == address(0)))) 
        {
            // call core 
            core(_rID, _pID, value);
        
        // if round is not active     
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false) 
            {
                // end the round (distributes pot) & start new round
			    round_[_rID].ended = true;
                endRound();
            }
            
            // put eth in players vault 
            plyr_[_pID].gen = plyr_[_pID].gen.add(value);
        }
    }
    
    /**
     * @dev logic runs whenever a reload order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not 
     */
    function reLoadCore(address _pID, uint256 _eth)
        private
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // if round is active
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].addr == address(0)))) 
        {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player 
            // tried to spend more eth than they have.
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            
            // call core 
            core(_rID, _pID, _eth);
        
        // if round is not active and end round needs to be ran   
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            endRound();

        }
    }
    
    /**
     * @dev this is the core logic for any buy/reload that happens while a round 
     * is live.
     */
    function core(uint256 _rID, address _pID, uint256 _eth)
        private
    {
        // if player is new to round
        if (plyrRnds_[_pID][_rID].keys == 0)
            managePlayer(_pID);
        
        // if eth left is greater than min eth allowed
        if (_eth > 1000000000) 
        {
            
            // mint the new keys
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);
            
            // if they bought at least 1 whole key
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                // set new leaders
                if (round_[_rID].addr != _pID)
                    round_[_rID].addr = _pID;  
            }
         
            // update player 
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
            
            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);

            // distribute eth
            distributeExternal(_eth);
            distributeInternal(_rID, _pID, _eth, _keys);
        }
    }

    // calculators

    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(address _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }
    
    /** 
     * @dev returns the amount of keys you would get given an amount of eth. 
     * @param _rID round ID you want price for
     * @param _eth amount of eth sent in 
     * @return keys received 
     */
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].addr == address(0))))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else // rounds over.  need keys for new round
            return ( (_eth).keys() );
    }
    
    /** 
     * @dev returns current eth price for X keys.  
     * @param _keys number of keys desired (in 18 decimal format)
     * @return amount of eth needed to send
     */
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].addr == address(0))))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else // rounds over.  need price for new round
            return ( (_keys).eth() );
    }


    // tools

    /**
     * @dev decides if round end needs to be run & new round started.  and if 
     * player unmasked earnings from previously played rounds need to be moved.
     */
    function managePlayer(address _pID)
        private
    {
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);
            
        // update player's last round played
        plyr_[_pID].lrnd = rID_;
    }
    
    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound()
        private
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab our winning player and team id's
        address _winPID = round_[_rID].addr;
        
        // grab our pot amount
        uint256 _pot = round_[_rID].pot;
        
        // calculate our winner share, community rewards, gen share, 
        // and amount reserved for next pot 
        uint256 _win = (_pot.mul(potWinnerShare)) / 100;
        uint256 _res = _pot.sub(_win);
        
        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);
        
        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].pot = _res;
    }
    
    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(address _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // put in gen vault
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // zero out their earnings by updating mask
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }
    
    /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        // grab time
        uint256 _now = now;
        
        // calculate time based on number of keys bought
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].addr == address(0)) // new round
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);
        
        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

    /**
     * @dev distributes eth based on fees to com
     */
    function distributeExternal(uint256 _eth)
        private
    {
        uint256 _com = _eth.div(20);
        burnFund_ = burnFund_.add(_com);
    }
    
    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, address _pID, uint256 _eth, uint256 _keys)
        private
    {
        // calculate gen share
        uint256 _gen = (_eth.mul(playerFees)) / 100;
        
        // update eth balance (eth = eth - com share)
        _eth = _eth.sub((_eth.mul(burnFundFee)) / 100);
        
        // calculate pot 
        uint256 _pot = _eth.sub(_gen);
        
        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
        // add eth to pot
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);
    }

    /**
     * @dev updates masks for round and player when keys are bought
     * @return dust left over 
     */
    function updateMasks(uint256 _rID, address _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
        /* MASKING NOTES
            earnings masks are a tricky thing for people to wrap their minds around.
            the basic thing to understand here.  is were going to have a global
            tracker based on profit per share for each round, that increases in
            relevant proportion to the increase in share supply.
            
            the player will have an additional mask that basically says "based
            on the rounds mask, my shares, and how much i've already withdrawn,
            how much is still owed to me?"
        */
        
        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
            
        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);
        
        // calculate & return dust
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }
    
    /**
     * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
     * @return earnings in wei format
     */
    function withdrawEarnings(address _pID)
        private
        returns(uint256)
    {
        // update gen vault
        updateGenVault(_pID, plyr_[_pID].lrnd);
        
        // from vaults 
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
        }

        return(_earnings);
    }

    // security

    /** upon contract deploy, it will be deactivated.  this is a one time
     * use function that will activate the contract.  we do this so devs 
     * have time to set things up on the web end                            
     **/
    bool public activated_ = false;
    function activate(address _primaryToken, address _wbnbAddress, address _routerAddress)
        public
    {
        // only owner can activate 
        require(
            msg.sender == owner_,
            "only owner just can activate"
        );
        
        // can only be ran once
        require(activated_ == false, "soup3 already activated");

        // approve uniswap router to spend our wbnb
        Utils.approveTokenTransfer(_wbnbAddress, _routerAddress, 2**256 - 1);
        
        // Add router
        setRouter(_routerAddress);

        // set WBNB address
        setWBNB(_wbnbAddress);

        // add to whitelist
        addWhitelist(_primaryToken);

        // set primary token
        setPrimaryToken(_primaryToken);
        
        // activate the contract 
        activated_ = true;
        
        // lets start first round
		rID_ = 1;
        round_[1].strt = now;
        round_[1].end = now + rndInit_;
    }
}