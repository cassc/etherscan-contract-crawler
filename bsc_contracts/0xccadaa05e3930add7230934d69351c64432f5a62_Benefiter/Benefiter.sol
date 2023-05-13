/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

// SPDX-License-Identifier: MIT
// Contract Author: Benefiter

pragma solidity >= 0.8.10;
pragma abicoder v2;

interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Benefiter {

    IBEP20 public token;
    address[] public usedTokens;
    constructor() {
        token = IBEP20(0x55d398326f99059fF775485246999027B3197955);
        usedTokens.push(address(token));
    }
    receive() external payable {}

    struct Node {
        address parent;
        address[] children;
        uint256 levelOneChildCount;
        uint256 subscribeCount;
        uint256 registerTime;
    }

    struct Transaction {
        string txType;
        uint256 amount;
        address token;
        uint256 time;
    }

    string public currentDomains;
    mapping(address => Node) public tree;
    mapping(address => mapping(address => uint256)) public balance;
    mapping(address => bool) public hasDeposited;
    address public root = 0x0000b1111E222233334444555566667777888899;
    uint256 public retirementPool;
    uint256 public allRetirementPool;
    uint256 public rewardPool;
    uint256 public allRewardPool;
    uint256 public constant RETIREMENT_POOL_AMOUNT = 4 ether;
    uint256 public constant REWARD_POOL_AMOUNT = 3 ether;
    address[] public eligibleRetirementNodes;
    address[] public eligibleRewardNodes;
    uint256 public allNodesCount = 0;
    address[] public allNodes;
    uint256 public lastDistribution = block.timestamp;
    address payable wallet1 = payable(0xdD1DE60E6B5FF80feD9d7BbFa91266d9B1eaDB33);
    address payable wallet2 = payable(0x11601D56C71971789e2c567C0dA443251782cbBD);
    address payable wallet3 = payable(0x0cFfdfa5153eed927D5A2040b9e8deD7361e4cF9);
    address payable wallet4 = payable(0x3E63674C5E00FDDd9c57694C8ee654883459e4BE);
    mapping(address => uint256) public subscriptionEnd;
    uint256 constant SUBSCRIPTION_FEE = 10 ether;
    uint256 constant PARENT_SUBSCRIPTION_REWARD = 0.3 ether;
    uint256 public allSubscribeCount = 0;
    mapping(address => uint256) totalWithdraw;
    mapping(address => uint256) totalCompanyReward;
    mapping(address => uint256) totalSpecialReward;
    mapping(address => Transaction[]) public userTransactions;

    /*
    The contract owner has access to the following actions:
    1. Changing the contract owner.
    2. Changing the addresses of depositable token in case the balance of the token worth $1 is lost.
    3. Defining the domains on which Benefiter is currently active.
    */

    address public owner = msg.sender;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function to change the token address.");
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    event setNewToken(string txType);

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        distributeRetirementPool();
        distributeRewardPool();
        lastDistribution = block.timestamp;
        token = IBEP20(_tokenAddress);
        usedTokens.push(_tokenAddress);
        emit setNewToken("Set New Token");
    }

    event setNewDomains(string txType);

    function setCurrentDomain(string calldata _domains) external onlyOwner {
        currentDomains = _domains;
        emit setNewDomains("Set New Domains");
    }


    // Partners
    modifier onlyOwnerOfWallet1() {
        require(msg.sender == wallet1, "Only the owner of wallet1 can perform this action");
        _;
    }

    function changeWallet1Address(address payable newAddress) public onlyOwnerOfWallet1 {
        uint256 wallet1Balance = balance[wallet1][address(token)];
        balance[wallet1][address(token)] = 0;
        balance[newAddress][address(token)] = wallet1Balance;
        wallet1 = newAddress;
    }

    modifier onlyOwnerOfWallet2() {
        require(msg.sender == wallet2, "Only the owner of wallet2 can perform this action");
        _;
    }

    function changeWallet2Address(address payable newAddress) public onlyOwnerOfWallet2 {
        uint256 wallet2Balance = balance[wallet2][address(token)];
        balance[wallet2][address(token)] = 0;
        balance[newAddress][address(token)] = wallet2Balance;
        wallet2 = newAddress;
    }

    modifier onlyOwnerOfWallet3() {
        require(msg.sender == wallet3, "Only the owner of wallet3 can perform this action");
        _;
    }

    function changeWallet3Address(address payable newAddress) public onlyOwnerOfWallet3 {
        uint256 wallet3Balance = balance[wallet3][address(token)];
        balance[wallet3][address(token)] = 0;
        balance[newAddress][address(token)] = wallet3Balance;
        wallet3 = newAddress;
    }

    modifier onlyOwnerOfWallet4() {
        require(msg.sender == wallet4, "Only the owner of wallet4 can perform this action");
        _;
    }

    function changeWallet4Address(address payable newAddress) public onlyOwnerOfWallet4 {
        uint256 wallet4Balance = balance[wallet4][address(token)];
        balance[wallet4][address(token)] = 0;
        balance[newAddress][address(token)] = wallet4Balance;
        wallet4 = newAddress;
    }


    // Main functions --------------------------------------------------------------------

    function addChild(address parent, address child) private {
        require(parent != address(0), "Parent address should not be zero.");
        require(child != address(0), "Child address should not be zero.");
        require(parent != child, "Parent and child addresses should not be the same.");
        require(tree[parent].parent != child, "Cannot set child as parent of its parent.");
        require(tree[child].parent == address(0), "Child node already has a parent.");
        
        tree[parent].children.push(child);
        tree[child].parent = parent;
        tree[parent].levelOneChildCount += 1;
        tree[child].subscribeCount += 1;
        tree[child].registerTime = block.timestamp;

        if (parent != root && tree[parent].children.length == 20 ) {
            eligibleRetirementNodes.push(parent);
        }

        allNodes.push(child);
        allNodesCount++;
        allSubscribeCount++;
    }

    function getParents(address addr) public view returns (address[] memory) {
        address[] memory result = new address[](20);
        address current = tree[addr].parent;
        uint i = 0;
        while (current != address(0)) {
            result[i] = current;
            current = tree[current].parent;
            i++;
        }
        return result;
    }

    event DepositEvent(string txType, uint256 amount);

    function deposit(address parent, address child, uint256 _amount) external payable {
        if (parent != root) {
            require(tree[parent].parent != address(0), "Parent address not registered.");
        }
        require(tree[child].parent == address(0), "Child node already has a parent.");
        require(!hasDeposited[msg.sender], "You have already deposited.");
        require(token.allowance(msg.sender, address(this)) >= _amount, "Token allowance not enough");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(_amount >= 110, "Amount must be at least 110$");
        token.transferFrom(msg.sender, address(this), _amount);

        hasDeposited[msg.sender] = true;

        // Call addChild function with parent and child addresses
        addChild(parent, child);
        
        // Parent nodes of sender
        address[] memory parents = getParents(child);
        uint256 payBack = _amount - 110 ether;
        uint256 remainingAmount = _amount - payBack;
        
        // Check the level of sender and set the values of perPerson and totalAmount
        uint256[] memory perPerson = new uint256[](parents.length);
        perPerson[0] = 20 ether;
        perPerson[1] = 10 ether;
        for (uint256 i = 2; i < perPerson.length; i++) {
            if (i < 8) {
                perPerson[i] = 5 ether;
            }
            else if (i < 12) {
                perPerson[i] = 3 ether;
            }
            else {
                perPerson[i] = 1 ether;
            }
        }
        
        // Distribute the totalAmount among the parent nodes of sender
        for (uint i = 0; i < parents.length; i++) {
            address currentParent = parents[i];
            if (currentParent != address(0) && currentParent != root) {
                uint256 thisAmount = perPerson[i];
                if (thisAmount != 0) {
                    balance[currentParent][address(token)] += thisAmount;
                    remainingAmount -= thisAmount;

                    Transaction memory Balance = Transaction({
                        txType: "New User",
                        amount: thisAmount,
                        token: address(token),
                        time: block.timestamp
                    });
                    userTransactions[currentParent].push(Balance);
                }
            }
        }

        // Send 4 ether to the retirement pool
        retirementPool += RETIREMENT_POOL_AMOUNT;
        allRetirementPool += RETIREMENT_POOL_AMOUNT;
        rewardPool += REWARD_POOL_AMOUNT;
        allRewardPool += REWARD_POOL_AMOUNT;
        remainingAmount -= RETIREMENT_POOL_AMOUNT;
        remainingAmount -= REWARD_POOL_AMOUNT;

        //PayBack extra amount to sender
        balance[msg.sender][address(token)] += payBack;

        //Subscribe first month
        subscriptionEnd[msg.sender] = block.timestamp + 30 days;
        
        // Send the remaining balance to the specified wallets
        uint256 walletsPart = remainingAmount / 4;
        balance[wallet1][address(token)] += walletsPart;
        balance[wallet2][address(token)] += walletsPart;
        balance[wallet3][address(token)] += walletsPart;
        balance[wallet4][address(token)] += walletsPart;

        Transaction memory Deposit = Transaction({
            txType: "Register",
            amount: _amount,
            token: address(token),
            time: block.timestamp
        });
        userTransactions[msg.sender].push(Deposit);

        if (payBack > 0) {
            Transaction memory PayBack = Transaction({
                txType: "PayBack",
                amount: payBack,
                token: address(token),
                time: block.timestamp
            });
            userTransactions[msg.sender].push(PayBack);
        }

        emit DepositEvent("New User", _amount);
    }

    event SubscribeEvent(string txType, uint256 amount);

    function subscribe(uint256 _amount) external {
        require(_amount >= SUBSCRIPTION_FEE, "Insufficient subscription fee.");
        require(hasDeposited[msg.sender], "You have not deposited.");

        // Transfer token from sender's address to contract address
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");
        
        // Parent nodes of sender
        address[] memory parents = getParents(msg.sender);
        uint256 remainingSubscriptionAmount = _amount;
        uint256 payBack = _amount % SUBSCRIPTION_FEE;
        remainingSubscriptionAmount -= payBack;
        uint256 subscriptionMonths = remainingSubscriptionAmount / SUBSCRIPTION_FEE;
        tree[msg.sender].subscribeCount += subscriptionMonths;
        allSubscribeCount += subscriptionMonths;

        // Update the subscription end time
        if (subscriptionEnd[msg.sender] >= block.timestamp) {
            subscriptionEnd[msg.sender] += subscriptionMonths * 30 days;
        }
        else{
            subscriptionEnd[msg.sender] = block.timestamp + subscriptionMonths * 30 days;
        }
        
        // Distribute the subscription fee among the parent nodes of sender
        for (uint i = 0; i < parents.length; i++) {
            address currentParent = parents[i];
            if (currentParent != address(0) && currentParent != root) {
                balance[currentParent][address(token)] += subscriptionMonths * PARENT_SUBSCRIPTION_REWARD;
                remainingSubscriptionAmount -= subscriptionMonths * PARENT_SUBSCRIPTION_REWARD;

                Transaction memory Balance = Transaction({
                    txType: "New Subscribe",
                    amount: subscriptionMonths * PARENT_SUBSCRIPTION_REWARD,
                    token: address(token),
                    time: block.timestamp
                });
                userTransactions[currentParent].push(Balance);
            }
        }

        // Send the remaining balance to the specified wallets
        uint256 walletsPart = remainingSubscriptionAmount / 4;
        balance[wallet1][address(token)] += walletsPart;
        balance[wallet2][address(token)] += walletsPart;
        balance[wallet3][address(token)] += walletsPart;
        balance[wallet4][address(token)] += walletsPart;

        // Pay back extra amount to sender
        balance[msg.sender][address(token)] += payBack;

        Transaction memory Subscribe = Transaction({
            txType: "Subscribe",
            amount: _amount,
            token: address(token),
            time: block.timestamp
        });
        userTransactions[msg.sender].push(Subscribe);

        if (payBack > 0) {
            Transaction memory PayBack = Transaction({
                txType: "PayBack",
                amount: payBack,
                token: address(token),
                time: block.timestamp
            });
            userTransactions[msg.sender].push(PayBack);
        }

        emit SubscribeEvent("Subscribe", _amount);
    }

    event WithdrawEvent(string txType, uint256 amount);

    function withdraw(address _token, uint256 amount) public {
        require(amount > 0, "Amount should be greater than zero.");
        require(balance[msg.sender][_token] >= amount, "Insufficient balance.");
        balance[msg.sender][_token] -= amount;
        totalWithdraw[_token] += amount;
        require(IBEP20(_token).transfer(msg.sender, amount), "Token transfer failed");

        Transaction memory Withdraw = Transaction({
            txType: "Withdraw",
            amount: amount,
            token: address(_token),
            time: block.timestamp
        });
        userTransactions[msg.sender].push(Withdraw);

        emit WithdrawEvent("Withdraw", amount);
    }


    // Distribution --------------------------------------------------------------------

    event EndOfMonthEvent(string txType);

    function EndOfMonth() public {
        uint256 currentTime = block.timestamp;
        require(currentTime >= lastDistribution + 30 days, "Minimum distribution interval not elapsed.");
        distributeRetirementPool();
        distributeRewardPool();
        lastDistribution = currentTime;
        emit EndOfMonthEvent("End Of Month");
    }

    event distributeRetirementPoolEvent(string txType, uint256 amount);

    function distributeRetirementPool() private {
        // Distribute the retirement pool equally among eligible nodes
        if (eligibleRetirementNodes.length > 0) {
            uint256 amountPerNode = retirementPool / eligibleRetirementNodes.length;
            for (uint256 i = 0; i < eligibleRetirementNodes.length; i++) {
                address node = eligibleRetirementNodes[i];
                balance[node][address(token)] += amountPerNode;

                if (amountPerNode > 0) {
                    Transaction memory Balance = Transaction({
                        txType: "Retiremen",
                        amount: amountPerNode,
                        token: address(token),
                        time: block.timestamp
                    });
                    userTransactions[node].push(Balance);
                }
            }
        }
        else{
            balance[wallet1][address(token)] += retirementPool / 4;
            balance[wallet2][address(token)] += retirementPool / 4;
            balance[wallet3][address(token)] += retirementPool / 4;
            balance[wallet4][address(token)] += retirementPool / 4;
        }

        emit distributeRetirementPoolEvent("Distribute Retirement Pool", retirementPool);

        retirementPool = 0;
    }

    event distributeRewardPoolEvent(string txType, uint256 amount);

    function distributeRewardPool() private {
        delete eligibleRewardNodes;
        eligibleRewardNodes = new address[](0);
        for (uint i = 0; i < allNodes.length; i++) {
            address node = allNodes[i];
            uint count = 0;
            for (uint j = 0; j < tree[node].children.length; j++) {
                address nodeChild = tree[node].children[j];
                if (tree[nodeChild].registerTime >= lastDistribution) {
                    count++;
                }
            }
            if(count >= 4) {
                eligibleRewardNodes.push(node);
            }
        }
        // Distribute the reward pool equally among eligible nodes
        if (eligibleRewardNodes.length > 0) {
            uint256 amountPerNode = rewardPool / eligibleRewardNodes.length;
            for (uint256 i = 0; i < eligibleRewardNodes.length; i++) {
                address node = eligibleRewardNodes[i];
                balance[node][address(token)] += amountPerNode;

                if (amountPerNode > 0) {
                    Transaction memory Balance = Transaction({
                        txType: "Reward",
                        amount: amountPerNode,
                        token: address(token),
                        time: block.timestamp
                    });
                    userTransactions[node].push(Balance);
                }
            }
        }
        else{
            balance[wallet1][address(token)] += rewardPool / 4;
            balance[wallet2][address(token)] += rewardPool / 4;
            balance[wallet3][address(token)] += rewardPool / 4;
            balance[wallet4][address(token)] += rewardPool / 4;
        }

        emit distributeRewardPoolEvent("Distribute Reward Pool", rewardPool);

        rewardPool = 0;
    }

    /*
    The company operates as an active holding and will allocate a portion of its revenue to users of the network.
    A portion of this reward will be distributed to all users based on the number of times they have purchased the monthly subscription,
    and another portion will be allocated to active individuals who have played a significant role in the network's progress.
    */

    event CompanyRewardEvent(string txType, uint256 amount);

    function CompanyReward(uint256 _amount) public {
        require(token.allowance(msg.sender, address(this)) >= _amount, "Token allowance not enough");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(_amount > 0, "Amount should be greater than zero.");
        token.transferFrom(msg.sender, address(this), _amount);
        totalCompanyReward[address(token)] += _amount;

        uint256 amountPerSubscribe = _amount / allSubscribeCount;
        for (uint i = 0; i < allNodes.length; i++) {
            address node = allNodes[i];
            uint count = tree[node].subscribeCount;
            balance[node][address(token)] += amountPerSubscribe * count;

            Transaction memory Balance = Transaction({
                txType: "Company Reward",
                amount: amountPerSubscribe * count,
                token: address(token),
                time: block.timestamp
            });
            userTransactions[node].push(Balance);
        }
        emit CompanyRewardEvent("CompanyReward", _amount);
    }

    event SpecialRewardEvent(string txType, uint256 amount);

    function SpecialReward(uint256 _amount, address _address) public {
        require(token.allowance(msg.sender, address(this)) >= _amount, "Token allowance not enough");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(_amount > 0, "Amount should be greater than zero.");
        token.transferFrom(msg.sender, address(this), _amount);
        totalSpecialReward[address(token)] += _amount;

        balance[_address][address(token)] += _amount;

        Transaction memory Balance = Transaction({
            txType: "Special Reward",
            amount: _amount,
            token: address(token),
            time: block.timestamp
        });
        userTransactions[_address].push(Balance);

        emit SpecialRewardEvent("SpecialReward", _amount);
    }

    
    // Get full details ---------------------------------------------------------------------

    function getTokenAddress() public view returns (address) {
        return (address(token));
    }

    function getCurrentDomains() public view returns (string memory) {
        return currentDomains;
    }

    function getUsedTokens() public view returns (address[] memory) {
        return usedTokens;
    }

    function getAllNodes() public view returns (address[] memory) {
        return allNodes;
    }

    function getAllNodesCount() public view returns (uint256) {
        return allNodesCount;
    }

    function getLastDistribution() public view returns (uint256) {
        return lastDistribution;
    }

    function allRetirementAmount() public view returns (uint256) {
        return allRetirementPool;
    }

    function retirementAmount() public view returns (uint256) {
        return retirementPool;
    }

    function eligibleRetirementCount() public view returns (uint256) {
        return eligibleRetirementNodes.length;
    }

    function allRewardAmount() public view returns (uint256) {
        return allRewardPool;
    }

    function rewardAmount() public view returns (uint256) {
        return rewardPool;
    }

    function eligibleRewardCount() public view returns (uint256) {
        uint total = 0;
        for (uint i = 0; i < allNodes.length; i++) {
            address node = allNodes[i];
            uint count = 0;
            for (uint j = 0; j < tree[node].children.length; j++) {
                address nodeChild = tree[node].children[j];
                if (tree[nodeChild].registerTime >= lastDistribution) {
                    count++;
                }
            }
            if(count >= 4) {
                total++;
            }
        }
        return total;
    }

    function getAllSubscribeCount() public view returns (uint256) {
        return allSubscribeCount;
    }

    function getTotalWithdraw(address _token) public view returns (uint256) {
        return totalWithdraw[_token];
    }

    function getTotalCompanyReward(address _token) public view returns (uint256) {
        return totalCompanyReward[_token];
    }

    function getTotalSpecialReward(address _token) public view returns (uint256) {
        return totalSpecialReward[_token];
    }


    // Get a node details ---------------------------------------------------------------------

    function getNodeDetails(address nodeAddress) public view returns (address parent, address[] memory children, uint256 levelOneChildCount, uint256 subscribeCount, uint256 registerTime) {
        Node memory nodeStruct = tree[nodeAddress];
        return (nodeStruct.parent, nodeStruct.children, nodeStruct.levelOneChildCount, nodeStruct.subscribeCount, nodeStruct.registerTime);
    }

    function ifDeposited() public view returns (bool) {
        return hasDeposited[msg.sender];
    }

    function getBalance(address _token) public view returns (uint256) {
        return balance[msg.sender][_token];
    }

    function isSubscriptionActive() public view returns(bool) {
        return (subscriptionEnd[msg.sender] >= block.timestamp);
    }

    function getParent(address child) public view returns (address) {
        return tree[child].parent;
    }

    function getChildren(address parent) public view returns (address[] memory) {
        return tree[parent].children;
    }

    // Check Eligible Retirement
    function getAddresslevelOneChildCount(address _address) public view returns (uint256) {
        return tree[_address].levelOneChildCount;
    }

    function getAddressRegisterTime(address _address) public view returns (uint256) {
        return tree[_address].registerTime;
    }

    function getAddressSubscribeCount(address _address) public view returns (uint256) {
        return tree[_address].subscribeCount;
    }

    function getSubscriptionTimeLeft() public view returns (uint256) {
        require(subscriptionEnd[msg.sender] > 0, "User has not subscribed.");
        uint256 timeLeft = subscriptionEnd[msg.sender] - block.timestamp;
        if (timeLeft < 0) {
            timeLeft = 0;
        }
        return timeLeft;
    }

    function getChildrenCount(address parent) public view returns (uint256) {
        address[] memory levelOne = tree[parent].children;
        if (levelOne.length > 0) {
            uint j = 0;
            for (uint i = 0; i < getFullTree(parent).length; i++) {
                j += getFullTree(parent)[i].length;
            }
            return j;
        }
        else{
            return 0;
        }
    }

    function checkEligibleReward() public view returns (uint256) {
        uint count = 0;
        for (uint j = 0; j < tree[msg.sender].children.length; j++) {
            address nodeChild = tree[msg.sender].children[j];
            if (tree[nodeChild].registerTime >= lastDistribution) {
                count++;
            }
        }
        return count;
    }

    function getTransactions(address _wallet) public view returns (Transaction[] memory) {
        return userTransactions[_wallet];
    }


    // Get full tree details ----------------------------------------------------------------

    function getFullTree(address parent) public view returns (address[][] memory) {
        address[][] memory levels = new address[][](20);
        levels[0] = new address[](0);
        
        address[] memory levelOne = tree[parent].children;
        if (levelOne.length > 0) {
            levels[0] = levelOne;
        }
        
        for (uint256 i = 0; i < 19; i++) {
            address[] memory expandedLevel = expandLevel(levels[i]);
            levels[i+1] = expandedLevel;
            if (expandedLevel.length == 0) {
                break;
            }
        }
        
        // Find the last level that has at least one element
        uint256 lastLevel = 0;
        for (uint256 i = 0; i < levels.length; i++) {
            if (levels[i].length > 0) {
                lastLevel = i;
            }
        }
        
        // Copy the levels array to a new array with the correct size
        address[][] memory result = new address[][](lastLevel + 1);
        for (uint256 i = 0; i <= lastLevel; i++) {
            result[i] = levels[i];
        }
        
        return result;
    }

    function expandLevel(address[] memory level) private view returns (address[] memory) {
        uint256 count;
        for (uint256 i = 0; i < level.length; i++) {
            count += tree[level[i]].children.length;
        }
        address[] memory result = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < level.length; i++) {
            address[] memory children = tree[level[i]].children;
            for (uint256 j = 0; j < children.length; j++) {
                result[index] = children[j];
                index++;
            }
        }
        return result;
    }
}