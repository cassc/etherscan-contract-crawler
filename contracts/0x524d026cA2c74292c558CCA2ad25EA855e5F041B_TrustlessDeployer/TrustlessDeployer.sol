/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITRUST {
    function setV2Pair(address V2Pair) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract TrustlessDeployer is Context, Ownable, ReentrancyGuard {
    event LiquidityClaimEnabled(uint256 amount);
    using SafeMath for uint256;
    IERC20 public trustlessToken;
    uint256 public softcapped = 2.5 ether;
    uint256 public hardcapped = 25 ether;
    bool public liquidityAdded;
    bool public distributeLiquidity; // allow 25% liquidity distribution to contributors
    bool public allowRefund;
    uint256 public liquidityTokensToDistribute;
    address private uniswapV2Pair;
    uint256 private hardcapMinDivisor = 1000;
    uint256 public minContributionPerWallet = hardcapped/hardcapMinDivisor; // limited to 0.1% of hard cap
    uint256 public maxContributionPerWallet = hardcapped/100; // limited to 1% of hard cap
    uint256 public finalLiquidity;
    uint256 public toDistributeTokens;
    uint256 public toPoolTokens;
    uint256 public toMarketing;
    IUniswapV2Router02 private uniswapV2Router;
    uint256 public addLiquidityAfter;
    uint256 public allowRefundAfter;
    uint256 public allowLiquidityClaimAfter;
    uint256 public allowMarketingAfter;
    mapping(address => uint256) private contribution;
    mapping(address => bool) private claimedTokens;
    mapping (address => bool) private claimedLiqtokens;
    address public marketingWallet;


    constructor (address trustlessToken_, uint256 toDistributeTokens_, uint256 toPoolTokens_, uint256 toMarketing_) {
        trustlessToken = IERC20(trustlessToken_);
        toDistributeTokens = toDistributeTokens_;
        toPoolTokens = toPoolTokens_;
        toMarketing = toMarketing_;
        addLiquidityAfter = block.timestamp + 48 hours;
        allowRefundAfter = block.timestamp + 72 hours;
        allowMarketingAfter = block.timestamp + 7 days;
    }

    function addLiquidity() external onlyOwner() {
        require(!liquidityAdded, 'Already added');
        require(address(this).balance >= softcapped, 'not enough ether');
        require(block.timestamp > addLiquidityAfter, 'addLiquidityAfter not reached yet');
        require(trustlessToken.balanceOf(address(this)) >= toDistributeTokens+toPoolTokens+toMarketing);

        finalLiquidity = address(this).balance;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        trustlessToken.approve(address(uniswapV2Router),toPoolTokens);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(trustlessToken), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(trustlessToken),toPoolTokens,0,0,address(this),block.timestamp);
        ITRUST(address(trustlessToken)).setV2Pair(uniswapV2Pair);
        allowLiquidityClaimAfter = block.timestamp + 30 days;
        liquidityAdded = true;
    }

    // crowd funding related function below for contributions and claim rewards
    function claimTokens() external nonReentrant() {
        require(liquidityAdded);
        require(!claimedTokens[_msgSender()], 'already claimed');
        address contributor = _msgSender();
        uint256 tokensToTransfer = claimAvailable(contributor);
        require(tokensToTransfer > 0, 'no tokens');
        claimedTokens[contributor] = true;
        trustlessToken.transfer(contributor, tokensToTransfer);
    }

    function claimAvailable(address contributor) public view returns(uint256) {
        if(!liquidityAdded) return 0;
        if(claimedTokens[contributor]) return 0;
        uint256 contributed = contribution[contributor];
        uint256 finalShare = contributed.mul(hardcapMinDivisor).div(finalLiquidity);
        uint256 tokensToTransfer = toDistributeTokens.mul(finalShare).div(hardcapMinDivisor);
        return tokensToTransfer;
    }

    function claimLiquidity() external nonReentrant() {
        require(block.timestamp > allowLiquidityClaimAfter, 'wait till 30 days after liquidity');
        require(distributeLiquidity, 'not open');
        require(!claimedLiqtokens[_msgSender()]);
        address contributor = _msgSender();
        uint256 liqtokensToTransfer = liquidityClaimAvailable(contributor);
        require(liqtokensToTransfer > 0, 'no tokens');
        claimedLiqtokens[contributor] = true;
        IERC20(uniswapV2Pair).transfer(contributor, liqtokensToTransfer);
    }

    function liquidityClaimAvailable(address contributor) public view returns(uint256) {
        if(!distributeLiquidity || !liquidityAdded) return 0;
        if(claimedLiqtokens[contributor]) return 0;
        uint256 contributed = contribution[contributor];
        uint256 finalShare = contributed.mul(hardcapMinDivisor).div(finalLiquidity);
        uint256 liqtokensToTransfer = liquidityTokensToDistribute.mul(finalShare).div(hardcapMinDivisor);
        return liqtokensToTransfer;
    }

    function yourContribution(address contributor) public view returns(uint256){
        uint256 contributed = contribution[contributor];
        return contributed;
    }

    function claimRefund() external nonReentrant() {
        require(block.timestamp >= allowRefundAfter && !liquidityAdded);
        address contributor = _msgSender();
        uint256 ethToRefund =  contribution[msg.sender];
        require(ethToRefund > 0);
        contribution[msg.sender] = 0;
        payable(contributor).transfer(ethToRefund);
    }
    //end of contribution related functions

    //marketing wallet claim token
    function claimMarketingFund() external {
        require(_msgSender() == marketingWallet, 'forbid');
        require(block.timestamp >= allowMarketingAfter, 'allowMarketingAfter');
        trustlessToken.transfer(marketingWallet, toMarketing);
    }

    //enable liquidity token distribution (25%) functions for owner only
    function allowLiquidityDistribution(bool allowFullrefund) external onlyOwner(){
        require(!distributeLiquidity);
        distributeLiquidity = true;
        liquidityTokensToDistribute = (allowFullrefund)?IERC20(uniswapV2Pair).balanceOf(address(this)):IERC20(uniswapV2Pair).balanceOf(address(this)).div(4); // 25% share
        emit LiquidityClaimEnabled(liquidityTokensToDistribute);
    }

    function disableLiquidityDistribution() external onlyOwner(){
        distributeLiquidity = false;
        liquidityTokensToDistribute = 0;
        emit LiquidityClaimEnabled(liquidityTokensToDistribute);
    }

    function setMarketingWallet(address marketingWallet_) external onlyOwner() {
        marketingWallet = marketingWallet_;
    }

    receive() external payable {
        require(msg.value >= minContributionPerWallet, 'send more than minContributionPerWallet');
        require((contribution[msg.sender]+msg.value) <= maxContributionPerWallet, 'send less than maxContributionPerWallet');
        require(address(this).balance <= hardcapped, 'hardcap reached');
        contribution[msg.sender] += msg.value;
    }
}