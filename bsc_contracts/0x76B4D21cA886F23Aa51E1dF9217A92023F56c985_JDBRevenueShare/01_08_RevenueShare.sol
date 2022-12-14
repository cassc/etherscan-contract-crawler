// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/interfaces/IDEXRouter.sol";
import "contracts/interfaces/IDEXFactory.sol";
import "contracts/interfaces/IDEXPair.sol";




contract JDBRevenueShare is Ownable {

    using SafeMath for uint256;
    uint256 public sendBNBAtAmount;
    uint256 public devShare;
    address public devWallet;
    address public marketingWallet;
    IDEXRouter public defaultDexRouter;
    IERC20 public JDBToken;

    event LogSetRouter(address router);
    event LogSetJDBToken(address _JDBToken);
    event LogSetDevShare(uint256 _devShare);
    event LogSetSendBNBAtAmount(uint256 _sendBNBAtAmount);
    event LogReceiveBNB(uint256 amount);
    event LogTransferBNB(address _devWallet, uint256 _amount);
    event LogBuyBack(uint256 _amount);
    event TransferTokensToMarketing(uint256 _amount);
    event LogSetDevWallet(address wallet);
    event LogSetMarketingWallet(address wallet);

    constructor(
        address _routerAddress, 
        uint256 _sendBNBAtAmount, 
        uint256 _devShare, 
        address _devWallet,
        address _marketingWallet, 
        address _JDBToken){
        require(_JDBToken != address(0), "JDBToken cannot be address 0");
        require(_routerAddress != address(0), "Router cannot be address 0");
        require(_devWallet != address(0), "Dev wallet cannot be address 0");
        require(_marketingWallet != address(0), "Marketing wallet cannot be address 0");
        IDEXRouter _dexRouter = IDEXRouter(_routerAddress);
        defaultDexRouter = _dexRouter;
        JDBToken = IERC20(_JDBToken);
        devShare = _devShare;
        devWallet = _devWallet;
        marketingWallet = _marketingWallet;
        sendBNBAtAmount = _sendBNBAtAmount;
    }

    receive() external payable {
        uint256 balance = address(this).balance;
        if(balance >= sendBNBAtAmount){
            uint256 _devShare = _calculateDevShareFromAmount(balance);
            uint256 buyBackAmount = balance.sub(_devShare);
            buyBack(buyBackAmount);
            uint256 tokens = JDBToken.balanceOf(address(this));
            if(tokens > 0){
                JDBToken.transfer(marketingWallet, tokens);
                emit TransferTokensToMarketing(tokens);
            }
            safeTransferBNB(devWallet, _devShare);
        }
        emit LogReceiveBNB(msg.value);
    }

    function setRouter(address _routerAddress) external onlyOwner{
        require(_routerAddress != address(defaultDexRouter), "Already set to this Value");
        require(_routerAddress != address(0), "Router cannot be address 0");
        IDEXRouter _dexRouter = IDEXRouter(_routerAddress);
        defaultDexRouter = _dexRouter;
        emit LogSetRouter(_routerAddress);
    }

    function setJDBToken(address _JDBToken) external onlyOwner{
        require(address(JDBToken) != _JDBToken, "Already set to this Value");
        require(_JDBToken != address(0), "JDBToken cannot be address 0");
       
        JDBToken = IERC20(_JDBToken);
        emit LogSetJDBToken(_JDBToken);
    }

    function setDevWallet(address _devWallet) external onlyOwner{
        require(devWallet != _devWallet, "Already set to this Value");
        require(_devWallet != address(0), "Dev wallet cannot be address 0");
       
        devWallet = _devWallet;
        emit LogSetDevWallet(_devWallet);
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner{
        require(marketingWallet != _marketingWallet, "Already set to this Value");
        require(_marketingWallet != address(0), "Marketing wallet cannot be address 0");
       
        marketingWallet = _marketingWallet;
        emit LogSetMarketingWallet(_marketingWallet);
    }

    function setDevShare(uint256 _devShare) external onlyOwner{
        require(devShare != _devShare, "Already set to this Value");
        require(devShare <= 10000, "10k is 100%");
       
        devShare = _devShare;

        emit LogSetDevShare(_devShare);
    }

    function setSendBNBAtAmount(uint256 _sendBNBAtAmount) external onlyOwner{
        require(sendBNBAtAmount != _sendBNBAtAmount, "Already set to this Value");
        require(_sendBNBAtAmount != 0, "Can't be 0");
       
        sendBNBAtAmount = _sendBNBAtAmount;
        emit LogSetSendBNBAtAmount(_sendBNBAtAmount);
    }

    function buyBack(uint256 amount) private{
        swapEthForTokens(amount);
        emit LogBuyBack(amount);
    }

    function swapEthForTokens(uint256 ethAmount) private {
        // generate the uniswap pair path of weth -> token`
        address[] memory path = new address[](2);
        path[0] = defaultDexRouter.WETH();
        path[1] = address(JDBToken);

        // make the swap
        defaultDexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of Tokens
            path,
            address(this),
            block.timestamp
        );
    }

    function _calculateDevShareFromAmount(uint256 _amount)
        public
        view
        returns (uint256)
    {
        require(_amount > 0, "Amount cannot be zero");
        require(devShare > 0,"devShare not set");

        return _amount.mul(devShare).div(10**4);
    }

    // Internal function to handle safe transfer
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success);
        emit LogTransferBNB(to, value);
    }


}