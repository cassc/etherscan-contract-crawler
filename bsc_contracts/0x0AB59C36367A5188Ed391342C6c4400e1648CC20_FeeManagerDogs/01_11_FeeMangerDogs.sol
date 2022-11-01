// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface WethLike {

    function deposit() external payable;

    function withdraw(uint256) external;

}

contract FeeManagerDogs is Ownable {
    using SafeERC20 for IERC20;

    uint256 public dogsSwapThreshold = 50 ether;
    address public constant busdCurrencyAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant bnbCurrencyAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public dogsV2Address;

    address public vaultBUSDaddress = 0x68Bdc7b480d5b4df3bB086Cc3f33b0AEf52F7d55;
    address public vaultBNBaddress;
    
    uint256 public feeDistribution = 33;
    IUniswapV2Router02 public constant PancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address[] private pathDogsBusd;
    address[] private pathDogsBNB;

    receive() external payable {}

    constructor(address _dogsV2Address, address _vaultBNBaddress){
        dogsV2Address = _dogsV2Address;
        vaultBNBaddress = _vaultBNBaddress;
        _approveTokenIfNeeded(_dogsV2Address);

        pathDogsBusd = _createRoute(dogsV2Address, busdCurrencyAddress);
        pathDogsBNB = _createRoute(dogsV2Address, bnbCurrencyAddress);
    }

    // Modifiers
    modifier onlyDogsToken() {
        require(dogsV2Address == msg.sender, "dogsToken only");
        _;
    }

    // Events
    event DepositFeeConvertedToBUSD(address indexed inputToken, uint256 inputAmount, uint256 busdInstant, uint256 busdVault);
    event UpdateVault(address indexed vaultAddress);
    event UpdatePigPen(address indexed pigpenAddress);
    event UpdateDogsToken(address indexed dogsTokenAddress);
    event UpdateLiquidationThreshold(uint256 indexed threshold);

    // EXTERNAL FUNCTIONS
    function liquefyDogs() external {

        uint256 totalTokenBalance = IERC20(dogsV2Address).balanceOf(address(this));

        if (totalTokenBalance < dogsSwapThreshold){
            return;
        }
        
        uint256 busdVaultAllocation = (((totalTokenBalance * 1e4) * feeDistribution)/100) / 1e4; // 33% of dogs go to BUSD Vault
        uint256 bnbVaultAllocation  = totalTokenBalance - busdVaultAllocation; // 67% of dogs go to  BNB Vault

        convertTokenToBUSD(busdVaultAllocation);
        convertTokenToBNB(bnbVaultAllocation);

        _distributeDepositFeeBusd();
        _distributeDepositFeeBNB();

    }

    function _distributeDepositFeeBusd() internal {
        uint256 totalBusdBalance = IERC20(busdCurrencyAddress).balanceOf(address(this));
        IERC20(busdCurrencyAddress).transfer(vaultBUSDaddress, totalBusdBalance);

    }

    function _distributeDepositFeeBNB() internal {
        uint256 totalwBnbBalance = IERC20(bnbCurrencyAddress).balanceOf(address(this));
        WethLike(bnbCurrencyAddress).withdraw(totalwBnbBalance);
        uint256 totalBNBBalance = address(this).balance;
        payable (vaultBNBaddress).transfer(totalBNBBalance);

    }

   
    function _getBestDogsBUSDSwapPath(uint256 _amountDogs) internal returns (address[] memory){

        address[] memory pathDogs_BNB_BUSD = _createRoute3(dogsV2Address, bnbCurrencyAddress, busdCurrencyAddress);

        uint256[] memory amountOutBUSD = PancakeRouter.getAmountsOut(_amountDogs, pathDogsBusd);
        uint256[] memory amountOutBUSDviaBNB = PancakeRouter.getAmountsOut(_amountDogs, pathDogs_BNB_BUSD);

        if (amountOutBUSD[amountOutBUSD.length - 1] > amountOutBUSDviaBNB[amountOutBUSDviaBNB.length - 1]){ 
            return pathDogsBusd;
        }
        return pathDogs_BNB_BUSD;

    }

    function _getBestDogsBNBSwapPath(uint256 _amountDogs) internal returns (address[] memory){

        address[] memory pathDogs_BUSD_BNB = _createRoute3(dogsV2Address, busdCurrencyAddress, bnbCurrencyAddress);

        uint256[] memory amountOutBNB = PancakeRouter.getAmountsOut(_amountDogs, pathDogsBNB);
        uint256[] memory amountOutBNBviaBUSD = PancakeRouter.getAmountsOut(_amountDogs, pathDogs_BUSD_BNB);

        if (amountOutBNB[amountOutBNB.length - 1] > amountOutBNBviaBUSD[amountOutBNBviaBUSD.length-1]){ 
            return pathDogsBNB;
        }
        return pathDogs_BUSD_BNB;

    }

    function convertTokenToBUSD(uint256 amount) internal {

        address[] memory bestPath = _getBestDogsBUSDSwapPath(amount);

        // make the swap
        PancakeRouter.swapExactTokensForTokens(
            amount,
            0, // accept any amount  of tokens
            bestPath,
            address(this),
            block.timestamp
        );
    }

    function convertTokenToBNB(uint256 amount) internal {

        address[] memory bestPath = _getBestDogsBNBSwapPath(amount);

        // make the swap
        PancakeRouter.swapExactTokensForTokens(
            amount,
            0, // accept any amount of tokens
            bestPath,
            address(this),
            block.timestamp
        );
    }


    function _approveTokenIfNeeded(address token) private {
        if (IERC20(token).allowance(address(this), address(PancakeRouter)) == 0) {
            IERC20(token).safeApprove(address(PancakeRouter), type(uint256).max);
        }
    }

    function _createRoute(address _from, address _to) internal returns(address[] memory){
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        return path;
    }

    function _createRoute3(address _from, address _mid, address _to) internal returns(address[] memory){
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = _mid;
        path[2] = _to;
        return path;
    }

    // ADMIN FUNCTIONS
    function updateVaultAddress(address _vaultBUSDaddress, address _vaultBNBaddress) external onlyOwner {
        vaultBUSDaddress = _vaultBUSDaddress;
        vaultBNBaddress = _vaultBNBaddress;

        //        emit UpdateVault(_newVault);
    }

    function updateDogsTokenAddress(address _dogsToken) external onlyOwner {
        dogsV2Address = _dogsToken;
        _approveTokenIfNeeded(_dogsToken);
        pathDogsBusd = _createRoute(_dogsToken, busdCurrencyAddress);
        pathDogsBNB = _createRoute(_dogsToken, bnbCurrencyAddress);

        emit UpdateDogsToken(_dogsToken);
    }

    function updateFeeDistrib(uint256 distrib) external onlyOwner {
        feeDistribution = distrib;
    }


    function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateLiquidationThreshold(uint256 _threshold) external onlyOwner {
        dogsSwapThreshold = _threshold;

        emit UpdateLiquidationThreshold(_threshold);
    }


}