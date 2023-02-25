// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 < 0.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./UniRouterData.sol";


contract SplitterV2 is ReentrancyGuard{

    using SafeMath for uint256;
    using SafeMath for uint16;

    event UserChanged(address indexed newUser, uint256 indexed location);
    event Success(bool success, address user);
    event AdminUpdated(address indexed admin, bool indexed truth);
    event DonationEdited(address indexed nonProfit, bool truth);

    struct Profile{
        address user;
        uint16 split;
        uint16 donationSplit;
        uint16 rebaseSplit;
        uint16 adjustedSplit;
    }

    struct PairedToken{
        address token;
        uint creator;
        uint position;
    }

    mapping(address => PairedToken) public tokenPaired;
    address[] public pairedTokens;
    uint16 rebaseSplit;
    uint256 index;

    mapping(address => bool) admin;

    Profile[] public userData;

    address public immutable primaryToken;
    address public defaultDonation;
    uint16 public donationSplit;
    bool public donationActive;

    uint16 public constant totalPoints = 1000;
    
    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor(){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        primaryToken = address(0);
        userData.push(Profile(0x1784662D0Af586f42F0E822D5c675a9766DDF7Ed,650,0,0,650));
        admin[0x1784662D0Af586f42F0E822D5c675a9766DDF7Ed] = true;
        userData.push(Profile(0xfDDd11361a8De23106b8699e638155885c6DaF6a, 20,0,0,20));
        userData.push(Profile(0xd99EB89CAa390aF9e83BFcB29Ca52306b7E052F9, 75,0,0,75));
        userData.push(Profile(0xc69147239617e66E8CE1Fa103f07776Ba6B9e63b, 25,0,0,25));
        userData.push(Profile(0x7e6BC386A3fF7D4fd4BF78D96f7316263855521b, 75,0,0,75));
        admin[0x7e6BC386A3fF7D4fd4BF78D96f7316263855521b]=true;

        addToken(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,475); //WBTC
        addToken(0x6B175474E89094C44Da98b954EedeAC495271d0F,475); //DAI
        addToken(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,475); //Matic

        rebaseSplit =155;
    }
    /**
     * @dev function to change address of user to another addres
     * @param newUser address to change to
     * @param userLocation location to change
     */
    function changeUser(address newUser, uint256 userLocation)external{
        require(userLocation < userData.length, "Location out of bounds");
        require(msg.sender == userData[userLocation].user, "Not Approved");
        if(admin[msg.sender]){
            admin[userData[userLocation].user] = false;
            admin[newUser] = true;
        }
        userData[userLocation].user = newUser;
    }
    /**
     * @dev used for admin only functions
     */
    modifier isAdmin(){
        require(admin[msg.sender], "Error: No entry");
        _;
    }
    /**
     * @dev function to add and remove admin addresses
     * @param newAdmin address to toggle
     * @param truth true or false for isadmin
     */
    function toggleAdmin(address newAdmin, bool truth)external isAdmin{
        require(msg.sender != newAdmin, "Can not toggle self");
        admin[newAdmin] = truth;
        emit AdminUpdated(newAdmin, truth);
    }
    /**
     * @dev function to add new token for rebase
     * @param token to add to rebase
     * @param userLocation caller user
     */
    function addPairedToken(address token, uint userLocation) external{
        Profile storage user = userData[userLocation];
        require(user.user == msg.sender, "Not User");
        require(20 <= user.adjustedSplit, "User does not have enough to Split");
        require(canAdd(token), "Cannot add token");
        user.adjustedSplit -=20;
        user.rebaseSplit +=20;
        rebaseSplit +=20;
        addToken(token, userLocation);
    }
    /**
     * @dev function to check if a token can be added
     * @param token to check
     */
    function canAdd(address token)public view returns(bool){
        bool truth = token != primaryToken; // not PrimaryToken
        truth = truth && token != address(0); //not null
        truth = truth && tokenPaired[token].token == address(0); //not added
        truth = (truth && token != uniswapV2Router.WETH()); // not weth
        truth = (truth && address(0) != IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, primaryToken)); //LP created
        truth = (truth && address(0) != IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, uniswapV2Router.WETH())); //token has eth LP
        return truth;

    }
    /**
     * @dev function to add token to rebase system
     * @param token to add to the rebase system
     * @param location to of creator
     */
    function addToken(address token, uint location)internal {
        PairedToken storage t = tokenPaired[token];
        t.token = token;
        t.creator = location;
        t.position = pairedTokens.length;
        pairedTokens.push(token);

    }
    /**
     * @dev funciton to remove a token from the rebase system
     * @param token the token to remove
     */
    function removeToken(address token) external {
        PairedToken storage t1 = tokenPaired[token];
        require(t1.token != address(0), "Token Does not exist");
        require(pairedTokens[t1.position] == token, "Not token location");
        Profile storage user = userData[t1.creator];
        require(user.user == msg.sender, "Not approved");
        
        PairedToken storage t2 = tokenPaired[pairedTokens[pairedTokens.length-1]];
        pairedTokens[t1.position] = t2.token;
        t2.position = t1.position;
        pairedTokens.pop();
        t1.token = address(0);

        user.adjustedSplit +=20;
        if(user.rebaseSplit <=20){user.rebaseSplit =0;}
        else{user.rebaseSplit -=20;}
        rebaseSplit -=20;
    }
    /**
     * @dev function to call distribute with default nonProfit address if active
     */
    function distribute()external{
        require(admin[msg.sender] || msg.sender == userData[1].user, "Not Approved");
        _distribute(defaultDonation);
    }

    /**
     * @dev function for users to give points to donation Address
     * @param userLocation the callers array index
     * @param trueAddToDonationFalseRemove bool to determine add or removal of points to nonProfit
     * @param points the amount of points to add or remove
     */
    function toggleDonationSplit(uint userLocation, bool trueAddToDonationFalseRemove, uint16 points)external {
        require(userLocation < userData.length, "User Out of Bounders");
        require(points > 0, "Need an actual number");
        Profile storage user = userData[userLocation];
        require(user.user == msg.sender, "Not User");
        if(trueAddToDonationFalseRemove){
            if(user.adjustedSplit <= points){points = user.adjustedSplit;}
            user.adjustedSplit -= points;
            user.donationSplit += points;
            donationSplit += points;
        }else{
            if(user.donationSplit <= points){points = user.donationSplit;}
            user.donationSplit -= points;
            user.adjustedSplit += points;
            if(donationSplit<=points){donationSplit = 0;}
            else{donationSplit -= points;}
        }
    }
    /**
     * @dev funciton to toggle donation address and activity
     * @param nonProfit address to set as default
     * @param truth is donation active or false
     */
    function toggleActiveDonation(address nonProfit, bool truth)external isAdmin{
        require(nonProfit != address(0) || !truth, "Must be real address");
        defaultDonation = nonProfit;
        donationActive = truth;
        emit DonationEdited(nonProfit, truth);
    }
    /**
     * @dev funciton to distribute eth to addresses and rebase
     * @param donation address of nonProfit
     */
    function _distribute(address donation) internal{
        uint256 denom =totalPoints;
        if(!donationActive && donationSplit >0){
            denom -= donationSplit; //If donations not active then it'll try to balance the %s while removing the donation split
        }
        uint256 baseEth = address(this).balance/denom; 
        bool success;
        uint256 amount;
        for(uint256 i =0; i < userData.length; i++){
            if(userData[i].adjustedSplit > 0){
                amount = baseEth * userData[i].adjustedSplit;
                (success, ) = address(userData[i].user).call{value: amount}("");
                emit Success(success, userData[i].user);
            }
        }
        if(donationSplit > 0 && donationActive){
            amount = baseEth * donationSplit;
            (success, ) = address(donation).call{value: amount}("");
            emit Success(success, donation);  
        }
        rebase();
    }
    /**
     * @dev function to rebase LPs
     */
    function rebase()internal{
        if(index >= pairedTokens.length){//if finished with the indexes move to the eth LP and rebase it
            IWETH(uniswapV2Router.WETH()).deposit{value: address(this).balance}();
            _erc20Rebase(uniswapV2Router.WETH());
            index = index % pairedTokens.length;
        }else{
            address to = IUniswapV2Factory(uniswapV2Router.factory()).getPair(pairedTokens[index], primaryToken);
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = pairedTokens[index];
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(0, path, to, block.timestamp);
            IUniswapV2Pair(to).sync();
            index++;
        }
    }
    /**
     * @dev funciton to rebase or sale erc20 tokens
     * @param token erc20 address to sell or rebase
     */
    function ERC20(address token) external{
        require(admin[msg.sender] || msg.sender == userData[1].user, "Not Approved");
        require(IERC20(token).balanceOf(address(this)) > 1, "No tokens to transfer");
        if(IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, uniswapV2Router.WETH()) != address(0)){
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = uniswapV2Router.WETH();
            IERC20(token).approve(address(uniswapV2Router), type(uint256).max);
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                IERC20(token).balanceOf(address(this)),
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
            if(1 ether < address(this).balance){
                _distribute(defaultDonation);
            }        
        }   
    }

    /**
     * @dev function to rebase into token and primaryToken LP
     * @param token token to rebase with primaryToken
     */
    function _erc20Rebase(address token) internal{
        address to = IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, primaryToken);
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
        IUniswapV2Pair(to).sync();
    }
    /**
     * @dev function to send points to another user.
     * @param callerLocation the senders spot in the array
     * @param points the amount of points to give reciever
     * @param sendToRebase mark as true if points go to rebase split
     */
    function givePointsToAnother(uint callerLocation, uint16 points, uint16 receiverLocation, bool sendToRebase) external{
        require(callerLocation < userData.length, "Caller Out of Bounders");
        Profile storage user = userData[callerLocation];
        require(user.user == msg.sender, "Not User");
        require(user.adjustedSplit >= points, "Not enough Points");
        require(sendToRebase || receiverLocation < userData.length, "reciever out of bounds");
        user.split -= points;
        user.adjustedSplit -= points;
        if(sendToRebase){
            rebaseSplit +=points;
        }else{
            userData[receiverLocation].split += points;
            userData[receiverLocation].adjustedSplit += points;
        }
    }
    /**
     * @dev function to return points/positions of different elements for distribution.
     */
    function viewPoints()external view returns(uint16 marketingPoints, uint16 devPoints, uint16 donationPoints, uint16 rebasePoints, uint16 divideBy){

        marketingPoints = userData[0].adjustedSplit;
        devPoints += userData[1].adjustedSplit;
        devPoints += userData[2].adjustedSplit;
        devPoints += userData[3].adjustedSplit;
        devPoints += userData[4].adjustedSplit;
        rebasePoints = rebaseSplit;
        divideBy = totalPoints;
        donationPoints = donationSplit;
        if(!donationActive && donationSplit > 0){
            donationPoints =0;
            divideBy -= donationSplit;
        }
    }
    receive() external payable {}

    function nextToRebase()external view returns(address token){

        if(index < pairedTokens.length){
            token = pairedTokens[index];
        }else{
            token = uniswapV2Router.WETH();
        }
    }
}