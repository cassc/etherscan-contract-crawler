// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TSVesting.sol";
import "./TSGovernor.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "./TSProject.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TSSaleFactory is Proxy,Ownable,ReentrancyGuard {

    event SaleConfigCreate(address indexed owner, uint256 indexed smPoolId, bytes32 poolId, SaleConfig saleconfig);
    event ApproveSale(uint256 indexed saleIndex, address indexed vesting, address indexed dao);
    event AddWhiteList(uint256 indexed saleIndex, address indexed vc, uint256 indexed amount);
    event Invest(address indexed vc, uint256 indexed saleId, uint256 indexed amount, bool status);
    event SummarySale(uint256 indexed saleIndex, uint256 indexed totalBuy, uint indexed status);

    enum SaleStatus {
        PENDING,
        APPROVE,
        EXPIRED,
        SUCCESS,
        FAIL
    }

    struct SaleConfig {
        uint256 projectId;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 totalSell;
        uint256 currentWhiteList;
        uint256 currentBuy;
        bool onlyWhiteList;
        address tokenAddress;
        address tokenBuy;
        SaleStatus status;
        address tsVesting;
        address governance;
        uint256 vtStartTime;
        uint256 vtCliffTime;
        uint256 vtDuration;
        uint256 feeRefund;
        uint256 feeDisbursement;
    }

    struct WhiteListInfo {
        address addressVc;
        uint256 amount;
    }

    struct AmountBuyDetail {
        uint256 amount;
        uint256 amountTokenBuy;
    }
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    SaleConfig[] private saleConfigs;

    uint256 public BPS = 1000_000;
    uint256 private ratioSuccess = 900_000;
    uint256 public feeClaim = 20_000;
    uint256 private feeRefund = 20_000;
    uint256 private feeDisbursement = 100_000;

    mapping(uint256 => mapping(address => uint256)) private amountSells;
    mapping(uint256 => mapping(address => AmountBuyDetail)) private historyBuys;
    mapping(uint256 => mapping(address => AmountBuyDetail)) private amountBuys;

    mapping(uint256 => WhiteListInfo[]) private whiteLists;
    mapping(uint256 => mapping(address => uint256)) private whiteListsIndex;
    mapping(uint256 => uint256) private totalUser;
    address public implAddress;
    TSProject private tsProject;
    mapping(address => uint256) private totalFee;

    modifier addressZero(address _address) {
        require(_address != address(0), "TS: address zero");
        _;
    }
    modifier indexValid(uint256 saleIndex) {
        require(saleIndex < saleConfigs.length, "TS: index out of bound");
        _;
    }
    
    function _implementation()  internal view override returns (address){
        return  implAddress;
    }
    
    function setImplAddress(address _implAddress) external onlyOwner{
        implAddress = _implAddress;
    }

    function setTsProjectAddress(address _tsProject)external onlyOwner{
        tsProject = TSProject(_tsProject);
    }
    function updateFeeClaim(uint256 _feeClaim) external onlyOwner{
        require(_feeClaim>=0 && _feeClaim<=BPS,"TS: fee invalid");
        feeClaim = _feeClaim;
    }
    function updateFeeRefund(uint256 _feeRefund) external onlyOwner{
        require(_feeRefund>=0 && _feeRefund<=BPS,"TS: fee invalid");
        feeRefund = _feeRefund;
    }
    function updateFeeDisbursement(uint256 _feeDisbursement) external onlyOwner{
        require(_feeDisbursement>=0 && _feeDisbursement<=BPS,"TS: fee invalid");
        feeDisbursement = _feeDisbursement;
    }
    function createSale(bytes32 _poolId, SaleConfig memory _saleConfig) external addressZero(_saleConfig.tokenAddress) addressZero(_saleConfig.tokenBuy) {
        address ownerOfProject = tsProject.getOwnerOfProject(_saleConfig.projectId);
        require(msg.sender == ownerOfProject,"TS: not owner project");
        require(_saleConfig.endTime > _saleConfig.startTime, "TS: starttime invalid");
        require(_saleConfig.endTime > block.timestamp, "TS: endtime invalid");
        require(_saleConfig.vtStartTime > block.timestamp, "TS: starttime vesting invalid");   
        require(_saleConfig.totalSell > 0, "TS: total sell invalid");
        require(_saleConfig.vtDuration > 0, "TS: duration invalid");
        saleConfigs.push(SaleConfig(
                _saleConfig.projectId,
                _saleConfig.startTime,
                _saleConfig.endTime,
                _saleConfig.price,
                _saleConfig.totalSell,
                0,
                0,
                _saleConfig.onlyWhiteList,
                _saleConfig.tokenAddress,
                _saleConfig.tokenBuy,
                SaleStatus.PENDING,
                address(0),
                address(0),
                _saleConfig.vtStartTime,
                _saleConfig.vtCliffTime,
                _saleConfig.vtDuration,
                feeRefund,
                feeDisbursement
            )
        );
        amountSells[saleConfigs.length - 1][msg.sender]=_saleConfig.totalSell;
        emit SaleConfigCreate(_msgSender(), saleConfigs.length - 1, _poolId, _saleConfig);
        IERC20 token = IERC20(_saleConfig.tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), _saleConfig.totalSell);
    }
    function approveSale(address vesting, address dao, uint256 saleIndex)external indexValid(saleIndex) onlyOwner addressZero(vesting) addressZero(dao){
         SaleConfig storage saleConfig = saleConfigs[saleIndex];
         saleConfig.tsVesting = vesting;
         saleConfig.governance = dao;
         saleConfig.status = SaleStatus.APPROVE;
         emit ApproveSale(saleIndex, vesting, dao);
    }
   function addWhiteList(uint256 saleIndex, address vc, uint256 amount)external indexValid(saleIndex) addressZero(vc){
        require(amount > 0, "TS: amount invalid");
        SaleConfig storage saleConfig = saleConfigs[saleIndex];
        require(msg.sender == tsProject.getOwnerOfProject(saleConfig.projectId),"TS: not owner sale");
        require(tsProject.userIsVc(vc),"TS: user isn't vc");
        require(saleConfig.currentWhiteList+amount<=saleConfig.totalSell, "TS: total added maximum");
        saleConfig.currentWhiteList += amount;
        whiteLists[saleIndex].push(WhiteListInfo(vc,amount));
        whiteListsIndex[saleIndex][vc] = whiteLists[saleIndex].length -1;
        emit AddWhiteList(saleIndex, vc, amount);
    }
   
    function invest(uint256 saleIndex, uint256 amount)
        external
        indexValid(saleIndex)
    {
        SaleConfig storage saleConfig = saleConfigs[saleIndex];
        require(block.timestamp >= saleConfig.startTime && block.timestamp < saleConfig.endTime,"TS: not start or ended");
        require(whiteLists[saleIndex].length>0, "TS: whitelist is empty");
        WhiteListInfo memory vcInfo = whiteLists[saleIndex][whiteListsIndex[saleIndex][msg.sender]];        
        require(vcInfo.addressVc!=address(0)&&vcInfo.addressVc==msg.sender, "TS: vc not whitelist");
        require(vcInfo.amount == amount && amount>0, "TS: amount invalid");
        require(amountBuys[saleIndex][_msgSender()].amount == 0, "TS: vc invested");
        totalUser[saleIndex] += 1;
        IERC20 buyToken = IERC20(saleConfig.tokenBuy);
        uint256 amountTokenBuy = (amount * saleConfig.price) / BPS;
        amountBuys[saleIndex][_msgSender()] = AmountBuyDetail(
            amount,
            amountTokenBuy
        );
        historyBuys[saleIndex][_msgSender()] = AmountBuyDetail(
            amount,
            amountTokenBuy
        );
        saleConfig.currentBuy += amount;
        buyToken.safeTransferFrom(msg.sender, address(this), amountTokenBuy);
        emit Invest(_msgSender(), saleIndex, amount, saleConfig.currentBuy * BPS >= ratioSuccess * saleConfig.totalSell);
    }

    function saleSummary(uint256 saleIndex) external indexValid(saleIndex) {
        SaleConfig storage saleConfig = saleConfigs[saleIndex];
        require(block.timestamp > saleConfig.endTime, "TS: sale not end");
        require(saleConfig.status!=SaleStatus.FAIL&& saleConfig.status!=SaleStatus.SUCCESS,"TS: sale summaried");
        if (saleConfig.currentBuy * BPS >= ratioSuccess * saleConfig.totalSell) {
            require(saleConfig.tsVesting!=address(0)&&saleConfig.governance!=address(0), "TS: address zero");
            address ownerOfProject = tsProject.getOwnerOfProject(saleConfig.projectId);
            TSVesting vesting = TSVesting(saleConfig.tsVesting);
            vesting.initValue(ownerOfProject, saleConfig.governance, saleConfig.tokenBuy, saleConfig.currentBuy, totalUser[saleIndex]);
            saleConfig.status = SaleStatus.SUCCESS;
            IERC20 token = IERC20(saleConfig.tokenBuy);
            token.safeTransfer(saleConfig.governance, saleConfig.currentBuy * saleConfig.price / BPS);          
        } else {
            totalFee[saleConfig.tokenBuy] = feeClaim*(saleConfig.currentBuy*saleConfig.price/BPS)/BPS;
            saleConfig.status = SaleStatus.FAIL;
        }
        emit SummarySale(saleIndex, saleConfig.currentBuy, uint(saleConfig.status));
    }
    function claimFee(address tokenClaim) external onlyOwner {
        require(totalFee[tokenClaim]>0,"TS: insufficient funds");
        uint256 amountClaim = totalFee[tokenClaim];
        totalFee[tokenClaim] = 0;
        IERC20 token = IERC20(tokenClaim);
        token.safeTransfer(msg.sender, amountClaim);
    }
    function claimToken(uint256 saleIndex, address user)
        external 
        indexValid(saleIndex)
        nonReentrant
    {
        require(tsProject.userIsVc(user)||tsProject.userIsStartup(user), "TS: user not exist");
        SaleConfig storage saleConfig = saleConfigs[saleIndex];
        require(saleConfig.status == SaleStatus.SUCCESS||saleConfig.status == SaleStatus.FAIL,"TS: sale not summary");
        if(tsProject.userIsVc(user)){
            if (saleConfig.status == SaleStatus.SUCCESS) {
                require(amountBuys[saleIndex][user].amount > 0, "TS: balance is zero");
                amountBuys[saleIndex][user].amount = 0;
                TSVesting tsVesting = TSVesting(saleConfig.tsVesting);
                IERC20 token = IERC20(saleConfig.tokenAddress);
                token.safeApprove(saleConfig.tsVesting, historyBuys[saleIndex][user].amount);
                tsVesting.deposit(user, historyBuys[saleIndex][user].amount);
            } else {
                require(amountBuys[saleIndex][user].amountTokenBuy>0,"TS: balance is zero");
                amountBuys[saleIndex][user].amountTokenBuy = 0;
                IERC20 token = IERC20(saleConfig.tokenBuy);
                token.safeTransfer(user, (historyBuys[saleIndex][user].amountTokenBuy/BPS)*(BPS-saleConfig.feeRefund));
            }
        }else{
            address ownerOfProject = tsProject.getOwnerOfProject(saleConfig.projectId);
            require(user == ownerOfProject,"TS: user not owner sale");
            require(amountSells[saleIndex][user]>0,"TS: balance is zero");
            amountSells[saleIndex][user] = 0;
            IERC20 token = IERC20(saleConfig.tokenAddress);
            if(saleConfig.status == SaleStatus.FAIL){
                token.safeTransfer(user, saleConfig.totalSell);
            }else if(saleConfig.status == SaleStatus.SUCCESS && saleConfig.currentBuy < saleConfig.totalSell){
                token.safeTransfer(user, saleConfig.totalSell-saleConfig.currentBuy);
            }
        }
    }

    // function getAddressProject () external view returns (address) {
    //     return address(tsProject);
    // }

    function getAmountSell(uint256 smSaleId, address account) external view returns (uint256) {
        return amountSells[smSaleId][account];
    }

    function getAmountBuy(uint256 smSaleId, address account) external view returns(AmountBuyDetail memory buyDetail) {
        buyDetail = amountBuys[smSaleId][account];
    }

    function getHistoryBuy(uint256 smSaleId, address account) external view returns(AmountBuyDetail memory history) {
        history = historyBuys[smSaleId][account];
    }
    function getTotalFee(address token) external view returns (uint256) {
        return totalFee[token];
    }
    function getSaleConfigByIndex(uint256 saleId) external view returns(SaleConfig memory saleConfig){
        saleConfig = saleConfigs[saleId];
    }
    function countUserInvest(uint256 saleId) external view returns(uint256) {
        return totalUser[saleId];
    }

}