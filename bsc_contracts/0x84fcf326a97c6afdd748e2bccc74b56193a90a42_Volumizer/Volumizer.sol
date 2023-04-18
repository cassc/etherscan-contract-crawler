/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
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
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface AIVolumizer {
    function setMaxAmount(uint256 max) external;
    function volumeTokenTransaction(uint256 percent) external;
    function swapGasBalance(uint256 percent) external;
    function swapTokenBalance(uint256 percent) external;
    function setParameters(address _token) external;
    function setIsAuthorized(address _address) external;
    function rescueHubETH(address receiver, uint256 percent) external;
    function rescueHubERC20(address token, address receiver, uint256 percent) external;
    function amountTotalPurchased() external view returns (uint256);
    function amountTotalSold() external view returns (uint256);
    function totalVolume() external view returns (uint256);
    function lastVolumeTimestamp() external view returns (uint256);
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
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract Volumizer is AIVolumizer, Ownable {
    using SafeMath for uint256;
    
    mapping (address => bool) public isAuthorized;
    modifier authorized() {require(isAuthorized[msg.sender], "!TOKEN"); _;}
    
    IERC20 tokenContract;
    IRouter router;
    address deployer;
    
    uint256 private denominator = 10000;
    uint256 public maxAmount = 100000000000000 * (10 ** 18);

    uint256 private _amountTotalPurchased;
    uint256 private _amountTotalSold;
    uint256 private _totalVolumeTokens;
    uint256 private _lastVolumeTimestamp;

    receive() external payable {}
    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        router = _router;
        deployer = msg.sender;
        isAuthorized[msg.sender] = true; 
        isAuthorized[address(this)] = true;
    }

    function setParameters(address _token) external override authorized {
        tokenContract = IERC20(_token); isAuthorized[_token] = true;
    }

    function setDeployer(address _deployer) external authorized {
        deployer = _deployer;
    }
    
    function setIsAuthorized(address _address) external override authorized {
        isAuthorized[_address] = true;
    }

    function setMaxAmount(uint256 max) external override authorized {
        maxAmount = max;
    }
    
    function rescueERC20(address token, address recipient, uint256 amount) external authorized {
        IERC20(token).transfer(recipient, amount);
    }

    function rescueHubERC20(address token, address receiver, uint256 percent) external override authorized {
        uint256 amount = IERC20(token).balanceOf(address(this)).mul(percent).div(uint256(100));
        IERC20(token).transfer(receiver, amount);
    }

    function rescueETH(address receiver, uint256 amount) external authorized {
        payable(receiver).transfer(amount);
    }

    function rescueHubETH(address receiver, uint256 percent) external override authorized {
        uint256 amount = address(this).balance.mul(percent).div(uint256(100));
        payable(receiver).transfer(amount);
    }

    function swapTokenBalance(uint256 percent) external override authorized {
        uint256 amount = tokenContract.balanceOf(address(this)).mul(percent).div(denominator);
        swapTokensForETH(amount);
    }

    function swapGasBalance(uint256 percent) external override authorized {
        uint256 amount = address(this).balance.mul(percent).div(denominator);
        swapETHForTokens(amount);
    }

    function amountTotalPurchased() external override view returns (uint256) {
        return _amountTotalPurchased;
    }

    function amountTotalSold() external override view returns (uint256) {
        return _amountTotalSold;
    }

    function totalVolume() external override view returns (uint256) {
        return _totalVolumeTokens;
    }

    function lastVolumeTimestamp() external override view returns (uint256) {
        return _lastVolumeTimestamp;
    }

    function volumeTokenTransaction(uint256 percent) public override authorized {
        uint256 initialETH = address(this).balance;
        uint256 volumeTokens = tokenContract.balanceOf(address(this)).mul(percent).div(denominator);
        if(volumeTokens > maxAmount){volumeTokens = maxAmount;}
        _amountTotalSold = _amountTotalSold.add(volumeTokens);
        swapTokensForETH(volumeTokens);
        uint256 initialTokens = tokenContract.balanceOf(address(this));
        uint256 amountETH = address(this).balance.sub(initialETH);
        swapETHForTokens(amountETH);
        uint256 purchasedTokens = tokenContract.balanceOf(address(this)).sub(initialTokens);
        _amountTotalPurchased = _amountTotalPurchased.add(purchasedTokens);
        _totalVolumeTokens = _totalVolumeTokens.add(purchasedTokens).add(volumeTokens);
        _lastVolumeTimestamp = block.timestamp;
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(tokenContract);
        path[1] = router.WETH();
        tokenContract.approve(address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function swapETHForTokens(uint256 amountETH) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(tokenContract);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(
            0,
            path,
            address(this),
            block.timestamp);
    }
}