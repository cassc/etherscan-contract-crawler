// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IAccessContract.sol";
import "../interfaces/Sale/IBlxPresale.sol";
import "../interfaces/IBlxToken.sol";
import "../interfaces/Sale/IIBCO.sol";

import "hardhat/console.sol";

contract BlxPresale is IBlxPresale, ERC2771Context, AccessContract, Initializable {
    uint public softCap; //200.000 USDC
    uint public hardCap; //1.000.000 USDC
    uint public minAmount; //100 USDC
 
    uint public presaleDuration; //14 days
    //additional time for admin to load a whitelist 
    uint public additionalTime; //30 days
    
    using SafeERC20 for IERC20;
    //BLX amount received for 1 USDC 
    uint public blxRate = 10; //1 BLX = 0.1 USDC
    
    //presale status
    //true - after presale start
    //false - hard cap reached
    bool public presaleActive;
    
    bool public softCapReached;// from whitelisted
    bool public hardCapReached;// HYPOTETICALLY, we still need to check
                               // if funds were aquired from whitelisted users

    struct Collateral {
        uint amount;//invested amount
        bool redeemed;//claimed or refunded
    }
    mapping(address => Collateral) public collaterals;
    //all participants 
    //address[] public investors;

    //amount aquired from whitelisted users
    uint public amountFromWhitelisted;
    //amount claimed
    uint public amountClaimed;
    //amount transfered to DAO agent address
    uint public amountTransfered;
    
    //start time
    uint public presaleStart;
    //start time + presale duration
    uint public presaleEnd;
    //start time + additional time
    uint public presaleEndPlus;

    // tx cost in USDC value in case of metaTx usage(add on top of the purchase amount)
    uint public txCost;
    // fee(gas cost) collected
    uint public txFee;

    struct Rewards {
        uint referred_amount; // presale referred amount in USDC
        uint referred_blx; // presale referred amount in BLX
        uint referred_ibco_amount; // from ibco
        uint referred_ibco_blx; // blx from ibco
        uint rewards;  // eligible total rewards in BLX
        uint claimed;  // claimed rewards in BLX
    }

    // the referrer of a given BLX buyer
    mapping(address => address) public referrers;
    // total 'referred' amount of a given referrer
    mapping(address => Rewards) public referral_rewards;
    
    uint public total_rewards;
    uint public total_claimed_rewards;

    // reward unclaimed burnt(no longer claimable)
    bool public rewards_burnt;
    // unsold burnt
    bool public unsold_burnt;

    event NewPresaleReferral(address indexed referrer, address user);
    event NewIBCOReferral(address indexed referrer, address user);
    event NewPurchase(address indexed buyer, uint usdc, uint blx);
    event BlxClaimed(address indexed user, uint blx);
    event BlxRewardsBurnt(address indexed user, uint blx);
    event PresaleStart(uint endTime, uint duration,  uint additionalDuration, uint softCap, uint hardCap);
    event BurnUnused(uint blx);

    IERC20 USDC;
    IBlxToken BLX;

    address public daoAgentAddress;
    address public ibcoAddress;
    address public tokenSaleAddress;

    constructor (address trustedForwarder, address _usdcAddress, address _blxAddress, address _tokenSaleAddress) ERC2771Context(trustedForwarder) {
        require(_usdcAddress != address(0), "PRESALE:USDC_ADDRESS_ZERO");
        require(_blxAddress != address(0), "PRESALE:BLX_ADDRESS_ZERO");
        require(_tokenSaleAddress != address(0), "PRESALE:TOKENSALE_ADDRESS_ZERO");

        USDC = IERC20(_usdcAddress);
        BLX = IBlxToken(_blxAddress);
        tokenSaleAddress = _tokenSaleAddress;
   }
    
    function config(
        address _daoAgentAddress,
        address _ibcoAddress,
        uint _presaleDuration,
        uint _additionalTime,
        uint _softCap,
        uint _hardCap,
        uint _start
    )   
        external
        onlyOwner
        initializer
    {
        require(_daoAgentAddress != address(0), "PRESALE:DAO_AGENT_ADDRESS_ZERO");
        require(_ibcoAddress != address(0), "PRESALE:IBCO_ADDRESS_ZERO");
        require(_start > 0, "PRESALE:NEED_START_TIME");
        require(_presaleDuration > 0, "PRESALE:NEED_DURATION");
        daoAgentAddress = _daoAgentAddress;
        ibcoAddress = _ibcoAddress;
        presaleStart = _start;
        presaleDuration = _presaleDuration;
        additionalTime = _additionalTime;
        softCap = _softCap;
        hardCap = _hardCap;
        presaleEnd = _start + _presaleDuration;
        presaleEndPlus = _start + _additionalTime;
    }

    modifier onlyIBCO {
        require(_msgSender() == ibcoAddress, "PRESALE:ONLY_IBCO");
        _;
    }

    /// @dev launches the presale
    function start() external onlyTrustedCaller {
        require(amountFromWhitelisted == 0 && !presaleActive, "PRESALE:ALREADY_STARTED");
        require(block.timestamp < presaleEnd, "PRESALE:PRESALE_CLOSED");
        // need sufficient BLX to full sale AND reward(for presale stage) 
        //uint requiredBLX = hardCap * blxRate + hardCap; // hardCap(in USDC) * 10 + rewards(10% of BLX hardCap) 
        //uint chainid = block.chainid;
        //require(BLX.balanceOf(address(this)) >= requiredBLX || (chainid != 1 && chainid != 31337) , "PRESALE:NEED_BLX");
        presaleActive = true;
        emit PresaleStart(presaleEnd, presaleDuration, additionalTime, softCap, hardCap);
    }

    /// @dev set minimum amount USDC to enter presale
    /// @param amount USDC amount to enter in wei
    function setMinAmount(uint amount) external onlyTrustedCaller {
        minAmount = amount;
    }
    /// @dev set tx cost charged
    /// @param amount USDC amount to enter in wei
    function setTxCost(uint amount) external onlyTrustedCaller {
        txCost = amount;
    }
    /// @dev set ibco address
    /// @param _ibcoAddress IBCO contract address
    /// only if current ibco address is empty or not started
    /// used in case IBCO condition changed after presale stage
    function setIBCO(address _ibcoAddress) external onlyTrustedCaller {
        require((ibcoAddress == address(0) || !IIBCO(ibcoAddress).started()), "PRESALE:IBCO_ALREADY_START");
        require(BLX.balanceOf(ibcoAddress) == 0, "PRESALE:IBCO_HAS_BLX");
        require(_ibcoAddress != address(0) && !IIBCO(_ibcoAddress).started(), "PRESALE:ONLY_FRESH_IBCO");
        ibcoAddress = _ibcoAddress;
    }

    /// @dev return BLX
    /// only if not started, in cases there need to be logic revision BETFORE start(and BLX already deposited)
    function returnBLX() external onlyTrustedCaller {
        require(amountFromWhitelisted == 0 && block.timestamp < presaleStart, "PRESALE:ALREADY_START");
        BLX.transfer(daoAgentAddress, BLX.balanceOf(address(this)));
    }

    /// @dev returns true if soft cap reached, false otherwise
    /// needed to allow IBCO start
    function presaleSoftCapStatus() external view returns(bool) {
        return softCapReached;
    }

    /// @dev returns true if presale closed
    /// needed to allow IBCO start
    function presaleClosed() external view returns(bool) {
        return (block.timestamp >= presaleEnd && presaleEnd > 0) || amountFromWhitelisted >= hardCap;
    }

    /// @dev returns true if reward burnt
    /// needed to allow IBCO claim
    function rewardBurnt() external view returns(bool) {
        return rewards_burnt;
    }


    /// @dev receive USDC from users
    /// @param amount USDC amount
    /// @param msgSender user making the purchase, we trust only TokenSale contract
    function purchase(uint amount, address referrer, address msgSender, bool collectFee) external {
        require(_msgSender() == tokenSaleAddress,"PRESALE:ONLY_FROM_TOKENSALE");
        _enterPresale(amount, referrer, msgSender, collectFee);
    }

    /// @dev receive USDC from users
    /// @param amount USDC amount

    function enterPresale(uint amount, address referrer) external {
        _enterPresale(amount, referrer, _msgSender(), isTrustedForwarder(msg.sender));
    }

    /// @dev receive USDC from users
    /// @param amount USDC amount
    function _enterPresale(uint amount, address referrer, address msgSender, bool collectFee) private {
        require(block.timestamp >= presaleStart, "PRESALE:PRESALE_NOT_STARTED");
        require(presaleActive, amountFromWhitelisted >= hardCap || (block.timestamp >= presaleEnd && presaleEnd > 0) ? "PRESALE:PRESALE_CLOSED" : "PRESALE:PRESALE_NOT_STARTED");
        require(block.timestamp < presaleEnd, "PRESALE:PRESALE_CLOSED");
        require(amount >= minAmount || amount == maxPurchase(), "PRESALE:MIN_AMOUNT_REQUIREMENT_NOT_MET");
        require(amount + amountFromWhitelisted  <= hardCap, "PRESALE:AMOUNT_EXCEED_SALES_BALANCE");
        uint blx = amount * blxRate;

        // add fee for metaTx(note we use msg.sender not intended _msgSender())
        uint fee = collectFee ? txCost : 0;
        // take USDC
        USDC.transferFrom(msgSender, address(this), amount + fee);
        // remember fee collected
        txFee += fee;

        // all wallets are accepted
        amountFromWhitelisted += amount;

        //not commited before OR not commited and refunded
        if(collaterals[msgSender].amount == 0 && !collaterals[msgSender].redeemed) {
            collaterals[msgSender].amount = amount;
            collaterals[msgSender].redeemed = false;
        }
        //commited but not claimed
        else {
            collaterals[msgSender].amount += amount;
            collaterals[msgSender].redeemed = false;
        }
        _updateReferral(msgSender, referrer, amount, blx, false);
        // state can only be updated AFTER
        if (!softCapReached && amountFromWhitelisted >= softCap) softCapReached = true;
        if (!hardCapReached && (amountFromWhitelisted >= hardCap)) {
            hardCapReached = true; presaleActive = false;
        }
        emit NewPurchase(msgSender, amount, blx);
    } 

    function _updateReferral(address user, address referrer, uint amount, uint blx, bool isIBCO) private {
        address _referrer = referrers[user];
        if (_referrer == address(0) // first specified referrer, later change ignored
            && referrer != address(0) 
            && referrer != user // no self-referral
            ) {
            // new user with referrer info
            referrers[user] = referrer; 
            _referrer = referrer;
        }

        if (_referrer != address(0)) {
            bool newPresaleReferrer = !isIBCO && referral_rewards[_referrer].referred_amount == 0;
            bool newIBCOReferrer = isIBCO && referral_rewards[_referrer].referred_ibco_amount == 0;
            if (isIBCO) {
                referral_rewards[_referrer].referred_ibco_amount += amount;
                referral_rewards[_referrer].referred_ibco_blx += blx;
            }
            else {
                referral_rewards[_referrer].referred_amount += amount;
                referral_rewards[_referrer].referred_blx += blx;
            }
            if (newIBCOReferrer) {
                emit NewIBCOReferral(_referrer, user);
            }
            if (newPresaleReferrer) {
                emit NewPresaleReferral(_referrer, user);
            }
        }
    }

    function _calcRewards(address referrer) private returns (uint rewards) {
        bool presaleSoftCapReached = softCapReached;
        bool ibcoSoftCapReached = IIBCO(ibcoAddress).softCapStatus();
        bool ibcoClosed = IIBCO(ibcoAddress).closed();
        uint referred_amount = (presaleSoftCapReached ? referral_rewards[referrer].referred_amount : 0)
                               + 
                               (ibcoSoftCapReached && ibcoClosed ? referral_rewards[referrer].referred_ibco_amount : 0);

        uint referred_blx = (presaleSoftCapReached ? referral_rewards[referrer].referred_blx : 0)
                            + 
                            (ibcoSoftCapReached && ibcoClosed ? referral_rewards[referrer].referred_ibco_blx : 0);

        if (referred_blx > 0) {
            // previously calculated rewards
            uint calculated_rewards = referral_rewards[referrer].rewards;

            if (referred_amount > 100_000_000_000) { // 100K+ USD(6 decimals)
                rewards = referred_blx / 10; // 10%
            } else if (referred_amount > 20_000_000_000) { // 20K+ 
                rewards = referred_blx * 7 / 100;// 7%
            } else if (referred_amount > 10_000_000_000) { // 10K+
                rewards = referred_blx / 20;// 5%
            } else if (referred_amount > 5_000_000_000) { // 5K+
                rewards = referred_blx * 3 / 100; // 3%
            } else { // base
                rewards = referred_blx / 100; // 1%
            }
            
            // update total rewards
            if (rewards > calculated_rewards) {
                referral_rewards[referrer].rewards = rewards;
                total_rewards += rewards - calculated_rewards;
            } 
            else
                rewards = 0; // case where presale claim after ibco claim(already include presale), no double count
        }
    }

    /// @dev allows to claim BLX for presale users
    function claim() external {
        address msgSender = _msgSender();
        require(block.timestamp >= presaleStart, "PRESALE:PRESALE_NOT_STARTED");
        require(
            (block.timestamp >= presaleEnd && presaleEnd > 0) || hardCapReached,
            "PRESALE:PRESALE_IN_PROGRESS"
        );
        //require(softCapReached, "PRESALE:TOTAL_AMOUNT_BELOW_SOFT_CAP");
        //require(!collaterals[msgSender].redeemed, "PRESALE:ALREADY_CLAIMED");
        
        (uint blx, uint rewards) = _claim(msgSender);
        
        require(blx > 0 || rewards > 0, "PRESALE:NOTHING_TO_CLAIM");
    }

    /// @dev allows to claim BLX for presale users
    function _claim(address msgSender) private returns (uint blxToSend, uint remainingRewards) {
        
        uint amountPurchased = collaterals[msgSender].redeemed || !softCapReached ? 0 : collaterals[msgSender].amount;

        // referrer rewards
        (uint rewards) = _calcRewards(msgSender);
        uint claimedRewards = referral_rewards[msgSender].claimed;

        // for the case the claim is done first in IBCO then here
        // where all the rewards would be claimed there, nothing extra here
        remainingRewards = rewards > claimedRewards ? rewards - claimedRewards : 0;    
        uint claimableRewards = rewards_burnt ? 0 : remainingRewards;

        amountClaimed += amountPurchased;
        
        //BLX to send = USDC amount x 10 
        blxToSend = amountPurchased * blxRate;

        if (blxToSend > 0) {
            BLX.transfer(msgSender, blxToSend);
            collaterals[msgSender].redeemed = true;

            emit BlxClaimed(msgSender, blxToSend);
        }

        if (claimableRewards > 0) {
            BLX.transfer(msgSender, claimableRewards);
            emit BlxClaimed(msgSender, claimableRewards);
        }

        // update claimed rewards
        if (remainingRewards > 0) {
            // update but not necessary sent
            referral_rewards[msgSender].claimed += remainingRewards;
            total_claimed_rewards += remainingRewards;
        }

        if (remainingRewards > claimableRewards) {
            // claims 90 days after ibco end would forfeit remaining eligible rewards
            // if it has been burnt
            emit BlxRewardsBurnt(msgSender, remainingRewards);
        }
    } 

    /// @dev allows to refund USDC if conditions are met
    function refund(address msgSender) external returns (uint amount, bool redeemed) {
        require(
            (block.timestamp >= presaleEnd && presaleEnd > 0) || hardCapReached,
            "PRESALE:PRESALE_IN_PROGRESS"
        );
        require(!softCapReached || msg.sender == ibcoAddress,"PRESALE:PLEASE_CLAIM_YOUR_BLX_TOKENS");

        // we trust the passed in msgSender only if it is from ibco
        // otherwise get the 'real' sender and ignore passed in value
        if (msg.sender != ibcoAddress) {
            msgSender = _msgSender();
        }
        
        redeemed = collaterals[msgSender].redeemed;
        amount = collaterals[msgSender].amount;

        if (softCapReached && msg.sender == ibcoAddress) return (0, true);

        if (!redeemed) {
            // assume this would not fail
            if (amount > 0) {
                USDC.transfer(msgSender, collaterals[msgSender].amount);
            }

            if (txFee > 0) {
            // transfer all tx cost collected too as we are here when presale ended but failed so do it just once  ? FIXME
            // ignore fail so we don't block refund, worst case collected fee
            // trapped here
            try USDC.transfer(daoAgentAddress, txFee) returns (bool success) {
                if (success) txFee = 0;
            }
            catch {}
            }
            amountFromWhitelisted -= collaterals[msgSender].amount;           
            collaterals[msgSender].amount = 0;
            collaterals[msgSender].redeemed = true;
        } else if (msg.sender != ibcoAddress) {
            // only revert if not from ibco
            revert("PRESALE:ALREADY_REFUNDED");
        }
    } 

    /// @dev transfer all funds received from whitelisted to DAO agent
    function transferToDaoAgent() external onlyTrustedCaller {
        // only called once when presale ended
        require(
            (block.timestamp >= presaleEnd && presaleEnd > 0) || hardCapReached,
            "PRESALE:PRESALE_IN_PROGRESS"
        );
        require(softCapReached, "PRESALE:TOTAL_AMOUNT_BELOW_SOFT_CAP");
        //due to how we count whitelisted USDC we need to make sure
        //that we do not send same amount twice
        require(
            (amountFromWhitelisted > amountTransfered),
            "PRESALE:NO_FUNDS_TO_TRANSFER"
        );
        // all balance transferred including tx fee
        uint myBalance = USDC.balanceOf(address(this));
        if (myBalance > 0) {
            USDC.transfer(daoAgentAddress , myBalance);
            amountTransfered = amountFromWhitelisted;
            txFee = 0;
        }
    }

    /// @dev transfer collected tx fee, regardless whether if softcap reach or not any time
    function transferTxFee() external onlyTrustedCaller {
        require(txFee > 0, "PRESALE:NO_TX_FEE"); 
        // only tx fee portion, rest are untouched(for refund etc.)
        uint myBalance = USDC.balanceOf(address(this));
        if (myBalance > txFee) {
            try USDC.transfer(daoAgentAddress, txFee) returns (bool success) {
                // reset
                if (success) txFee = 0;
            }
            catch {}
        }
    }

    /// @dev burn unsold BLX(not including rewards)
    function burnUnsoldBLX() external {
        require(block.timestamp >= presaleStart, "PRESALE:PRESALE_NOT_STARTED");
        require(
            (block.timestamp >= presaleEnd && presaleEnd > 0) || hardCapReached,
            "PRESALE:PRESALE_IN_PROGRESS"
        );
        require(!unsold_burnt, "PRESALE:NO_UNSOLD_BLX");

        // not purchased
        uint burnable = (hardCap - (softCapReached ? amountFromWhitelisted : 0)) * blxRate;
        // outstanding balance
        uint blxBalance = BLX.balanceOf(address(this));
        uint unused = (blxBalance > burnable ? burnable : 0);
        if (unused > 0) {
            BLX.burn(unused);
            unsold_burnt = true;
            emit BurnUnused(unused);
        }
        else {
            revert("PRESALE:NO_UNSOLD_BLX");
        }
    }

    /// @dev calculate burnable BLX
    function burnableBLX() public view returns (uint unused, uint claimable) {
        // total claimable(purchased and not claimed, not including rewards), not going to be burnt
        claimable = (softCapReached ? (amountFromWhitelisted - amountClaimed) * blxRate : 0);
        // outstanding balance
        uint blxBalance = BLX.balanceOf(address(this));
        // excess reward allocated + unclaimed rewards(expired) + potential unsold presale(it not burnt above)
        unused = (blxBalance > claimable ? blxBalance - claimable : 0);
    }

    /// @dev burn unused BLX only after IBCO close and 90 days passed(controlled by IBCO)
    function burnRemainingBLX() external onlyIBCO {
        require(BLX.balanceOf(address(this)) > 0, "PRESALE:NOTHING_TO_BURN");
        require(!unsold_burnt || !rewards_burnt,"PRESALE:ALREADY_BURNT");
        (uint unused, uint claimable) = burnableBLX();

        if (unused > 0) {
            BLX.burn(unused);
            emit BurnUnused(unused);
        }
        // rewards no longer available
        rewards_burnt = true;
        // unsold also burnt
        unsold_burnt = true;
        // remaining are unclaimed purchases
        require(BLX.balanceOf(address(this)) == claimable, "PRESALE:OVER_BURNT");

    }

    /// @dev update referrer status by IBCO
    function updateReferrer(address user, address referrer, uint amount, uint blx) external onlyIBCO {
        _updateReferral(user, referrer, amount, blx, true);
    }

    /// @dev claim rewards for IBCO stage(by IBCO)
    function claimRewards(address msgSender) onlyIBCO external returns (uint blx, uint rewards) {
        require(msgSender != address(0),"PRESALE:REFERRER_ADDRESS_ZERO");
        require(block.timestamp >= presaleStart, "PRESALE:NOT_STARTED");
        require(
            (block.timestamp >= presaleEnd && presaleEnd > 0) || hardCapReached,
            "PRESALE:PRESALE_IN_PROGRESS"
        );

        (blx, rewards) = _claim(msgSender);
    }

    /// @dev max purchaseable usdc
    function maxPurchase() public view returns (uint available) {
        available = hardCap > amountFromWhitelisted ? hardCap - amountFromWhitelisted : 0;
    }

    /// @dev max outstanding BLX obligation for claimable BLX
    function blxObligation() external view returns (uint amount) {
        amount = (!softCapReached ? 0 : (amountFromWhitelisted - amountClaimed) * 10)
                 +
                 // this may overstate the reward obligation as it is using max 10% - already claimed
                 // the function is only intended to be called by IBCO
                 (rewards_burnt || !softCapReached ? 0 : amountFromWhitelisted - total_claimed_rewards);
    }

    /// @dev pick ERC2771Context over Ownable
    function _msgSender() internal view override(Context, ERC2771Context)
      returns (address sender) {
      sender = ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context)
      returns (bytes calldata) {
      return ERC2771Context._msgData();
    }
}