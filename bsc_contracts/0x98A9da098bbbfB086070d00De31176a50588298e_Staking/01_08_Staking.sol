// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import "hardhat/console.sol";



contract Staking is Ownable, Pausable {

    IERC20 public usdt;
    IUniswapV2Router public router;
    IWETH public weth;
    uint8 public maxRate5 = 5;
    uint8 public maxRate10 = 10;

    
    TokenType public inputToken;
    TokenType public outputToken;

    enum TokenType{
        usdt,
        eth
    }// for usdt(tokenId = 1) and for bnb (tokenId=2)

    
    enum Ranks {
        rank0,  
        rank1,
        rank2,
        rank3,
        rank4,
        rank5,
        rank6,
        rank7, 
        rank8, 
        rank9, 
        rank10
    }

    struct Staker {
        address parent;         // the address extracted from ReferalLink
        bool active;
        uint8 rank;             // a staker can earn in each rank : maxRate*stakeAmount
        uint earn;              // the earning amount in current rank           
        uint contractEndTime;   // block.timestamp + 300 days
        bool freezed;
    }

    
    mapping (address => Staker) public stakers;// stakerAddress => StakerInfo
    mapping (uint8 => uint) public stakeAmounts;//base stake amout per rank
    mapping (address => uint) public pendingRewards;// pending reward of each user
    uint public totalPending;//total pending reward of all users
    address[] public users;//address of all users

    constructor(address _usdt, address _router, address _weth) {
        usdt = IERC20(_usdt);
        router = IUniswapV2Router(_router);
        weth = IWETH(_weth);
        inputToken = TokenType.usdt;
        outputToken = TokenType.usdt;
        stakeAmounts[0] = 30e18;
        stakeAmounts[1] = 300e18;
        stakeAmounts[2] = 600e18;
        stakeAmounts[3] = 900e18;
        stakeAmounts[4] = 1200e18;
        stakeAmounts[5] = 1500e18;
        stakeAmounts[6] = 1800e18;
        stakeAmounts[7] = 2100e18;
        stakeAmounts[8] = 2400e18;
        stakeAmounts[9] = 2700e18;
        stakeAmounts[10] = 3000e18;
    }

    modifier onlyValidTokenName(uint8 _tokenId) {
        require(_tokenId == 0 || _tokenId == 1, "token id should be 0 or 1");
        _;
    }

    fallback() external payable { }

    function setInputType(uint8 _tokenId) public onlyOwner onlyValidTokenName(_tokenId) {
        if(_tokenId == 0){
            inputToken = TokenType.usdt;
        }
        if(_tokenId == 1){
            inputToken = TokenType.eth;
        }
    }


    function setOutputType(uint8 _tokenId) public onlyOwner onlyValidTokenName(_tokenId) {
        if(_tokenId == 0){
            outputToken = TokenType.usdt;
        }
        if(_tokenId == 1){
            outputToken = TokenType.eth;
        }
    }


    function getParents(address _user, address _ref) public view returns(address[] memory){
        uint rank = stakers[_user].rank;
        address owner = owner();
        address[] memory parents;
        parents = new address[](3);
        address parent1;
        if(rank == 0 && stakers[_user].active == false){
            parent1 = _ref;
            // stakers[_user].parent = _ref;
        }else{
            parent1 = stakers[_user].parent;
        }
        address parent2;
        if(stakers[parent1].parent == address(0)){
            parent2 = owner;
        }else{
            parent2 = stakers[parent1].parent;
        }
        address parent3;
        if(stakers[parent2].parent == address(0)){
            parent3 = owner;
        }else{
            parent3 = stakers[parent2].parent;
        }

        parents[0] = parent1;
        parents[1] = parent2;
        parents[2] = parent3;

        return parents;
    }

    function stakeAble(address _user) public view returns(bool isAble) {
        uint8 rank = stakers[_user].rank;
        if(rank == 1 && stakeAmounts[0]*maxRate10 <= stakers[_user].earn && stakers[_user].active == false){
            isAble = true;
        }else if(rank !=0 && rank !=1 && rank !=10 && stakeAmounts[rank-1]*maxRate5 <= stakers[_user].earn && stakers[_user].active == false){
            isAble = true;
        } else if(rank ==10 && stakeAmounts[10]*maxRate5 <= stakers[_user].earn && stakers[_user].active == false){
            isAble = true;
        } else if(stakers[_user].active ==false && stakers[_user].parent == address(0) && rank ==0) {
            isAble = true;
        } else if(stakers[_user].active ==false && stakers[_user].contractEndTime <= block.timestamp) {
            isAble = true;
        }else {
            isAble = false;
        }
    }


    function changeMaxRate5(uint8 _newRate) public onlyOwner {
        maxRate5 = _newRate;
    }

    function changeMaxRate10(uint8 _newRate) public onlyOwner {
        maxRate10 = _newRate;
    }

    function _addToUserList(address _newUser) public {
        if(stakers[_newUser].parent == address(0)){
            users.push(_newUser);
        }
    }

    function totalUsers() public view returns(address []memory){
        return users;
    }

    function _giveParentsReward(address[] memory parents, uint stakeAmount) internal {
        address owner = owner();
        //give parent1 reward
        uint parent1Reward = 40*stakeAmount/100;
        uint8 parent1Rank = stakers[parents[0]].rank;
        uint8 maxRate1 = parent1Rank == 0 ? maxRate10 : maxRate5;
        if(stakers[parents[0]].active == true){
        stakers[parents[0]].earn += parent1Reward;
        pendingRewards[parents[0]] += parent1Reward;
        }else{
            stakers[owner].earn += parent1Reward;
            pendingRewards[owner] += parent1Reward;
        }
        totalPending += parent1Reward;
        if(stakeAmounts[parent1Rank]*maxRate1 <= stakers[parents[0]].earn &&
            stakers[parents[0]].active &&
            parent1Rank < 10
        ){
            uint extraAmount1 = stakers[parents[0]].earn - stakeAmounts[parent1Rank]*maxRate1;
            stakers[parents[0]].earn -= extraAmount1;
            pendingRewards[parents[0]] -= extraAmount1;
            stakers[owner].earn += extraAmount1;
            pendingRewards[owner] += extraAmount1;
            stakers[parents[0]].rank ++;
            stakers[parents[0]].active = false;
        }
        if(stakeAmounts[parent1Rank]*maxRate1 <= stakers[parents[0]].earn &&
            stakers[parents[0]].active &&
            parent1Rank == 10
        ){
            uint extraAmount1 = stakers[parents[0]].earn - stakeAmounts[parent1Rank]*maxRate1;
            stakers[parents[0]].earn -= extraAmount1;
            pendingRewards[parents[0]] -= extraAmount1;
            stakers[owner].earn += extraAmount1;
            pendingRewards[owner] += extraAmount1;
            stakers[parents[0]].active = false;
        }
        if(stakers[parents[0]].contractEndTime <= block.timestamp  && parents[0] != owner){
            stakers[parents[0]].active = false;
        }

        //give parent2 reward
        uint parent2Reward = 30*stakeAmount/100;
        uint8 parent2Rank = stakers[parents[1]].rank;
        uint8 maxRate2 = parent2Rank == 0 ? maxRate10 : maxRate5;
        if(stakers[parents[1]].active == true){
        stakers[parents[1]].earn += parent2Reward;
        pendingRewards[parents[1]] += parent2Reward;
        }else{
            stakers[owner].earn += parent2Reward;
            pendingRewards[owner] += parent2Reward;
        }
        totalPending += parent2Reward;
        if(stakeAmounts[parent2Rank]*maxRate2 <= stakers[parents[1]].earn &&
            stakers[parents[1]].active &&
            parent2Rank < 10
        ){
            uint extraAmount2 = stakers[parents[1]].earn - stakeAmounts[parent2Rank]*maxRate2;
            stakers[parents[1]].earn -= extraAmount2;
            pendingRewards[parents[1]] -= extraAmount2;
            stakers[owner].earn += extraAmount2;
            pendingRewards[owner] += extraAmount2;
            stakers[parents[1]].rank ++;
            stakers[parents[1]].active = false;
        }
        if(stakeAmounts[parent2Rank]*maxRate2 <= stakers[parents[1]].earn &&
            stakers[parents[1]].active &&
            parent2Rank == 10
        ){
            uint extraAmount2 = stakers[parents[1]].earn - stakeAmounts[parent2Rank]*maxRate2;
            stakers[parents[1]].earn -= extraAmount2;
            pendingRewards[parents[1]] -= extraAmount2;
            stakers[owner].earn += extraAmount2;
            pendingRewards[owner] += extraAmount2;
            stakers[parents[1]].active = false;
        }
        if(stakers[parents[1]].contractEndTime <= block.timestamp  && parents[1] != owner){
            stakers[parents[1]].active = false;
        }

        //give parent3 reward
        uint parent3Reward = 20*stakeAmount/100;
        uint8 parent3Rank = stakers[parents[2]].rank;
        uint8 maxRate3 = parent3Rank == 0 ? maxRate10 : maxRate5;
        if(stakers[parents[2]].active == true){
        stakers[parents[2]].earn += parent3Reward;
        pendingRewards[parents[2]] += parent3Reward;
        }else{
            stakers[owner].earn += parent3Reward;
            pendingRewards[owner] += parent3Reward;
        }
        totalPending += parent3Reward;
        if(stakeAmounts[parent3Rank]*maxRate3 <= stakers[parents[2]].earn &&
            stakers[parents[2]].active &&
            parent3Rank < 10
        ){
            uint extraAmount3 = stakers[parents[2]].earn - stakeAmounts[parent3Rank]*maxRate3;
            stakers[parents[2]].earn -= extraAmount3;
            pendingRewards[parents[2]] -= extraAmount3;
            stakers[owner].earn += extraAmount3;
            pendingRewards[owner] += extraAmount3;
            stakers[parents[2]].rank ++;
            stakers[parents[2]].active = false;
        }
        if(stakeAmounts[parent3Rank]*maxRate3 <= stakers[parents[2]].earn &&
            stakers[parents[2]].active &&
            parent3Rank == 10
        ){
            uint extraAmount3 = stakers[parents[2]].earn - stakeAmounts[parent3Rank]*maxRate3;
            stakers[parents[2]].earn -= extraAmount3;
            pendingRewards[parents[2]] -= extraAmount3;
            stakers[owner].earn += extraAmount3;
            pendingRewards[owner] += extraAmount3;
            stakers[parents[2]].active = false;
        }
        if(stakers[parents[2]].contractEndTime <= block.timestamp  && parents[2] != owner){
            stakers[parents[2]].active = false;
        }
    }


    // msg.value = stakeAmounts + (Fee: 10% stakeAmounts)
    function stakeUsdt(address _ref) public whenNotPaused {
        address owner = owner();
        require(inputToken == TokenType.usdt, "You should stake with ether");
        require(_ref != address(0), "you should have referral address");
        require(_ref != msg.sender || _ref == owner, "You cant put your address as inviter !");
        require(stakers[_ref].parent != address(0) || _ref == owner, "The referal address is not a staker in our app");
        uint8 rank = stakers[msg.sender].rank;
        uint stakeAmount = stakeAmounts[rank];
        require(stakeAble(msg.sender), "You can not stake again until your rank be increased" );
        //check that user sent enough token
        uint fee;
        
        fee = 10 * stakeAmount / 100;
       
        uint requireAmount = stakeAmount + fee;
        // uint allowance = usdt.allowance(msg.sender, address(this));
        // require(allowance >= stakeAmount + fee , "Contract does not have allowance to transfer the token");
        usdt.transferFrom(msg.sender, address(this), requireAmount);
        
        //transfer owner the share and fee
        uint adminShare = 9 * stakeAmount / 100;
        uint ownerShare = adminShare + fee;
        usdt.transfer(owner, ownerShare);

        _addToUserList(msg.sender);

        //declare the parents
        address[] memory parents = getParents(msg.sender, _ref);
        stakers[msg.sender].parent = parents[0];
        
        _giveParentsReward(parents, stakeAmount);
                //compliting user data
        stakers[msg.sender].active = true;
        stakers[msg.sender].earn = 0;
        stakers[msg.sender].contractEndTime = block.timestamp + 1080 days;
    }

    
    function stakeEth(address _ref) public payable whenNotPaused {
        address owner = owner();
        require(inputToken == TokenType.eth, "You should stake with eth");
        require(_ref != address(0), "you should have referral address");
        require(_ref != msg.sender || _ref == owner, "You can not put your address as inviter !");
        require(stakers[_ref].parent != address(0) || _ref == owner , "The referal address is not a staker in our app");
        // uint8 rank = stakers[msg.sender].rank;
        uint stakeAmount = stakeAmounts[stakers[msg.sender].rank];
        require(stakeAble(msg.sender), "You can not stake again until your rank be increased" );
        //check that user sent enough token
        uint fee = 10 * stakeAmount / 100;
        
        // fee = ;
        
        uint requireAmount = stakeAmount + fee;
        uint requireEtherAmount = getAmountEthOut(requireAmount);
        require(requireEtherAmount == msg.value, "Your msg.value is not equal to exact eth amount that we want");

        address[] memory path;
        path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);

        router.swapExactETHForTokens{value: msg.value}(
        requireEtherAmount,
        path,
        address(this),
        block.timestamp
      );
    

        //transfer owner the share and fee
        // uint adminShare = 9 * stakeAmount / 100;
        uint ownerShare = 9*stakeAmount/100 + fee;
        usdt.transfer(owner, ownerShare);

        _addToUserList(msg.sender);
        //declare the parents
        address[] memory parents = getParents(msg.sender, _ref);
        stakers[msg.sender].parent = parents[0];

        _giveParentsReward(parents, stakeAmount);
    
        //compliting user data
        stakers[msg.sender].active = true;
        stakers[msg.sender].earn = 0;
        stakers[msg.sender].contractEndTime = block.timestamp + 1080 days;
    }
    

    function withdrawRewardsUsdt(uint256 _amount) public {
        address owner = owner();
        require(outputToken == TokenType.usdt, "You should withdraw your tokens using ether");
        require(pendingRewards[msg.sender] >= 0, "You dont have any reward to withdraw");
        require(pendingRewards[msg.sender] >= _amount, "You dont enough reward to withdraw");
        // require(stakers[msg.sender].contractEndTime >= block.timestamp|| msg.sender == owner, "You can not withdraw because your contract is ended and you need to stake again");
        // require(stakers[msg.sender].active == true  || msg.sender == owner, "You can not withdraw until to stake in your new rank");
        require(stakers[msg.sender].freezed == false, "You can not withdraw because you are freezed");
        uint adminFee = 5*_amount/100;
        uint userReward = _amount - adminFee;
        usdt.transfer(owner, adminFee);
        usdt.transfer(msg.sender, userReward);
        pendingRewards[msg.sender] -= _amount;
        totalPending -= _amount;
    }


    function withdrawRewardsEther(uint256 _usdtAmount) public {
        address owner = owner();
        require(outputToken == TokenType.eth, "You should withdraw your tokens using bnb");
        require(pendingRewards[msg.sender] >= 0, "You dont have any reward to withdraw");
        // require(stakers[msg.sender].contractEndTime >= block.timestamp || msg.sender == owner, "You can not withdraw because your contract is ended and you need to stake again");
        // require(stakers[msg.sender].active == true || msg.sender == owner, "You can not withdraw until to stake in your new rank");
        require(stakers[msg.sender].freezed == false, "You can not withdraw because you are freezed");
        address[] memory path;
        path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(weth);
        require(pendingRewards[msg.sender] >= _usdtAmount, "You dont enough reward to withdraw");
        uint ethAmountsOut = getAmountEthOut(_usdtAmount);
        uint adminFee = 5*ethAmountsOut/100;
        uint userReward = ethAmountsOut - adminFee;
        usdt.approve(address(router), _usdtAmount);
        router.swapExactTokensForETH(_usdtAmount, ethAmountsOut, path, address(this), block.timestamp);
        payable(owner).transfer(adminFee);
        payable(msg.sender).transfer(userReward);
        pendingRewards[msg.sender] -= _usdtAmount;
        totalPending -= _usdtAmount;
    }

    function getAmountEthOut(uint _usdtAmount) public view returns(uint256){
        require(_usdtAmount > 0, "input amount should be more than zero");
        address[] memory path;
        path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(weth);
        uint256[] memory amounts = router.getAmountsOut(_usdtAmount, path);
            return amounts[amounts.length - 1];
    }

    function getAmountUsdtOut(uint _ethAmount) public view returns(uint256){
        require(_ethAmount > 0, "input amount should be more than zero");
        address[] memory path;
        path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        uint256[] memory amounts = router.getAmountsOut(_ethAmount, path);
            return amounts[amounts.length - 1];
    }

    function swapEthToUsdt() public payable {
        address[] memory path;
        path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        uint amountout = getAmountUsdtOut(msg.value);
        router.swapExactETHForTokens{value: msg.value}(
        amountout,
        path,
        msg.sender,
        block.timestamp
      );
    }


    function avableUsdtAmount() public view returns(uint256){
        uint available_amount_for_admin = usdt.balanceOf(address(this)) - totalPending;
        return available_amount_for_admin;
    }

    function avableAdminEthAmount() public view returns(uint256){
        address[] memory path;
        path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(weth);
        uint available_amount_for_admin = usdt.balanceOf(address(this)) - totalPending;
        if(available_amount_for_admin == 0){
            return 0;
        }else{
            uint256[] memory amounts = router.getAmountsOut(available_amount_for_admin, path);
            return amounts[amounts.length - 1];
        }
    }


    function withdrawAdmin_usdt(uint _amount) public onlyOwner {
        uint available_amount_for_admin = usdt.balanceOf(address(this)) - totalPending;
        require(available_amount_for_admin > 0, "There is not any token for admin in this contract");
        require(_amount <= available_amount_for_admin, "Your desire amount is grater than available usdt amount!");
        usdt.transfer(msg.sender, _amount);
    }

    function withdrawAdmin_eth(uint _amount) public onlyOwner {
        uint available_amount_for_admin = avableAdminEthAmount();
        require(available_amount_for_admin > 0, "There is not any token for admin in this contract");
        require(_amount <= available_amount_for_admin, "Your desire amount is grater than available amount!");
        payable(msg.sender).transfer(_amount);
    }

    function freezing(address _user, bool status) public onlyOwner {
        stakers[_user].freezed = status;
    }

    function pause() public onlyOwner {
        bool isPaused = paused();
        require(isPaused == false, "The contract is now paused");
        _pause();
    }

    function unpause() public onlyOwner {
        bool isPaused = paused();
        require(isPaused == true, "The contract is unpaused");
        _unpause();
    }

}