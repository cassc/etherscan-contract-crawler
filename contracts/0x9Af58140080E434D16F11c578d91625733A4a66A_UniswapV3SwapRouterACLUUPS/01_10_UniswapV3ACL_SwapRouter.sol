// 61f5a666f1e2638ad41e1350907deced9dabdb64
pragma solidity 0.8.17;
import "UUPSUpgradeable.sol";
import "OwnableUpgradeable.sol";


interface IOracle {
    function getUSDValue(address _token, uint256 _amount) external view returns(uint256) ;
}



contract UniswapV3SwapRouterACLUUPS is OwnableUpgradeable, UUPSUpgradeable {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct SwapInToken {
        bytes32 role;
        address token; 
        bool tokenStatus;
    }

    struct SwapOutToken {
        bytes32 role;
        address token; 
        bool tokenStatus;
    }

    address public safeAddress;
    address public safeModule;
    mapping(bytes32 => mapping (address => bool)) public swapInTokenWhitelist;
    mapping(bytes32 => mapping (address => bool)) public swapOutTokenWhitelist;
    IOracle public oracle;
    mapping(bytes32 => uint256) public role_maxSlippagePercent;
    uint256 private constant SLIPPAGE_BASE = 10000;

    bool public isCheckSwapToken = true;
    bool public isCheckRoleSlippage = true;

    bytes32 private _checkedRole = hex"01";
    uint256 private _checkedValue = 1;
    string public constant NAME = "UniswapSwapRouterACL";
    uint public constant VERSION = 1;

    //v3 swap router related
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;
    address private constant EMPTY_ADDRESS = address(0);

    function initialize(address _safeAddress, address _safeModule) initializer public {
        __UniswapV3_acl_init(_safeAddress, _safeModule);
    }

    function __UniswapV3_acl_init(address _safeAddress, address _safeModule) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __UniswapV3_acl_init_unchained(_safeAddress, _safeModule);
    }

    function __UniswapV3_acl_init_unchained(address _safeAddress, address _safeModule) internal onlyInitializing {
        require(_safeAddress != address(0), "Invalid safe address");
        require(_safeModule!= address(0), "Invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;


        // make the given safe the owner of the current acl.
        _transferOwnership(_safeAddress);
    }

    // Safe contract setting functions

    function setSwapInToken(bytes32 _role, address _token, bool _tokenStatus) external onlySafe returns (bool){   // sell
        require(swapInTokenWhitelist[_role][_token] != _tokenStatus, "swapIntoken tokenStatus existed");
        swapInTokenWhitelist[_role][_token] = _tokenStatus;
        return true;
    }

    function setSwapInTokens(SwapInToken[] calldata _swapInToken) external onlySafe returns (bool){    
        for (uint i=0; i < _swapInToken.length; i++) { 
            swapInTokenWhitelist[_swapInToken[i].role][_swapInToken[i].token] = _swapInToken[i].tokenStatus;
        }
        return true;
    }

    function setSwapOutToken(bytes32 _role, address _token, bool _tokenStatus) external onlySafe returns (bool){   // buy
        require(swapOutTokenWhitelist[_role][_token] != _tokenStatus, "swapIntoken tokenStatus existed");
        swapOutTokenWhitelist[_role][_token] = _tokenStatus;
        return true;
    }

    function setSwapOutTokens(SwapOutToken[] calldata _swapOutToken) external onlySafe returns (bool){    
        for (uint i=0; i < _swapOutToken.length; i++) { 
            swapOutTokenWhitelist[_swapOutToken[i].role][_swapOutToken[i].token] = _swapOutToken[i].tokenStatus;
        }
        return true;
    }

    function setOracle(address _oracle) external onlySafe{
        oracle = IOracle(_oracle);
    }

    function setRoleSlippage(bytes32 _role, uint256 _precentage) external onlySafe {
        role_maxSlippagePercent[_role] = _precentage;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}


    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    function setSwapCheckMethod(bool _isCheckSwapToken,bool _isCheckRoleSlippage) external onlySafe returns (bool){
        isCheckSwapToken = _isCheckSwapToken;
        isCheckRoleSlippage = _isCheckRoleSlippage;
        return true;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    modifier onlySafe() {
        require(safeAddress == msg.sender, "Caller is not the safe");
        _;
    }

    function check(
        bytes32 _role,
        uint256 _value,
        bytes calldata data
    ) external onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success, ) = address(this).staticcall(data);
        _checkedRole = hex"01";
        _checkedValue = 1;
        return success;
    }

    //ACL functions 
    function multicall(bytes[] calldata data) external onlySelf {
        for(uint256 i = 0; i < data.length; i++){
            (bool success,) = address(this).staticcall(data[i]);
            require(success, "Failed in multicall check");
        }

    }


    function slippageCheck(address token0, address token1, uint256 amountIn, uint256 amountOut) internal view{
        uint256 valueInput = oracle.getUSDValue(token0, amountIn);
        uint256 valueOutput = oracle.getUSDValue(token1, amountOut);
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - role_maxSlippagePercent[_checkedRole]) / SLIPPAGE_BASE, "Slippage is too high");
    }

    function swapInOutTokenCheck(address _inToken, address _outToken) internal {  
        require(swapInTokenWhitelist[_checkedRole][_inToken],"token not allowed");
        require(swapOutTokenWhitelist[_checkedRole][_outToken],"token not allowed");
    }

    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function decodeFirstPool(bytes memory path, uint256 _start)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = toAddress(path, _start);
        fee = toUint24(path, _start + ADDR_SIZE);
        tokenB = toAddress(path, _start + NEXT_OFFSET);
    }

    function decodePath(bytes memory path)
        internal
        view
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        require(path.length >= POP_OFFSET, "Invalid path");
        bool _hasMultiplePools = hasMultiplePools(path);
        if (!_hasMultiplePools) {
            return decodeFirstPool(path, 0);
        }

        tokenA = EMPTY_ADDRESS;
        tokenB = EMPTY_ADDRESS;
        fee = 0;

        uint256 start = 0;
        while (true) {
            if (start + NEXT_OFFSET > path.length) {
                break;
            }
            (address _tokenA, address _tokenB, uint24 _fee) = decodeFirstPool(path, start);
            if (tokenA == EMPTY_ADDRESS) {
                tokenA = _tokenA;
            }
            tokenB = _tokenB;
            fee = fee + _fee;
            start = start + NEXT_OFFSET;
        }
    }


    
    //swapRouter
    function sweepToken(address,uint256,address recipient) external onlySelf {
        // sweepToken 位于每个流程的最后面，所以不需要对token 进行限制
        require(recipient == safeAddress, "Not safe address");
     }

    function unwrapWETH9(uint256, address recipient) external onlySelf {
        require(recipient == safeAddress, "Not safe address");
     }


    function check_recipient(address _recipient) internal{
        require(_recipient == safeAddress, "Not safe address");
    }

    
    function exactInputSingle(ExactInputSingleParams calldata params) external onlySelf {
        //notice: uniswap V3 swap router 允许 params.amountIn == 0, 表明直接使用合约内的代币余额进行兑换
        //由于存在滑点检查，所以不额外做amountIn 不为0的检查
        if(isCheckSwapToken){
            swapInOutTokenCheck(params.tokenIn, params.tokenOut);
        }
        if(isCheckRoleSlippage){
            slippageCheck(params.tokenIn, params.tokenOut, params.amountIn, params.amountOutMinimum);
        }
        check_recipient(params.recipient);
    }

    function exactInput(ExactInputParams memory params) external onlySelf {
        (address tokenIn, address tokenOut,) = decodePath(params.path);
        if(isCheckSwapToken){
            swapInOutTokenCheck(tokenIn, tokenOut);
        }
        if(isCheckRoleSlippage){
            slippageCheck(tokenIn, tokenOut, params.amountIn, params.amountOutMinimum);  
        }
        check_recipient(params.recipient); 
        
    }

    function exactOutput(ExactOutputParams calldata params) external  onlySelf {
        (address tokenIn, address tokenOut,) = decodePath(params.path);
        if(isCheckSwapToken){
            swapInOutTokenCheck(tokenIn, tokenOut);
        }
        check_recipient(params.recipient); 
        if(isCheckRoleSlippage){
            slippageCheck(tokenIn, tokenOut, params.amountInMaximum, params.amountOut);
        }
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external  onlySelf {
        if(isCheckSwapToken){
            swapInOutTokenCheck(params.tokenIn, params.tokenOut);
        }
        check_recipient(params.recipient);
        // check swap slippage
        if(isCheckRoleSlippage){
            slippageCheck(params.tokenIn, params.tokenOut, params.amountInMaximum, params.amountOut);
        }
    }

    function swapExactTokensForTokens(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to) external onlySelf{
        address tokenIn = path[0];
        address tokenOut = path[path.length-1];
        if(isCheckSwapToken){
            swapInOutTokenCheck(tokenIn, tokenOut);
        }
        check_recipient(to);
        if(isCheckRoleSlippage){
            slippageCheck(tokenIn, tokenOut, amountIn, amountOutMin);
        }
    }  

    function swapTokensForExactTokens(uint256 amountOut,uint256 amountInMax,address[] calldata path,address to) external onlySelf{
        address tokenIn = path[0];
        address tokenOut = path[path.length-1];
        if(isCheckSwapToken){
            swapInOutTokenCheck(tokenIn, tokenOut);
        }
        check_recipient(to);
        if(isCheckRoleSlippage){
            slippageCheck(tokenIn, tokenOut, amountInMax, amountOut);
        }
    }


    function refundETH() external onlySelf{}
}