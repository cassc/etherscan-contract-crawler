/**
 *Submitted for verification at BscScan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface Token{
    function transferFrom(address,address,uint) external;
    function transfer(address,uint) external;
    function approve(address,uint) external;
    function balanceOf(address) external view returns(uint);
}
interface LockLike {
    function vestingLock(address owner, 
        address token, 
        bool isLpToken, 
        uint256 amount, 
        uint256 tgeDate, 
        uint256 tgeBps, 
        uint256 cycle, 
        uint256 cycleBps, 
        string  memory description
        )external returns (uint256 id);
}
contract Donation  {

    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Donation/not-authorized");
        _;
    }
 
    address                                           public  foundaddress = 0x23D7E66266FBB0e5a30B3b2a199Cc74E082C96E7;
    address                                           public  foundaddress1 = 0x23D7E66266FBB0e5a30B3b2a199Cc74E082C96E7;
    Token                                             public  usdt = Token(0x55d398326f99059fF775485246999027B3197955);
    Token                                             public  tmd = Token(0x0f27d12182f7f4D879d267B31BD02dd27086e7Ce);
    Token                                             public  tmt = Token(0x0C3bE46AF643AE51c42dD67A4a8CcA0722B54f39);
    address                                           public  lockAddr = 0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE;
    uint256                                           public  donaAmount = 100*1E18;
    uint256                                           public  tmdAmount =  10*1E18;
    uint256                                           public  tmtAmount =  1000*1E18;
    uint256                                           public  tmtLock =  30000*1E18;
    mapping (address => UserInfo)                     public  userInfo;

    struct UserInfo { 
        address    recommend;
        address[]  under;
        uint256    tmdAmount;
        uint256    tmtAmount;
    }
    constructor() {
        wards[msg.sender] = 1;
        Token(tmt).approve(lockAddr, ~uint256(0));
    }
    function global(uint256 what,address usr,uint256 data) external auth {                                               
        if (what == 1) foundaddress = usr; 
        else if (what == 2) foundaddress1 = usr;    
        else if (what == 3) donaAmount = data;                   
        else revert("Donation/setdata-unrecognized-param");
    }
    function setRecommend(address usr,address recommender) external auth {
        userInfo[usr].recommend = recommender;
        userInfo[recommender].under.push(usr);
    }
    function setUpline(address usr,address recommender) external auth {
        userInfo[usr].recommend = recommender;
    }
    function setUnder(address usr,address[] memory unlines) external auth {
        userInfo[usr].under = unlines;
    }
    function depositTmd(address recommender) public {
        UserInfo storage user = userInfo[msg.sender];
        if(user.recommend == address(0) && recommender != address(0) && recommender == msg.sender){
           user.recommend = recommender;
           userInfo[recommender].under.push(msg.sender);
        }
        require(user.tmdAmount==0,"Donation/1");
        usdt.transferFrom(msg.sender, foundaddress, donaAmount);
        tmd.transfer(msg.sender, tmdAmount); 
        user.tmdAmount = donaAmount; 
    } 
    function depositTmt(address recommender) public {
        UserInfo storage user = userInfo[msg.sender];
        if(user.recommend == address(0) && recommender != address(0) && recommender == msg.sender){
           user.recommend = recommender;
           userInfo[recommender].under.push(msg.sender);
        }
        require(user.tmtAmount==0,"Donation/2");
        usdt.transferFrom(msg.sender,foundaddress1,donaAmount);
        user.tmtAmount = donaAmount; 
        LockLike(lockAddr).vestingLock(msg.sender, address(tmt), false, tmtLock, block.timestamp+86400, 666, 86400, 666, "");
        address upAddress = user.recommend;
        if(upAddress != address(0)) tmt.transfer(upAddress,tmtAmount);
    }
    function getUserInfo(address usr) public view returns(UserInfo memory user){
        user = userInfo[usr];
    }
    function getUpline(address usr) public view returns(address recommend){
        recommend = userInfo[usr].recommend;
    }
    function getUnderline(address usr) public view returns(address[] memory under){
        under = userInfo[usr].under;
    }
    function getUnderInfo(address usr) public view returns(UserInfo[]  memory under,uint tmdToal,uint tmtToal){
        UserInfo memory user = userInfo[usr];
        uint length = user.under.length;
        under = new UserInfo[](length);
        for(uint i=0;i<length;++i) {
            address underline = user.under[i];
            under[i].recommend = underline;
            UserInfo memory user1 = userInfo[underline];
            under[i].tmdAmount = user1.tmdAmount;
            under[i].tmtAmount = user1.tmtAmount;
            tmdToal += user1.tmdAmount;
            tmtToal += user1.tmdAmount;
        }
    }
    function getInfo(address usr) public view returns(UserInfo memory user,UserInfo[]  memory under,uint tmdToal,uint tmtToal){
        user = userInfo[usr];
        (under,tmdToal,tmtToal) = getUnderInfo(usr); 
    }
    function withdraw(address asses, uint256 amount, address ust) public auth {
        Token(asses).transfer(ust, amount);
    }
}