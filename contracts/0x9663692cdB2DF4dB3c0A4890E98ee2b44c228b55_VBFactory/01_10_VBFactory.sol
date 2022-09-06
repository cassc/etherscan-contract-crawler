// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VBFactory is Ownable, ReentrancyGuard ,AccessControl{


    using SafeMath for uint256;

    address public nft;

    address public token;

    uint256 public price = 0.0088 ether;

    bool public freeOpen = true;

    bool public open = false;

    mapping(address => address) public inviteMarket;
    
    address public defaultInviter;

    uint256[] private preRandNumbers;

    mapping(address => uint256) public lockBalance;

    mapping(address => uint256) public unlockBalance;

    uint256 public unlockTime;

    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }

    modifier requireFreeOpen() {
        require(freeOpen, "Not open.");
        _;
    }

    modifier requireOpen() {
        require(open, "Not open.");
        _;
    }

    function init(address _nft,address _token,address _defaultInviter) external onlyOwner
    {
        nft = _nft;
        token = _token;
        addPreRandNumbers();
        setDefaultInviter(_defaultInviter);
    }

    function setPrice(uint256 _price) external onlyOwner {

        price = _price;
    }

    function toggleFreeOpen(bool _freeOpen) external onlyOwner {

        freeOpen = _freeOpen;
    }

    function toggleOpen(bool _open) external onlyOwner {

        open = _open;
    }

    function updateUnlockTime(uint256 _unlockTime) external onlyOwner {

        unlockTime = _unlockTime;
    }

    function tokenBalanceAvailable(address user) public view returns(uint256){
        
        require(unlockTime > 0 , "Release not started.");
        uint256 duringTime = block.timestamp.sub(unlockTime);
        uint256 duringDay = duringTime.div(86400);
        uint256 available = lockBalance[user].mul(duringDay).div(100).sub(unlockBalance[user]);
        return available;
    }

    function tokenBalanceUnlock(address user) public view returns(uint256){
        
        // require(unlockTime > 0 , "Release not started.");
        uint256 userUnlockBalance = lockBalance[user].sub(unlockBalance[user]);
        return userUnlockBalance;
    }

    function unlock() public {

        uint256 available = tokenBalanceAvailable(msg.sender);
        require(IERC20(token).balanceOf(address(this))>=available,"Not enough balance.");
        unlockBalance[msg.sender] = unlockBalance[msg.sender].add(available);
        IERC20(token).transfer(msg.sender,available);
    }

    function setDefaultInviter(address _defaultInviter) public onlyOwner {

        defaultInviter = _defaultInviter;
    }

    function addPreRandNumbers() private{
        
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp,block.number,msg.sender)));
        preRandNumbers.push(random);
    }

    function marketReward(uint256 amount) private{

        address firstInviter;
        if(inviteMarket[msg.sender] != address(0)){
            firstInviter = inviteMarket[msg.sender];
        }else{
            firstInviter = defaultInviter;
        }

        address secondInviter;
        if(inviteMarket[inviteMarket[msg.sender]] != address(0)){
            secondInviter = inviteMarket[inviteMarket[msg.sender]];
        }else{
            secondInviter = defaultInviter;
        }

        address thirdInviter;
        if(inviteMarket[inviteMarket[inviteMarket[msg.sender]]] != address(0)){
            thirdInviter = inviteMarket[inviteMarket[inviteMarket[msg.sender]]];
        }else{
            thirdInviter = defaultInviter;
        }
        
        if(firstInviter != address(0)){
            uint256 firstReward = uint256(125 * 10 ** 18).mul(amount);
            lockBalance[firstInviter] = lockBalance[firstInviter].add(firstReward);
        }
        
        if(secondInviter != address(0)){
            uint256 secondReward = uint256(75 * 10 ** 18).mul(amount);
            lockBalance[secondInviter] = lockBalance[secondInviter].add(secondReward);
        }
        
        if(thirdInviter != address(0)){
            uint256 thirdReward = uint256(50 * 10 ** 18).mul(amount);
            lockBalance[thirdInviter] = lockBalance[thirdInviter].add(thirdReward);
        }
        
    }


    function free_buy_Nft(uint256 amount,address inviter) eoaOnly requireFreeOpen public {

        require(msg.sender != inviter, "Account and invitation account cannot be consistent.");

        uint256 totalSupply = Nft(nft).totalSupply();

        if(totalSupply.add(amount) > 2000){
            amount = uint256(2000).sub(totalSupply);
        }

        require(amount > 0,"Reach the maximum free supply.");

        if(inviter == address(0)){
            inviter = defaultInviter;
        }
        if(inviteMarket[msg.sender] == address(0)){
            inviteMarket[msg.sender] = inviter;
        }
        uint256 preRandNumber = preRandNumbers[preRandNumbers.length - 1];
        uint256 preBlock1 = amount >=1? block.number.sub((preRandNumber.add(block.number).add(block.difficulty).add(block.timestamp).add(uint256(uint160(msg.sender))))%254) : 0;
        uint256 preBlock2 = amount >=2? block.number.sub((preRandNumber.add(block.number).add(block.difficulty).add(uint256(uint160(msg.sender))))%254) : 0;
        uint256 preBlock3 = amount >=3? block.number.sub((preRandNumber.add(block.number).add(block.timestamp).add(uint256(uint160(msg.sender))))%254) : 0;
        uint256 preBlock4 = amount >=4? block.number.sub((preRandNumber.add(block.difficulty).add(block.timestamp).add(uint256(uint160(msg.sender))))%254) : 0;
        uint256 preBlock5 = amount >=5? block.number.sub((preRandNumber.add(block.difficulty).add(uint256(uint160(msg.sender))))%254) : 0;

        uint256[5] memory _preBlockNumbers = [preBlock1,preBlock2,preBlock3,preBlock4,preBlock5];
        
        Nft(nft).mint(msg.sender,amount,_preBlockNumbers);

        addPreRandNumbers();
    }

    function buy_Nft(uint256 amount,address inviter) eoaOnly requireOpen public payable{

        require(msg.sender != inviter, "Account and invitation account cannot be consistent.");
        require(msg.value == amount.mul(price),"Insufficient funds.");

        uint256 totalSupply = Nft(nft).totalSupply();
        require(totalSupply.add(amount) <= 10000,"Reach the maximum supply.");

        if(inviter == address(0)){
            inviter = defaultInviter;
        }
        if(inviteMarket[msg.sender] == address(0)){
            inviteMarket[msg.sender] = inviter;
        }
        uint256 preRandNumber = preRandNumbers[preRandNumbers.length - 1];
        uint256 preBlock1 = amount >=1? block.number.sub((preRandNumber.add(block.number).add(block.difficulty).add(block.timestamp).add(uint256(uint160(msg.sender))))%255) : 0;
        uint256 preBlock2 = amount >=2? block.number.sub((preRandNumber.add(block.number).add(block.difficulty).add(uint256(uint160(msg.sender))))%255) : 0;
        uint256 preBlock3 = amount >=3? block.number.sub((preRandNumber.add(block.number).add(block.timestamp).add(uint256(uint160(msg.sender))))%255) : 0;
        uint256 preBlock4 = amount >=4? block.number.sub((preRandNumber.add(block.difficulty).add(block.timestamp).add(uint256(uint160(msg.sender))))%255) : 0;
        uint256 preBlock5 = amount >=5? block.number.sub((preRandNumber.add(block.difficulty).add(uint256(uint160(msg.sender))))%255) : 0;

        uint256[5] memory _preBlockNumbers = [preBlock1,preBlock2,preBlock3,preBlock4,preBlock5];

        Nft(nft).mint(msg.sender,amount,_preBlockNumbers);

        addPreRandNumbers();

        marketReward(amount);
    }


    function withdrawETH() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }


    function withdrawToken(address _erc20,address _to) public onlyOwner{

        IERC20(_erc20).transfer(_to,IERC20(_erc20).balanceOf(address(this)));
    }
}

interface Nft{

    function mint(address to,uint256 amount,uint256[5] memory preBlockNumbers) external;

    function totalSupply() external view returns(uint256);
}

interface IERC20{
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address _user) external view returns (uint256);
}