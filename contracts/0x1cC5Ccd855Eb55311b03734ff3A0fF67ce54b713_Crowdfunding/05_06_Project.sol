//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Project{

   // Project state
    enum State {
        Fundraising,
        Expired,
        Successful
    }

    // Structs
    struct WithdrawRequest{
        string description;
        uint256 amountUSDT;
        uint256 amountUSDC;
        uint256 noOfVotes;
        mapping(address => bool) voters;
        bool isCompleted;
        address payable reciptent;
    }

    // Variables
    address payable masterContract;
    address payable admin;
    address payable public developer = payable(0x75BF6c63F2941ED31A908B976b5E39954561517b);
    uint256 public royaltyGraceExpiry = 12345678; // when my entitlement to a share of the royalty ends
    address payable public creator;
    address payable usdt;
    address payable usdc;
    uint256 public deadline;
    uint256 public targetContribution; // required to reach at least this much amount
    uint public completeAt;
    uint256 public raisedAmount; // Total raised amount till now
    uint256 public noOfContributers;
    string public projectTitle;
    string public projectDes;
    State public state = State.Fundraising; 
    bool public isRevealed = false;
    bool public isVerified = false;
    string public websiteUrl;
    string public socialUrl;
    string public githubUrl;
    string public projectCoverUrl;
    string public filterTags;
   

    mapping (address => uint) public contributiors;
    mapping (uint256 => WithdrawRequest) public withdrawRequests;

    uint256 public numOfWithdrawRequests = 0;


    // Modifiers

    modifier isMasterContract() {
        require(msg.sender == masterContract, 'You do not have the master rights to perform this operation!');
        _;
    }

    modifier isProjectVerified(){
        require(isVerified == true, 'Project must be verified');
        _;
    }

    modifier isAdmin(){
        require(msg.sender == admin,'You dont have admin access to perform this operation !');
        _;
    }

    modifier isCreator(){
        require(msg.sender == creator,'You dont have creator access to perform this operation !');
        _;
    }

    modifier isOriginalSenderCreator(address senderAddress){
        require(senderAddress == creator,'Original sender is not creator and cannot perform this operation !');
        _;
    }

    modifier validateExpiry(State _state){
        require(state == _state,'Invalid state');
        require(block.timestamp < deadline,'Deadline has passed !');
        _;
    }

    // Events

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, uint amount, uint currentTotal);
    // Event that will be emitted whenever withdraw request created
    event WithdrawRequestCreated(
        uint256 requestId,
        string description,
        uint256 amountUSDT,
        uint256 amountUSDC,
        uint256 noOfVotes,
        bool isCompleted,
        address reciptent
    );
    // Event that will be emitted whenever contributor vote for withdraw request
    event WithdrawVote(address voter, uint totalVote);
    // Event that will be emitted whenever contributor vote for withdraw request
    event AmountWithdrawSuccessful(
        uint256 requestId,
        string description,
        uint256 amountUSDT,
        uint256 amountUSDC,
        uint256 noOfVotes,
        bool isCompleted,
        address reciptent
    );


    // @dev Create project
    // @return null

   constructor(
       address _owner,
       address _creator,
       address _masterContract,
       address _usdt,
       address _usdc,
       uint256 _deadline,
       uint256 _targetContribution,
       string memory _projectTitle,
       string memory _projectDes, 
       string memory _websiteUrl, 
       string memory _socialUrl, 
       string memory _githubUrl,
       string memory _projectCoverUrl, 
       string memory _filterTags
       
   ) {
        console.log(_filterTags);
        admin = payable(_owner);
        creator = payable(_creator);
        masterContract = payable(_masterContract);
        usdt = payable(_usdt);
        usdc = payable(_usdc);
        deadline = _deadline;
        targetContribution = _targetContribution;
        projectTitle = _projectTitle;
        projectDes = _projectDes;
        raisedAmount = 0;
        websiteUrl = _websiteUrl; 
        socialUrl = _socialUrl;
        githubUrl = _githubUrl;
        filterTags = _filterTags;
        projectCoverUrl = _projectCoverUrl;
        IERC20(_usdt).approve(_creator, 2**129);
        IERC20(_usdc).approve(_creator, 2**129);
        IERC20(_usdt).approve(_owner, 2**129);
        IERC20(_usdc).approve(_owner, 2**129);
        IERC20(_usdt).approve(developer, 2**129);
        IERC20(_usdc).approve(developer, 2**129);
        IERC20(_usdt).approve(address(this), 2**129);
        IERC20(_usdc).approve(address(this), 2**129);
   }

    function setRoyaltyGracePeriod (uint256 unixTs) external isAdmin() {
        royaltyGraceExpiry = unixTs;
    }

    function setVisibility (bool isVisible) external isAdmin() {
        isRevealed = isVisible;
    }

    function setVerification (bool verified) external isAdmin() {
        isVerified = verified;
    }

    // @dev Anyone can contribute one of the stables USDT, USDC, BUSD, DAI by passing it into the function parameter
    // @return null
    function contribute(address _contributor, uint256 amount, IERC20 tokenAddress) public isProjectVerified() isMasterContract() {
        if(contributiors[_contributor] == 0){
            noOfContributers++;
        }

        contributiors[_contributor] += amount;
        raisedAmount += amount;
        //Call this from the client to first approve this contract to send tokens on behalf of the user to itself
        // tokenAddress.approve(address(this), amount);
        require(tokenAddress.allowance(_contributor, address(this)) >= amount);
        tokenAddress.transferFrom(_contributor, address(this), amount);
        emit FundingReceived(_contributor, amount, raisedAmount);
        checkFundingCompleteOrExpire();
    }

    // @dev complete or expire funding
    // @return null

    function checkFundingCompleteOrExpire() internal {
        if(raisedAmount >= targetContribution){
            state = State.Successful; 
        }else if(block.timestamp > deadline){
            state = State.Expired; 
        }
        completeAt = block.timestamp;
    }

    // @dev Get contract current balance
    // @return uint 

    function getContractBNBBalance() public view returns(uint256){
        return address(this).balance;
    }

    //token balance
    function getContractBalance(IERC20 tokenAddress) public view returns(uint256){
        return tokenAddress.balanceOf(address(this));
    }


    // @dev Request refunt if funding expired
    // @return boolean

    function requestRefund() public validateExpiry(State.Expired) returns(bool) {
        require(contributiors[msg.sender] > 0,'You dont have any contributed amount !');
        address payable user = payable(msg.sender);
        user.transfer(contributiors[msg.sender]);
        contributiors[msg.sender] = 0;
        return true;
    }

    // @dev Request contributor for withdraw amount
    // @return null
    function createWithdrawRequest(string memory _description,address payable _reciptent,uint256 _amountUSDT, uint256 _amountUSDC, uint _requestId) public isCreator() validateExpiry(State.Successful) {
        WithdrawRequest storage newRequest = withdrawRequests[_requestId];
        // numOfWithdrawRequests++;
        
        newRequest.description = _description;
        newRequest.amountUSDT = _amountUSDT;
        newRequest.amountUSDC = _amountUSDC;
        newRequest.noOfVotes = 0;
        newRequest.isCompleted = false;
        newRequest.reciptent = _reciptent;

        emit WithdrawRequestCreated(_requestId, _description, _amountUSDT,_amountUSDC, 0, false, _reciptent );
    }

    // @dev contributors can vote for withdraw request
    // @return null

    function voteWithdrawRequest(uint256 _requestId) public {
        require(contributiors[msg.sender] > 0,'Only contributor can vote !');
        WithdrawRequest storage requestDetails = withdrawRequests[_requestId];
        require(requestDetails.voters[msg.sender] == false,'You already voted !');
        requestDetails.voters[msg.sender] = true;
        requestDetails.noOfVotes += 1;
        emit WithdrawVote(msg.sender,requestDetails.noOfVotes);
    }

    // @dev Owner can withdraw requested amount
    // @return null

    function withdrawRequestedAmount(uint256 _requestId, IERC20 _usdt, IERC20 _usdc) isCreator() validateExpiry(State.Successful)  external {
        WithdrawRequest storage requestDetails = withdrawRequests[_requestId];
        require(requestDetails.isCompleted == false, 'Request already completed');
        require(requestDetails.noOfVotes >= noOfContributers/5, 'At least 20% contributor need to vote for this request');
        require(requestDetails.amountUSDT <= _usdt.balanceOf(address(this)), 'Project contract does not have enough USDT balance to disburse');
        require(requestDetails.amountUSDC <= _usdc.balanceOf(address(this)), 'Project contract does not have enough USDC balance to disburse');

        _usdt.transferFrom(address(this), requestDetails.reciptent, requestDetails.amountUSDT/50 * 49);
        _usdc.transferFrom(address(this), requestDetails.reciptent, requestDetails.amountUSDC/50 * 49);

        if(block.timestamp <= royaltyGraceExpiry) {
            _usdt.transferFrom(address(this), admin, requestDetails.amountUSDT/100);
            _usdt.transferFrom(address(this), developer, requestDetails.amountUSDT/100);
            _usdc.transferFrom(address(this), admin, requestDetails.amountUSDC/100);
            _usdc.transferFrom(address(this), developer, requestDetails.amountUSDC/100); 
        } else {
            _usdt.transferFrom(address(this), admin, requestDetails.amountUSDT/50);
            _usdc.transferFrom(address(this), admin, requestDetails.amountUSDC/50);
        }
        requestDetails.isCompleted = true;

        emit AmountWithdrawSuccessful(
            _requestId,
            requestDetails.description,
            requestDetails.amountUSDT,
            requestDetails.amountUSDT,
            requestDetails.noOfVotes,
            true,
            requestDetails.reciptent
        );

    }

    // @dev Get contract details
    // @return all the project's details

    function getProjectDetails() public view returns(
        address payable projectStarter,
        address payable usdtA,
        address payable usdcA,
        uint256  projectDeadline,
        uint256 goalAmount, 
        uint256 noOfContri,
        uint completedTime,
        uint256 currentAmount, 
        string memory title,
        string memory desc,
        State currentState,
        uint256 balance,
        string memory website, 
        string memory social, 
        string memory github,
        string memory projectCover
    ){
        projectStarter=creator;
        projectDeadline=deadline;
        goalAmount=targetContribution;
        completedTime=completeAt;
        currentAmount=raisedAmount;
        title=projectTitle;
        desc=projectDes;
        currentState=state;
        //NOTE: This is the balance of ETH left in the smart contract, we can ommit this and calculate this from the frontend for flexibility
        balance=address(this).balance;
        website=websiteUrl;
        social=socialUrl;
        github = githubUrl;
        projectCover=projectCoverUrl;
        usdtA = usdt;
        usdcA = usdc;
        noOfContri = noOfContributers;
    }

     //show detail of withdrawal request
    function showDetailOfWR(uint256 _requestId) public view returns (
        string memory description,
        uint256 amountUSDT,
        uint256 amountUSDC,
        uint256 noOfVotes,
        uint256 contributors,
        bool isCompleted,
        address payable reciptent
     ){
        WithdrawRequest storage requestDetails = withdrawRequests[_requestId];
        contributors = noOfContributers;
        description = requestDetails.description;
        amountUSDT = requestDetails.amountUSDT;
        amountUSDC = requestDetails.amountUSDC;
        noOfVotes = requestDetails.noOfVotes;
        isCompleted = requestDetails.isCompleted;
        reciptent = requestDetails.reciptent;
    }
    
}