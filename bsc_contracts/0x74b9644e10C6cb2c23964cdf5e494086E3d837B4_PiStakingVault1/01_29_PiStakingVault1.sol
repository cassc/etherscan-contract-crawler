// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./interfaces/IWETH.sol";
import "./interfaces/IPi.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/INFT.sol";

import "./libraries/UniswapV2Library.sol";
import "./openzeppelinupgradeable/math/MathUpgradeable.sol";
import "./openzeppelinupgradeable/math/SafeMathUpgradeable.sol";
import "./openzeppelinupgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./openzeppelinupgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./openzeppelinupgradeable/utils/PausableUpgradeable.sol";
import "./openzeppelinupgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IpBNB_Direct.sol";
import "./interfaces/IPBNB.sol";

abstract contract TokensRecoverable is OwnableUpgradeable
{   
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function recoverTokens(IERC20Upgradeable token) public onlyOwner() 
    {
        require (canRecoverTokens(token));
        
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverERC1155(IERC1155 token, uint256 tokenId, uint256 amount) public onlyOwner() 
    {        
        token.safeTransferFrom(address(this),msg.sender,tokenId,amount,"0x");
    }

    function recoverERC721(IERC721 token, uint256 tokenId) public onlyOwner() 
    {        
        token.safeTransferFrom(address(this),msg.sender,tokenId);
    }

    function recoverETH(uint256 amount) public onlyOwner() 
    {        
        msg.sender.transfer(amount);
    }    

    function canRecoverTokens(IERC20Upgradeable token) internal virtual view returns (bool) 
    { 
        return address(token) != address(this); 
    }
}

// Have fun reading it. Hopefully it's bug-free. God bless.
contract PiStakingVault1 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, TokensRecoverable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Info of each userInfo[_pid][msg.sender].
    struct UserInfo {
        uint256 amount;         // How many LP tokens/ WANT tokens the user has staked.
        uint256 shares; 
        uint256[] AllNFTIds;
    }
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(uint256 => mapping(address => mapping(uint256=>uint256))) public NFTIdsDeposits; // NFT id, quantity

    // Info of each pool.
    struct PoolInfo {
        uint256 PiTokenAmtPerNFT;  // this amount of Pi will be given to user for each NFT staked
        address nativeToken;           // Address of native token
        address nativeNFTtoken;           // Address of native NFT token
        uint256 ERC1155NFTid;
        bool isERC1155;
        address wantToken;           // Address of LP token / want contract
        uint256 depositFeeNative;      // Deposit fee in basis points 100000 = 100%
        address strat;             // Strategy address that will auto compound want tokens
        uint256 max_slots; // active stakes cannot be more than max_slots
        uint256 max_per_user; // 1 user cannot stake NFTs more than max_per_user
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;

    mapping(uint256=>uint256) public slots_filled; // pid => nfts quantity

    // The Pi TOKEN!
    IPi public Pi;

    IpBNB_Direct public pBNBDirect;
    IPBNB public pBNB;

    // Deposit Fee address
    address public feeAddress;

    mapping(address => bool) public poolExistence;    
    uint256 slippage; // 10% = 10000
    address public wrappedBNB;
    IUniswapV2Router02 private uniswapV2Router; 
    IUniswapV2Factory private uniswapV2Factory; 
    uint256 public timeLockInSecs;
    mapping(address=>uint256) public lockTimeStamp; 
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);

    receive() external payable{
    } 

    function initialize(        
        IPi _Pi,
        address _feeAddress,
        IpBNB_Direct _pBNBDirect,
        IPBNB _pBNB
        )  public initializer  {
        
        __Ownable_init_unchained();
        Pi = _Pi;
        feeAddress = _feeAddress;
        pBNBDirect = _pBNBDirect;
        pBNB = _pBNB;

        wrappedBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73); //IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

        slippage = 10000;// 10% 
        timeLockInSecs = 14 days;

        IERC20Upgradeable(address(Pi)).approve(address(uniswapV2Router), uint256(-1));   
        IERC20Upgradeable(address(Pi)).approve(address(pBNBDirect), uint256(-1));   

    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function allNFTsDeposited(uint256 _pid, address _user) external view returns(uint[] memory){
        return userInfo[_pid][_user].AllNFTIds;
    }

    modifier nonDuplicated(address _wantToken) {
        require(!poolExistence[_wantToken], "nonDuplicated: duplicated");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }
    

    // Add a new lp to the pool. Can only be called by the owner.
    // [10,100,200] = 10 -> low risk, 100 -> medium, 200 -> high risk vault
    function add( uint256 _piTokenAmtPerNFT, address _nativeToken, address _nativeNFTtoken, uint256 _ERC1155NFTid, bool _isERC1155, address _wantToken, uint256 _depositFeeNative, 
        address _strat, uint256 _max_slots, uint256 _max_per_user) public onlyOwner nonDuplicated(_wantToken) {
        
        // require(_max_slots>_max_per_user,"_max_slots should be more than _max_per_user");
        // require(_wantToken == IStrategy(_strat).wantAddress(),"wantToken not equal to pool strat wantAddress");
        // require(_nativeToken!=address(0),"_nativeToken shouldnot be zero address");
        // require(_strat!=address(0),"_strat shouldnot be zero address");
        // require(_depositFeeNative>0,"_depositFeeNative should be more than 0");
        // require(_piTokenAmtPerNFT>0,"_piTokenAmtPerNFT should be more than 0");

        // try IUniswapV2Pair(_wantToken).factory(){
        //     require(address(Pi) != IUniswapV2Pair(_wantToken).token0(),"wantToken equal to pool strat token0");
        //     require(address(Pi) != IUniswapV2Pair(_wantToken).token1(),"wantToken equal to pool strat token1");
        // }
        // catch{
        //     require(address(Pi) != _wantToken,"wantToken equal to Pi");
        // }
        

        // poolExistence[_wantToken] = true;
        // poolInfo.push(PoolInfo({
        //     PiTokenAmtPerNFT : _piTokenAmtPerNFT,
        //     nativeToken : _nativeToken,
        //     nativeNFTtoken : _nativeNFTtoken,
        //     ERC1155NFTid: _ERC1155NFTid,
        //     isERC1155 : _isERC1155,
        //     wantToken : _wantToken,
        //     depositFeeNative : _depositFeeNative, // native tokens required as fee => either of 10, 100, 1000 as per risk of vault => 10000, 100000 or 1000000
        //     strat: _strat,
        //     max_slots : _max_slots,
        //     max_per_user : _max_per_user
        // }));

        // IERC20Upgradeable(_wantToken).approve(feeAddress, uint256(-1));   
        // IERC20Upgradeable(_wantToken).approve(address(uniswapV2Router), uint256(-1));   

        // try IUniswapV2Pair(_wantToken).factory(){
        //     IERC20Upgradeable(IUniswapV2Pair(_wantToken).token0()).approve(address(uniswapV2Router), uint256(-1));   
        //     IERC20Upgradeable(IUniswapV2Pair(_wantToken).token1()).approve(address(uniswapV2Router), uint256(-1));   
        // } catch{}

    }

    // Update the given pool's Pi allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _depositFeeNative, uint256 _max_slots, uint256 _max_per_user, uint256 _piTokenAmtPerNFT) public onlyOwner {

        poolInfo[_pid].depositFeeNative = _depositFeeNative;
        poolInfo[_pid].max_slots = _max_slots;
        poolInfo[_pid].max_per_user = _max_per_user;
        poolInfo[_pid].PiTokenAmtPerNFT = _piTokenAmtPerNFT;

    }

   
    // View function to see your initial deposit
    function balanceOf(uint256 _pid, address _user) public view returns (uint256) {
        return userInfo[_pid][_user].amount;
    }

    function zapEthToToken(address _token1, uint256 _amount) internal{
        uint slippageFactor=(SafeMathUpgradeable.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default     
        address[] memory path2 = new address[](2);
        path2[0] = wrappedBNB;
        path2[1] = _token1; 
        if(path2[0]!=path2[1])
        {
            (uint256[] memory amounts2) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), _amount, path2);
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _amount}(amounts2[1].mul(slippageFactor).div(100), path2, address(this), block.timestamp+300);
        }
        else 
            IWETH(wrappedBNB).deposit{ value: _amount }();
        
        delete path2;
    }

    // _erc721tokenId send if NFT token is ERC 721
    function deposit(uint256 _pid, uint256 totalNFTs, uint256[] memory _erc721tokenIds) public nonReentrant {

        PoolInfo storage pool = poolInfo[_pid];
        uint256 _amount;
        uint256 allocatedPi; 
        lockTimeStamp[msg.sender] = block.timestamp.add(timeLockInSecs);


        if(pool.isERC1155){
            require(totalNFTs>0,"amount of totalNFTs to transfer cannot be 0");

            _amount = totalNFTs.mul(pool.depositFeeNative);
            allocatedPi = totalNFTs.mul(pool.PiTokenAmtPerNFT);

            IERC1155(pool.nativeNFTtoken).safeTransferFrom( msg.sender, address(this), pool.ERC1155NFTid, totalNFTs, "0x");
            // donot duplicate erc1155 token ids
            if(NFTIdsDeposits[_pid][msg.sender][pool.ERC1155NFTid]==0){
                userInfo[_pid][msg.sender].AllNFTIds.push(pool.ERC1155NFTid);
            }
            NFTIdsDeposits[_pid][msg.sender][pool.ERC1155NFTid]=NFTIdsDeposits[_pid][msg.sender][pool.ERC1155NFTid].add(totalNFTs);
            slots_filled[_pid]=slots_filled[_pid].add(totalNFTs);
            require(slots_filled[_pid]<=pool.max_slots,"Max slots filled");
            require(NFTIdsDeposits[_pid][msg.sender][pool.ERC1155NFTid]<=pool.max_per_user,"Max per user already done");

        } else // erc721
        {
            require(_erc721tokenIds.length>0,"amount of totalNFTs to transfer cannot be 0");

            _amount = _erc721tokenIds.length.mul(pool.depositFeeNative);
            allocatedPi = _erc721tokenIds.length.mul(pool.PiTokenAmtPerNFT);

            for(uint i=0;i<_erc721tokenIds.length;i++){
                IERC721(pool.nativeNFTtoken).transferFrom(msg.sender, address(this), _erc721tokenIds[i]);
                userInfo[_pid][msg.sender].AllNFTIds.push(_erc721tokenIds[i]);
                NFTIdsDeposits[_pid][msg.sender][_erc721tokenIds[i]]=1;
                slots_filled[_pid]=slots_filled[_pid].add(1);
            }
            require(slots_filled[_pid]<=pool.max_slots,"Max slots filled");
            require(userInfo[_pid][msg.sender].AllNFTIds.length<=pool.max_per_user,"Max per user already done");

        }

        IERC20Upgradeable(pool.nativeToken).safeTransferFrom(msg.sender, feeAddress, _amount);

        // market buy 
        uint256 prevWantAmount = IERC20(pool.wantToken).balanceOf(address(this)); 
        
        // so that stack is not deep -> making copies
        uint poolId = _pid;
        uint256 amount = _amount;

        uint slippageFactor=(SafeMathUpgradeable.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default     
        uint prevpbnbBal = pBNB.balanceOf(address(this));
        uint prevBNBBal = address(this).balance;
        pBNBDirect.easySellToPBNB(allocatedPi);
        pBNB.withdraw(pBNB.balanceOf(address(this)).sub(prevpbnbBal));

        uint256 bnbAmtAfterSell = address(this).balance.sub(prevBNBBal);

        // check if uniswap pair
        try IUniswapV2Pair(pool.wantToken).factory(){
            
            address wantToken1 = pool.wantToken;
            uint256 prevToken0Bal = IERC20Upgradeable(IUniswapV2Pair(pool.wantToken).token0()).balanceOf(address(this)); 
         
            zapEthToToken(IUniswapV2Pair(wantToken1).token0(), bnbAmtAfterSell.div(2));

            uint256 prevToken1Bal = IERC20Upgradeable(IUniswapV2Pair(wantToken1).token1()).balanceOf(address(this)); 

            zapEthToToken(IUniswapV2Pair(wantToken1).token1(), bnbAmtAfterSell.div(2));

            uniswapV2Router.addLiquidity(
                IUniswapV2Pair(wantToken1).token0(), 
                IUniswapV2Pair(wantToken1).token1(), 
                IERC20Upgradeable(IUniswapV2Pair(wantToken1).token0()).balanceOf(address(this)).sub(prevToken0Bal), 
                IERC20Upgradeable(IUniswapV2Pair(wantToken1).token1()).balanceOf(address(this)).sub(prevToken1Bal), 
                100, 
                100,
                address(this), 
                block.timestamp+900);
        }
        catch {
            zapEthToToken(pool.wantToken, bnbAmtAfterSell);
        }

        uint256 WantTokenReceivedInContractAfterSwap = IERC20Upgradeable(pool.wantToken).balanceOf(address(this)).sub(prevWantAmount);
        IERC20Upgradeable(pool.wantToken).safeIncreaseAllowance(pool.strat, WantTokenReceivedInContractAfterSwap);
        
        uint256 sharesAdded = IStrategy(pool.strat).deposit(msg.sender, WantTokenReceivedInContractAfterSwap);

        userInfo[poolId][msg.sender].amount = userInfo[poolId][msg.sender].amount.add(WantTokenReceivedInContractAfterSwap);
        userInfo[poolId][msg.sender].shares = userInfo[poolId][msg.sender].shares.add(sharesAdded);
        emit Deposit(msg.sender, poolId, amount);
    }

    // to see the updated LPs of user
    function getusercompounds(uint256 _pid, address _useraddress) public view returns (uint256){
        
        PoolInfo storage pool = poolInfo[_pid];
        uint256 wantLockedTotal =
            IStrategy(pool.strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if(sharesTotal==0)
            return 0;

        uint256 amount = userInfo[_pid][_useraddress].shares.mul(wantLockedTotal).div(sharesTotal);
        if(userInfo[_pid][_useraddress].amount>amount) // can give 99999 due to division for 100000
            return userInfo[_pid][_useraddress].amount;
        else
            return amount;
    }

    function zapTokenToEth(address _token1, uint256 _amount) internal{
        uint slippageFactor=(SafeMathUpgradeable.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default     
        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = wrappedBNB; 
        if(path[0]!=path[1])
        {
            (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), _amount, path);
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, amounts[1].mul(slippageFactor).div(100), path, address(this), block.timestamp+300);
        }
        else
            IWETH(wrappedBNB).withdraw(_amount);
            
        delete path;
    }


   function emergencyWithdrawNFT(address _userAddress, uint256 _pid) public onlyOwner {
       
        // require(lockTimeStamp[msg.sender]<=block.timestamp,"Cannot withdraw before timelock finishes");
        PoolInfo storage pool = poolInfo[_pid];
        // uint256 _amount = userInfo[_pid][_userAddress].amount;

        // uint256 wantLockedTotal =
        //     IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        // uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();

        // require(userInfo[_pid][_userAddress].shares > 0, "userInfo[_pid][msg.sender].shares is 0");
        // require(sharesTotal > 0, "sharesTotal is 0");

        // give nft back to user
        // if(pool.isERC1155){

        //     slots_filled[_pid]=slots_filled[_pid].sub(NFTIdsDeposits[_pid][_userAddress][pool.ERC1155NFTid]);

        //     IERC1155(pool.nativeNFTtoken).safeTransferFrom( address(this), msg.sender, pool.ERC1155NFTid, NFTIdsDeposits[_pid][_userAddress][pool.ERC1155NFTid], "0x");

        //     uint[] memory auxArray;
        //     userInfo[_pid][_userAddress].AllNFTIds = auxArray;
        //     NFTIdsDeposits[_pid][_userAddress][pool.ERC1155NFTid]=0;

        // } else // erc721
        // {
            uint256[] memory erc721tokenIds = userInfo[_pid][_userAddress].AllNFTIds;
            for(uint i=0;i<erc721tokenIds.length;i++){
                IERC721(pool.nativeNFTtoken).transferFrom( address(this), _userAddress, erc721tokenIds[i]);
                NFTIdsDeposits[_pid][_userAddress][erc721tokenIds[i]]=0;
            }
            // slots_filled[_pid]=slots_filled[_pid].sub(erc721tokenIds.length);

            // uint[] memory auxArray;
            // userInfo[_pid][_userAddress].AllNFTIds = auxArray;
        // }


        // Withdraw want tokens
        // uint256 amount = userInfo[_pid][_userAddress].shares.mul(wantLockedTotal).div(sharesTotal);

        // uint256 rewardForUser = 0;

        // if (amount < _amount) {
        //     amount = _amount;
        // }
        // else rewardForUser = amount.sub(_amount); // only the reward

        // uint256 sharesRemoved =
        //     IStrategy(poolInfo[_pid].strat).withdraw(_userAddress, amount);

        // if (sharesRemoved > userInfo[_pid][_userAddress].shares) 
            userInfo[_pid][_userAddress].shares = 0; 
        // else
        //     userInfo[_pid][_userAddress].shares = userInfo[_pid][_userAddress].shares.sub(sharesRemoved);

        // if(amount > userInfo[_pid][_userAddress].amount)
            userInfo[_pid][_userAddress].amount = 0;
        // else
        //     userInfo[_pid][_userAddress].amount = userInfo[_pid][_userAddress].amount.sub(amount);

        // marketBuyAndTransfer(pool.wantToken, msg.sender, amount);
    

        // emit Withdraw(msg.sender, _pid, amount);
   }

    // Withdraw LP tokens 
    // all NFTs will be withdrawn
    function withdrawAll(uint256 _pid) public nonReentrant  {
        
        require(lockTimeStamp[msg.sender]<=block.timestamp,"Cannot withdraw before timelock finishes");
        PoolInfo storage pool = poolInfo[_pid];
        uint256 _amount = userInfo[_pid][msg.sender].amount;

        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();

        require(userInfo[_pid][msg.sender].shares > 0, "userInfo[_pid][msg.sender].shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        // give nft back to user
        // if(pool.isERC1155){

        //     slots_filled[_pid]=slots_filled[_pid].sub(NFTIdsDeposits[_pid][msg.sender][pool.ERC1155NFTid]);

        //     IERC1155(pool.nativeNFTtoken).safeTransferFrom( address(this), msg.sender, pool.ERC1155NFTid, NFTIdsDeposits[_pid][msg.sender][pool.ERC1155NFTid], "0x");

        //     uint[] memory auxArray;
        //     userInfo[_pid][msg.sender].AllNFTIds = auxArray;
        //     NFTIdsDeposits[_pid][msg.sender][pool.ERC1155NFTid]=0;

        // } else // erc721
        // {
            uint256[] memory erc721tokenIds = userInfo[_pid][msg.sender].AllNFTIds;
            for(uint i=0;i<erc721tokenIds.length;i++){
                IERC721(pool.nativeNFTtoken).transferFrom( address(this), msg.sender, erc721tokenIds[i]);
                NFTIdsDeposits[_pid][msg.sender][erc721tokenIds[i]]=0;
            }
            slots_filled[_pid]=slots_filled[_pid].sub(erc721tokenIds.length);

            uint[] memory auxArray;
            userInfo[_pid][msg.sender].AllNFTIds = auxArray;
        // }


        // Withdraw want tokens
        uint256 amount = userInfo[_pid][msg.sender].shares.mul(wantLockedTotal).div(sharesTotal);

        uint256 rewardForUser = 0;

        if (amount < _amount) {
            amount = _amount;
        }
        else rewardForUser = amount.sub(_amount); // only the reward

        if (amount > 0) {
            uint256 sharesRemoved =
                IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, amount);

            if (sharesRemoved > userInfo[_pid][msg.sender].shares) 
                userInfo[_pid][msg.sender].shares = 0; 
            else
                userInfo[_pid][msg.sender].shares = userInfo[_pid][msg.sender].shares.sub(sharesRemoved);

            if(amount > userInfo[_pid][msg.sender].amount)
                userInfo[_pid][msg.sender].amount = 0;
            else
                userInfo[_pid][msg.sender].amount = userInfo[_pid][msg.sender].amount.sub(amount);
            

            uint256 amountForVaults = amount.sub(rewardForUser);

            if(amountForVaults>0){
                marketBuyAndTransfer(pool.wantToken, address(this), amountForVaults);
            }
            if(rewardForUser>0)            
                marketBuyAndTransfer(pool.wantToken, msg.sender, rewardForUser);
        }

        emit Withdraw(msg.sender, _pid, amount);
    }


    function marketBuyAndTransfer(address _tokenAddress, address _to, uint256 _amount) internal{

        uint256 prevBNB = address(this).balance;

        try IUniswapV2Pair(_tokenAddress).factory(){

            uint256 prevBalanceToken0 = IERC20(IUniswapV2Pair(_tokenAddress).token0()).balanceOf(address(this)); 
            uint256 prevBalanceToken1 = IERC20(IUniswapV2Pair(_tokenAddress).token1()).balanceOf(address(this)); 
            
            if(IUniswapV2Pair(_tokenAddress).token0()==wrappedBNB){
                uniswapV2Router.removeLiquidityETH(IUniswapV2Pair(_tokenAddress).token1(), _amount, 100, 100, address(this), block.timestamp+300);        
                uint256 amountToken1 = IERC20(IUniswapV2Pair(_tokenAddress).token1()).balanceOf(address(this)).sub(prevBalanceToken1); 
                zapTokenToEth(IUniswapV2Pair(_tokenAddress).token1(), amountToken1);

            }
            else if(IUniswapV2Pair(_tokenAddress).token1()==wrappedBNB){
                uniswapV2Router.removeLiquidityETH(IUniswapV2Pair(_tokenAddress).token0(), _amount, 100, 100, address(this), block.timestamp+300);
                uint256 amountToken0 = IERC20(IUniswapV2Pair(_tokenAddress).token0()).balanceOf(address(this)).sub(prevBalanceToken0); 
                zapTokenToEth(IUniswapV2Pair(_tokenAddress).token0(), amountToken0);
            }
            else{
                uniswapV2Router.removeLiquidity(IUniswapV2Pair(_tokenAddress).token0(), IUniswapV2Pair(_tokenAddress).token1(), _amount, 100, 100, address(this), block.timestamp+300);
                uint256 amountToken0 = IERC20(IUniswapV2Pair(_tokenAddress).token0()).balanceOf(address(this)).sub(prevBalanceToken0); 
                uint256 amountToken1 = IERC20(IUniswapV2Pair(_tokenAddress).token1()).balanceOf(address(this)).sub(prevBalanceToken1); 

                zapTokenToEth(IUniswapV2Pair(_tokenAddress).token0(), amountToken0);
                zapTokenToEth(IUniswapV2Pair(_tokenAddress).token1(), amountToken1);
            }

        }
        catch{
            zapTokenToEth(_tokenAddress, _amount);
        }

        uint256 totalBNB = address(this).balance.sub(prevBNB);
        uint prevPi = Pi.balanceOf(address(this));
        pBNBDirect.easyBuy{ value: totalBNB }();
        
        if(_to != address(this) )
            Pi.transfer(_to, Pi.balanceOf(address(this)).sub(prevPi));

    }

    function setFeeAddress(address _feeAddress) external onlyOwner{
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    // change strat for pool id
    function changeStratForPool(uint256 _pid, address _stratAddress) external onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        pool.strat = _stratAddress;
    }

    function setSlippage(uint _slippage) external onlyOwner{
        slippage = _slippage;
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external  returns(bytes4){
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external  returns(bytes4){
        return 0xbc197c81;
    }     
}