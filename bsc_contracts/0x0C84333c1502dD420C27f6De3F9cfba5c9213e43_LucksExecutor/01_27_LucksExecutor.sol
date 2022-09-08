// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Openluck interfaces
import {ILucksExecutor, TaskItem, TaskExt, TaskStatus, Ticket, TaskInfo, UserState } from "./interfaces/ILucksExecutor.sol";
import {IProxyNFTStation, DepositNFT} from "./interfaces/IProxyNFTStation.sol";
import {IProxyTokenStation} from "./interfaces/IProxyTokenStation.sol";
import {ILucksHelper} from "./interfaces/ILucksHelper.sol";
import {ILucksBridge, lzTxObj} from "./interfaces/ILucksBridge.sol";
import {LucksValidator} from "./libraries/LucksValidator.sol";

/** @title Openluck LucksTrade.
 * @notice It is the core contract for crowd funds to buy NFTs result to one lucky winner
 * randomness provided externally.
 */
contract LucksExecutor is ILucksExecutor, ReentrancyGuardUpgradeable, OwnableUpgradeable {    
    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    Counters.Counter private ids;

    // ============ Openluck interfaces ============
    ILucksHelper public HELPER;    
    IProxyNFTStation public NFT;
    IProxyTokenStation public TOKEN;
    ILucksBridge public BRIDGE;
    
    uint16 public lzChainId;
    bool public isAllowTask; // this network allow running task or not (ethereum & Rinkeby not allow)

    // ============ Public Mutable Storage ============

    // VARIABLES    
    mapping(uint256 => TaskItem) public tasks; // store tasks info by taskId    
    mapping(uint256 => TaskInfo) public infos; // store task updated info (taskId=>TaskInfo)
    mapping(uint256 => mapping(uint256 => Ticket)) public tickets; // store tickets (taskId => ticketId => ticket)    
    mapping(uint256 => uint256[]) public ticketIds; // store ticket ids (taskId => lastTicketIds)             
    mapping(address => mapping(uint256 => UserState)) public userState; // Keep track of user ticket ids for a given taskId (user => taskId => userstate)        

    // ======== Constructor =========

    /**
     * @notice Constructor / initialize
     * @param _chainId layerZero chainId
     * @param _allowTask allow running task
     */
    function initialize(uint16 _chainId, bool _allowTask) external initializer { 
        __ReentrancyGuard_init();
        __Ownable_init();
        lzChainId = _chainId;
        isAllowTask = _allowTask;
    }

    //  ============ Modifiers  ============

    // MODIFIERS
    modifier isExists(uint256 taskId) {
        require(exists(taskId), "not exists");
        _;
    }

    // ============ Public functions ============

    function count() public view override returns (uint256) {
        return ids.current();
    }

    function exists(uint256 taskId) public view override returns (bool) {
        return taskId > 0 && taskId <= ids.current();
    }

    function getTask(uint256 taskId) public view override returns (TaskItem memory) {
        return tasks[taskId];
    }

    function getInfo(uint256 taskId) public view override returns (TaskInfo memory) {
        return infos[taskId];
    }
    
    function isFail(uint256 taskId) public view override returns(bool) {
        return tasks[taskId].status == TaskStatus.Fail ||
            (tasks[taskId].amountCollected < tasks[taskId].targetAmount && block.timestamp > tasks[taskId].endTime);
    }

    function getChainId() external view override returns (uint16) {
        return lzChainId;
    }

    function getUserState(uint256 taskId, address user) external view override returns(UserState memory){
        return userState[user][taskId];
    }
    
    function createTask(TaskItem memory item, TaskExt memory ext, lzTxObj memory _param) external payable override nonReentrant {
        
        require(lzChainId == item.nftChainId || (lzChainId + 100) == item.nftChainId, "chainId"); // action must start from NFTChain   
        require(address(NFT) != address(0), "ProxyNFT");

        // inputs validation
        LucksValidator.checkNewTask(msg.sender, item);
        LucksValidator.checkNewTaskNFTs(msg.sender, item.nftContract, item.tokenIds, item.tokenAmounts, HELPER);
        LucksValidator.checkNewTaskExt(ext);  

        // adapt to CryptoPunks
        if (HELPER.isPunks(item.nftContract)) {

            item.depositId = HELPER.getProxyPunks().deposit(msg.sender, item.nftContract, item.tokenIds, item.tokenAmounts, item.endTime);
        }
        else {

            // Transfer nfts to proxy station (NFTChain) 
            // in case of dst chain transection fail, enable user redeem nft back, after endTime            
            item.depositId = NFT.deposit(msg.sender, item.nftContract, item.tokenIds, item.tokenAmounts, item.endTime);
        }
             
        // Create Task Item           
        if (ext.chainId == item.nftChainId) { // same chain creation              
            _createTask(item, ext);
        }
        else {
            // cross chain creation
            require(address(BRIDGE) != address(0), "Bridge unset");
            BRIDGE.sendCreateTask{value: msg.value}(ext.chainId, payable(msg.sender), item, ext, _param);
        }
    }

    /**
    @notice Use the original NFTs to reCreateTask
    Only if the task fails or can be cancelled
    and the NFTs has not been claimed
     */
    function reCreateTask(uint256 taskId, TaskItem memory item, TaskExt memory ext) external payable override nonReentrant {
        
        LucksValidator.checkReCreateTask(tasks, userState, taskId, item, ext);
       
        // update originTask claim info
        userState[tasks[taskId].seller][taskId].claimed = true;

        // update task status
        if (tasks[taskId].amountCollected > 0) {
            tasks[taskId].status = TaskStatus.Fail; 
            emit CloseTask(taskId, msg.sender, tasks[taskId].status);
        }
        else {
            tasks[taskId].status = TaskStatus.Cancel; 
            emit CancelTask(taskId, msg.sender);
        }

        // create new task
        _createTask(item, ext);
    }

    /**
    @notice buyer join a task
    num: how many ticket
    */
    function joinTask(uint256 taskId, uint32 num, string memory note) external payable override isExists(taskId) nonReentrant 
    {
        // check inputs and task
        LucksValidator.checkJoinTask(tasks[taskId], msg.sender, num, note, HELPER);

        // Calculate number of TOKEN to this contract
        uint256 amount = tasks[taskId].price.mul(num);

        // deposit payment to token station.        
        TOKEN.deposit{value: msg.value}(msg.sender, tasks[taskId].acceptToken, amount);

        // create tickets
        uint256 lastTID = _createTickets(taskId, num, msg.sender);

        // update task item info
        if (tasks[taskId].status == TaskStatus.Pending) {
            tasks[taskId].status = TaskStatus.Open; 
        }
        tasks[taskId].amountCollected = tasks[taskId].amountCollected.add(amount);

        //if reach target amount, trigger to close task
        if (tasks[taskId].amountCollected >= tasks[taskId].targetAmount) {
            if (address(HELPER.getAutoClose()) != address(0)) {
                HELPER.getAutoClose().addTask(taskId, tasks[taskId].endTime);
            }
        }

        emit JoinTask(taskId, msg.sender, amount, num, lastTID, note);
    }

    /**
    @notice seller cancel the task, only when task status equal to 'Pending' or no funds amount
    */
    function cancelTask(uint256 taskId, lzTxObj memory _param) external payable override isExists(taskId) nonReentrant 
    {                                
        require((tasks[taskId].status == TaskStatus.Pending || tasks[taskId].status == TaskStatus.Open) && infos[taskId].lastTID <= 0, "Opening or canceled");        
        require(tasks[taskId].seller == msg.sender, "Owner"); // only seller can cancel
        
        // update status
        tasks[taskId].status = TaskStatus.Close;
        
        _withdrawNFTs(taskId, payable(tasks[taskId].seller), true, _param);

        emit CancelTask(taskId, msg.sender);
    }


    /**
    @notice finish a Task, 
    case 1: reach target crowd amount, status success, and start to pick a winner
    case 2: time out and not reach the target amount, status close, and returns funds to claimable pool
    */
    function closeTask(uint256 taskId, lzTxObj memory _param) external payable override isExists(taskId) nonReentrant 
    {        
        require(tasks[taskId].status == TaskStatus.Open, "Not Open");
        require(tasks[taskId].amountCollected >= tasks[taskId].targetAmount || block.timestamp > tasks[taskId].endTime, "Not reach target or not expired");

        // mark operation time
        infos[taskId].closeTime = block.timestamp;

        if (tasks[taskId].amountCollected >= tasks[taskId].targetAmount) {    
            // Reached task target        
            // update task, Task Close & start to draw
            tasks[taskId].status = TaskStatus.Close; 

            // Request a random number from the generator based on a seed(max ticket number)
            HELPER.getVRF().reqRandomNumber(taskId, infos[taskId].lastTID);

            // add to auto draw Queue
            if (address(HELPER.getAutoDraw()) != address(0)) {
                HELPER.getAutoDraw().addTask(taskId, block.timestamp + HELPER.getDrawDelay());
            }

            // cancel the auto close queue if seller open directly
             if (msg.sender == tasks[taskId].seller && address(HELPER.getAutoClose()) != address(0)) {
                HELPER.getAutoClose().removeTask(taskId);
            }

        } else {
            // Task Fail & Expired
            // update task
            tasks[taskId].status = TaskStatus.Fail; 

            // NFTs back to seller            
            _withdrawNFTs(taskId, payable(tasks[taskId].seller), false, _param);                            
        }

        emit CloseTask(taskId, msg.sender, tasks[taskId].status);
    }

    /**
    @notice start to picker a winner via chainlink VRF
    */
    function pickWinner(uint256 taskId, lzTxObj memory _param) external payable override isExists(taskId) nonReentrant
    {                
        require(tasks[taskId].status == TaskStatus.Close, "Not Close");
         
        // get drawn number from Chainlink VRF
        uint32 finalNo = HELPER.getVRF().viewRandomResult(taskId);
        require(finalNo > 0, "Not Drawn");
        require(finalNo <= infos[taskId].lastTID, "finalNo");

        // find winner by drawn number
        Ticket memory ticket = _findWinner(taskId, finalNo);    
        require(ticket.number > 0, "Lost winner");
        
        // update store item
        tasks[taskId].status = TaskStatus.Success;    
        infos[taskId].finalNo = ticket.number;          
        
        // withdraw NFTs to winner (maybe cross chain)         
        _withdrawNFTs(taskId, payable(ticket.owner), true, _param);

        // dispatch Payment
        _payment(taskId, ticket.owner);    
        
        emit PickWinner(taskId, ticket.owner, finalNo);
    }


    /**
    @notice when taskItem Fail, user can claim tokens back 
    */
    function claimTokens(uint256[] memory taskIds) override external nonReentrant
    {
        for (uint256 i = 0; i < taskIds.length; i++) {
            _claimToken(taskIds[i]);
        }
    }

    /**
    @notice when taskItem Fail, user can claim NFTs back (cross-chain case)
    */
    function claimNFTs(uint256[] memory taskIds, lzTxObj memory _param) override external payable nonReentrant
    {  
        for (uint256 i = 0; i < taskIds.length; i++) {
            _claimNFTs(taskIds[i], _param);
        }
    }

    // ============ Remote(destination) functions ============
    
    function onLzReceive(uint8 functionType, bytes memory _payload) override external {
        require(msg.sender == address(BRIDGE) || msg.sender == owner(), "Executor: onlyBridge");
        if (functionType == 1) { //TYPE_CREATE_TASK
            (, TaskItem memory item, TaskExt memory ext) = abi.decode(_payload, (uint256, TaskItem, TaskExt));             

            _createTask(item, ext);
                    
        } else if (functionType == 2) { //TYPE_WITHDRAW_NFT
            (, address user, address nftContract, uint256 depositId) = abi.decode(_payload, (uint8, address, address, uint256));                        
            _doWithdrawNFTs(depositId, nftContract, user);
        }
    }    

    // ============ Internal functions ============

    function _createTask(TaskItem memory item, TaskExt memory ext) internal 
    {        
        require(isAllowTask, "Not allow");
        LucksValidator.checkNewTaskRemote(item, HELPER);  

        //create TaskId
        ids.increment();
        uint256 taskId = ids.current();

        // start now
        if (item.status == TaskStatus.Open) {
            item.startTime = item.startTime < block.timestamp ? item.startTime : block.timestamp;
        } else {
            require(block.timestamp <= item.startTime && item.startTime < item.endTime, "endTime");
            // start in future
            item.status = TaskStatus.Pending;
        }

        //store taskItem
        tasks[taskId] = item;

        emit CreateTask(taskId, item, ext);
    }

    function _createTickets(uint256 taskId, uint32 num, address buyer) internal returns (uint256) 
    {
        uint256 start = infos[taskId].lastTID.add(1);
        uint256 lastTID = start.add(num).sub(1);

        tickets[taskId][lastTID] = Ticket(lastTID, num, buyer);
        ticketIds[taskId].push(lastTID);

        userState[buyer][taskId].num += num;
        infos[taskId].lastTID = lastTID;

        emit CreateTickets(taskId, buyer, num, start, lastTID);
        return lastTID;
    }

    function _findWinner(
        uint256 taskId, 
        uint32 number
        ) internal view returns (Ticket memory)
    {
        // find by ticketId
        Ticket memory ticket = tickets[taskId][number];

        if (ticket.number == 0) {

            uint256 idx = ticketIds[taskId].findUpperBound(number);
            uint256 lastTID = ticketIds[taskId][idx];
            ticket = tickets[taskId][lastTID];
        }

        return ticket;
    }

    function _claimToken(uint256 taskId) internal isExists(taskId)
    {
        TaskItem storage item = tasks[taskId];
        require(isFail(taskId), "Not Fail");
        require(userState[msg.sender][taskId].claimed == false, "Claimed");

        // Calculate the funds buyer payed
        uint256 amount = item.price.mul(userState[msg.sender][taskId].num);
        
        // update claim info
        userState[msg.sender][taskId].claimed = true;
        
        // Transfer
        _transferOut(item.acceptToken, msg.sender, amount);

        emit ClaimToken(taskId, msg.sender, amount, item.acceptToken);
    }


    function _claimNFTs(uint256 taskId, lzTxObj memory _param) internal isExists(taskId)
    {
        address seller = tasks[taskId].seller;
        require(isFail(taskId), "Not Fail");
        require(userState[seller][taskId].claimed == false, "Claimed");
        
        // update claim info
        userState[seller][taskId].claimed = true;
        
        // withdraw NFTs to winner (maybe cross chain)     
        _withdrawNFTs(taskId, payable(seller), true, _param);

        emit ClaimNFT(taskId, seller, tasks[taskId].nftContract, tasks[taskId].tokenIds);
    }

    function _withdrawNFTs(uint256 taskId, address payable user, bool enableCrossChain, lzTxObj memory _param) internal
    {
        if (lzChainId == tasks[taskId].nftChainId) { // same chain    

           _doWithdrawNFTs(tasks[taskId].depositId, tasks[taskId].nftContract, user);
            
        }
        else if (enableCrossChain){ // cross chain            
            BRIDGE.sendWithdrawNFTs{value: msg.value}(tasks[taskId].nftChainId, payable(msg.sender), user,tasks[taskId].nftContract, tasks[taskId].depositId, _param);
        }
    }

    function _doWithdrawNFTs(uint256 depositId, address nftContract, address user) internal {
       
        // adapt to CryptoPunks
        if (HELPER.isPunks(nftContract)) {
             HELPER.getProxyPunks().withdraw(depositId, user);
        }
        else {
            NFT.withdraw(depositId, user);
        }
    }

    /**
     * @notice transfer protocol fee and funds
     * @param taskId taskId
     * @param winner winner address
     * paymentStrategy for winner share is up to 50% (500 = 5%, 5,000 = 50%)
     */
    function _payment(uint256 taskId, address winner) internal
    {
        // inner variables
        address acceptToken = tasks[taskId].acceptToken;

        // Calculate amount to seller
        uint256 collected = tasks[taskId].amountCollected;
        uint256 sellerAmount = collected;

        // 1. Calculate protocol fee
        uint256 fee = (collected.mul(HELPER.getProtocolFee())).div(10000);
        address feeRecipient = HELPER.getProtocolFeeRecipient();
        require(fee >= 0, "fee");
        sellerAmount = sellerAmount.sub(fee);

        // 2. Calculate winner share amount with payment stragey (up to 50%)
        uint256 winnerAmount = 0;
        uint256 winnerShare = 0;
        uint256[] memory splitShare;
        address[] memory splitAddr;
        if (tasks[taskId].paymentStrategy > 0) {
            (winnerShare, splitShare, splitAddr) = HELPER.getSTRATEGY().viewPaymentShares(tasks[taskId].paymentStrategy, winner, taskId);
            require(winnerShare >= 0 && winnerShare <= 5000, "strategy");
            require(splitShare.length <= 10, "splitShare"); // up to 10 splitter
            if (winnerShare > 0) {
                winnerAmount = (collected.mul(winnerShare)).div(10000);
                sellerAmount = sellerAmount.sub(winnerAmount);
            }
        }
        
        // 3. transfer funds

        // transfer protocol fee
        _transferOut(acceptToken, feeRecipient, fee);
        emit TransferFee(taskId, feeRecipient, acceptToken, fee);     

        // transfer winner share
        if (winnerAmount > 0) {
            if (splitShare.length > 0 && splitShare.length == splitAddr.length) {  
                // split winner share for strategy case
                uint256 splited = 10000;                
                for (uint i=0; i < splitShare.length; i++) {   
                    // make sure spliter cannot overflow
                    if ((splited.sub(splitShare[i])) >=0 && splitShare[i] > 0) { 
                        uint256 splitAmount = (winnerAmount.mul(splitShare[i]).div(10000));
                        _transferOut(acceptToken, splitAddr[i], splitAmount);
                        splited = splited.sub(splitShare[i]);

                        emit TransferShareAmount(taskId, splitAddr[i], acceptToken, splitAmount); 
                    }
                }

                if (splited > 0) {
                    // if there's a remainder of splitShare, give it to the seller
                    sellerAmount = sellerAmount.add((winnerAmount.mul(splited).div(10000)));
                }
            }
            else {                
                _transferOut(acceptToken, winner, winnerAmount);

                emit TransferShareAmount(taskId, winner, acceptToken, winnerAmount); 
            }
        }    

        // transfer funds to seller
        _transferOut(acceptToken, tasks[taskId].seller, sellerAmount);  

        emit TransferPayment(taskId, tasks[taskId].seller, acceptToken, sellerAmount);                    
    }

    function _transferOut(address token, address to, uint256 amount) internal {        
        TOKEN.withdraw(to, token, amount);
    }    

    //  ============ onlyOwner  functions  ============

    function setAllowTask(bool enable) external onlyOwner {
        isAllowTask = enable;
    }

    function setLucksHelper(ILucksHelper addr) external onlyOwner {
        HELPER = addr;
    }

    function setBridgeAndProxy(ILucksBridge _bridge, IProxyTokenStation _token, IProxyNFTStation _nft) external onlyOwner {

        require(address(_bridge) != address(0x0), "BRIDGE");
        if (isAllowTask) {
            require(address(_token) != address(0x0), "TOKEN");
        }
        require(address(_nft) != address(0x0), "NFT");

        BRIDGE = _bridge;
        TOKEN = _token;
        NFT = _nft;
    }

    function setLzChainId(uint16 chainId) external onlyOwner {
        lzChainId = chainId;
    }

}