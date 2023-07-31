import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';



contract Swapper is AccessControl{
    using SafeERC20 for IERC20;
    // Access control.
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
    
    // Declare an instance of the Uniswap V2 Router02 contract.
    IUniswapV2Router02 immutable public uniswapV2Router;
    IUniswapV2Pair immutable public uniswapV2Pair;

    address public ExternalTokenContract;
    address public vault;
    
    address immutable private WETH;

    // If the external Token is token0 or token1 in the pair.
    bool immutable private isToken0;

    constructor(address _uniswapV2Router, address _vault, address _externalTokenContract) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());

        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        // Get the wrapped native token address.
        WETH = uniswapV2Router.WETH();
        // Get the pair that will be used to swap the tokens.
        uniswapV2Pair = IUniswapV2Pair(IUniswapV2Factory(IUniswapV2Router02(_uniswapV2Router).factory()).getPair(_externalTokenContract, WETH));
        // Check if the external token is token0 or token1 in the pair.
        isToken0 = uniswapV2Pair.token0() == _externalTokenContract;

        vault = _vault;
        ExternalTokenContract = _externalTokenContract;
    }

    function setVault(address newVault) public {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            'must have operator role to change vault'
        );
        vault = newVault;
    }

    function setExternalTokenContract(address _externalTokenContract) public{
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            'must have operator role to change external contract token'
        );
        ExternalTokenContract = _externalTokenContract;
    }

    receive() external payable {
    }


    function swapAndLiquify(uint256 amount) external {
        address tokenContract = ExternalTokenContract;
        IUniswapV2Pair pair = uniswapV2Pair;
        require(msg.sender == tokenContract, "can only be called by the token contract");

        // Transfer tokens directly to the pair address, instead of to this contract and then swapping
        // from the contract. This saves us a good bunch of gas!
        IERC20(tokenContract).transferFrom(msg.sender, address(pair), amount);

        // Swap based off uniswap's router _swapSupportingFeeOnTransferTokens.
        uint amountInput;
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = isToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(tokenContract).balanceOf(address(pair)) - reserveInput;
        amountOutput = uniswapV2Router.getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = isToken0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

        // Withdraw WETH and send it to the vault.
        IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        (bool success,) = vault.call{value:address(this).balance}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    function transferToken(address token, uint amount, address receiver) public{
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            'must have operator role to transfer token'
        );
        IERC20 erc20 = IERC20(token);
        erc20.safeTransfer(receiver, amount);
    }

    function transferETHBalanceToVault() public{
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            'must have operator role to transfer token'
        );
        (bool success,) = vault.call{value:address(this).balance}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IUniswapV2Pair {
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}