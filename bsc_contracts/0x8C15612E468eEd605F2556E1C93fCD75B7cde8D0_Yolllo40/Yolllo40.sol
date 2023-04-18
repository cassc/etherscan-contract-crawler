/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

//SPDX-License-Identifier: MIT


pragma solidity 0.8.0;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPancakeRouter01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// This contract keeps all Ether sent to it with no way
// to get it back.
contract Yolllo40 is ReentrancyGuard {
    address private systemWallet;
    address private owner;
    address private splitManager;
    uint8 public maxDestinations = 15;
    uint16 public percentsMultiplier = 100;
    IPancakeRouter02 private pancakeRouter;

    struct SwapDistributionDestination {
        address liqPairTokenTo;
        uint16 percent;
    }

    SwapDistributionDestination[] public swapDistributionDestination;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlySplitManager() {
        require(splitManager == msg.sender, "Ownable: caller is not the split manager");
        _;
    }

    constructor() {
        systemWallet = tx.origin;
        splitManager = tx.origin;
        owner = tx.origin;
        
        _setPancakeRouter(address(0x10ED43C718714eb63d5aA57B78B54704E256024E)); // ROUTER V2

        swapDistributionDestination.push(SwapDistributionDestination({
            liqPairTokenTo: address(0x68569056c9D8E93201270a22588632a138Fca324), // YOLLLO
            percent: 100 * percentsMultiplier
        }));
        validateDestinations(swapDistributionDestination);
    }

    function _setPancakeRouter(address _routerAddress) private {
        pancakeRouter = IPancakeRouter02(payable(_routerAddress));
    }

    function validateDestinations(SwapDistributionDestination[] memory _destinations) view internal {
        uint16 totalPercents = 0;
        require(_destinations.length <= maxDestinations, "Max destinations error. Provide destinations <= maxDestinations");
        for(uint16 i = 0; i < _destinations.length; i ++) {
            totalPercents += _destinations[i].percent;
            require(totalPercents <= 100 * percentsMultiplier, "Total percents must be <= 100");
        }
    }

    function setSystemWallet(address _newSystemWallet) external onlyOwner {
        systemWallet = _newSystemWallet;
    }

    function setSplitManager(address _new_splitManager) external onlyOwner {
        splitManager = _new_splitManager;
    }

    function processDestinations(ITRC20 token, SwapDistributionDestination[] memory _destinations, uint256 _total_amount, uint256 _invoice_id) private nonReentrant returns (uint256) {
        validateDestinations(_destinations);
        
        uint256 alreadyPaid = 0;
        address _tokenFromAddress = address(token);
        
        for (uint16 i = 0; i < _destinations.length; i ++) {
            uint256 toPay = _destinations[i].percent * _total_amount / 100 / percentsMultiplier;
            if (toPay > _total_amount - alreadyPaid) {
                toPay = _total_amount - alreadyPaid;
            }

            if (toPay == 0) {
                continue;
            }

            address[] memory path = new address[](2);

            path[0] = _tokenFromAddress;
            path[1] = _destinations[i].liqPairTokenTo;
            
            require(token.approve(address(pancakeRouter), toPay), "Approvement failed");
            pancakeRouter.swapExactTokensForTokens(toPay, 1, path, address(this), block.timestamp + 100);
            alreadyPaid += toPay;

            emit PaymentPartDistributed(_invoice_id, address(pancakeRouter), toPay, _tokenFromAddress, _destinations[i].liqPairTokenTo);

            if (_total_amount - alreadyPaid == 0) {
                break;
            }
        }

        emit PaymentDistributed(alreadyPaid, _total_amount - alreadyPaid);
        return _total_amount - alreadyPaid;
    }
    
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
    	(bool sent, bytes memory data) = _to.call{value: _amount}("");
        require(sent, "Failed to send");
    }
    
    function withdrawToken(address _token_address, address _to, uint256 _amount) external onlyOwner {
        require(_token_address != address(0), "Token TRC20 address is required");
        require(_amount > 0, "Amount is required");

        ITRC20 token = ITRC20(payable(_token_address));
        
        require(token.transfer(_to, _amount), "Payment with amount failed");
    }
    
    function split(address _token_address, uint256 _amount, uint256 _invoice_id, bool _sendFromThis) external onlySplitManager {
        require(_token_address != address(0), "Token TRC20 address is required");
        require(_amount > 0, "Amount is required");

        ITRC20 token = ITRC20(payable(_token_address));

        if (!_sendFromThis) {
            uint256 allowance = token.allowance(msg.sender, address(this));
        	require(allowance >= _amount, "Amount is not sufficient. Please, increase allowance and send request again");
            require(token.transferFrom(msg.sender, address(this), _amount), 'Transfer failed');
        }

        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Amount is not sufficient. Please, increase balance and send request again");

        emit PaymentReceived(msg.sender, _invoice_id, _amount);

        uint256 change = 0;
        change = processDestinations(token, swapDistributionDestination, _amount, _invoice_id);
        if (change > 0) {
            require(token.transfer(systemWallet, change), "Payment with change amount failed");
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event Received(address, address, uint);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event PaymentReceived(
        address indexed paymentSender,
        uint256 indexed invoiceId,
        uint256 indexed amount
    );
    event PaymentPartDistributed(
        uint256 indexed invoiceId,
        address indexed routerAddress,
        uint256 indexed amount,
        address addressTokenFrom,
        address addressTokenTo
    );

    event PaymentDistributed(
        uint256 amountDistributedTotal,
        uint256 amountChange
    );
}