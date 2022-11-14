// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./pancake/IPancakeRouter.sol";
import "./pancake/IPancakePair.sol";
import "./pancake/IPancakeFactory.sol";

contract BTDogStakePool is Initializable, ReentrancyGuardUpgradeable,AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint;


    bytes32 public constant SCHEDUL_ROLE = keccak256("SCHEDUL_ROLE");

    mapping(uint => mapping(uint => uint)) dayToAmountToRewardRate;
    address public usdt;
    address public btdog;
    IPancakePair public pair;
    IPancakeRouter public router;

    uint[] refferRewardsRate;

    address [] userAddressArr;


    function initialize(address router_, address btdogAddr,address usdt_) initializer public {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        usdt = usdt_;
        btdog = btdogAddr;
        router = IPancakeRouter(router_);
        pair = IPancakePair(IPancakeFactory(router.factory()).getPair(usdt, btdogAddr));
        _init();
    }

    function _init() private {
        dayToAmountToRewardRate[1][100] = 30;
        dayToAmountToRewardRate[1][200] = 35;
        dayToAmountToRewardRate[1][500] = 40;
        dayToAmountToRewardRate[1][1000] = 45;
        dayToAmountToRewardRate[1][2000] = 50;

        dayToAmountToRewardRate[7][100] = 245;
        dayToAmountToRewardRate[7][200] = 280;
        dayToAmountToRewardRate[7][500] = 315;
        dayToAmountToRewardRate[7][1000] = 350;
        dayToAmountToRewardRate[7][2000] = 385;

        dayToAmountToRewardRate[30][100] = 1050;
        dayToAmountToRewardRate[30][200] = 1200;
        dayToAmountToRewardRate[30][500] = 1350;
        dayToAmountToRewardRate[30][1000] = 1500;
        dayToAmountToRewardRate[30][2000] = 1650;

        dayToAmountToRewardRate[90][100] = 3600;
        dayToAmountToRewardRate[90][200] = 4050;
        dayToAmountToRewardRate[90][500] = 4500;
        dayToAmountToRewardRate[90][1000] = 4950;
        dayToAmountToRewardRate[90][2000] = 5400;

        refferRewardsRate = [20,10,5,1,1,1,1,1];
        maxDepositAmount = 200;

    }


    struct Deposit {
        uint amountUSDT;
        uint amountBTDog;
        uint createTime;
        uint duration;
        uint rewards;
        uint withdrawn;
        bool finished;
        uint finishedTime;
    }

    struct User {
        Deposit[] deposits;
        address upline;
        address[] reffers;
        uint unclaimRefferReward;
        uint withdrawnedRefferReward;

        uint unclaimedNodeReward;
        uint withdrawnedNodeReward;

        uint totalDepositAmountUSDT;
        uint totalDepositAmountBTDog;
        uint totalPerformance;
        uint nodeType;


    }

    mapping(address => User) public users;

    uint public lastJobExcuteTimestamp;
    uint public jobExcuteTimes;

    mapping(address => uint)  refferToPerfomance;

    uint maxDepositAmount;


    event Stake(address addr,uint amountUSDT);
    event Job(uint timestamp,uint userAddrlength,uint times);
    event Withdrawn(address addr,uint depositIndex,uint prin,uint rewards);
    event WithdrawnRefferAndNodeReward(address addr,uint amount);



    function setMaxDepositAmount(uint maxDepositAmount_) external onlyRole(DEFAULT_ADMIN_ROLE){
        maxDepositAmount = maxDepositAmount_;
    }

    function stake(uint day_, uint amount_, address up) public {
        require(amount_ <= maxDepositAmount,'amount wrong');
        uint day = day_;
        uint amount = amount_;
        require(dayToAmountToRewardRate[day][amount] > 0, 'params wrong');

        User storage user = users[msg.sender];

        Deposit[] memory usersDeposits = user.deposits;

        for (uint i = 0; i < usersDeposits.length; i++) {
            if (!usersDeposits[i].finished) {
                require(usersDeposits[i].amountUSDT != amount * 1e18, 'repeat');
            }
        }


        if (user.upline == address(0)) {
            require(up != address(0) && up != msg.sender && users[up].upline != msg.sender, 'refferr wallet wrong');
            user.upline = up;
            users[up].reffers.push(msg.sender);
        }

        uint btDogPrice = getBtDogPrice();

        uint _amountBTDog = amount * 1e36 / btDogPrice;



        uint allowance = IERC20Upgradeable(btdog).allowance(msg.sender,address(this));
        if(allowance < _amountBTDog &&  allowance >= _amountBTDog * 95/ 100){
            _amountBTDog = allowance;
        }
        Deposit[] memory dd = getUserAllDeposit(msg.sender);
        IERC20Upgradeable(btdog).safeTransferFrom(msg.sender,address(this),_amountBTDog);

        user.deposits.push(Deposit({
            amountUSDT : amount * 1e18,
            amountBTDog : _amountBTDog,
            createTime : block.timestamp,
            duration : day,
            rewards : 0,
            withdrawn : 0,
            finished : false,
            finishedTime : 0
        }));

        address up_ = user.upline;

        for(uint i=0;i<30;i++){
            if(up_ == address (0)){
                break;
            }
            users[up_].totalPerformance += (amount * 1e18);
            up_ = users[up_].upline;
        }
        user.totalDepositAmountUSDT += amount * 1e18;
        user.totalDepositAmountBTDog += _amountBTDog;


        if(dd.length == 0){
            userAddressArr.push(msg.sender);
        }
        emit Stake(msg.sender,amount);
    }

    function addUser(address[] memory addr) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint i;i<addr.length;i++){
            userAddressArr.push(addr[i]);
        }

    }

    function getUser() external view returns(address [] memory userdd,uint length){
        userdd = userAddressArr;
        length = userAddressArr.length;

    }



    function job() external onlyRole(SCHEDUL_ROLE){

        if(lastJobExcuteTimestamp + 23 hours > block.timestamp){
            return;
        }
        jobExcuteTimes++;
        lastJobExcuteTimestamp = block.timestamp;
        uint _price = getBtDogPrice();
        for(uint i;i<userAddressArr.length;i++){
            (uint max,uint min) = getPerformance(userAddressArr[i]);
            if(max > 1000000 * 1e18 && min > 1000000 * 1e18  ){
                users[userAddressArr[i]].unclaimedNodeReward += (1000 *1e36 /_price);
                users[userAddressArr[i]].nodeType = 4;
            }else if(max > 300000 * 1e18 && min > 300000 * 1e18  ){
                users[userAddressArr[i]].unclaimedNodeReward += (500 *1e36 /_price);
                users[userAddressArr[i]].nodeType = 3;
            }else if(max > 50000 * 1e18 && min > 50000 * 1e18  ){
                users[userAddressArr[i]].unclaimedNodeReward += (200 *1e36 /_price);
                users[userAddressArr[i]].nodeType = 2;
            }else if(max > 10000 * 1e18 && min > 10000 * 1e18  ){
                users[userAddressArr[i]].unclaimedNodeReward += (50 *1e36 /_price);
                users[userAddressArr[i]].nodeType = 1;
            }
        }
        emit Job(lastJobExcuteTimestamp,userAddressArr.length,jobExcuteTimes);
    }


    function getPerformance(address addr) public returns (uint max, uint min){
        address[] memory _reffers = users[addr].reffers;

        for(uint i;i<_reffers.length;i++){
            (uint u,) = getActiveDeposit(_reffers[i]);
            refferToPerfomance[_reffers[i]] = users[_reffers[i]].totalPerformance + u;
        }

        address a;
        for(uint i;i<_reffers.length;i++){
            uint p = refferToPerfomance[_reffers[i]];
            if(p>max){
                max = p;
                a = _reffers[i];
            }
        }
        for(uint i;i<_reffers.length;i++){
            if(a == _reffers[i]){
                continue;
            }
            min += refferToPerfomance[_reffers[i]];
        }
    }

    function getActiveDeposit(address addr) public view returns(uint amountUSDT,uint amountBTDog){
        Deposit [] memory dop = users[addr].deposits;
        for(uint i=0;i<dop.length;i++){
            if(!dop[i].finished){
                amountUSDT += dop[i].amountUSDT;
                amountBTDog += dop[i].amountBTDog;
            }
        }
    }


    function withdrawn(uint depositIndex) external nonReentrant{
        User storage user = users[msg.sender];
        Deposit storage deposit = user.deposits[depositIndex];
        uint price = getBtDogPrice();

        require(!deposit.finished,'finished');

        uint _d = deposit.duration * 1 days;
        require(block.timestamp > deposit.createTime + _d,'unFinished');

        deposit.finished = true;
        deposit.finishedTime = block.timestamp;
        uint _day = deposit.duration;
        uint _amountUSDT = deposit.amountUSDT/1e18;

        uint _principal = deposit.amountUSDT * 1e18 / price ;
        uint _reward = _principal * dayToAmountToRewardRate[_day][_amountUSDT] / 1000;

        uint _p = deposit.amountUSDT;
        deposit.rewards = _reward;
        deposit.withdrawn = (_principal + _reward);
        IERC20Upgradeable(btdog).safeTransfer(msg.sender,_principal + _reward);

        address _up = user.upline;
        for(uint i; i<30;i++){
            if(_up == address (0)){
                break;
            }

            uint amountUSDTBase = users[_up].totalDepositAmountUSDT.min(deposit.amountUSDT);
            uint _tt = amountUSDTBase * dayToAmountToRewardRate[_day][_amountUSDT] * 1e18 / price / 1000;

            uint _refferRewards ;

            if(i<3 && users[_up].reffers.length > i){
                _refferRewards = _tt * refferRewardsRate[i]/100;

            }else if( (i>=3 && i<8) && users[_up].reffers.length >= 4){
                _refferRewards = _tt * refferRewardsRate[i]/100;
            }

            users[_up].unclaimRefferReward += _refferRewards;
            users[_up].totalPerformance -= _p;
            _up = users[_up].upline;
        }

        user.totalDepositAmountBTDog -= deposit.amountBTDog;
        user.totalDepositAmountUSDT -= deposit.amountUSDT;
        emit Withdrawn(msg.sender,depositIndex,_principal , _reward);
    }

    function withdrawnRefferAndNodeReward() external nonReentrant{
        User storage user = users[msg.sender];
        uint _withdrawnAmount;
        if(user.unclaimRefferReward > 0){
            _withdrawnAmount += user.unclaimRefferReward;
            user.withdrawnedRefferReward += user.unclaimRefferReward;
            user.unclaimRefferReward =0;
        }
        if(user.unclaimedNodeReward >0 ){
            _withdrawnAmount += user.unclaimedNodeReward;
            user.withdrawnedNodeReward += user.unclaimedNodeReward;
            user.unclaimedNodeReward =0;
        }
        if(_withdrawnAmount>0){
            IERC20Upgradeable(btdog).safeTransfer(msg.sender,_withdrawnAmount);
            emit WithdrawnRefferAndNodeReward(msg.sender,_withdrawnAmount);
        }

    }

    function getTeam(address addr) external view returns(address[] memory usersArray,uint [] memory perfomanceArray){

        address[] storage reffersArr = users[addr].reffers;

//        address[] memory usersArray = new address[reffersArr.length];
//        address[] memory perfomanceArray = new address[reffersArr.length];
        for(uint i;i< reffersArr.length;i++){
            usersArray[i] = reffersArr[i];
            perfomanceArray[i] = users[reffersArr[i]].totalPerformance;
        }
    }

    function getMyRefferr(address addr) public view returns(address [] memory reffers){
        reffers = users[addr].reffers;
    }





    function getUserAllDeposit(address addr) public view returns(Deposit [] memory deposits){
        return users[addr].deposits;
    }



    function getBtDogPrice() public view returns (uint){
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        (uint112 reserveUsdt, uint112 reserveBtDog) = (reserve0, reserve1);
        if (pair.token0() != usdt) {
            reserveUsdt = reserve1;
            reserveBtDog = reserve0;
        }
        return router.getAmountOut(1e18, reserveBtDog, reserveUsdt);
    }


    function claim(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(token).transfer(msg.sender, IERC20Upgradeable(token).balanceOf(address(this)));
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }


}