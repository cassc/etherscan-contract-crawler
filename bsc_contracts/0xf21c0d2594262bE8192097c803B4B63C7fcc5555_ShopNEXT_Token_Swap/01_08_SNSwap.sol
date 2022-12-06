// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract ShopNEXT_Token_Swap is Ownable {
    struct Swap{
        uint256 startBlock;
        uint256 amount;
        uint256 durationBlock;
        uint256 released;
    }
    event SwapToken(address indexed user, uint256 indexed amount, uint256 indexed startBlock,uint256 duration);
    event ClaimToken(address indexed user, uint256 indexed amount);

    using SafeERC20 for IERC20;
   
    IERC20 public oldSNToken;
    IERC20 public newSNToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public BPS = 10000;
    uint256 public rate = 1000;

    uint256 public unlockDuration;
   //mapping(uint256 => uint256) public startTimeSwap;

    mapping(address => bool) public whiteList;

    Swap[] public listSwap;
    mapping(address => uint256[]) public listSwapOfUsers;

    function setWL(address user, bool status ) external onlyOwner{
       whiteList[user] = status;
    }
    
    function setDurationLock(uint256 durationLock) external onlyOwner{
        unlockDuration = durationLock;
    }
     function setBPS(uint256 _bps) external onlyOwner{
        BPS = _bps;
    }
      function setRate(uint256 _rate) external onlyOwner{
        rate = _rate;
    }
    function setOldSN(address oldToken) external onlyOwner{
        oldSNToken = IERC20(oldToken);
    }
    function setNewSN(address newToken)external onlyOwner{
        newSNToken = IERC20(newToken);
    }

    function swap(uint256 amount) external{
        require(amount > 0, "SN: amount invalid");
        oldSNToken.safeTransferFrom(_msgSender(),deadAddress, amount);
       
        uint256 released =0;
         if(whiteList[msg.sender]){
            released = amount * rate/BPS;
            newSNToken.safeTransfer(msg.sender,released);
         }else {
            listSwap.push(Swap(block.number,amount,unlockDuration,released));
            listSwapOfUsers[msg.sender].push(listSwap.length -1);
         }
      
        emit SwapToken(msg.sender, amount, block.number, unlockDuration);
    }
    function claim(address user) external{
        uint256[] memory listSwapOfUser = listSwapOfUsers[user];
        uint256 totalClaim ;
        for(uint256 i =0;i< listSwapOfUser.length;i++){
            Swap storage swapItem = listSwap[listSwapOfUser[i]];
            uint256 released = getReleaseAble(listSwapOfUser[i]);
            totalClaim += (released - swapItem.released);            
            swapItem.released = released;
        }
        newSNToken.safeTransfer(user, totalClaim* rate/BPS);
        emit ClaimToken(user, totalClaim* rate/BPS); 
    }
    function getTotalClaimAble(address user) external view  returns(uint256 totalClaim) {
        uint256[] memory listSwapOfUser = listSwapOfUsers[user];
        
        for(uint256 i =0;i< listSwapOfUser.length;i++){
            Swap memory swapItem = listSwap[listSwapOfUser[i]];
            uint256 released = getReleaseAble(listSwapOfUser[i]);
            totalClaim += (released - swapItem.released);           
            
        }
        totalClaim = totalClaim*rate/BPS;
    }
    function getReleaseAble(uint256 swapIndex) public view returns (uint256){
        Swap memory swapItem = listSwap[swapIndex];

        if (block.number > (swapItem.startBlock + swapItem.durationBlock) ){
            return swapItem.amount;
        } else if (block.number >=swapItem.startBlock) {
            return (swapItem.amount * (block.number - swapItem.startBlock))/ swapItem.durationBlock;
        }else{
            return 0;
        }
       
    }
}