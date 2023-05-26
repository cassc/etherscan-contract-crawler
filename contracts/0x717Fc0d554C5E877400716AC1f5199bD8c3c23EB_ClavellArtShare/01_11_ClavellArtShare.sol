// SPDX-License-Identifier: MIT
/// @author Mr D 
/// @title Clavel Art Shares
pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ClavellArtShare is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    
    IERC20 public token;
    IERC721 public nftContract;

    /* @dev team wallet should be a multi-sig wallet, used to transfer 
    ETH out of the contract for a migration, or EOL of the contract */
    address public opsWallet;

    // global flag to set staking and depositing active
    bool public isActive;

    // flag to turn off only deposits
    bool public depositsActive;


    // total points to allocate rewards 
    uint256 public totalSharePoints;

    uint256 private lockDuration =14 days;

    struct UserLock {
        uint256 tokenAmount; // total amount they currently have locked
        uint256 claimedAmount; // total amount they have withdrawn
        uint256 startTime; // start of the lock
        uint256 endTime; // when the lock ends
    }

    struct UserNftLock {
        uint256 nftId; // nft id they have staked
        uint256 amount; // amount they have locked
        uint256 startTime; // start of the lock
        uint256 endTime; // when the lock ends
    }

    struct NftInfo {
        uint256 lockDuration; // how long this nft needs is locked
        uint256 shareMultiplier;  // multiply users shares by this number 1x = 10
        uint256 lockedNfts; // how many nfts are currently locked for this ID
        bool isDisabled; // so we can hide ones we don't want
    }

    mapping(address => UserLock) public userLocks;
    mapping(address => UserNftLock) public userNftLocks;
    
    NftInfo public nftInfo;
    mapping(address => uint256) public currentMultiplier;

    mapping(address => uint256) public sharePoints;

    uint256 public constant MAX_MULTIPLIER = 30; // 3x

    
    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    
    //profit for each share a holder holds, a share equals a decimal.
    uint256 public profitPerShare;

    //the total reward distributed through the vault, for tracking purposes
    uint256 public totalShareRewards;
    
    //the total payout through the vault, for tracking purposes
    uint256 public totalPayouts;
   
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;


    event Locked(address indexed account, uint256 unlock );
    event WithdrawTokens(address indexed account, uint256 amount);
    event NftLocked(address indexed account, uint256 nftId, uint256 unlock);

    event ClaimNative(address claimAddress, uint256 amount);
    event NftUnLocked(address indexed account, uint256 nftId);

    constructor (
        IERC20 _token,
        IERC721 _nftContract,
        address  _opsWallet
    ) {     
        token = _token;
        nftContract = _nftContract;
        opsWallet = _opsWallet;
    }

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }


    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function setDepositsActive(bool _depositsActive) public onlyOwner {
        depositsActive = _depositsActive;
    }

    function setLockDuration(uint256 _lockDuration) public onlyOwner {
        lockDuration = _lockDuration;
    }

    function setNftContract( IERC721 _nftContract ) public onlyOwner {
        nftContract = _nftContract;      
    }

    function setNftInfo(
        uint256 _lockDuration, 
        uint256 _shareMultiplier) public onlyOwner {
        
        require(_shareMultiplier <= MAX_MULTIPLIER, 'Multiplier too high');

        nftInfo.lockDuration = _lockDuration;
        nftInfo.shareMultiplier = _shareMultiplier; 

    }

    function setNftDisabled(bool _isDisabled) public onlyOwner {
        nftInfo.isDisabled = _isDisabled;        
    }

    function lock(uint256 _amount) public nonReentrant {
        require(isActive && depositsActive,'Not active');
        require(token.balanceOf(msg.sender) >= _amount, 'Not enough tokens');

        userLocks[msg.sender].tokenAmount = userLocks[msg.sender].tokenAmount + _amount;
        userLocks[msg.sender].startTime = block.timestamp; 
        userLocks[msg.sender].endTime = block.timestamp + lockDuration; 
        

        // move the tokens
        token.safeTransferFrom(address(msg.sender), address(this), _amount);

        // multiply existing shares by the multiplier 
        uint256 shares = _amount; 

        if(currentMultiplier[msg.sender] > 0) {
          shares = (_amount * currentMultiplier[msg.sender])/10;
        }

         // give the shares
        _addShares(msg.sender,shares);

        emit Locked( msg.sender,userLocks[msg.sender].endTime );

    }

    function claimLock(uint256 _amount) public nonReentrant {
        require(isActive,'Not active');
        require(userLocks[msg.sender].endTime <= block.timestamp,'Tokens Locked');
        require(userLocks[msg.sender].tokenAmount > 0 && userLocks[msg.sender].tokenAmount >= _amount, 'Not enough tokens Locked');

        userLocks[msg.sender].claimedAmount = userLocks[msg.sender].claimedAmount + _amount;
        userLocks[msg.sender].tokenAmount = userLocks[msg.sender].tokenAmount - _amount;

        // multiply existing shares by the multiplier 
        uint256 shares = _amount; 

        if(currentMultiplier[msg.sender] > 0) {
          shares = (_amount * currentMultiplier[msg.sender])/10;
        }

        // remove the shares
        _removeShares(msg.sender, shares);

        // move the tokens
        token.safeTransfer(address(msg.sender), _amount);
        emit WithdrawTokens(msg.sender, _amount);
        
    }

    // locks an NFT for the amount of time and give shares
    function lockNft(uint256 _nftId) public nonReentrant {
        require(
            isActive &&
            depositsActive &&
            nftInfo.shareMultiplier > 0  && 
            !nftInfo.isDisabled && 
            nftContract.ownerOf(_nftId) == msg.sender &&
            userNftLocks[msg.sender].startTime == 0, "Can't Lock");

        userNftLocks[msg.sender].nftId = _nftId;
        userNftLocks[msg.sender].startTime = block.timestamp; 
        userNftLocks[msg.sender].endTime = block.timestamp + nftInfo.lockDuration; 
        userNftLocks[msg.sender].amount = userNftLocks[msg.sender].amount + 1; 
        
        // update the locked count
        nftInfo.lockedNfts = nftInfo.lockedNfts + 1;

        // assing the multiplier
        currentMultiplier[msg.sender] = nftInfo.shareMultiplier;

        uint256 currentShares = getShares(msg.sender); 
        // multiply existing shares by the multiplier and give them the difference
        uint256 shares = ((currentShares * nftInfo.shareMultiplier)/10) - currentShares;

        _addShares(msg.sender, shares);

        // send the NFT
        nftContract.safeTransferFrom( msg.sender, address(this), _nftId);

        emit NftLocked( msg.sender, _nftId, userNftLocks[msg.sender].endTime);

    }

    // unlocks and claims an NFT if allowed and removes the shares
    function unLockNft(uint256 _nftId) public nonReentrant {
        require(isActive && userNftLocks[msg.sender].amount > 0, 'Not Locked');
        require(block.timestamp >= userNftLocks[msg.sender].endTime, 'Still Locked');
 
        uint256 currentShares = getShares(msg.sender); 
        uint256 shares;
        if(currentMultiplier[msg.sender] > 0) {
            // divide existing shares by the multiplier and remove the difference
            shares = currentShares - ((currentShares*10)/currentMultiplier[msg.sender]);
        }
        
        // reset the multiplier
        currentMultiplier[msg.sender] = 0;

        // remove the shares
        _removeShares(msg.sender, shares);

        uint256 amount = userNftLocks[msg.sender].amount;
        delete userNftLocks[msg.sender];

        // update the locked count
        nftInfo.lockedNfts = nftInfo.lockedNfts - amount;
        
        // send the NFT
        nftContract.safeTransferFrom(  address(this), msg.sender, _nftId);

        emit NftUnLocked( msg.sender, _nftId);
    }

    //gets shares of an address
    function getShares(address _addr) public view returns(uint256){
        return (sharePoints[_addr]);
    }

    //gets locks of an address
    function getLocked(address _addr) public view returns(uint256){
        return userLocks[_addr].tokenAmount;
    }

    //Returns the not paid out dividends of an address in wei
    function getDividends(address _addr) public view returns (uint256){
        return _getDividendsOf(_addr) + toBePaid[_addr];
    }

    function claimNative() public nonReentrant {
        require(isActive,'Not active');
           
        uint256 amount = getDividends(msg.sender);
        require(amount!=0,"=0"); 
        //Substracts the amount from the dividends
        _updateClaimedDividends(msg.sender, amount);
        totalPayouts+=amount;
        (bool sent,) =msg.sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
        emit ClaimNative(msg.sender,amount);

    }

    //adds Token to balances, adds new Native to the toBePaid mapping and resets staking
    function _addShares(address _addr, uint256 _amount) private {
        // the new amount of points
        uint256 newAmount = sharePoints[_addr] + _amount;

        // update the total points
        totalSharePoints+=_amount;

        //gets the payout before the change
        uint256 payment = _getDividendsOf(_addr);

        //resets dividends to 0 for newAmount
        alreadyPaidShares[_addr] = profitPerShare * newAmount;
        //adds dividends to the toBePaid mapping
        toBePaid[_addr]+=payment; 
        //sets newBalance
        sharePoints[_addr]=newAmount;
    }

    //removes shares, adds Native to the toBePaid mapping and resets staking
    function _removeShares(address _addr, uint256 _amount) private {
        //the amount of token after transfer
        uint256 newAmount=sharePoints[_addr] - _amount;
        totalSharePoints -= _amount;

        //gets the payout before the change
        uint256 payment =_getDividendsOf(_addr);
        //sets newBalance
        sharePoints[_addr]=newAmount;
        //resets dividendss to 0 for newAmount
        alreadyPaidShares[_addr] = profitPerShare * sharePoints[_addr];
        //adds dividendss to the toBePaid mapping
        toBePaid[_addr] += payment; 
    }

    //gets the dividends of an address that aren't in the toBePaid mapping 
    function _getDividendsOf(address _addr) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * sharePoints[_addr];
        //if excluded from staking or some error return 0
        if(fullPayout<=alreadyPaidShares[_addr]) return 0;
        return (fullPayout - alreadyPaidShares[_addr])/DistributionMultiplier;
    }

    //adjust the profit share with the new amount
    function _updateProfitPerShare(uint256 _amount) private {

        totalShareRewards += _amount;
        if (totalSharePoints > 0) {
            //Increases profit per share based on current total shares
            profitPerShare += ((_amount * DistributionMultiplier)/totalSharePoints);
        }
    }

    //Substracts the amount from dividends, fails if amount exceeds dividends
    function _updateClaimedDividends(address _addr,uint256 _amount) private {

        uint256 newAmount = _getDividendsOf(_addr);

        //sets payout mapping to current amount
        alreadyPaidShares[_addr] = profitPerShare * sharePoints[_addr];
        //the amount to be paid 
        toBePaid[_addr]+=newAmount;
        toBePaid[_addr]-=_amount;
    }

    event OnArtSharesReceive(address indexed sender, uint256 amount);
    receive() external payable {

        if(msg.value > 0 && totalSharePoints > 0){
            _updateProfitPerShare(msg.value);
        }

        emit OnArtSharesReceive(msg.sender, msg.value);
    }

    event OpsWalletChanged(address oldOpsWallet, address newOpsWallet);
    function setOpsWallet(address _opsWallet) public {
        require(msg.sender == opsWallet,'Not allowed');

        address prevWallet = opsWallet;
        opsWallet = _opsWallet;

        emit OpsWalletChanged(prevWallet, _opsWallet);
    }

    // pull all the ETH out of the contract to the owner, needed for migrations/emergencies/EOL 
    // the team wallet should be set to a multi-sig wallet
    event AdminMigrateEth(address account, uint256 amount);
    function migrateETH() public {
        require(msg.sender == opsWallet,'Not allowed');
        uint256 amount = address(this).balance;
         (bool sent,) =address(owner()).call{value: (amount)}("");

        require(sent,"withdraw failed");
        emit AdminMigrateEth(msg.sender, amount);
    }

    function onERC721Received(address operator, address, uint256, bytes calldata) external view returns(bytes4) {
        require(operator == address(this), "can not directly transfer");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}