//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.17;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function getUnpaidEarnings(address shareHolder) external view returns(uint256);
    function getClaimedDividends(address shareHolder) external view returns(uint256); 
    function claimDividend(address shareHolder, bool swapTo8Bit) external;
    function setRewardToken(address newToken) external;
    function getCurrentIndex() external view returns(uint256);
    function getShareHolderIndex(address shareHolder) external view returns(uint256);
    
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    IERC20 public rewardToken;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _rewardToken, address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _token = msg.sender;
        rewardToken = IERC20(_rewardToken);
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder, false);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() public payable {
        if(msg.value == 0){
            return;
        }
        address[] memory path = new address[](2);
        path[0] = IDEXRouter(router).WETH();
        path[1] = address(rewardToken);
        uint256 beforeBalance = rewardToken.balanceOf(address(this));
        IDEXRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value : msg.value}(
            0,
            path,
            address(this),
            block.timestamp            
        );
        uint256 receivedTokens = rewardToken.balanceOf(address(this)) - beforeBalance;
        totalDividends = totalDividends.add(receivedTokens);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(receivedTokens).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 maxIteration = shareholderCount > 5 ? 5 : shareholderCount;
        
        while(gasUsed < gas && iterations < maxIteration) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            distributeDividend(shareholders[currentIndex], false);

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function distributeDividend(address shareholder, bool swapTo8Bit) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            if(swapTo8Bit){
                uint256 eb = IERC20(_token).balanceOf(address(this));
                SwapTo8Bit(amount);
                uint256 received8Bit = IERC20(_token).balanceOf(address(this)) - eb;
                IERC20(_token).transfer(shareholder, received8Bit);
            }else{
                rewardToken.transfer(shareholder, amount);
            }
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend(address shareHolder, bool swapTo8Bit) external {
        distributeDividend(shareHolder, swapTo8Bit);
    }

    function getClaimedDividends(address shareHolder) external view returns(uint256) {
        return shares[shareHolder].totalRealised;
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function setRewardToken(address _newToken) public onlyToken{
        rewardToken = IERC20(_newToken);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    function getCurrentIndex() external view returns(uint256){
        return currentIndex;
    }

    function getShareHolderIndex(address shareHolder) external view returns(uint256){
        return shareholderIndexes[shareHolder];
    }

    function SwapTo8Bit(uint256 btcAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(rewardToken); 
        path[1] = IDEXRouter(router).WETH();
        uint256 beforeBalance = address(this).balance; 

        rewardToken.approve(address(router), ~uint256(0));
        IERC20(_token).approve(address(router), ~uint256(0));

        IDEXRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
           btcAmount,
           0,
           path,
           address(this),
           block.timestamp 
        );

        uint256 receivedTokens = address(this).balance - beforeBalance;

        if(receivedTokens > 0){
            address[] memory path2 = new address[](2);
            path2[0] = IDEXRouter(router).WETH();
            path2[1] = _token;
            IDEXRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value : receivedTokens}(
                0,
                path2,
                address(this),
                block.timestamp            
            );
        }
    }
    
    receive() external payable{
        if(msg.sender != address(router)){
            deposit();
        }
    }
}