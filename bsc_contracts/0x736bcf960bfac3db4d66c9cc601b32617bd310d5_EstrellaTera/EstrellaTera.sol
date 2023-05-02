/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function mint2(address to) external;
    function burn2(address to,uint256 value) external;
    function minting(address to,uint256 value) external;
}
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface com_Contract {
    function percentage(uint256 _tokenAmount, uint256 _round) external view returns(uint256[] memory);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(){
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract EstrellaTera is Ownable{

    com_Contract public com;
    IBEP20 public USDTToken;
    IERC20 public USDACE$Token;
    IERC20 public ETAToken;

    address public defaultRefer;
    address public anotheraddress;

    struct UserInfo {
        address referrer;
        uint256 totalDeposit;
        uint256 USDT_1stLCommission;
        uint256 USDACE_1stLCommission;
        uint256 USDT_Com_FromBuyer;
        uint256 USDACE_Com_FromBuyer;
        uint256 USDT_Com_FromSeller;
        uint256 USDACE_Com_FromSeller;
        uint256 directsReferralNum;
        uint256 referralTeamNum;
    }
    mapping(address => UserInfo) public userInfo;

    struct CommissionInfo {
        uint256 USDT_Commission;
        uint256 USDACE_Commission;
    }
    mapping(address => CommissionInfo) public commissionInfo;


    bool roundbool;
    uint256 public round;
    uint256 public endRound;
    uint256 public totalUser;
    uint256 public mulplier = 4;
    uint256 private Rem_Amount1;
    uint256 private Rem_Amount2;
    uint256 public PreviousRound; 
    uint256 private endcycles= 100;  // Miannet 
    uint256 public totalTokenMint;
    uint256 public referDepth = 30;
    uint256 public fixedPrice = 200000000000000000;
    uint256 public tokenPrice = 200000000000000000;
    uint256 private ownerPercentage = 100;
    uint256 public minDeposit = 1e18; 
    uint256 public maxDeposit = 10000e18; // Miannet 
    uint256 public cycleSupply = 10000e18; // Miannet 
    uint256 public roundSupply = 1000000e18; // Miannet 
    uint256 public tokenPriceAfterTwoRounds;
    uint256 private constant baseDivider = 100;
    uint256 public tokenPriceIncreament = 2000000000000000;
    
    uint256[6] private Selling_Percents = [0,0,160,180,200,800];
    uint256[6] private Balance_Percents = [100,200,240,300,400,0];
    uint256[6] private Round_Percents = [100,200,400,480,600,800];

    mapping(uint256 => uint256) public cycle;
    mapping(uint256 => bool) private checking;
    mapping(address => uint256) public w_count;
    mapping(uint256 => bool) public checkMinting;
    mapping(uint256 => uint256) public seller_Count;
    mapping(uint256 => uint256) public buyer_Count;
    mapping(uint256 => uint256) public totalTokenRound; 
    mapping(address => uint256 ) public buyertimeCount;
    mapping(address => uint256 ) public TotalUSDSpent;
    mapping(address => uint256 ) public totalUSDTSpent;
    mapping(address => uint256 ) public totalUSDACESpent;
    mapping(address => uint256 ) public TotalUSDTEarned;
    mapping(address => uint256 ) public TotalUSDACEEarned;
    mapping(uint256 => uint256 ) public TotalTokenInRound;
    mapping(address => uint256 ) public totalUSDTCommission;
    mapping(address => uint256 ) public totalUSDACECommission;
    mapping(address => mapping(uint256 => uint256)) public countSell;
    mapping(address => mapping(uint256 => uint256)) public userCount;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => mapping(uint256 =>  uint256)) public buyerRound;
    mapping(uint256 => mapping(uint256 =>  address)) public buyer_address;
    mapping(uint256 => mapping(uint256 => uint256)) public totalTokencycle;
    mapping(address =>  mapping(uint256 => uint256)) public SellTotalToken;
    mapping(address => mapping(uint256 =>  uint256)) public buyerTotalToken;
    mapping(address => mapping(uint256 => uint256)) public withdrawHistoryTime;
    mapping(address => mapping(uint256 => uint256)) public withdrawHistoryOfUSDT;
    mapping(address => mapping(uint256 => uint256)) public withdrawHistoryOfUSDACE;
    mapping(address => mapping(uint256 => mapping(uint256 => address))) public userReferral;
    mapping(address => mapping(uint256 => mapping(uint256 =>  uint256))) public buyer_Token;
    mapping(address => mapping(uint256 => mapping(uint256 =>  uint256))) public userSellToken;
    mapping(address => mapping(uint256 => mapping(uint256 =>  uint256))) public userSellPrice;
    mapping(address => mapping(uint256 => mapping(uint256 =>  uint256))) public buyerToken_Price;  
    mapping(address => mapping(address => mapping(uint256 => bool))) private userReferralVerification;
    mapping(address => mapping(uint256 => mapping(uint256 =>   mapping(uint256 =>  uint256)))) public buyerSellTotalToken;

    event Register(address user, address referral);

    constructor()
    {
        com = com_Contract(0x7a6980F63b952aa741e7d5062C5C18d1e48f2920);
        USDTToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
        USDACE$Token = IERC20(0x81430fE6288f9e26F4d9f80F6941E1B92Abd4Fb6);
        ETAToken = IERC20(0x9d54278a9A7fb8FB00dB8c128a91dc2Bb05C6baC);
        defaultRefer = 0x5D9b2fc97f41D0f69d31E78E2961FcaDCec525cf;
        anotheraddress = 0x10CfcB0d7c36FeA2E4ce24787b43c063737A6ec4;
        round = 0;
        cycle[0] = 0;
    }

    function register(address _referral) 
    public{
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        _updateTeamNum(msg.sender);
        totalUser = totalUser+(1);
        updateReferral(msg.sender);
        emit Register(msg.sender, _referral);
    }

    function _updateTeamNum(address _user) 
    private{
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].referralTeamNum = userInfo[upline].referralTeamNum+(1);
                teamUsers[upline][i].push(_user);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function updateReferral(address _user) 
    private
    {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 1; i <= referDepth; i++){
            if(upline != address(0)){
                if(!userReferralVerification[upline][_user][i]){ 
                userCount[upline][i] += 1;
                uint256 counts = userCount[upline][i];
                userReferral[upline][i][counts] = _user;
                userReferralVerification[upline][_user][i] = true;
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    } 

    function buy(address tokenAddress, uint256 tokenAmount, uint256 token)  
    public
    {
        require(msg.sender == tx.origin," External Error ");
        require(IBEP20(tokenAddress) == USDTToken || IERC20(tokenAddress) == USDACE$Token,"Invalid token address");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer != address(0), "register first");
        require(token >= minDeposit, "less than min");
        if(round < 2){   
            require(token <= maxDeposit, "less than max");   }
        else {
              maxDeposit =  maxToken();
              require(token <= maxDeposit, "less than max");   }
        if(roundbool == false)
        {
            uint256 tokentransfer;
            (uint256[] memory roundDetails,uint256[] memory currentDetails,uint256[] memory nextDetails) 
            = getPrice1(token, round, cycle[round]);
            if(roundDetails[0] == 0 || roundDetails[0] == 1)
            { 
                (uint256 price1, uint256 price2) = getPrice(token, round, cycle[round], tokenPrice);
                uint256 totalprice = price1+(price2);
                if(roundDetails[2] > 1)
                {    tokentransfer = roundDetails[1]; 
                     totalprice =  price1; 
                     Rem_Amount1 = tokenAmount-(price2); 
                     Rem_Amount2 = price2;
                }else{
                    tokentransfer = roundDetails[1]+(roundDetails[3]);  
                    Rem_Amount1 = tokenAmount; 
                }
                require(Rem_Amount1 == totalprice, "Invalid amount");
                userInfo[msg.sender].totalDeposit += token;
                TotalUSDSpent[msg.sender] = TotalUSDSpent[msg.sender]+(Rem_Amount1);
                round = roundDetails[0];
                TotalTokenInRound[round] = TotalTokenInRound[round]+(roundDetails[1]);
                totalTokenRound[round] += roundDetails[1];
                cycle[round] = currentDetails[0];
                totalTokencycle[round][cycle[round]] += currentDetails[1];
                buyer_Token[msg.sender][round][buyer_Count[round]] = currentDetails[1];
                buyerToken_Price[msg.sender][round][buyer_Count[round]] = tokenPrice;
                buyer_address[round][buyer_Count[round]] = msg.sender;
                buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = currentDetails[1];
                buyer_Count[round] = buyer_Count[round]+(1);

                if(currentDetails[2] > currentDetails[0])
                {
                cycle[round] = currentDetails[2];
                tokenPrice = tokenPrice+(tokenPriceIncreament);
                totalTokencycle[round][cycle[round]] += currentDetails[3];
                buyer_Token[msg.sender][round][buyer_Count[round]] = currentDetails[3];
                buyerToken_Price[msg.sender][round][buyer_Count[round]] = tokenPrice;
                buyer_address[round][buyer_Count[round]] = msg.sender;
                buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] += currentDetails[3];
                buyer_Count[round] = buyer_Count[round]+(1);
                }  

                buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
                buyertimeCount[msg.sender] = buyertimeCount[msg.sender]+(1);

                if(roundDetails[2] > roundDetails[0])
                {
                    round = roundDetails[2];
                    totalTokenRound[round] += roundDetails[3];
                    TotalTokenInRound[round] = TotalTokenInRound[round]+(roundDetails[3]);
                    cycle[round] = nextDetails[0];
                    tokenPrice = fixedPrice;
                    totalTokencycle[round][cycle[round]] += nextDetails[1];
                    buyer_Token[msg.sender][round][buyer_Count[round]] = nextDetails[1];
                    buyerToken_Price[msg.sender][round][buyer_Count[round]] = tokenPrice;
                    buyer_address[round][buyer_Count[round]] = msg.sender;
                    buyer_Count[round] = buyer_Count[round]+(1);
                    buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = nextDetails[1];
                    buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
                    buyertimeCount[msg.sender] = buyertimeCount[msg.sender]+(1);
                }
                if(IBEP20(tokenAddress) == USDTToken)
                {
                    uint256[] memory levelPercentage_ = new uint256[](5);
                    levelPercentage_ = com.percentage(Rem_Amount1,round);
                    totalUSDTSpent[msg.sender] = totalUSDTSpent[msg.sender]+(Rem_Amount1);
                    USDTToken.transferFrom(msg.sender, owner(), levelPercentage_[0]);
                    USDTToken.transferFrom(msg.sender, address(this), levelPercentage_[1]);
                    buyerReferralCommission(msg.sender,levelPercentage_);
                    ETAToken.transferFrom(owner(),address(this),tokentransfer);
                }
                else if(IERC20(tokenAddress) == USDACE$Token)
                {
                    totalUSDACESpent[msg.sender] = totalUSDACESpent[msg.sender]+(Rem_Amount1);
                    USDACE$Token.transferFrom(msg.sender, address(this), Rem_Amount1);
                    ETAToken.transferFrom(owner(),address(this),tokentransfer);
                    USDACE$Token.burn2(address(this),Rem_Amount1);
                }
            } 
            if(roundDetails[2] > 1)
            {
                roundbool = true;
                round = roundDetails[2]; 
                uint256 remainingbuyerToken;
                PreviousRound = round-(2);
                address SellerAddress = buyer_address[PreviousRound][seller_Count[PreviousRound]];
                uint256 sellerTokenPrice = buyerToken_Price[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                tokenPriceAfterTwoRounds = sellerTokenPrice;
                uint256 TokenBuy_ = buyer_Token[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                uint256[] memory TokenBuy_User = new uint256[](3);
                TokenBuy_User = checktoken(round,PreviousRound, TokenBuy_);
                TokenBuy_User[0] = TokenBuy_User[0]-(buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]);
                remainingbuyerToken = nextDetails[1];
                if(remainingbuyerToken <= TokenBuy_User[0])
                {
                    totalTokenMint = totalTokenMint+(remainingbuyerToken);
                    buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]] = 
                    buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]+(remainingbuyerToken);
                    SellTotalToken[SellerAddress][round] += remainingbuyerToken; 
                    userSellToken[SellerAddress][PreviousRound][countSell[SellerAddress][PreviousRound]] = remainingbuyerToken;
                    userSellPrice[SellerAddress][PreviousRound][countSell[SellerAddress][PreviousRound]] = sellerTokenPrice;
                    countSell[SellerAddress][PreviousRound] = countSell[SellerAddress][PreviousRound]+(1);
                    uint256 totalamount = remainingbuyerToken*(sellerTokenPrice);
                    trasnferAmount(tokenAddress,SellerAddress,totalamount);
                    totalamount = totalamount/(1e18);
                    TotalUSDSpent[msg.sender] = TotalUSDSpent[msg.sender]+(totalamount);
                    buyer_Token[msg.sender][round][buyer_Count[round]] = remainingbuyerToken;
                    buyerToken_Price[msg.sender][round][buyer_Count[round]] = sellerTokenPrice;
                    buyer_address[round][buyer_Count[round]] = msg.sender;
                    buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = remainingbuyerToken;
                    remainingbuyerToken = 0;
                }
                else{
                        uint256 totalamount = remainingbuyerToken * (fixedPrice);
                        totalamount = totalamount/(1e18);
                        buy(tokenAddress, totalamount, remainingbuyerToken);
                }
            }   
        }
        else
        { 
            uint256 remainingbuyerToken;
            if(!checking[round]){
                if(round < 5){
                    endRound = round-(2);
                }else{
                    endRound = round-(2);
                    PreviousRound = round-(5);
                    }
                checking[round] = true;
            }
            uint256 totaluser = buyer_Count[PreviousRound];
            address SellerAddress = buyer_address[PreviousRound][seller_Count[PreviousRound]];
            uint256 sellerTokenPrice = buyerToken_Price[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
            tokenPriceAfterTwoRounds = sellerTokenPrice;
            checkRemainingToken(SellerAddress,PreviousRound);
            uint256 TokenBuy_ = buyer_Token[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
            uint256[] memory TokenBuy_User = new uint256[](3);
            TokenBuy_User = checktoken(round, PreviousRound, TokenBuy_);
            TokenBuy_User[0] = TokenBuy_User[0]-(buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]);
            uint256[] memory BuyerandSalesDetails = new uint256[](3);
            BuyerandSalesDetails =  getPriceAfterTwoRunds(token,PreviousRound,endRound,totaluser,SellerAddress,sellerTokenPrice,
            TokenBuy_User[0],seller_Count[PreviousRound]);
            require(tokenAmount == BuyerandSalesDetails[0], "Enter the valid amount");
            userInfo[msg.sender].totalDeposit = token;
            TotalUSDSpent[msg.sender] = TotalUSDSpent[msg.sender]+(tokenAmount);
            remainingbuyerToken = token;
            while(remainingbuyerToken > 0)
            {
                if(remainingbuyerToken <= TokenBuy_User[0])
                {
                totalTokenMint = totalTokenMint+(remainingbuyerToken);
                TotalTokenInRound[round] = TotalTokenInRound[round]+(remainingbuyerToken);
                buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]] = 
                buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]+(remainingbuyerToken);
                userSellToken[SellerAddress][PreviousRound][countSell[SellerAddress][PreviousRound]] = remainingbuyerToken;
                userSellPrice[SellerAddress][PreviousRound][countSell[SellerAddress][PreviousRound]] = sellerTokenPrice;
                countSell[SellerAddress][PreviousRound] = countSell[SellerAddress][PreviousRound]+(1);
                uint256 totalamount = remainingbuyerToken*(sellerTokenPrice);
                trasnferAmount(tokenAddress,SellerAddress,totalamount);
                SellTotalToken[SellerAddress][round] += remainingbuyerToken;
                buyer_Token[msg.sender][round][buyer_Count[round]] = remainingbuyerToken;
                buyerToken_Price[msg.sender][round][buyer_Count[round]] = sellerTokenPrice;
                buyer_address[round][buyer_Count[round]] = msg.sender;
                buyer_Count[round] = buyer_Count[round]+(1);
                buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = remainingbuyerToken;
                remainingbuyerToken = 0;
                }
                else{
                    totalTokenMint = totalTokenMint+(TokenBuy_User[0]);
                    TotalTokenInRound[round] = TotalTokenInRound[round]+(TokenBuy_User[0]);
                    remainingbuyerToken = remainingbuyerToken-(TokenBuy_User[0]);
                    buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]] = 
                    buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]+(TokenBuy_User[0]);
                    userSellToken[SellerAddress][PreviousRound][countSell[SellerAddress][PreviousRound]] = TokenBuy_User[0];
                    userSellPrice[SellerAddress][PreviousRound][countSell[SellerAddress][PreviousRound]] = sellerTokenPrice;
                    countSell[SellerAddress][PreviousRound] = countSell[SellerAddress][PreviousRound]+(1);
                    uint256 totalamount = TokenBuy_User[0]*(sellerTokenPrice);
                    trasnferAmount(tokenAddress,SellerAddress,totalamount);
                    SellTotalToken[SellerAddress][round] += TokenBuy_User[0];
                    buyer_Token[msg.sender][round][buyer_Count[round]] = TokenBuy_User[0];
                    buyerToken_Price[msg.sender][round][buyer_Count[round]] = sellerTokenPrice;
                    buyer_address[round][buyer_Count[round]] = msg.sender;
                    buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] += TokenBuy_User[0];
                    buyer_Count[round] = buyer_Count[round]+(1);
                    seller_Count[PreviousRound] = seller_Count[PreviousRound]+(1);
                    if(seller_Count[PreviousRound] >= buyer_Count[PreviousRound]){
                        seller_Count[PreviousRound] = 0;
                        PreviousRound = PreviousRound+(1);
                        if(PreviousRound > endRound){
                            PreviousRound = 0;
                            buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
                            buyertimeCount[msg.sender] = buyertimeCount[msg.sender]+(1);
                            if(!checkMinting[round])
                            {
                            ETAToken.minting(address(this),totalTokenMint);
                            totalTokenMint = 0;
                            checkMinting[round] = true;
                            }
                            round = round+(1);
                            if(round > 4)
                            {
                                endRound = round-(2);
                                PreviousRound = round-(5);
                            }
                        }
                    }
                    SellerAddress = buyer_address[PreviousRound][seller_Count[PreviousRound]];
                    sellerTokenPrice = buyerToken_Price[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                    tokenPriceAfterTwoRounds = sellerTokenPrice;
                    TokenBuy_ = buyer_Token[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                    TokenBuy_User = checktoken(round,PreviousRound, TokenBuy_);
                    TokenBuy_User[0] = TokenBuy_User[0]-(buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]);
                }
                buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
                buyertimeCount[msg.sender] = buyertimeCount[msg.sender]+(1);
            }
        }
    }
    function countBuyers(address _user, uint256 _round) public view returns(uint256[] memory,uint256[] memory)
    {
        uint256 total = buyer_Count[_round];
        uint256 count;
        uint256 count1;
        for(uint256 i = 0; i < total; i++)
        {
            if(buyer_address[_round][i] == _user)
            {   count = count+(1);    } 
        }
        uint256[] memory tokenBuyer_ = new uint256[](count);
        uint256[] memory tokenBuyerPrice_ = new uint256[](count);
        for(uint256 i = 0; i < total; i++)
        {
            if(buyer_address[_round][i] == _user)
            {    
                tokenBuyer_[count1] = buyer_Token[_user][_round][i];
                tokenBuyerPrice_[count1] = buyerToken_Price[_user][_round][i];
                count1 = count1+(1);     
            }
        }
        return(tokenBuyer_,tokenBuyerPrice_);
    }
    function trasnferAmount(address _tokenAddress, address _SellerAddress,uint256 _totalamount) 
    private{
        uint256[] memory levelPercentage_ = new uint256[](5);
        _totalamount = _totalamount/(1e18);
        if(_totalamount > 0)
        {
            levelPercentage_ = com.percentage(_totalamount,round);
            if(IBEP20(_tokenAddress) == USDTToken)
            {
                totalUSDTSpent[msg.sender] = totalUSDTSpent[msg.sender]+(_totalamount);
                USDTToken.transferFrom(msg.sender, _SellerAddress, levelPercentage_[0]);
                USDTToken.transferFrom(msg.sender, address(this), levelPercentage_[1]);
                USDTToken.transferFrom(msg.sender, owner(), levelPercentage_[2]);
                USDTToken.transferFrom(msg.sender, anotheraddress, levelPercentage_[6]);
                buyerReferralCommission(msg.sender,levelPercentage_);
                sellerReferralCommission(_SellerAddress,levelPercentage_);
            }else if(IERC20(_tokenAddress) == USDACE$Token)
            {
                totalUSDACESpent[msg.sender] = totalUSDACESpent[msg.sender]+(_totalamount);
                USDACE$Token.transferFrom(msg.sender, address(this), _totalamount);
                USDACE$Token.burn2(address(this),_totalamount);
                USDTToken.transfer(_SellerAddress, levelPercentage_[0]);
                USDTToken.transfer(owner(), levelPercentage_[2]);
                USDTToken.transfer(anotheraddress, levelPercentage_[6]);
                buyerReferralCommission(msg.sender,levelPercentage_);
                sellerReferralCommission(_SellerAddress,levelPercentage_);
            }    
        }
    }
    
    function Commission(address _address, uint256 value) 
    private{
        CommissionInfo storage info = commissionInfo[_address];
        uint256 per_80 = (value*(80))/(100);
        uint256 per_20 = (value*(20))/(100);
        info.USDT_Commission = info.USDT_Commission+(per_80);
        info.USDACE_Commission = info.USDACE_Commission+(per_20);
    }
    
    function buyerReferralCommission(address _address, uint256[] memory levelPercentage_) 
    private{
        uint256 _perPercentage;
        uint total = levelPercentage_[3]+(levelPercentage_[4])+(levelPercentage_[5]);
        UserInfo storage user = userInfo[_address];
        uint256 totalamount;
        address upline = user.referrer;
        uint256 per_80 = (levelPercentage_[2]*(80))/(100);
        uint256 per_20 = (levelPercentage_[2]*(20))/(100);
        userInfo[upline].USDT_1stLCommission = userInfo[upline].USDT_1stLCommission+(per_80);
        userInfo[upline].USDACE_1stLCommission = userInfo[upline].USDACE_1stLCommission+(per_20);
        for(uint256 count= 0; count < referDepth; count++){
            if(upline != address(0))
            {
                if(count < 10)
                {      _perPercentage = levelPercentage_[3]; } 
                else if(count < 20)
                {      _perPercentage = levelPercentage_[4]; }  
                else {  _perPercentage = levelPercentage_[5]; }    
                _perPercentage = _perPercentage/(10);
                totalamount = totalamount+(_perPercentage);
                uint256 per80 = (_perPercentage*(80))/(100);
                uint256 per20 = (_perPercentage*(20))/(100);
                userInfo[upline].USDT_Com_FromBuyer = userInfo[upline].USDT_Com_FromBuyer+(per80);
                userInfo[upline].USDACE_Com_FromBuyer = userInfo[upline].USDACE_Com_FromBuyer+(per20);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
        total = total-(totalamount);
        Commission(owner(),total);
    }
    function sellerReferralCommission(address _address, uint256[] memory levelPercentage_) 
    private{
        uint256 _perPercentage;
        uint total = levelPercentage_[3]+(levelPercentage_[4])+(levelPercentage_[5]);
        UserInfo storage user = userInfo[_address];
        uint256 totalamount;
        address upline = user.referrer;
        for(uint256 count= 0; count < referDepth; count++){
            if(upline != address(0))
            {
                if(count < 10)
                {      _perPercentage = levelPercentage_[3]; } 
                else if(count < 20)
                {      _perPercentage = levelPercentage_[4]; }  
                else {  _perPercentage = levelPercentage_[5]; }    
                _perPercentage = _perPercentage/(10);
                totalamount = totalamount+(_perPercentage);
                uint256 per80 = (_perPercentage*(80))/(100);
                uint256 per20 = (_perPercentage*(20))/(100);
                userInfo[upline].USDT_Com_FromSeller = userInfo[upline].USDT_Com_FromSeller+(per80);
                userInfo[upline].USDACE_Com_FromSeller = userInfo[upline].USDACE_Com_FromSeller+(per20);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
        total = total-(totalamount);
        Commission(owner(),total);
    } 
    
    function checkUSDACE(address to) public view returns(uint256)
    {
        uint256 values = USDACE$Token.balanceOf(to);
        return values;
    }
    function totalEarned(address _address) 
    public view returns(uint256 _TotalUSDTEarned,uint256 _TotalUSDACEEarned)
    {
        (uint256 _totalUSDT,uint256 _totalUSDACE ) = TotalClaimed(_address);
        _TotalUSDTEarned = _totalUSDT+(TotalUSDTEarned[_address]);
        _TotalUSDACEEarned = _totalUSDACE+(TotalUSDACEEarned[_address]);
        return (_TotalUSDTEarned,_TotalUSDACEEarned);
    }
    function TotalClaimed(address _address) 
    public view returns(uint256,uint256)
    {
        UserInfo storage user = userInfo[_address];
        uint256 totalUSDT;
        uint256 totalUSDACE;
        totalUSDT = totalUSDT+(user.USDT_1stLCommission)+(user.USDT_Com_FromBuyer)+(user.USDT_Com_FromSeller);
        totalUSDACE = totalUSDACE+(user.USDACE_1stLCommission)+(user.USDACE_Com_FromBuyer)+(user.USDACE_Com_FromSeller);

        if(_address == owner())
        {
            CommissionInfo storage info = commissionInfo[_address];
            totalUSDT = totalUSDT+(info.USDT_Commission);
            totalUSDACE = totalUSDACE+(info.USDACE_Commission);
        }
    return (totalUSDT, totalUSDACE);
    }
    function claimedCommission() 
    public{

        UserInfo storage user = userInfo[msg.sender];
        CommissionInfo storage info = commissionInfo[msg.sender];
        address _user = msg.sender;
        uint256 totalUSDT;
        uint256 totalUSDACE;
        totalUSDT = totalUSDT+(user.USDT_1stLCommission)+(user.USDT_Com_FromBuyer)+(user.USDT_Com_FromSeller);
        totalUSDACE = totalUSDACE+(user.USDACE_1stLCommission)+(user.USDACE_Com_FromBuyer)+(user.USDACE_Com_FromSeller);

        if(msg.sender == owner())
        {
            totalUSDT = totalUSDT+(info.USDT_Commission);
            totalUSDACE = totalUSDACE+(info.USDACE_Commission);
            totalUSDT = totalUSDT*(ownerPercentage)/(100);
        }

        require(totalUSDT > 0 && totalUSDACE > 0, "Balance less than zero");

        uint256 max = maxWithdraw(_user);
        uint256 total = TotalUSDTEarned[msg.sender]+(totalUSDT);
        require(total <= max);

        totalUSDTCommission[msg.sender] += totalUSDT;
        totalUSDACECommission[msg.sender] += totalUSDACE;

        USDTToken.transfer(msg.sender,totalUSDT);
        USDACE$Token.mint2(msg.sender);

        TotalUSDTEarned[msg.sender] += totalUSDT;
        TotalUSDACEEarned[msg.sender] += totalUSDACE;

        withdrawHistoryOfUSDT[msg.sender][w_count[msg.sender]] = totalUSDT;
        withdrawHistoryOfUSDACE[msg.sender][w_count[msg.sender]] = totalUSDACE;
        withdrawHistoryTime[msg.sender][w_count[msg.sender]] = block.timestamp;
        w_count[msg.sender] = w_count[msg.sender]+(1);

        user.USDT_1stLCommission = 0;
        user.USDT_Com_FromBuyer = 0;
        user.USDT_Com_FromSeller = 0;
        user.USDACE_1stLCommission = 0;
        user.USDACE_Com_FromBuyer = 0; 
        user.USDACE_Com_FromSeller = 0;
        info.USDT_Commission = 0;
        info.USDACE_Commission = 0;
    }

    function maxWithdraw(address _users) public view  returns(uint256)
    {
        uint256 _max = TotalUSDSpent[_users]*(mulplier);
        return _max;
    }

    function checkRemainingToken(address _SellerAddress, uint256 _PreviousRound) 
    public view returns (uint256){
            uint256 _TokenBuy = buyer_Token[_SellerAddress][_PreviousRound][seller_Count[_PreviousRound]];
            uint256[] memory TokenBuy_User1 = new uint256[](3);
            TokenBuy_User1 = checktoken(round,_PreviousRound, _TokenBuy);
            TokenBuy_User1[0] = TokenBuy_User1[0]-(buyerSellTotalToken[_SellerAddress][round][_PreviousRound][seller_Count[_PreviousRound]]);
            return TokenBuy_User1[0];
    } 
    
    function checktoken(uint256 currentRound , uint256 _round, uint256 _token) 
    private view returns (uint256[] memory){
        uint256 percentages = currentRound-(_round);
        uint256[] memory totalTokens = new uint256[](3);
        totalTokens[0] = (_token*(Selling_Percents[percentages]))/(baseDivider);
        totalTokens[1] = (_token*(Balance_Percents[percentages]))/(baseDivider);
        totalTokens[2] = (_token*(Round_Percents[percentages]))/(baseDivider);
        return totalTokens;
    }

    function checkbalance(address _user) 
    public view returns(uint256)
    {
        uint256 totalTokens;
        if(TotalUSDSpent[_user] > 0)
        {
            for(uint256 i = 0; i < buyertimeCount[_user] ; i++)
            {
                uint256 currentRound = round;
                uint256 _tokens = buyerTotalToken[_user][i];
                if(_tokens > 0)
                {
                    uint256 _rounds = buyerRound[_user][i];
                    uint256 percentages = currentRound-(_rounds);
                    uint256 total;
                    if(percentages <= 5)
                    {
                        total = (_tokens*(Round_Percents[percentages]))/(baseDivider);
                    }
                    else{
                        total = 0;
                    }
                    totalTokens = totalTokens+(total);
                }
            }
            totalTokens = totalTokens-(SellTotalToken[_user][round]);
            return totalTokens;
        }
        else{
            return totalTokens;
        }
    }

    function checkPrice(uint256 _tokens) public view returns (uint256 price)
    { 
        require(_tokens >= minDeposit, "less than min");
        uint256 _Price;
        if(round < 2)
        {
            require(_tokens <= maxDeposit, "less than max");
            (uint256 _Price1,uint256 _Price2) = getPrice(_tokens,round,cycle[round],tokenPrice);
            _Price = _Price1+(_Price2);
        }
        else{
            uint256 _maxRoundToken =  maxToken();
            require(_tokens <= _maxRoundToken, "less than max");
            uint256 _sellerCount = seller_Count[PreviousRound];
            address seller_address = buyer_address[PreviousRound][_sellerCount];
            uint256 seller_TokenPrice = buyerToken_Price[seller_address][PreviousRound][_sellerCount];
            uint256 Rem_token = checkRemainingToken(seller_address, PreviousRound);
            uint256[] memory BuyerandSales_Details = new uint256[](3);
            BuyerandSales_Details= getPriceAfterTwoRunds(_tokens, PreviousRound, endRound, buyer_Count[PreviousRound],
            seller_address,seller_TokenPrice,Rem_token,_sellerCount);
            _Price = BuyerandSales_Details[0];
        }
        return _Price;

    }
    function maxToken() public view
    returns(uint256)
    {
        uint256 TotalToken = (TotalTokenInRound[PreviousRound]*(Selling_Percents[round-PreviousRound]))/(baseDivider);
        return TotalToken;
    }
    function getPriceAfterTwoRunds(uint256 _Tokens,uint256 _PreviousRound,uint256 _endRound, uint256 _totaluser, 
    address _SellerAddress,uint256 _sellerTokenPrice,uint256 _TokenRemaining,uint256 _seller_Count) 
    public view returns(uint256[] memory Details){
        uint256 _remainingbuyerToken = _Tokens;
        uint256[] memory priceDetails = new uint256[](3);
        priceDetails[1] = _PreviousRound;
        uint256[] memory TokenBuy_User = new uint256[](3);
        TokenBuy_User[0] = _TokenRemaining;
        uint256 _currentRound = round;
        while(_remainingbuyerToken > 0)
            {
                if(_remainingbuyerToken <= TokenBuy_User[0]){
                priceDetails[0] = priceDetails[0]+(_remainingbuyerToken*(_sellerTokenPrice));
                _remainingbuyerToken = 0;
                }
                else{
                priceDetails[0] = priceDetails[0]+(TokenBuy_User[0]*(_sellerTokenPrice));
                _remainingbuyerToken = _remainingbuyerToken-(TokenBuy_User[0]);
                _seller_Count = _seller_Count+(1);
                    if( _seller_Count >= _totaluser){
                     priceDetails[1] = priceDetails[1]+(1);
                    if(priceDetails[1] > _endRound)
                        {
                            priceDetails[1] = 0;
                            _currentRound = _currentRound+(1);
                            if(_currentRound > 4)
                            {
                                _endRound = _currentRound-(2);
                                priceDetails[1] = _currentRound-(5);
                            }
                        }
                    _seller_Count = 0;
                    }
                _SellerAddress = buyer_address[priceDetails[1]][_seller_Count];
                _sellerTokenPrice = buyerToken_Price[_SellerAddress][priceDetails[1]][_seller_Count];
                _TokenRemaining = buyer_Token[_SellerAddress][priceDetails[1]][_seller_Count];
                TokenBuy_User = checktoken(_currentRound, priceDetails[1], _TokenRemaining);
                TokenBuy_User[0] = TokenBuy_User[0]-(buyerSellTotalToken[_SellerAddress][_currentRound][priceDetails[1]][_seller_Count]);
                }
            }
        priceDetails[0] = priceDetails[0]/(1e18);
        return priceDetails;
    }
    function getPrice1(uint256 _token, uint256 _round, uint256 _cycle)
    public view returns (uint256[] memory,uint256[] memory,uint256[] memory){
        uint256[] memory roundDetails = new uint256[](4);
        uint256[] memory currentDetails = new uint256[](4);
        uint256[] memory nextDetails = new uint256[](4);
        (roundDetails[0],roundDetails[1],roundDetails[2],roundDetails[3]) = checkRound(_token,_round);
        if(roundDetails[1] > 0){
            (currentDetails[0],currentDetails[1],currentDetails[2],currentDetails[3])
             = CheckCycle(roundDetails[1], roundDetails[0],_cycle);
        }
        if(roundDetails[3] > 0){
            (nextDetails[0],nextDetails[1],nextDetails[2],nextDetails[3])
            = CheckCycle(roundDetails[3], roundDetails[2],_cycle);
        }
        return (roundDetails,currentDetails, nextDetails);
    }

    function CheckCycle(uint256 _token,uint256 _round,uint256 _cycle) 
    private view returns (uint256,uint256,uint256,uint256){
        uint256 _remainingTokenCurrentCycle;
        uint256 _remainingTokenNextCycle;
        uint256 _cycle2;
        if(totalTokencycle[_round][_cycle] <= cycleSupply){
            _remainingTokenCurrentCycle = cycleSupply-(totalTokencycle[_round][_cycle]);
            if(_token <= _remainingTokenCurrentCycle){
                _remainingTokenCurrentCycle = _token;
                _remainingTokenNextCycle = 0;
                _cycle2 = 0;
                _cycle = cycle[_round];
            }
            else{
                _remainingTokenNextCycle = _token-(_remainingTokenCurrentCycle);
                _cycle2 = _cycle+(1);
                if(_cycle2 >= endcycles){
                    _remainingTokenNextCycle = 0;
                }
            }
        }
        return (_cycle,_remainingTokenCurrentCycle,_cycle2,_remainingTokenNextCycle);
    }

    function checkRound(uint256 _token,uint256 _round) 
    private view returns(uint256,uint256,uint256,uint256)
    {
        uint256 _remroundTokenCurrent;
        uint256 _remroundTokenNext;
        uint256 _round1;
        uint256 _round2;
        if(totalTokenRound[round] <= roundSupply)
        {
            _remroundTokenCurrent = roundSupply-(totalTokenRound[_round]);
            if(_token <= _remroundTokenCurrent){
                _remroundTokenCurrent = _token;
                _round1 = _round;
                _remroundTokenNext = 0;
                _round2 = 0;
            }else{
                    _remroundTokenNext = _token-(_remroundTokenCurrent);
                    _round1 = _round;
                    _round2 =_round+(1);
            }
        }
       return (_round1,_remroundTokenCurrent,_round2,_remroundTokenNext);
    }
    function checkSellerOrder() 
    private view returns(uint256 _price, uint256 _TokensellerRemaining){
            address SellerAddress = buyer_address[PreviousRound][seller_Count[PreviousRound]];
            uint256 sellerTokenPrice = buyerToken_Price[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
            uint256 TokensellerRemaining = checkRemainingToken(SellerAddress,PreviousRound);
            return (sellerTokenPrice, TokensellerRemaining);
    }

    function getPrice(uint256 _token, uint256 _round, uint256 _cycle, uint256 _price)
    public view returns (uint256,uint256){
        uint256 TotalCurrentPrice;
        uint256 TotalCurrentPrice1;
        uint256 TotalNextPrice;
        uint256 TotalNextPrice1;
        (uint256 PreviousRounds,uint256 roundTokenCurrent,uint256 nextRound,uint256 roundTokenNext) = checkRound(_token,_round);
        if(roundTokenCurrent > 0){
            uint256[] memory currentDetails = new uint256[](4);
            (currentDetails[0],currentDetails[1],currentDetails[2],currentDetails[3])
            = CheckCycle(roundTokenCurrent, PreviousRounds,_cycle);
            TotalCurrentPrice = currentDetails[1]*(_price);
            TotalCurrentPrice = TotalCurrentPrice/(1e18);
            if(currentDetails[3] > 0 ){
            uint256 nextPrice = _price+(tokenPriceIncreament);
            TotalCurrentPrice1 = currentDetails[3]*(nextPrice);
            TotalCurrentPrice1 = TotalCurrentPrice1/(1e18);
            }
        }
        if(roundTokenNext > 0){
            uint256[] memory nextDetails = new uint256[](4);
            _price = fixedPrice;
            _cycle = 0; 
            (nextDetails[0],nextDetails[1],nextDetails[2],nextDetails[3])
            = CheckCycle(roundTokenNext, nextRound,_cycle);
            TotalNextPrice = nextDetails[1]*(_price);
            TotalNextPrice = TotalNextPrice/(1e18);
            if(nextDetails[3] > 0){
            uint256 nextPrice = _price+(tokenPriceIncreament);
            TotalNextPrice1 = nextDetails[3]*(nextPrice);
            TotalNextPrice1 = TotalNextPrice1/(1e18);
            }
        }
        return ((TotalCurrentPrice1+(TotalCurrentPrice)),(TotalNextPrice+(TotalNextPrice1)));
    }

    function getETAWithdraw(address _user) 
    public view returns (uint256)
    {
        (uint result,,) = multiplerofETA(round);
        result = result/(1e18);
        uint256 _total = (TotalUSDSpent[_user]-(TotalUSDTEarned[_user]))*(result);
        return  _total;
    }

    function multiplerofETA(uint256 _round) private pure returns (uint256,uint256,uint256)
    {
        _round = _round*(1e18);
        uint256 multipal = 10000000000000000000;
        uint256 num = 8000000000000000000;
        uint256 diff;
        uint256 div;
        if(_round < 10000000000000000000)
        {
            multipal = 10000000000000000000;
        }
        else {
             diff = _round-(num);
             div = diff/(2000000000000000000);
            for(uint256 i=1;i<=div;i++)
            {
                multipal = multipal/(2);
            }
        }
        return (multipal,diff,div);

    }

    function userWithdrawETAToken() 
    public{
        address _user = msg.sender;
        require(getETAWithdraw(_user) > 0, "Sorry!, the amount is less than zero");
        ETAToken.transfer(msg.sender, getETAWithdraw(_user));
        updatebalance(msg.sender);
    }

    function updatebalance(address _user) private{

        for(uint256 i = 0 ; i <= round ; i++)
        {
            for(uint256 j = 0 ; j <= buyer_Count[i] ; j++)
            {
                if(buyer_address[i][j] == _user)
                {
                    buyer_Token[_user][i][j] = 0;
                    buyerToken_Price[_user][i][j] = 0;
                    SellTotalToken[_user][i] = 0;
                }
            }
        }
        for(uint256 i = 0; i < buyertimeCount[_user] ; i++)
        {
                buyerTotalToken[_user][i] = 0;
        }
        TotalUSDSpent[_user]  = 0;
        TotalUSDTEarned[_user] = 0;
        TotalUSDACEEarned[_user] = 0;
        
    }
    function changeWithdrawPercentage(uint256 _percentage)
    public
    onlyOwner
    {
        require(_percentage <= 100, "Invalid percentage");
        ownerPercentage = _percentage;
    }
    function WithdrawUSDToken()
    public
    onlyOwner
    {   USDTToken.transfer(owner(),USDTToken.balanceOf(address(this)));  }

}