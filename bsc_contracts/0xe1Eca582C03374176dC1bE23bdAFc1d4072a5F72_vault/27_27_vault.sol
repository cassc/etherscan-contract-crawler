// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


//Local imports
import "./AMT.sol";
import "./Master.sol";
import "./oracleAMT.sol";

//Standar imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//Imports for swaping
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "./IUniswapV2Router02.sol";


contract vault is Ownable{

    //General global declarations
    using SafeERC20 for IERC20;
    Master masterContract;
    AMT amt;
    IERC20 btcb;
    oracleAMT oracle ;
    uint256 lastSnapCharged;
    mapping(address => uint256) shares;
    mapping(address => uint256) initialSnapShot; 
    uint256 totalShares;

    //Pancake swap integrations
    IUniswapV2Router02 router;
    IUniswapV2Pair pair;
    address[] path;

    //General addresses
    address addrMaster = 0x13e98112e1c67DbE684adf3Aeb1C871F1fe6D1Ac;
    address addrAmt = 0x6Ae0A238a6f51Df8eEe084B1756A54dD8a8E85d3;
    address addrBtcb = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address addrPair = 0x66Cd75F1938e4F287f70F49B295207E9363f6a68;
    address addrRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address addrOracle = 0x4890cd5DB19C65356295f847E900B8a9aFcd1fA6;

    constructor(uint256 startSnapshot_){
        masterContract = Master(addrMaster);
        amt = AMT(addrAmt);
        lastSnapCharged = startSnapshot_;
        totalShares = 0;

        pair = IUniswapV2Pair(addrPair);
        router = IUniswapV2Router02(addrRouter);
        path = [addrBtcb,addrAmt];
        
        btcb = IERC20(addrBtcb);
        btcb.approve(addrRouter, 9999999999999999999999999);

        oracle = oracleAMT(addrOracle);
    }

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
    function stake(uint256 amount) public{

        //Sync contract with actual status
        syncContract();

        //Prev status variables
        uint256 totalAmt = amt.balanceOf(address(this));

        //Operations
        amt.transferFrom(msg.sender,address(this),amount);

        uint256 newShares;

        //Share distribution
        if (totalShares==0){
            newShares = amount;
        }
        else{
            newShares = (amount * totalAmt)/totalShares; //sharePrice = totalAmt/totalShares            
        }
        
        totalShares = totalShares + newShares;
        shares[msg.sender] = shares[msg.sender] + newShares;
        initialSnapShot[msg.sender] = amt.getCurrentSnapshotId();
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
        shares[msg.sender] = 0;

        //Operations
        amt.transfer(msg.sender,toSend);
    }

    function charge(uint256 snapId) private {
        masterContract.charge(snapId);
    }

    function convertToAmt() private { //TIENE QUE USAR EL ORACULOROC
        uint256 amountAMT;
        uint256 amountBtcb = btcb.balanceOf(address(this));

        amountAMT = oracle.consult(addrBtcb, amountBtcb);

        router.swapExactTokensForTokens(amountBtcb,
            amountAMT*90/100,
            path,
            address(this),
            block.timestamp + 600
        );
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
        convertToAmt();     
    }

    function syncContract() public{
        uint256 actualSnapShot = amt.getCurrentSnapshotId();
        if(actualSnapShot>lastSnapCharged){
            chargeAll();
        }
    }
}