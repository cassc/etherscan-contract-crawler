// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
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
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
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
//libraries
    struct User {
        uint256 startDate;
        uint256 divs;
        uint256 refBonus;
        uint256 totalInits;
        uint256 totalWiths;
        uint256 totalAccrued;
        uint256 lastWith;
        uint256 timesCmpd;
        uint256 keyCounter;
        Depo [] depoList;
    }
    struct Depo {
        uint256 key;
        uint256 depoTime;
        uint256 amt;
        address reffy;
        bool initialWithdrawn;
    }
    struct Main {
        uint256 ovrTotalDeps;
        uint256 ovrTotalWiths;
        uint256 users;
        uint256 compounds;
    }
    struct DivPercs{
        uint256 daysInSeconds; // updated to be in seconds
        uint256 divsPercentage;
    }
    struct FeesPercs{
        uint256 daysInSeconds;
        uint256 feePercentage;
    }
contract WealthBuilder_v1 is Initializable, UUPSUpgradeable, AuthUpgradeable, ReentrancyGuardUpgradeable  {
    function _authorizeUpgrade(address) internal override onlyOwner {}

    using SafeMathUpgradeable for uint256;
    uint256 constant launch = 0;
    uint256 constant hardDays = 86400;
    uint256 constant percentdiv = 10000;
    uint256 public refPercentage;
    uint256 public devPercentage;
    mapping (address => mapping(uint256 => Depo)) public DeposMap;
    mapping (address => User) public UsersKey;
    mapping (uint256 => DivPercs) public PercsKey;
    mapping (uint256 => FeesPercs) public FeesKey;
    mapping (uint256 => Main) public MainKey;
    using SafeERC20 for IERC20Upgradeable;
    IERC20Upgradeable public TOKEN_MAIN;


    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();

        refPercentage = 300;
        devPercentage = 1000;

        PercsKey[10] = DivPercs(864000, 100);
        PercsKey[20] = DivPercs(1728000, 200);
        PercsKey[30] = DivPercs(2592000, 300);
        PercsKey[40] = DivPercs(3456000, 400);
        PercsKey[50] = DivPercs(4320000, 500);
        FeesKey[10] = FeesPercs(864000, 1000);
        FeesKey[20] = FeesPercs(1728000, 800);
        FeesKey[30] = FeesPercs(3456000, 500);
        FeesKey[40] = FeesPercs(4320000, 200);

        TOKEN_MAIN = IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    }

    function upgradeToken(address _mainToken) external onlyOwner {
        TOKEN_MAIN = IERC20Upgradeable(_mainToken);
    }

    function stakeStablecoins(uint256 amtx, address ref) payable public nonReentrant whenNotPaused {
        require(block.timestamp >= launch || msg.sender == owner, "App did not launch yet.");
        require(ref != msg.sender, "You cannot refer yourself!");
        TOKEN_MAIN.safeTransferFrom(msg.sender, address(this), amtx);
        User storage user = UsersKey[msg.sender];
        User storage user2 = UsersKey[ref];
        Main storage main = MainKey[1];
        if (user.lastWith == 0){
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
        }
        uint256 userStakePercentAdjustment = percentdiv - devPercentage;
        uint256 adjustedAmt = amtx.mul(userStakePercentAdjustment).div(percentdiv);
        uint256 stakeFee = amtx.mul(devPercentage).div(percentdiv);

        user.totalInits += adjustedAmt;
        uint256 refAmtx = adjustedAmt.mul(refPercentage).div(percentdiv);
        if (ref == address(0)){
            user2.refBonus += 0;
            user.refBonus += 0;
        } else {
            user2.refBonus += refAmtx;
            user.refBonus += refAmtx;
        }

        user.depoList.push(Depo({
        key: user.depoList.length,
        depoTime: block.timestamp,
        amt: adjustedAmt,
        reffy: ref,
        initialWithdrawn: false
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        main.users += 1;

        TOKEN_MAIN.safeTransfer(owner, stakeFee);
    }

    function userInfo() view external returns (Depo [] memory depoList){
        User storage user = UsersKey[msg.sender];
        return(
        user.depoList
        );
    }

    function withdrawDivs() public nonReentrant whenNotPaused returns (uint256 withdrawAmount){
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        uint256 x = calcdiv(msg.sender);

        for (uint i = 0; i < user.depoList.length; i++){
            if (user.depoList[i].initialWithdrawn == false) {
                user.depoList[i].depoTime = block.timestamp;
            }
        }

        main.ovrTotalWiths += x;
        user.lastWith = block.timestamp;
        TOKEN_MAIN.safeTransfer(msg.sender, x);
        return x;
    }

    function withdrawInitial(uint256 keyy) nonReentrant public {

        User storage user = UsersKey[msg.sender];

        require(user.depoList[keyy].initialWithdrawn == false, "This has already been withdrawn.");

        uint256 initialAmt = user.depoList[keyy].amt;
        uint256 currDays1 = user.depoList[keyy].depoTime;
        uint256 currTime = block.timestamp;
        uint256 currDays = currTime - currDays1;
        uint256 transferAmt;

        if (currDays < FeesKey[10].daysInSeconds){ // LESS THAN 10 DAYS STAKED
            uint256 minusAmt = initialAmt.mul(FeesKey[10].feePercentage).div(percentdiv); //10% fee

            uint256 dailyReturn = initialAmt.mul(PercsKey[10].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);

            transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;

            TOKEN_MAIN.safeTransfer(msg.sender, transferAmt);
            TOKEN_MAIN.safeTransfer(owner, minusAmt);


        } else if (currDays >= FeesKey[10].daysInSeconds && currDays < FeesKey[20].daysInSeconds){ // BETWEEN 20 and 30 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[20].feePercentage).div(percentdiv); //8% fee

            uint256 dailyReturn = initialAmt.mul(PercsKey[10].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
            transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;

            TOKEN_MAIN.safeTransfer(msg.sender, transferAmt);
            TOKEN_MAIN.safeTransfer(owner, minusAmt);


        } else if (currDays >= FeesKey[20].daysInSeconds && currDays < FeesKey[30].daysInSeconds){ // BETWEEN 30 and 40 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[30].feePercentage).div(percentdiv); //5% fee

            uint256 dailyReturn = initialAmt.mul(PercsKey[20].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
            transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;

            TOKEN_MAIN.safeTransfer(msg.sender, transferAmt);
            TOKEN_MAIN.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[30].daysInSeconds && currDays < FeesKey[40].daysInSeconds){ // BETWEEN 30 and 40 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[40].feePercentage).div(percentdiv); //5% fee

            uint256 dailyReturn = initialAmt.mul(PercsKey[30].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
            transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;

            TOKEN_MAIN.safeTransfer(msg.sender, transferAmt);
            TOKEN_MAIN.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[40].daysInSeconds && currDays < FeesKey[50].daysInSeconds){ // BETWEEN 30 and 40 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[40].feePercentage).div(percentdiv); //2% fee

            uint256 dailyReturn = initialAmt.mul(PercsKey[40].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
            transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;

            TOKEN_MAIN.safeTransfer(msg.sender, transferAmt);
            TOKEN_MAIN.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[50].daysInSeconds){ // 40+ DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[40].feePercentage).div(percentdiv); //2% fee

            uint256 dailyReturn = initialAmt.mul(PercsKey[50].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
            transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;

            TOKEN_MAIN.safeTransfer(msg.sender, transferAmt);
            TOKEN_MAIN.safeTransfer(owner, minusAmt);

        } else {
            revert("Could not calculate the # of days youv've been staked.");
        }

    }
    function withdrawRefBonus() public whenNotPaused {
        User storage user = UsersKey[msg.sender];
        uint256 amtz = user.refBonus;
        user.refBonus = 0;

        TOKEN_MAIN.safeTransfer(msg.sender, amtz);
    }

    function stakeRefBonus() public whenNotPaused {
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        require(user.refBonus > 10);
        uint256 refferalAmount = user.refBonus;
        user.refBonus = 0;
        address ref = address(0); //ZERO ADDRESS

        user.depoList.push(Depo({
        key: user.keyCounter,
        depoTime: block.timestamp,
        amt: refferalAmount,
        reffy: ref,
        initialWithdrawn: false
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
    }

    function calcdiv(address dy) public view returns (uint256 totalWithdrawable){
        User storage user = UsersKey[dy];

        uint256 with;

        for (uint256 i = 0; i < user.depoList.length; i++){
            uint256 elapsedTime = block.timestamp.sub(user.depoList[i].depoTime);

            uint256 amount = user.depoList[i].amt;
            if (user.depoList[i].initialWithdrawn == false){
                if (elapsedTime <= PercsKey[20].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[10].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[20].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[30].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[40].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[50].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[50].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }

            }
        }
        return with;
    }
    function compound() public whenNotPaused nonReentrant {
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];

        uint256 y = calcdiv(msg.sender);

        for (uint i = 0; i < user.depoList.length; i++){
            if (user.depoList[i].initialWithdrawn == false) {
                user.depoList[i].depoTime = block.timestamp;
            }
        }

        user.depoList.push(Depo({
        key: user.keyCounter,
        depoTime: block.timestamp,
        amt: y,
        reffy: address(0),
        initialWithdrawn: false
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        main.compounds += 1;
        user.lastWith = block.timestamp;
    }

    bool public paused;
    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }
    function SET_PAUSED(bool _PAUSED) external onlyOwner{
        paused = _PAUSED;

    }

}