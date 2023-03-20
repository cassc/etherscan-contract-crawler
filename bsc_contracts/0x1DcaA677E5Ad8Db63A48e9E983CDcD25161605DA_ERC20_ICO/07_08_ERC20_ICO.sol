// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../IERC20.sol";
import "../SafeERC20.sol";
import "../Pancakeswap/IPancakeRouter01.sol";
import "hardhat/console.sol";

/*===================================================
    OpenZeppelin Contracts (last updated v4.5.0)
=====================================================*/

contract ERC20_ICO is Ownable {
    using SafeERC20 for IERC20;

    // IYA token
    IERC20 private baseToken;
    IPancakeRouter01 private pancakeRouter;

    address public pancakeRouterAddress;
    address[] public paymentTokens;
    address public USDT_ADDRESS;
    mapping (address => bool) public isPaymentToken;
    uint8 public paymentTokenCount;

    // time to start claim.
    // uint256 public releaseTime = 0; // Thu Apr 14 2022 00:00:00 UTC
    bool public isAlive = true;
    uint256 public currentCap = 0;
    uint64 public investors = 0;

    // wallet to withdraw
    address public wallet;

    // presale and airdrop program with refferals
    uint256 private salePrice = 3; //3c per token

    /**
     * @dev Initialize with token address and round information.
     */
    constructor (address _baseToken, address _usdt, address router) Ownable() {
        wallet = msg.sender;
        baseToken = IERC20(_baseToken);
        USDT_ADDRESS = _usdt;
        pancakeRouterAddress = router;
        pancakeRouter = IPancakeRouter01(pancakeRouterAddress);
        
        isAlive = true;
        salePrice = 3;

        paymentTokens.push(USDT_ADDRESS);
        isPaymentToken[USDT_ADDRESS] = true;
        paymentTokenCount = 1;
    }
    
    receive() payable external {}
    fallback() payable external {}

    function setToken(address _baseToken) public onlyOwner {
        require(_baseToken != address(0), "presale-err: invalid address");
        baseToken = IERC20(_baseToken);
    }

    function addPaymentToken(address _stableCoin) public onlyOwner {
        require(isPaymentToken[_stableCoin] == false, "Already added");
        paymentTokens.push(_stableCoin);
        isPaymentToken[_stableCoin] = true;
        paymentTokenCount = 1;
    }

    function removePaymentToken(address _stableCoin) public onlyOwner {
        require(isPaymentToken[_stableCoin], "Token not registered");
        isPaymentToken[_stableCoin] = false;
    }

    function setPrice(uint256 price) public onlyOwner {
        require(price > 0, "Invalid price");
        salePrice = price;
    }


    function getStatus() public view returns(uint256 , uint64){
        return (currentCap, investors);
    }

    function stopICO() public onlyOwner {
        isAlive = false;
    }

    /**
     * @dev Withdraw  baseToken token from this contract.
     */
    function withdrawTokens(address _token) external onlyOwner {
        if(_token == address(0)) {
            payable(wallet).transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(wallet, IERC20(_token).balanceOf(address(this)));
        }
    }

    /**
     * @dev Set wallet to withdraw.
     */
    function setWalletReceiver(address _newWallet) external onlyOwner {
        wallet = _newWallet;
    }

    function getEstimations(uint256 amount) public view returns (uint256) {
        return amount * 100 / salePrice;
    }

    function swapToUsdt(address token, uint256 amount) public returns(uint) {
        if(token == USDT_ADDRESS) return amount;
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = USDT_ADDRESS;
        IERC20 _tokenContract = IERC20(token);
        _tokenContract.approve(pancakeRouterAddress, amount);
        uint[] memory ans = pancakeRouter.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp + 1000);
        return ans[1];
    }

    function getEstimatedUSD(address token, uint256 amount) public view returns(uint) {
        if(token == USDT_ADDRESS) return amount;
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = USDT_ADDRESS;
        uint[] memory ans = pancakeRouter.getAmountsOut(amount, path);
        return ans[1];
    }

    function buy(uint256 tokenAmount, address _paymentCoin) public returns (bool) {
        uint usdAmount = getEstimatedUSD(_paymentCoin, tokenAmount);

        require(isAlive && usdAmount >= 1000000000000000000 * 100, "Too small!");
        require(isPaymentToken[_paymentCoin], "Token is not acceptable!");

        IERC20 stableCoin = IERC20(_paymentCoin);
      
        stableCoin.safeTransferFrom(msg.sender, address(this), tokenAmount);
        
        usdAmount = swapToUsdt(_paymentCoin, tokenAmount);

        uint256 _token = usdAmount * 100 / salePrice;
        baseToken.safeTransfer(msg.sender, _token);
        currentCap += usdAmount;
        investors ++;

        return true;
    }
}