// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//Local imports
import "./AMT.sol";
import "./Master.sol";

//Standar imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//Imports for swaping
//import "./IUniswapV2Pair.sol";
//import "./IUniswapV2Router02.sol";

contract vaultBtcb is Ownable{

    //General global declarations
    using SafeERC20 for IERC20;
    Master masterContract;
    AMT amt;
    IERC20 btcb;
    uint256 lastSnapCharged;
    uint256 totalStacked;
    mapping(address => uint256) public shares;
    mapping(address => uint256) initialSnapShot; 
    mapping(uint256 => uint256) public chargedAt; // From snapId to amount of BTCB charged on that snap
    mapping(uint256 => uint256) totalSharesAt; // From snapID to totalShares on that snapShot;
    mapping(address => uint256) public enterTime; //From user address to timestamp of stake
    uint256 totalShares;

    //General addresses
    address addrMaster = 0x13e98112e1c67DbE684adf3Aeb1C871F1fe6D1Ac;
    address addrAmt = 0x6Ae0A238a6f51Df8eEe084B1756A54dD8a8E85d3;
    address addrBtcb = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

    constructor(uint256 startSnapshot_){ //to change on prod for static variables
        masterContract = Master(addrMaster);
        amt = AMT(addrAmt);
        lastSnapCharged = startSnapshot_;
        totalShares = 0;
        btcb = IERC20(addrBtcb);
    }

    //Public view functions to assist fron end
    //Public view functions to assists front end
    function addressShares(address addr) public view returns (uint256){
        return shares[addr];
    }
    function addressAmt(address addr) public view returns (uint256){
        return (shares[addr]*amt.balanceOf(address(this)))/totalShares;
    }

    function addressInitialSnapShot(address addr) public view returns (uint256){
        return initialSnapShot[addr];
    }

    function isContractSync() public view returns (bool){
        return (amt.getCurrentSnapshotId()==lastSnapCharged);
    }

    function amtStacked() public view returns(uint256){
        return amt.balanceOf(address(this));
    }

    //State changing functions
    function charge(uint256 snapId) private {
        uint256 balanceBefore = btcb.balanceOf(address(this));
        masterContract.charge(snapId);
        uint256 balanceAfter = btcb.balanceOf(address(this));
        chargedAt[snapId] = balanceAfter - balanceBefore;
        totalSharesAt[snapId] = totalShares;
    }

    function chargeAll() public{
        //Prev status variables
        uint256 currentSnapshot = amt.getCurrentSnapshotId();
        uint256 snapsToCharge = currentSnapshot - lastSnapCharged;
        if(snapsToCharge > 0){
            for(uint256 i = lastSnapCharged +1; i < currentSnapshot + 1;i++){
                charge(i);
            }
        }
        lastSnapCharged = currentSnapshot; 
    }

    function syncContract() public{
        uint256 actualSnapShot = amt.getCurrentSnapshotId();
        if(actualSnapShot>lastSnapCharged){
            chargeAll();
        }
    }

    function stake(uint256 amount) public{
        require(shares[msg.sender]==0, "you need to withdrawl all to re enter the vault");
        //Sync contract with actual status
        syncContract();

        //Prev status variables
        uint256 totalAmt = amt.balanceOf(address(this));

        //Operations
        amt.transferFrom(msg.sender,address(this),amount);

        //Share distribution
        uint256 newShares = 0;
        if(totalShares == 0){
            newShares = amount;
        }
        else{
            newShares = (amount * totalShares)/totalAmt; //sharePrice = totalAmt/totalShares
        }
        totalShares = totalShares + newShares;
        shares[msg.sender] = newShares;
        initialSnapShot[msg.sender] = amt.getCurrentSnapshotId();
        enterTime[msg.sender] = block.timestamp;
    }

    function btcToWithdrawl(address addr, uint256 userShares) public view returns(uint256){
        uint256 btcAmount = 0;
        uint256 actualSnapshot = amt.getCurrentSnapshotId();
        for(uint256 i = initialSnapShot[addr] +1;i < actualSnapshot+1;i++){
            btcAmount = btcAmount + (chargedAt[i] * userShares) / totalSharesAt[i];
        }
        return btcAmount;
    }

    function withdrwal() public {
        
        require(shares[msg.sender]>0, "You are not participating on the vault");
        //Sync contract with actual status
        syncContract();

        //Prev status variables
        uint256 totalAmt = amt.balanceOf(address(this));

        //Share Redistribution
        uint256 removeShares = shares[msg.sender];
        uint256 toSend = (removeShares*totalAmt)/totalShares;
        totalShares = totalShares - removeShares;
        uint256 userShares = shares[msg.sender];
        shares[msg.sender] = 0;


        //Operations
        uint256 amountBtc = btcToWithdrawl(msg.sender,userShares);
        amt.transfer(msg.sender,toSend);
        if(amountBtc>0){
            btcb.transfer(msg.sender,amountBtc);
        } 
    }
}