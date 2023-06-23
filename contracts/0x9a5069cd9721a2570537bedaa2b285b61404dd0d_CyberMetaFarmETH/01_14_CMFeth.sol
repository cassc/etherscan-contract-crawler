// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../mock/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "../interfaces/iToken.sol";

//____________________________________________________________________________________________________//
contract CyberMetaFarmETH is ERC20,AccessControl,ReentrancyGuard {
    uint  public cap =1000000000*10**decimals(); 
    uint  public minCap=88888888*10**decimals();
    uint  public totalVesting;
    uint  public totalBurned;

// [0-staking,1-team,2-marketing,3-advisor,4-foundation,5-NFThold,6-lp]    
    address[7] teamWallets=[
        0x184Da7Ca591F6865f5B89C6621529D447Ed575f5,
        0x270CD1663d48988033De769BcFF4887A4319a351,
        0xAa0dE4259fCB03F97b510b0ba97BE5195996f2D4,
        0x8c0bCe3992edEb75563D5a27431727fF3f698B11,
        0x5f659618947f0D61b9C4d73a89AF3274ea8F4558,
        0x080E8716243d7bec27174fd165605e00DA63b263,
        0xD024920b6Ce6aF8415f9F5d91Fe62Cd33ea74E60
    ]; 
    
    address public burnWallet=0x60b6d0B987474460a3563767E7B915118aa0C229;
    uint    public TGE=1686625620; //june 13 

    struct Vesting { 
        address user; 
        uint8   cliff;
        uint8   delay;
        uint16  monthlyPercent;
        uint16  percentOnTge;   
        uint256 totalAmount;
        uint256 releasedAmount;
        bool    NFT;
        uint    lastWithdraw;
    }

    mapping (address=>bool)  public antiBot;
    mapping (address=>bool)  public taxFree;
    mapping (address=>uint64[])     userVestings;
    mapping (uint64 => Vesting)     vesting;
    mapping (address=>bool)  public whaleNoLimits;
    uint64[]public teamVestings=[0,1,2,3,4];
    uint64  public vestingId;
    
    bool    public antiWhale;
    uint    public maxTokenHold;

    constructor() ERC20("CyberMetaFarm", "CMF") {
        _grantRole(DEFAULT_ADMIN_ROLE,0xD024920b6Ce6aF8415f9F5d91Fe62Cd33ea74E60);
        _grantRole(DEFAULT_ADMIN_ROLE,0x0d4A7Aef4AaB9A507E227215a523817233f18E0e);
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        createVesting(0,30,200, 0,teamWallets[0],400000000);
        createVesting(24,30,500,0,teamWallets[1],100000000);
        createVesting(0,30,400, 0,teamWallets[2],50000000);
        createVesting(20,30,625,0,teamWallets[3],50000000);
        createVesting(3,1,10000,0,teamWallets[4],100000000);

        createVesting(0,1,0,10000,teamWallets[6],5000000);
        claimVesting(5);

        createVesting(12,30,500,500,teamWallets[1],30660000);
        taxFree[address(this)]=true;
        setAntiWhale(true,300);
    }

//BURN____________________________________________________________________________________________________//
    function burn(address from, uint amount) public {
        if(totalBurned<(cap-minCap)){
            if(totalBurned+amount>(cap-minCap))
                amount=(cap-minCap)-totalBurned;
            _burn(from,amount);
            totalBurned+=amount;
        }
    }

//ADMIN___________________________________________________________________________________________________//
    function createVestings(
        uint8  cliff_,
        uint8  delay_,
        uint16 monthlyPercent_,
        uint16 percentOnTge_,
        address[] memory users_,
        uint64[] memory totalAmount_
    ) 
    external onlyRole(DEFAULT_ADMIN_ROLE){          
        require(users_.length==totalAmount_.length,"Array's must be equal");
        for(uint16 i;i<users_.length;i++){
            vesting[vestingId]=Vesting(
                users_[i],
                cliff_,
                delay_,
                monthlyPercent_,
                percentOnTge_,
                totalAmount_[i]*10**decimals(),
                0,
                false,
                0
            );
            userVestings[users_[i]].push(vestingId);
            vestingId++;
            require(totalVesting+totalAmount_[i]<cap,"Can't claim more");
            totalVesting+=totalAmount_[i]*10**decimals();
        }
    }

    function createVesting(
        uint8   cliff_,
        uint8   delay_,
        uint16  monthlyPercent_,
        uint16  percentOnTge_,
        address user_,
        uint64  totalAmount_
    ) 
    public onlyRole(DEFAULT_ADMIN_ROLE){              
        vesting[vestingId]=Vesting(
            user_,
            cliff_,
            delay_,
            monthlyPercent_,
            percentOnTge_,
            totalAmount_*10**decimals(),
            0,
            false,
            0
        );
        userVestings[user_].push(vestingId);
        vestingId++;
        require(totalVesting+totalAmount_<cap,"Can't claim more");
        totalVesting+=totalAmount_*10**decimals();
    }
    

    function deleteVesting(uint64 vestingId_) external onlyRole(DEFAULT_ADMIN_ROLE){
        totalVesting-=vesting[vestingId_].totalAmount-vesting[vestingId_].releasedAmount;
        delete vesting[vestingId_];
    }

    function setTGE(uint TGE_) external onlyRole(DEFAULT_ADMIN_ROLE){
        TGE=TGE_;
    } 

    function setTeamVesting(uint64[] memory teamVestings_) external onlyRole(DEFAULT_ADMIN_ROLE){
        teamVestings=teamVestings_;
    }

    function setAntiWhale(bool antiWhale_, uint64 maxTokenHold_) public onlyRole(DEFAULT_ADMIN_ROLE){
        antiWhale=antiWhale_;
        maxTokenHold=maxTokenHold_*10**decimals();
    }

    function setWhaleNoLimits(address user_, bool limited) external onlyRole(DEFAULT_ADMIN_ROLE){
        whaleNoLimits[user_]=limited;
    }

    function setBurnWallet(address burnWallet_) external onlyRole(DEFAULT_ADMIN_ROLE){
        burnWallet=burnWallet_;
    }

    function setTeamWallets(address[7] memory wallets) external onlyRole(DEFAULT_ADMIN_ROLE){
        teamWallets=wallets;
    }

    function setTaxFreeWallets(address[] memory users_, bool taxFree_) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint16 i;i<users_.length;i++)
            taxFree[users_[i]]=taxFree_;
    }

    function setBotWallets(address[] memory users_, bool antiBot_) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint16 i;i<users_.length;i++)
            antiBot[users_[i]]=antiBot_;
    }

    function setVestingWallet(uint64 vestingId_, address newUser_) external onlyRole(DEFAULT_ADMIN_ROLE){
        vesting[vestingId_].user=newUser_;
    }

    function receivedNft(uint64 vestingId_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(vesting[vestingId_].totalAmount>0 && !vesting[vestingId_].NFT,"Can't claim NFT");
        vesting[vestingId_].NFT=true;
    }

//USER___________________________________________________________________________________________________//
    function claimVesting(uint64 vestingId_) public nonReentrant(){
        Vesting storage vest=vesting[vestingId_];
        require(vest.user==msg.sender || hasRole(DEFAULT_ADMIN_ROLE,msg.sender),"not the owner");
        require(msg.sender!=address(0),"Zero address");

        uint amount=getCurrentClaim(vestingId_);
        if (amount>0){
            vest.releasedAmount+=amount;
            _mint(vest.user,amount);     
            vest.lastWithdraw=block.timestamp;   
        }    
    }

    function transfer(address to, uint256 amount) public override virtual returns (bool) {
        _checkLimits(msg.sender,to,amount);
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override virtual returns (bool) {
        _checkLimits(from,to,amount);
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

//INTERNAL_______________________________________________________________________________________________//    
    function _checkLimits(address from,address to, uint amount) private view{
        require(!antiBot[from] && !antiBot[to],"Acc is blocked");
        uint maxHold=getMaxHold(to);
        if(maxHold>0){
            require((balanceOf(to)+amount)<=maxHold,"Your wallet has reached its maximum holding amount");
        }
    }

//VIEW___________________________________________________________________________________________________//
    function getMonthlyClaim(uint64 vestingId_) public view returns (uint claimPerMonth_) {
        Vesting storage vest=vesting[vestingId_];
        return ((vest.totalAmount/10000)*vest.monthlyPercent);
    }

    function getMaxHold(address user_) public view returns(uint maxHold) {
        if(antiWhale && !whaleNoLimits[user_])
            return maxTokenHold;
        return 0;
    } 
    
    function getCurrentClaim(uint64 vestingId_) public view returns (uint claim_){
        Vesting storage vest=vesting[vestingId_];
        uint cliff_=vest.cliff;
        uint cliffTime=TGE+(30 days*cliff_); 
        uint claimPerMonth=getMonthlyClaim(vestingId_);
        uint month;
        uint amount;
        if(vest.releasedAmount==0 && vest.totalAmount>0 && vest.percentOnTge>0){
            uint tge=(vest.totalAmount/10000)*vest.percentOnTge;
            amount+=tge;
        }
        if(block.timestamp>cliffTime){
            if(vest.lastWithdraw==0)
                month=(block.timestamp-cliffTime)/(vest.delay*1 days);
            else
                month=(block.timestamp-vest.lastWithdraw)/(vest.delay*1 days);
            amount+=claimPerMonth*month;
            if(amount>(vest.totalAmount-vest.releasedAmount))
                amount=vest.totalAmount-vest.releasedAmount;
        }
        return(amount);
    }

    function getVestingInfo(uint64 vestingId_) external view returns (
        address user_,
        uint8   cliff_,
        uint8   delay_,
        uint16  monthlyPercent_,
        uint16  percentOnTge_,
        uint    totalAmount_,
        uint    releasedAmount_,
        bool    getNFT_,
        uint    lastWithdraw_ 
    ){
        Vesting storage vest=vesting[vestingId_];
    return(
        vest.user,
        vest.cliff,
        vest.delay,
        vest.monthlyPercent,
        vest.percentOnTge,
        vest.totalAmount,
        vest.releasedAmount,
        vest.NFT,
        vest.lastWithdraw
    );
    }

    function getUsersVestings(address user_) external view returns (uint64[] memory ids){
        return userVestings[user_];
    }
}