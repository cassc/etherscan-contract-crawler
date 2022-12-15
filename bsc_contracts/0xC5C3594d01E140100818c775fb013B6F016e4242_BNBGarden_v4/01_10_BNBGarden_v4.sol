// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
pragma solidity 0.8.4;

abstract contract AuthUpgradeable is Initializable, UUPSUpgradeable, ContextUpgradeable {
    address owner;
    mapping (address => bool) private authorizations;

    function __AuthUpgradeable_init() internal onlyInitializing {
        __AuthUpgradeable_init_unchained();
    }

    function __AuthUpgradeable_init_unchained() internal onlyInitializing {
        owner = _msgSender();
        authorizations[_msgSender()] = true;
        __UUPSUpgradeable_init();
    }

    modifier onlyOwner() {
        require(isOwner(_msgSender())); _;
    }

    modifier authorized() {
        require(isAuthorized(_msgSender())); _;
    }

    function authorize(address _address) public onlyOwner {
        authorizations[_address] = true;
        emit Authorized(_address);
    }

    function unauthorize(address _address) public onlyOwner {
        authorizations[_address] = false;
        emit Unauthorized(_address);
    }

    function isOwner(address _address) public view returns (bool) {
        return _address == owner;
    }

    function isAuthorized(address _address) public view returns (bool) {
        return authorizations[_address];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        authorizations[oldOwner] = false;
        authorizations[newOwner] = true;
        emit Unauthorized(oldOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    event OwnershipTransferred(address oldOwner, address newOwner);
    event Authorized(address _address);
    event Unauthorized(address _address);

    uint256[49] private __gap;
}

abstract contract ReentrancyGuardUpgradeable {

    bool private _status;

    modifier nonReentrant() {
        require(_status != true, "ReentrancyGuard: reentrant call");
        _status = true;

        _;

        _status = false;
    }
}
library SafeERC20 {
    using AddressUpgradeable for address;
    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20Upgradeable token,address spender,uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20Upgradeable token,address spender,uint256 value) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    }
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IBNBGarden_Zap {
    function unZapToTokenFor(uint256 amount, address targetToken, address _user) external;
    function breakFor(uint256 amount, address _user) external;
}

//libraries
    struct User {
        uint256 startDate;
        uint256 divs;
        uint256 refBonus;
        uint256 totalInits;
        uint256 totalWiths;
        uint256 lastWith;
        uint256 keyCounter;
        Depo [] depoList;
        address ref;
        uint256 refCount;
        uint256 refWithdrawn;
    }
    struct Depo {
        uint256 key;
        uint256 depoTime;
        uint256 amt;
        bool initialWithdrawn;
        uint256 withdrawnAmt;
    }
    struct Main {
        uint256 ovrTotalDeps;
        uint256 ovrTotalWiths;
        uint256 users;
        uint256 compounds;
    }
    struct DivPercs{
        uint256 divsPercentage;
        uint256 feePercentage;
    }
contract BNBGarden_v4 is Initializable, UUPSUpgradeable, AuthUpgradeable, ReentrancyGuardUpgradeable  {
    function _authorizeUpgrade(address) internal override onlyOwner {}


    uint256 public constant launch = 1668153600;
    uint256 constant hardDays = 86400;
    uint256 constant percentdiv = 10000;
    uint256 public refPercentage;
    uint256 public devPercentage;
    uint256 public compoundPercentage;
    uint256 public collectPercentage;

    mapping (address => User) public UsersKey;
    mapping (uint256 => DivPercs) public PercsKey;

    mapping (uint256 => Main) public MainKey;
    using SafeERC20 for IERC20Upgradeable;
    IERC20Upgradeable public TOKEN_MAIN;

    bool public paused;
    address feeWallet;
    uint256 public MAX_EARNINGS;
    bool public RETRO_MODE;
    uint256 public MIN_INVEST_LIMIT;
    uint256 public WALLET_DEPOSIT_LIMIT;
    mapping(address => bool) public LockMagic;

    uint256 public WHALE_TAX_MULTIPLIER;

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();

        refPercentage = 300;
        devPercentage = 1000;
        compoundPercentage = 0;
        collectPercentage = 1000;
        TOKEN_MAIN = IERC20Upgradeable(0xd822E1737b1180F72368B2a9EB2de22805B67E34);

        WHALE_TAX_MULTIPLIER = 5;
        PercsKey[10] = DivPercs(100, 2000); //from day 1 to 10
        PercsKey[20] = DivPercs(100, 2000); //from day 11 to 20
        PercsKey[30] = DivPercs(200, 1800);
        PercsKey[40] = DivPercs(200, 1800);
        PercsKey[50] = DivPercs(200, 1800);
        PercsKey[60] = DivPercs(300, 1600);
        PercsKey[70] = DivPercs(300, 1600);
        PercsKey[80] = DivPercs(400, 1400);
        PercsKey[90] = DivPercs(400, 1400);
        PercsKey[100] = DivPercs(500, 1200); //from day 91 to 100
        PercsKey[110] = DivPercs(500, 1000); //from day 101 and up


        feeWallet = 0x8Ad9CB111d886dBAbBbf232c9A1339B13cB168F8;
        MAX_EARNINGS = 30000;

        MIN_INVEST_LIMIT = 1 * 1e18; // 1 LP = $100 , min invest = $25
        WALLET_DEPOSIT_LIMIT = 1000 * 1e18; // max invest = $25000
        // v2
        refPromotion = true;
        // v3
        SET_ZAPPER(0xF033b83DA815e7a0610891625FCb4ce169f8c58d);
        // v4
        WHALE_TAX_MINIMUM = 100; // 1%
    }

    function updatev2() external onlyOwner {
        bankWallet = 0x975a6e6c7425085eD4bc720f871C42Bc9eC6de62; // BankManager contract, to distribute to xThoreumBank stakers
    }

    function SET_ZAPPER(address _zapper) public onlyOwner {
        ZAPPER = IBNBGarden_Zap(_zapper);
        TOKEN_MAIN.safeApprove(_zapper, type(uint256).max);
    }

    function getMaxPayOutLeft(address adr, uint256 keyy) public view returns(uint256 maxPayout) {
        User storage user = UsersKey[adr];
        if (user.depoList[keyy].initialWithdrawn) return 0;
        maxPayout = ((user.depoList[keyy].amt * MAX_EARNINGS)/percentdiv) - (user.depoList[keyy].amt + user.depoList[keyy].withdrawnAmt) ;
    }

    function stake(uint256 amtx, address ref) public whenNotPaused {
        stakeFor(msg.sender, amtx, ref);
    }
    event StakeFor(address adr, uint256 amtx, address ref);
    function stakeFor(address adr, uint256 amtx, address ref) public nonReentrant whenNotPaused {
        require(amtx >= MIN_INVEST_LIMIT, "Minimum investment not enough");

        TOKEN_MAIN.safeTransferFrom(msg.sender, address(this), amtx);
        User storage user = UsersKey[adr];
        if (user.ref != address(0)) {
            ref = user.ref;
        } else {
            if (ref == adr || ref == address(0)) {
                ref=feeWallet;
            }
            user.ref = ref;
        }

        User storage user2 = UsersKey[ref];
        Main storage main = MainKey[1];

        if (user.lastWith == 0){
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
            main.users += 1;
        }
        uint256 userStakePercentAdjustment = percentdiv - devPercentage;
        uint256 adjustedAmt = (amtx * userStakePercentAdjustment)/(percentdiv);
        uint256 stakeFee = amtx - adjustedAmt;
        TOKEN_MAIN.safeTransfer(feeWallet, stakeFee/2);
        TOKEN_MAIN.safeTransfer(bankWallet, stakeFee/2);

        if (ref != address(0)){
            user2.refBonus += (adjustedAmt* refPercentage)/(percentdiv);
            user2.refCount++;
            if (refPromotion && ref!=feeWallet) {
                adjustedAmt += (adjustedAmt* refPercentage)/(percentdiv);
            }
        }

        require(user.totalInits + adjustedAmt <= WALLET_DEPOSIT_LIMIT, "Max deposit reached");
        user.totalInits += adjustedAmt;

        uint256 time = block.timestamp;
        if (time < launch ) {
            time = launch;
        }
        user.depoList.push(Depo({
        key: user.depoList.length,
        depoTime: time,
        amt: adjustedAmt,
        initialWithdrawn: false,
        withdrawnAmt: 0
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        emit StakeFor(adr, amtx, ref);

    }

    function userInfo(address adr) view external returns (Depo [] memory depoList){
        return(UsersKey[adr].depoList);
    }

    function getUserPercentage(address _adr) public view returns(uint256) {
        uint256 _contractBalance = contractBalance();
        if (UsersKey[_adr].totalInits==0 || _contractBalance==0) return 0;
        return (UsersKey[_adr].totalInits * percentdiv)/(_contractBalance);
    }

    function getWhaleTax(address _adr, uint256 amount) public view returns(uint256 _whaleTax) {
        uint256 userPercentage = getUserPercentage(_adr);
        if (userPercentage>1000) { userPercentage=1000;} // 10%
        else if (userPercentage<=WHALE_TAX_MINIMUM) { userPercentage=0;}
        _whaleTax = (amount * userPercentage * WHALE_TAX_MULTIPLIER)/(percentdiv);
    }

    function withdrawDivsToToken(address targetToken) public nonReentrant whenNotPaused returns (uint256 withdrawAmount){
        require(started(), "Not started");

        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        uint256 currentReturn;
        uint256 withdrawFee;

        for (uint i = 0; i < user.depoList.length; i++){
            if (user.depoList[i].initialWithdrawn == false) {

                uint256 collectable = calculateEarningsForUserKey(msg.sender,i);
                uint256 collectFee = (collectable * collectPercentage)/percentdiv;
                collectable -= collectFee;

                withdrawFee += collectFee;
                currentReturn += collectable;

                user.depoList[i].withdrawnAmt += collectable;
                user.depoList[i].depoTime = block.timestamp;
            }
        }

        user.divs += currentReturn; //total dividens collected
        user.totalWiths += currentReturn;
        user.lastWith = block.timestamp;
        main.ovrTotalWiths += currentReturn + withdrawFee;
        transferForGood(feeWallet, withdrawFee/2);
        transferForGood(bankWallet, withdrawFee/2);
        transferOrConvert(currentReturn, targetToken);

        return currentReturn;

    }

    function withdrawDivs() public whenNotPaused returns (uint256 withdrawAmount){
        return withdrawDivsToToken(address(TOKEN_MAIN));
    }

    function calculateEarningsForUserKey(address adr, uint256 keyy) public view returns(uint256 currentReturn) {
        User storage user = UsersKey[adr];
        if (!started() || user.depoList[keyy].initialWithdrawn == true) return 0;
        uint256 initialAmt = user.depoList[keyy].amt;
        uint256 elapsedDays = (block.timestamp - user.depoList[keyy].depoTime)/(hardDays);
        uint256 elapsedHours = (block.timestamp - user.depoList[keyy].depoTime)%(hardDays);

        uint256 t = Retro(initialAmt, elapsedDays);
        uint256 q = RetroRem(initialAmt, elapsedHours, elapsedDays);
        currentReturn = t+q;
        uint256 whaleTax = getWhaleTax(adr,currentReturn);
        currentReturn = currentReturn - whaleTax;

        uint256 withdrawnAmt = user.depoList[keyy].withdrawnAmt;
        uint256 maxPayout = (initialAmt * MAX_EARNINGS)/(percentdiv);
        if (currentReturn + initialAmt + withdrawnAmt > maxPayout) {
            if (maxPayout<=initialAmt + withdrawnAmt) {
                currentReturn = 0; // in case maxPayout is adjusted down
            } else {
                currentReturn = maxPayout - initialAmt - withdrawnAmt;
            }

        }
    }
    function contractBalance() public view returns(uint256) {
        return(TOKEN_MAIN.balanceOf(address(this)));
    }

    function transferForGood(address to, uint256 amount) private {
        amount = min ( amount, contractBalance());
        if (amount>0) {
            TOKEN_MAIN.safeTransfer(to, amount);
        } else {
            revert ("Contract balance or your amount is 0");
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function transferOrConvert(uint256 amount, address targetToken) private {
        if (targetToken == address(TOKEN_MAIN)) {
            transferForGood(msg.sender, amount);
        } else {
            amount = min ( amount, contractBalance());
            if (amount>0) {
                if (targetToken == address(0)) {
                    ZAPPER.breakFor(amount, msg.sender);
                } else {
                    ZAPPER.unZapToTokenFor(amount, targetToken, msg.sender);
                }
            } else {
                revert ("Contract balance or your amount is 0");
            }
        }
    }

    function unStakeToToken(uint256 keyy, address targetToken) nonReentrant whenNotPaused public {


        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];

        require(user.depoList[keyy].initialWithdrawn == false, "This has already been withdrawn.");

        uint256 initialAmt = user.depoList[keyy].amt;
        uint256 transferAmt;
        uint256 currentReturn = calculateEarningsForUserKey(msg.sender, keyy);

        uint256 collectFee = (currentReturn * collectPercentage)/(percentdiv);
        uint256 elapsedDays = 0;
        if (started()) {
            elapsedDays = (block.timestamp - user.depoList[keyy].depoTime)/(hardDays);
        }

        uint256 y = getIndex(elapsedDays);
        uint256 unstakeFee = (initialAmt * PercsKey[y].feePercentage)/(percentdiv);
        require(initialAmt >= unstakeFee && currentReturn >= collectFee,"fee setting is wrong");

        transferAmt = initialAmt - unstakeFee + currentReturn - collectFee;

        require(user.totalInits >= initialAmt,"something wrong with user.totalInits");
        user.totalInits -= initialAmt;

        if (started()) {
            for (uint i = 0; i < user.depoList.length; i++){
                if (user.depoList[i].initialWithdrawn == false) {
                    user.depoList[i].depoTime = block.timestamp;
                }
            }
        }

        user.divs += currentReturn - collectFee; //total dividens collected
        user.totalWiths += transferAmt;
        user.lastWith = block.timestamp;
        //user.depoList[keyy].amt = 0;
        user.depoList[keyy].withdrawnAmt += currentReturn - collectFee;
        user.depoList[keyy].initialWithdrawn = true;

        main.ovrTotalWiths += transferAmt + collectFee + unstakeFee;
        transferForGood(feeWallet, (collectFee + unstakeFee)/2);
        transferForGood(bankWallet, (collectFee + unstakeFee)/2);
        transferOrConvert(transferAmt, targetToken);
    }

    function withdrawInitial(uint256 keyy) whenNotPaused public {
        unStakeToToken(keyy, address(TOKEN_MAIN));
    }

    function withdrawRefBonus() public whenNotPaused {
        User storage user = UsersKey[msg.sender];
        uint256 amtz = user.refBonus;
        require(amtz>0,"no ref bonus");

        user.refWithdrawn +=amtz;
        user.refBonus = 0;
        Main storage main = MainKey[1];
        main.ovrTotalWiths += amtz;

        transferForGood(msg.sender, amtz);
    }

    function calcdiv(address dy) public view returns (uint256 totalWithdrawable){
        User storage user = UsersKey[dy];
        for (uint256 i = 0; i < user.depoList.length; i++){
            if (user.depoList[i].initialWithdrawn == false){
                totalWithdrawable +=calculateEarningsForUserKey(dy,i);
            }
        }
    }

    function getIndex(uint256 elapsedDays) public pure returns (uint256 index) {
        if (elapsedDays>=100)  {
            index = 110;
        }
        else {
            index = 10 * ((elapsedDays / 10) + 1);
        }
    }

    // Function to calculate the dividends for less than a day(remaining time beyond days). Takes in the deposit amount the dividends will be based on,
    // the hours elapsed since the last day counted, the time elapsed in days
    function RetroRem(
        uint256 amty,
        uint256 elapsedHours,
        uint256 elapsedDays
    ) public view returns (uint256 remPayOut) {
        uint256 y = getIndex(elapsedDays);
        remPayOut = (amty * elapsedHours * PercsKey[y].divsPercentage)/(hardDays * percentdiv);
        // returns total payout accrued past the last full day
    }

    // Function to calculate the amount of dividends earned based on how many full days have passed.
    function Retro(
        uint256 amount,
        uint256 currDays
    ) public view returns (uint256 newAmt) {

        uint256 remainder;

        if (currDays>100) {
            remainder = 100 * ((currDays-100)/100) + (currDays % 100);
        } else {
            remainder = currDays % 10;
        }

        uint256 y = (currDays / 10) + 1;
        if (y > 10) {
            y = 11;
        }

        for (uint256 i = 1; i <= y; i++) {
            uint256 z;
            if (i == y) {
                z = remainder;
            } else {
                z = 10;
            }
            newAmt += (amount * z * PercsKey[i*10].divsPercentage)/(percentdiv);
        }

    }

    function started() public view returns(bool) {
        return block.timestamp > launch;
    }

    function compound() public whenNotPaused nonReentrant {
        require(started(), "Not started");

        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];

        uint256 y = calcdiv(msg.sender);
        require (y>= MIN_INVEST_LIMIT || msg.sender == owner,"cannot compound less than MIN_INVEST_LIMIT");
        y =  ( y * (percentdiv - compoundPercentage)) / percentdiv;
        user.divs += y;

        uint256 adjustedPercent = percentdiv - devPercentage;
        y = (y * adjustedPercent)/(percentdiv);

        require(user.totalInits + y <= WALLET_DEPOSIT_LIMIT, "Max deposit reached");
        user.totalInits +=y;

        for (uint i = 0; i < user.depoList.length; i++){
            if (user.depoList[i].initialWithdrawn == false) {
                user.depoList[i].withdrawnAmt += (calculateEarningsForUserKey(msg.sender,i) * (percentdiv - compoundPercentage)) / percentdiv;
                user.depoList[i].depoTime = block.timestamp;
            }
        }

        user.depoList.push(Depo({
        key: user.keyCounter,
        depoTime: block.timestamp,
        amt: y,
        initialWithdrawn: false,
        withdrawnAmt: 0
        }));


        user.keyCounter += 1;
        user.lastWith = block.timestamp;

        main.ovrTotalDeps += 1;
        main.compounds += y;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }
    function SET_PAUSED(bool _PAUSED) external onlyOwner{
        paused = _PAUSED;
    }


    function changeWallet(address _feeWallet, address _bankWallet) external onlyOwner {
        feeWallet = _feeWallet;
        bankWallet = _bankWallet;
    }

    function SET_WALLET_DEPOSIT_LIMIT(uint256 _MIN_INVEST_LIMIT,uint256 _WALLET_DEPOSIT_LIMIT) external onlyOwner{
        MIN_INVEST_LIMIT = _MIN_INVEST_LIMIT;
        WALLET_DEPOSIT_LIMIT = _WALLET_DEPOSIT_LIMIT;
    }

    function retrieveTokens(address token) external onlyOwner {
        require(token != address(TOKEN_MAIN),"Cannot retrieve main token, only for stucked token");
        require(IERC20Upgradeable(token).transfer(msg.sender, IERC20Upgradeable(token).balanceOf(address(this))), "Transfer failed!");
    }

    bool public refPromotion;
    function SET_refPromotion (bool _value) external onlyOwner {
        refPromotion = _value;
    }
    IBNBGarden_Zap ZAPPER;

    uint256 public WHALE_TAX_MINIMUM;
    address public bankWallet;
}