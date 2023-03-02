//SPDX-License-Identifier: MIT
/*

    THE MOST MEMEABLE, COMMUNITY DRIVEN TOKEN ON THE ETHEREUM NETWORK

    https://pepethereum.org/

    https://t.me/Pepethereum



*/
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
 
contract Pepethereum is ERC20, Ownable{
 
    IRouter public router;
    address public pair;
 
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;
 
 
    mapping (address => bool) public noFees;
    mapping (address => bool) public isBot;
 
    uint256 public swapThreshold = 10000 * 10**18;
    uint256 public maxTxAmount = 2000000 * 10**18;
    address public marketingWallet = 0x13e1b58056d128a1f69F9a9Bb4F72E9F82830723;
    address public devWallet = 0x13e1b58056d128a1f69F9a9Bb4F72E9F82830723;
 
    struct Taxes {
        uint128 marketing;
        uint128 dev;
    }
    Taxes public taxes = Taxes(1,1);
 
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
 
    constructor() ERC20("Pepethereum", "PEPETH") {
        _mint(msg.sender, 1e9 * 10 ** 18);
        noFees[msg.sender] = true;
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());
 
        router = _router;
        pair = _pair;
        noFees[address(this)] = true;
        noFees[marketingWallet] = true;
        noFees[devWallet] = true;
    }
 
 
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
 
        if(!noFees[sender] && !noFees[recipient] && !swapping){
            require(tradingEnabled, "Trading not active");
            require(!isBot[sender] && !isBot[recipient], "Bye Bye Bot");
            if(recipient == pair) require(amount <= maxTxAmount, "Exceeding maxTxAmount");
        }
 
        uint256 fee;
 
        if (swapping || noFees[sender] || noFees[recipient] || (sender != pair && recipient != pair)) fee = 0;
 
        else fee = amount * (taxes.dev + taxes.marketing) / 100;
 
        if (swapEnabled && !swapping && sender != pair && fee > 0) translateFees();
 
        super._transfer(sender, recipient, amount - fee);
        if(fee > 0) super._transfer(sender, address(this) ,fee);
 
    }
 
    function translateFees() private inSwap {
        if (balanceOf(address(this)) >= swapThreshold) {
            swapTokensForETH(swapThreshold);
 
            uint256 totalBalance = address(this).balance;
            uint256 totalTax = taxes.marketing + taxes.dev;
            uint256 marketingAmt = totalBalance * taxes.marketing / totalTax;
            if(marketingAmt > 0){
                (bool success, ) = payable(marketingWallet).call{value: marketingAmt}("");
                require(success, "Error sending eth");
            }
            uint256 devAmt = totalBalance * taxes.dev / totalTax;
            if(devAmt > 0){
                (bool success, ) = payable(devWallet).call{value: devAmt}("");
                require(success, "Error sending eth");
            }
        }
    }
 
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
 
        _approve(address(this), address(router), tokenAmount);
 
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
 
    }
 
    function enableTrading() external onlyOwner{
        tradingEnabled = true;
        swapEnabled = true;
    }
    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }
 
    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount * 10**18;
    }
    function setMaxTxAmount(uint256 amount) external onlyOwner{
         maxTxAmount = amount;
}
    function setTaxes(uint128 _dev, uint128 _marketing) external onlyOwner{
        taxes = Taxes(_marketing, _dev);
    }
 
    function updateMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet = newWallet;
    }
    function removeLimits() external onlyOwner{
        maxTxAmount = totalSupply();
    }
    function updateDevWallet(address newWallet) external onlyOwner{
        devWallet = newWallet;
    }
 
    function updatePair(address _pair) external onlyOwner{
        pair = _pair;
    }
 
    function updateNoFees(address _address, bool state) external onlyOwner {
        noFees[_address] = state;
    }
    function setBot(address[] calldata bots, bool status) external onlyOwner{
        uint256 size = bots.length;
        for(uint256 i; i < size;){
            isBot[bots[i]] = status;
            unchecked{ ++i; }
        }
    }
 
    function rescueTokens(address tokenAddress, uint256 amount) external onlyOwner{
        IERC20(tokenAddress).transfer(owner(), amount);
    }
 
    function rescueETH(uint256 weiAmount) external onlyOwner{
        (bool success, ) = payable(owner()).call{value: weiAmount}("");
        require(success, "Error sending eth");
    }
 
    // fallbacks
    receive() external payable {}
 
}