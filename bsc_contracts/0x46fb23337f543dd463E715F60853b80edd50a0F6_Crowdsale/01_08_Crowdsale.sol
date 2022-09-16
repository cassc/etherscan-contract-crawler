//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library Zero {
  function requireNotZero(uint a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}


library ToAddress {

  function toAddr(bytes memory source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}

contract InvestorsStorage {
  struct investor {
    uint keyIndex;
    uint value;
    uint valueUsd;
    uint paymentTime;
    uint refBonus;
    uint refUsd;
    uint turnoverUsd;
    uint refFirstUsd;
    uint refSecondUsd;
    uint refThirdUsd;
    uint refFourthUsd;
    uint refFifthUsd;
    uint refSixthUsd;
    uint refSeventhUsd;
  }

  struct itmap {
    mapping(address => investor) data;
    address[] keys;
  }
  
  itmap private s;
  address private owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "access denied");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function insert(address addr, uint value, uint valueUsd) public onlyOwner returns (bool) {
    uint keyIndex = s.data[addr].keyIndex;
    if (keyIndex != 0) return false;
    s.data[addr].value = value;
    s.data[addr].valueUsd = valueUsd;

    uint keysLength = s.keys.length;
    keyIndex = keysLength+1;
    
    s.data[addr].keyIndex = keyIndex;
    s.keys.push(addr);
    return true;
  }

  function investorFullInfo(address addr) public view returns(uint, uint, uint, uint) {
    return (
      s.data[addr].keyIndex,
      s.data[addr].value,
      s.data[addr].paymentTime,
      s.data[addr].refBonus
    );
  }

  function investorBaseInfo(address addr) public view returns(uint, uint, uint, uint, uint) {
    return (
      s.data[addr].value,
      s.data[addr].valueUsd,
      s.data[addr].paymentTime,
      s.data[addr].refBonus,
      s.data[addr].refUsd
    );
  }

  function investorLevelsInfo(address addr) public view returns(uint, uint, uint, uint, uint, uint, uint) {
    return (
      s.data[addr].refFirstUsd,
      s.data[addr].refSecondUsd,
      s.data[addr].refThirdUsd,
      s.data[addr].refFourthUsd,
      s.data[addr].refFifthUsd,
      s.data[addr].refSixthUsd,
      s.data[addr].refSeventhUsd
    );
  }

  function investorShortInfo(address addr) public view returns(uint, uint) {
    return (
      s.data[addr].value,
      s.data[addr].refBonus
    );
  }

  function addRefBonus(address addr, uint refBonus, uint refUsd, uint turnoverUsd, uint level) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].refBonus += refBonus;
    s.data[addr].refUsd += refUsd;
    s.data[addr].turnoverUsd += turnoverUsd;

    if (level == 1) {
     s.data[addr].refFirstUsd += refUsd;
    } else if (level == 2) {
      s.data[addr].refSecondUsd += refUsd;
    } else if (level == 3) {
      s.data[addr].refThirdUsd += refUsd;
    } else if (level == 4) {
      s.data[addr].refFourthUsd += refUsd;
    } else if (level == 5) {
      s.data[addr].refFifthUsd += refUsd;
    } else if (level == 6) {
      s.data[addr].refSixthUsd += refUsd;
    } else if (level == 7) {
      s.data[addr].refSeventhUsd += refUsd;
    }
    return true;
  }

  function addValue(address addr, uint value, uint valueUsd) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].value += value;
    s.data[addr].valueUsd += valueUsd;
    return true;
  }

  function setPaymentTime(address addr, uint paymentTime) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].paymentTime = paymentTime;
    return true;
  }

  function setRefBonus(address addr, uint refBonus) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].refBonus = refBonus;
    return true;
  }

  function keyFromIndex(uint i) public view returns (address) {
    return s.keys[i];
  }

  function contains(address addr) public view returns (bool) {
    return s.data[addr].keyIndex > 0;
  }

  function size() public view returns (uint) {
    return s.keys.length;
  }

  function iterStart() public pure returns (uint) {
    return 1;
  }
}

library Percent {
  // Solidity automatically throws when dividing by 0
  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

contract Crowdsale is Context, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Percent for Percent.percent;
    using Zero for *;
    using ToAddress for *;

    mapping(uint => Percent.percent) internal m_refPercent;

    // percents 
    Percent.percent private m_adminPercent = Percent.percent(15, 100); // 15/100*100% = 15%
    Percent.percent private m_corporatePercent = Percent.percent(60, 100); // 60/100*100% = 60%

    enum CrowdsaleStage { STAGE_ONE, STAGE_TWO, STAGE_THREE, STAGE_FOUR }

    CrowdsaleStage public _stage = CrowdsaleStage.STAGE_ONE;

    uint256 public _rate;

    address payable _wallet;

    address payable _walletCorporate;

    address _admin;

    IERC20 public _token;

    uint256 public _weiRaised;

    uint256 public _tokensSold;

    uint256 public investmentsNum;

    mapping(address => uint256) private _contribution;

    mapping(address => bool) private m_referrals;

    mapping(address => address) public referral_tree;

    event TokenPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 when);

    event WithdrawBNB(address indexed admin, uint256 value);
    
    event PresaleEnded(address indexed admin, uint256 value);

    event LogBalanceChanged(uint256 when, uint256 balance);

    event LogNewReferral(address indexed addr, uint256 when, uint256 value);

    event LogNewInvestor(address indexed addr, uint256 when, uint256 value);

    event corporateWalletChanged(address indexed oldWallet, address indexed newWallet);

    AggregatorV3Interface internal priceFeed;

    InvestorsStorage internal m_investors;

    modifier onlyAdmin() {
        require(_admin == _msgSender(), "Called from non admin wallet");
        _;
    }

    modifier minAmount() {
        require(_getUsdAmount(msg.value) >= 100,"Minimal amount is $100");
        _;
    }

    modifier activeSponsor(address walletSponsor) {
        require(m_investors.contains(walletSponsor) == true,"There is no such sponsor");
        require(walletSponsor != _msgSender(),"You need a sponsor referral link, not yours");
        _;
    }

    modifier balanceChanged {
        _;
        emit LogBalanceChanged(block.timestamp, address(this).balance);
    }

    modifier checkFinalStage(uint stage) {
      require(uint(_stage) < stage,"This stage is now or past");
      _;
    }

    constructor(IERC20 token, address payable wallet, address payable walletCorporate, uint256 rate) {
        _token = token;
        _wallet = wallet;
        _walletCorporate = walletCorporate;
        _admin = _msgSender();
        _rate = rate;

        m_investors = new InvestorsStorage();
        investmentsNum = 0;

        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        m_refPercent[0] = Percent.percent(8, 100); // 8/100*100% = 8%
	    m_refPercent[1] = Percent.percent(6, 100); // 6/100*100% = 6%
	    m_refPercent[2] = Percent.percent(4, 100); // 4/100*100% = 4%
	    m_refPercent[3] = Percent.percent(3, 100); // 3/100*100% = 3%
	    m_refPercent[4] = Percent.percent(1, 100); // 1/100*100% = 1%
	    m_refPercent[5] = Percent.percent(1, 100); // 1/100*100% = 1%
	    m_refPercent[6] = Percent.percent(2, 100); // 2/100*100% = 2%

      assert(m_investors.insert(wallet, 0, 0));
      referral_tree[wallet] = address(0);
    }

    fallback() external payable {
      address a = msg.data.toAddr();
      require(a.notZero(),"try to add sponsor wallet to a hex data");
      buyTokensFront(a);
    }

    function investorsNumber() public view returns(uint) {
        return m_investors.size();
    }

    function adminPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_adminPercent.num, m_adminPercent.den);
    }

    function referrerPercent(uint level) public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_refPercent[level].num, m_refPercent[level].den);
    }

    function buyTokensFront(address sponsor) public payable minAmount activeSponsor(sponsor) balanceChanged nonReentrant {
        uint256 weiAmount = msg.value;

        address beneficiary = _msgSender();

        _prevalidatePurchase(beneficiary, weiAmount);

        uint256 tokenAmount = _getTokenAmount(weiAmount);

        _weiRaised = _weiRaised.add(weiAmount);

        _tokensSold += tokenAmount;

        _updateContribution(beneficiary, weiAmount);

        _token.transfer(beneficiary, tokenAmount);

        if (sponsor.notZero()) {
            address Sponsor = referral_tree[beneficiary];

            if (!Sponsor.notZero()) {
                referral_tree[beneficiary] = sponsor;
            }
            
            doMarketing(weiAmount);       
        } 

        // commission
        _wallet.transfer(m_adminPercent.mul(weiAmount)); 
        _walletCorporate.transfer(address(this).balance);
        
        // write to investors storage
        if (m_investors.contains(beneficiary)) {
            assert(m_investors.addValue(beneficiary, weiAmount, _getUsdAmount(weiAmount)));
        } else {
            assert(m_investors.insert(beneficiary, weiAmount, _getUsdAmount(weiAmount)));
            emit LogNewInvestor(beneficiary, block.timestamp, weiAmount); 
        }

        investmentsNum++; 

        emit TokenPurchased(_msgSender(), beneficiary, weiAmount, tokenAmount, block.timestamp);
    }

    function doMarketing(uint256 weiAmount) internal {
      // level 1
      address payable sponsorOne = payable(referral_tree[_msgSender()]);
      if (notZeroNotSender(sponsorOne) && m_investors.contains(sponsorOne)) {
          addReferralBonus(sponsorOne, weiAmount, 1);
          // level 2
          address payable sponsorTwo = payable(referral_tree[sponsorOne]);
          if (notZeroNotSender(sponsorTwo) && m_investors.contains(sponsorTwo)) { 
              addReferralBonus(sponsorTwo, weiAmount, 2);
              // level 3
              address payable sponsorThree = payable(referral_tree[sponsorTwo]);
              if (notZeroNotSender(sponsorThree) && m_investors.contains(sponsorThree)) { 
                  addReferralBonus(sponsorThree, weiAmount, 3);
                  // level 4
                  address payable sponsorFour = payable(referral_tree[sponsorThree]);
                  if (notZeroNotSender(sponsorFour) && m_investors.contains(sponsorFour)) { 
                      addReferralBonus(sponsorFour, weiAmount, 4);
                      // level 5
                      address payable sponsorFive = payable(referral_tree[sponsorFour]);
                      if (notZeroNotSender(sponsorFive) && m_investors.contains(sponsorFive)) { 
                          addReferralBonus(sponsorFive, weiAmount, 5);
                          // level 6
                          address payable sponsorSix = payable(referral_tree[sponsorFive]);
                          if (notZeroNotSender(sponsorSix) && m_investors.contains(sponsorSix)) { 
                              addReferralBonus(sponsorSix, weiAmount, 6);
                              // level 7
                              address payable sponsorSeven = payable(referral_tree[sponsorFive]);
                              if (notZeroNotSender(sponsorSeven) && m_investors.contains(sponsorSeven)) { 
                                  addReferralBonus(sponsorSeven, weiAmount, 7);
                              }
                          }
                      }
                  }
              }
          }
      }
    }

    function addReferralBonus(address payable sponsor, uint256 weiAmount, uint level) internal {
        uint index = level-1;
        uint reward = m_refPercent[index].mul(weiAmount);
        assert(m_investors.addRefBonus(sponsor, reward, _getUsdAmount(reward), _getUsdAmount(weiAmount), level));
        sponsor.transfer(reward);      
    }

    function notZeroNotSender(address addr) internal view returns(bool) {
        return addr.notZero() && addr != _msgSender();
    }

    function getTokenPrice() public view returns (uint256) {
        return _getTokenAmount(1*10**8);
    }

    function _getBNBPrice() internal view returns (int) {
        (
            , 
            int price,
            ,
            , 

        ) = priceFeed.latestRoundData();
        return price;
    }

    function _getUsdAmount(uint256 weiAmount) internal view returns (uint256){
        int bnbPrice = _getBNBPrice();

        uint256 _bnbPrice = uint256(bnbPrice);
        uint256 _Amount = ((weiAmount*(_bnbPrice*10**10))/(10**18))/(10**18);

        return _Amount;   
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        int bnbPrice = _getBNBPrice();

        uint256 _bnbPrice = uint256(bnbPrice);

        uint256 _Amount = _bnbPrice/_rate;

        return weiAmount.mul(_Amount);
    }

    function _forwardFunds(uint256 weiAmount) internal {
        _walletCorporate.transfer(weiAmount); // transfer bnb balance of this contract
    }

    function _updateContribution(address beneficiary, uint256 weiAmount) internal {
        _contribution[beneficiary] += weiAmount;
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    function _prevalidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Beneficiary is zero address");
        require(weiAmount != 0, "Wei amount is zero");
        this;
    }

    function withdrawFunds() public onlyAdmin {
        uint256 weiAmount = address(this).balance;

        _forwardFunds(address(this).balance); 

        emit WithdrawBNB(_msgSender(), weiAmount);
    }

    function endPresale() public onlyAdmin {
        uint256 weiAmount = address(this).balance;

        _forwardFunds(address(this).balance); 

        _token.transfer(_walletCorporate, _token.balanceOf(address(this)));

        emit PresaleEnded(_msgSender(), weiAmount);
    }

    function setCrowdsaleStage(uint stage, uint256 rate) public onlyAdmin checkFinalStage(stage) {
        if (uint(CrowdsaleStage.STAGE_TWO) == stage) {

          _stage = CrowdsaleStage.STAGE_TWO;
          _rate = 12500000;

        } else if (uint(CrowdsaleStage.STAGE_THREE) == stage) {

          _stage = CrowdsaleStage.STAGE_THREE;
          _rate = rate;

        } else if (uint(CrowdsaleStage.STAGE_FOUR) == stage) {

          _stage = CrowdsaleStage.STAGE_FOUR;
          _rate = rate;

        }
    }

    function activateReferralLink(address sponsor, address referral) public onlyAdmin {
      assert(m_investors.insert(referral, 0, 0));
      referral_tree[referral] = sponsor;
    }

    function changeCorporateWallet(address payable wallet) public onlyAdmin {
      require(wallet != address(0), "New corporate address is the zero address");
      address oldWallet = _walletCorporate;
      _walletCorporate = wallet;
      emit corporateWalletChanged(oldWallet, wallet);
    }

    function investorInfo(address addr) public view returns(uint value, uint valueUsd, uint paymentTime, uint refBonus, uint refUsd, bool isReferral) {
        (value, valueUsd, paymentTime, refBonus, refUsd) = m_investors.investorBaseInfo(addr);
        isReferral = m_referrals[addr];
    }

    function investorLevelsInfo(address addr) public view returns(uint refFirstUsd, uint refSecondUsd, uint refThirdUsd, uint refFourthUsd, uint refFifthUsd, uint refSixthUsd, uint refSeventhUsd, bool isReferral) {
        (refFirstUsd, refSecondUsd, refThirdUsd, refFourthUsd, refFifthUsd, refSixthUsd, refSeventhUsd) = m_investors.investorLevelsInfo(addr);
        isReferral = m_referrals[addr];
    }
}