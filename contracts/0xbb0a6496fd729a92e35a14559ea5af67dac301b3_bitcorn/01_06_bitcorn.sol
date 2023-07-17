// SPDX-License-Identifier: MIT

/**

Bitcorn4life baby. Never forget it. No socials, we’ll push from behind. Enjoy the ride. Buy bitcorn, shill bitcorn.

**/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}


library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract bitcorn is ERC20, Ownable{  
    using Address for address payable;

    mapping (address user => bool status) public exemptFee;
    mapping (address user => bool status) public isBlacklisted;

    IRouter public router;
    address public pair;
    address public marketingWallet;

    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;

    uint256 public swapThreshold = 1_000_000 * 10**9;    //treshold
    uint256 public maxWallet = 21_000_000 * 10**9;    //maxwallet

    struct Taxes {
        uint128 buy;
        uint128 sell;
    }

    Taxes public taxes = Taxes(0, 0);  //taxes

    modifier mutexLock() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }

    constructor(address _router, address _marketingWallet, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 21_000_000 * 10 ** 9);  //totalsupply

        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());

        marketingWallet = _marketingWallet;

        exemptFee[address(this)] = true;
        exemptFee[msg.sender] = true;
        exemptFee[_marketingWallet] = true;

        _approve(address(this), _router, type(uint256).max);
    }

    function decimals() public override pure returns(uint8){
        return 9;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        if (swapping || exemptFee[sender] || exemptFee[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }

        else{
            require(tradingEnabled, "Trading not enabled");
            require(!isBlacklisted[sender] && !isBlacklisted[recipient], "Blacklisted address");
            if (recipient != pair) {
                require(balanceOf(recipient) + amount <= maxWallet, "Wallet limit exceeded");
            }
        }

        uint256 fees;

        if(recipient == pair) fees = amount * taxes.sell / 100;
        else if(sender == pair) fees = amount * taxes.buy / 100;

        if (swapEnabled && sender != pair) swapFees();

        super._transfer(sender, recipient, amount - fees);
        if(fees > 0){
            super._transfer(sender, address(this), fees);
        }
    }

    function swapFees() private mutexLock {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(swapThreshold);
            uint256 deltaBalance = address(this).balance - initialBalance;
            payable(marketingWallet).sendValue(deltaBalance);
        }
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function setSwapEnabled(bool status) external onlyOwner {
        swapEnabled = status;
    }

    function setSwapTreshhold(uint256 amount) external onlyOwner {
        swapThreshold = amount * 10 ** decimals();
    }

    function setTaxes(uint128 _buyTax, uint128 _sellTax) external onlyOwner {
        taxes = Taxes(_buyTax, _sellTax);
    }

    function setRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
        _approve(address(this), address(newRouter), type(uint256).max);
    }

    function setTradingStatus(bool status) external onlyOwner{
        tradingEnabled = status;
        swapEnabled = status;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner{
        maxWallet = _maxWallet * 10 ** decimals();
    }

    function setMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet = newWallet;
    }

    function setExemptFee(address _address, bool state) external onlyOwner {
        exemptFee[_address] = state;
    }

    function bulkExemptFee(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            exemptFee[accounts[i]] = state;
        }
    }

    function setBlacklist(address[] memory accounts, bool status) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            isBlacklisted[accounts[i]] = status;
        }
    }

    function rescueETH(uint256 weiAmount) external onlyOwner{
        payable(msg.sender).sendValue(weiAmount);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner{
        IERC20(tokenAdd).transfer(msg.sender, amount);
    }

    // fallbacks
    receive() external payable {}

}