// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/IWETH.sol";
import "./interfaces/IPi.sol";
import "./libraries/EnumerableSet.sol";
import "./libraries/UniswapV2Library.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IPiStakingVaults.sol";
import "./interfaces/IPCSVault.sol";

import "./openzeppelinupgradeable/math/MathUpgradeable.sol";
import "./openzeppelinupgradeable/math/SafeMathUpgradeable.sol";
import "./openzeppelinupgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./openzeppelinupgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./openzeppelinupgradeable/utils/PausableUpgradeable.sol";
import "./openzeppelinupgradeable/access/OwnableUpgradeable.sol";
import "./openzeppelinupgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./openzeppelinupgradeable/token/ERC721/IERC721Upgradeable.sol";

abstract contract TokensRecoverable is OwnableUpgradeable
{   
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function recoverTokens(IERC20Upgradeable token) public onlyOwner() 
    {
        require (canRecoverTokens(token));
        
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverETH(uint256 amount) public onlyOwner() 
    {        
        msg.sender.transfer(amount);
    }    

    function recoverERC1155(IERC1155Upgradeable token, uint256 tokenId, uint256 amount) public onlyOwner() 
    {        
        token.safeTransferFrom(address(this),msg.sender,tokenId,amount,"0x");
    }

    function recoverERC721(IERC721Upgradeable token, uint256 tokenId) public onlyOwner() 
    {        
        token.safeTransferFrom(address(this),msg.sender,tokenId);
    }

    function canRecoverTokens(IERC20Upgradeable token) internal virtual view returns (bool) 
    { 
        return address(token) != address(this); 
    }
}

contract PiVaultStratLP is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, TokensRecoverable {

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IUniswapV2Router02 private uniswapV2Router; 
    IUniswapV2Factory private uniswapV2Factory; 


    uint256 public piVaultPoolid; // piVaultPoolid of pool in farmContractAddress

    address public wantAddress;
    address public token0Address;
    address public token1Address;
    address public earnedAddress;
    address public PCSTokenAddress;

    address public piFarmAddress;
    address public PCSVaultAddress;
    uint256 public PCSPoolId;

    address public govAddress;
    bool public onlyGov;

    uint256 public lastEarnBlock;   
    uint256 public wantLockedTotal;
    uint256 public sharesTotal;
    uint256 public waitMigTransferTime;

    uint256 public controllerFee;
    address public feeAddress;

    address[] public earnedToToken0Path;
    address[] public earnedToToken1Path;
    address[] public token0ToEarnedPath;
    address[] public token1ToEarnedPath;
    address[] public PCSToEarnedPath;


    struct MigrateTo{
        uint256 newPCSPoolID;
        address newPCSVaultAddress;
        uint256 timeMigration;
    }

    MigrateTo migrateVault;

    uint256 public slippage;

    event DepositFor(address userAddress, uint256 amount);
    event WithdrawFor(address userAddress, uint256 amount);
    
    function initialize(        
        address _piFarmAddress,
        uint256 _piVaultPoolid,
        address _wantAddress, // SLP token from token0 and token1 
        address _token0Address,
        address _token1Address,
        address _PCSVaultAddress, // PCS Staking Contract
        uint256 _PCSPoolId, // PCS Pool id of Vault
        address _earnedAddress, // CAKE token
        address _PCSTokenAddress, // PCS token
        uint256 _controllerFee, // 100 = 1%
        address _feeAddress
        )  public initializer  {
        
        __Ownable_init_unchained();
        govAddress = msg.sender;

        require(_piFarmAddress!=address(0),"_piFarmAddress should not be zero address");
        require(_wantAddress!=address(0),"_wantAddress should not be zero address");
        require(_token0Address!=address(0),"_token0Address should not be zero address");
        require(_token1Address!=address(0),"_token1Address should not be zero address");
        require(_earnedAddress!=address(0),"_earnedAddress should not be zero address");
        require(_PCSVaultAddress!=address(0),"_PCSVaultAddress should not be zero address");
        require(_PCSTokenAddress!=address(0),"_PCSTokenAddress should not be zero address");
        require(_feeAddress!=address(0),"_feeAddress should not be zero address");

        piFarmAddress = _piFarmAddress;

        wantAddress = _wantAddress;

        token0Address = _token0Address;
        token1Address = _token1Address;

        piVaultPoolid = _piVaultPoolid;
        earnedAddress = _earnedAddress;

        PCSVaultAddress = _PCSVaultAddress;
        PCSPoolId=_PCSPoolId;
        PCSTokenAddress=_PCSTokenAddress;
        
        slippage = 10000;

        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73); //IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

        
        lastEarnBlock = 0;   
        wantLockedTotal = 0;
        sharesTotal = 0;
        waitMigTransferTime = 8 hours;
        onlyGov = false; // anyone can call earn()


        
        earnedToToken0Path = [earnedAddress, token0Address];
        earnedToToken1Path = [earnedAddress, token1Address];
        token0ToEarnedPath = [token0Address, earnedAddress];
        token1ToEarnedPath = [token1Address, earnedAddress];
        PCSToEarnedPath = [PCSTokenAddress, earnedAddress];

        require(_controllerFee<10000,"_controllerFee should be less than 100%");
        controllerFee = _controllerFee;   

        feeAddress = _feeAddress; 
    }


    // Receives new deposits from user
    function deposit(address userAddress, uint256 _wantAmt)
        public
        StakingFarmOnly // piFarming Contract
        whenNotPaused
        returns (uint256)
    {
        IERC20Upgradeable(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        uint256 sharesAdded = _wantAmt;

        if (wantLockedTotal > 0) {
            sharesAdded = _wantAmt
                .mul(sharesTotal)
                .div(wantLockedTotal);
        }
        
        sharesTotal = sharesTotal.add(sharesAdded); 
        
        //or sharesAdded if fee applies

        _farm();

        emit DepositFor(userAddress, _wantAmt);
        
        return sharesAdded;
    }

    function farm() public nonReentrant {
        _farm();
    }

    function _farm() internal {
        uint256 wantAmt = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal.add(wantAmt);
        IERC20Upgradeable(wantAddress).safeIncreaseAllowance(PCSVaultAddress, wantAmt);
        IPCSVault(PCSVaultAddress).deposit(PCSPoolId, wantAmt);
    }


    function withdraw(address userAddress, uint256 _wantAmt)
        public
        StakingFarmOnly
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "_wantAmt <= 0");

        IPCSVault(PCSVaultAddress).withdraw(PCSPoolId, _wantAmt);

        uint256 wantAmt = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        
        sharesTotal = sharesTotal.sub(sharesRemoved);
        wantLockedTotal = wantLockedTotal.sub(_wantAmt);

        IERC20Upgradeable(wantAddress).safeTransfer(piFarmAddress, _wantAmt);
        emit WithdrawFor(userAddress, _wantAmt);

        return sharesRemoved;
    }

    

    function setGovOnly(bool _onlyGov) external onlyOwner{
        onlyGov=_onlyGov;
    }

    function setSlippage(uint256 _slippage) external onlyOwner{
        slippage = _slippage;
    }

    function estimateForSwapToken(address[] memory path, uint256 _amount) public view returns(uint256){

        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default     
        (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), _amount, path);
        
        return amounts[1].mul(slippageFactor).div(100);
    }

    // 1. Harvest farm tokens
    // 2. Converts farm tokens into want tokens
    // 3. Deposits want tokens

    function earn() public whenNotPaused {
        // require(isAutoComp, "!isAutoComp");
        if (onlyGov) {
            require(msg.sender == govAddress, "Not authorised");
        }

        // Harvest farm tokens  
        IPCSVault(PCSVaultAddress).withdraw(PCSPoolId, 0);
        
        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20Upgradeable(earnedAddress).balanceOf(address(this));

        earnedAmt = distributeFees(earnedAmt);
        // earnedAmt = buyBack(earnedAmt);

        if(earnedAmt>0){

            IERC20Upgradeable(earnedAddress).safeIncreaseAllowance(
                address(uniswapV2Router),
                earnedAmt
            );

            if (earnedAddress != token0Address) {
                // Swap half earned to token0
                uniswapV2Router
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    earnedAmt.div(2),
                    estimateForSwapToken(earnedToToken0Path, earnedAmt.div(2)),
                    earnedToToken0Path,
                    address(this),
                    block.timestamp + 60
                );
            }

            if (earnedAddress != token1Address) {
                // Swap half earned to token1
                uniswapV2Router
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    earnedAmt.div(2),
                    estimateForSwapToken(earnedToToken1Path, earnedAmt.div(2)),
                    earnedToToken1Path,
                    address(this),
                    block.timestamp + 60
                );
            }

            // Get want tokens, ie. add liquidity
            uint256 token0Amt = IERC20Upgradeable(token0Address).balanceOf(address(this));
            uint256 token1Amt = IERC20Upgradeable(token1Address).balanceOf(address(this));
            if (token0Amt > 0 && token1Amt > 0) {
                IERC20Upgradeable(token0Address).safeIncreaseAllowance(
                    address(uniswapV2Router),
                    token0Amt
                );
                
                IERC20Upgradeable(token1Address).safeIncreaseAllowance(
                    address(uniswapV2Router),
                    token1Amt
                );

                uniswapV2Router.addLiquidity(
                    token0Address,
                    token1Address,
                    token0Amt,
                    token1Amt,
                    100,
                    100,
                    address(this),
                    block.timestamp + 60
                );
            }

            lastEarnBlock = block.number;

            _farm();
        }

    }

    // function buyBack(uint256 _earnedAmt) internal returns (uint256) {
    //     if (buyBackRate <= 0) {
    //         return _earnedAmt;
    //     }

    //     uint256 buyBackAmt = _earnedAmt.mul(buyBackRate).div(buyBackRateMax);

    //     IERC20Upgradeable(earnedAddress).safeIncreaseAllowance(
    //         address(uniswapV2Router),
    //         buyBackAmt
    //     );

    //     uniswapV2Router
    //         .swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //         buyBackAmt,
    //         0,
    //         earnedToPiPath,
    //         buyBackAddress,
    //         block.timestamp + 60
    //     );

    //     return _earnedAmt.sub(buyBackAmt);
    // }

    function distributeFees(uint256 _earnedAmt) internal returns (uint256) {
        // Performance fee
        if (_earnedAmt > 0 && controllerFee > 0) {
            uint256 fee = _earnedAmt.mul(controllerFee).div(10000);
            if (fee>0) {
                IERC20Upgradeable(earnedAddress).safeTransfer(feeAddress, fee);
                _earnedAmt = _earnedAmt.sub(fee);
            }
        }        

        return _earnedAmt;
    }

    function convertDustToEarned() public whenNotPaused {
        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        uint256 token0Amt = IERC20Upgradeable(token0Address).balanceOf(address(this));
        if (token0Address != earnedAddress && token0Amt > 0) {
            IERC20Upgradeable(token0Address).safeIncreaseAllowance(
                address(uniswapV2Router),
                token0Amt
            );

            // Swap all dust tokens to earned tokens
            uniswapV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                token0Amt,
                estimateForSwapToken(token0ToEarnedPath,token0Amt),
                token0ToEarnedPath,
                address(this),
                block.timestamp + 60
            );
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amt = IERC20Upgradeable(token1Address).balanceOf(address(this));
        if (token1Address != earnedAddress && token1Amt > 0) {
            IERC20Upgradeable(token1Address).safeIncreaseAllowance(
                address(uniswapV2Router),
                token1Amt
            );

            // Swap all dust tokens to earned tokens
            uniswapV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                token1Amt,
                estimateForSwapToken(token1ToEarnedPath,token1Amt),
                token1ToEarnedPath,
                address(this),
                block.timestamp + 60
            );
        }

        // Converts PCS dust (if any) to earned tokens
        uint256 PCSAmt = IERC20Upgradeable(PCSTokenAddress).balanceOf(address(this));
        if (PCSTokenAddress != earnedAddress && PCSAmt > 0) {
            IERC20Upgradeable(PCSTokenAddress).safeIncreaseAllowance(
                address(uniswapV2Router),
                PCSAmt
            );

            // Swap all PCS dust tokens to earned tokens
            uniswapV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                PCSAmt,
                estimateForSwapToken(PCSToEarnedPath,PCSAmt),
                PCSToEarnedPath,
                address(this),
                block.timestamp + 60
            );
        }
        
    }


  function emergencyWithdrawFromPCS(address userAddress, uint256 _wantAmt)
        public
        onlyOwner
        returns (uint256)
    {
        require(_wantAmt > 0, "_wantAmt <= 0");

        IPCSVault(PCSVaultAddress).withdraw(PCSPoolId, _wantAmt);

        uint256 wantAmt = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        
        sharesTotal = sharesTotal.sub(sharesRemoved);
        wantLockedTotal = wantLockedTotal.sub(_wantAmt);

        IERC20Upgradeable(wantAddress).safeTransfer(msg.sender, _wantAmt);
        emit WithdrawFor(userAddress, _wantAmt);

        return sharesRemoved;
    }



    function pause() public {
        require(msg.sender == govAddress, "Not authorised");
        _pause();
    }

    function unpause() external {
        require(msg.sender == govAddress, "Not authorised");
        _unpause();
    }

    function setControllerFee(uint256 _controllerFee) public {
        require(msg.sender == govAddress, "Not authorised");
        controllerFee = _controllerFee;
    }

    // function setbuyBackRate(uint256 _buyBackRate) public {
    //     require(msg.sender == govAddress, "Not authorised");
    //     require(buyBackRate <= buyBackRateUL, "too high");
    //     buyBackRate = _buyBackRate;
    // }

    function setGov(address _govAddress) external onlyOwner{
        govAddress = _govAddress;
    }

    function setWaitTimeBeforeMigration(uint256 timeInSecs) external onlyOwner {
        waitMigTransferTime = timeInSecs;
    }

    function changeEarnedToken(address _earnedToken) external onlyOwner{
        earnedAddress = _earnedToken;
    }

    // have 8 hrs before migration
    function migratePCSVault(uint256 _PCSPoolId, address _PCSVaultAddress) public {
        require(msg.sender == govAddress, "!gov");
        require(_PCSVaultAddress!=address(0),"Vault address cannot be zero");
        migrateVault.newPCSPoolID= _PCSPoolId;
        migrateVault.newPCSVaultAddress=_PCSVaultAddress;
        migrateVault.timeMigration = block.timestamp.add(waitMigTransferTime);
    }

    // All funds are on PCSVaultAddress by this contract, withdraw and deposit to new PCSVaultAddress
    // incase pool id changes, just as a precaution
    function restakeAllToMigratedVault() public {
        require(msg.sender == govAddress, "!gov");

        require(migrateVault.newPCSVaultAddress!=address(0),"New Vault address cannot be zero");

        require(block.timestamp>=migrateVault.timeMigration, "Cannot start transfer before wait time is passed");
        require(block.timestamp<migrateVault.timeMigration.add(2 days) , "Migration time expired, should call this function within 2 days");

        // require(address(IPiStakingVaults(piFarmAddress).poolInfo(piVaultPoolid).wantToken)==IPCSVault(migrateVault.newPCSVaultAddress).poolInfo(migrateVault.newPCSPoolID).lpToken,"Pool id lptoken donot match");

        uint256 amount = IPCSVault(PCSVaultAddress).userInfo(PCSPoolId,address(this)).amount;

        IPCSVault(PCSVaultAddress).withdraw(PCSPoolId, amount);
        uint256 _bal = IERC20Upgradeable(wantAddress).balanceOf(address(this));

        IERC20Upgradeable(wantAddress).safeIncreaseAllowance(migrateVault.newPCSVaultAddress, _bal);
        IPCSVault(migrateVault.newPCSVaultAddress).deposit(migrateVault.newPCSPoolID, _bal);

        PCSPoolId=migrateVault.newPCSPoolID;
        PCSVaultAddress=migrateVault.newPCSVaultAddress;

        // reset so that it cannot be called again and again
        migrateVault.newPCSVaultAddress=address(0);

    }

     modifier StakingFarmOnly()
    {
        require (msg.sender == piFarmAddress, "piFarm address only");
        _;
    }


}