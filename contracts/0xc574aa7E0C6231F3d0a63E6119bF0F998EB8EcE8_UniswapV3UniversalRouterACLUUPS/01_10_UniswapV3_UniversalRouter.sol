// 34d4f7d15d02c6ce19219935a5a19d5f5cf20a2d
pragma solidity 0.8.17;
import "UUPSUpgradeable.sol";
import "OwnableUpgradeable.sol";

interface IOracle {
    function getUSDValue(address _token, uint256 _amount) external view returns(uint256);
}

contract UniswapV3UniversalRouterACLUUPS is OwnableUpgradeable, UUPSUpgradeable {

	struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
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
    
    IOracle public oracle;
    mapping(bytes32 => uint256) public role_maxSlippagePercent;
    address public weth;
    address public universal_router;
    mapping(bytes32 => mapping (address => bool)) public swapInTokenWhitelist;
    mapping(bytes32 => mapping (address => bool)) public swapOutTokenWhitelist;
    bytes32 private _checkedRole = hex"01";
    uint256 private _checkedValue = 1;
    string public constant NAME = "UniswapUniversalACL";
    uint public constant VERSION = 1;
    uint256 private constant SLIPPAGE_BASE = 10000;

	//universal router setting
	address constant universal_router_map = address(2);
	uint256 constant V3_SWAP_EXACT_IN = 0x00;
    uint256 constant V3_SWAP_EXACT_OUT = 0x01; 
    uint256 constant V2_SWAP_EXACT_IN = 0x08;
    uint256 constant V2_SWAP_EXACT_OUT = 0x09;
    uint256 constant WRAP_ETH = 0x0b;
    uint256 constant UNWRAP_WETH = 0x0c;
    uint256 constant PERMIT2_PERMIT = 0x0a;
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;
    address private constant EMPTY_ADDRESS = address(0);

	function initialize(address _safeAddress, address _safeModule) initializer public {
        __UniswapV3Universal_router_acl_init(_safeAddress, _safeModule);
    }

    function __UniswapV3Universal_router_acl_init(address _safeAddress, address _safeModule) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __UniswapV3Universal_router_acl_init_unchained(_safeAddress, _safeModule);
    }

    function __UniswapV3Universal_router_acl_init_unchained(address _safeAddress, address _safeModule) internal onlyInitializing {
        require(_safeAddress != address(0), "Invalid safe address");
        require(_safeModule!= address(0), "Invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;


        // make the given safe the owner of the current acl.
        _transferOwnership(_safeAddress);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

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
            swapInTokenWhitelist[_swapOutToken[i].role][_swapOutToken[i].token] = _swapOutToken[i].tokenStatus;
        }
        return true;
    }

    function setOracle(address _oracle) external onlySafe{
        oracle = IOracle(_oracle);
    }

    function setRoleSlippage(bytes32 _role, uint256 _precentage) external onlySafe {
        role_maxSlippagePercent[_role] = _precentage;
    }

    function setWETH(address _weth) external onlySafe{
        weth = _weth;
    }

    function setUniversaslRouter(address _router) external onlySafe{
        universal_router = _router;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
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

    function slippageCheck(address token0, address token1, uint256 amountIn, uint256 amountOut) internal view{
        uint256 valueInput = oracle.getUSDValue(token0, amountIn);
        uint256 valueOutput = oracle.getUSDValue(token1, amountOut);
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - role_maxSlippagePercent[_checkedRole]) / SLIPPAGE_BASE, "Slippage is too high");

    }

    function swapInOutTokenCheck(address _inToken, address _outToken) internal {  
        require(swapInTokenWhitelist[_checkedRole][_inToken],"token not allowed");
        require(swapOutTokenWhitelist[_checkedRole][_outToken],"token not allowed");
    }

    function swapInTokenCheck(address _inToken) internal {  
        require(swapInTokenWhitelist[_checkedRole][_inToken],"token not allowed");
    }

    function swapOutTokenCheck(address _outToken) internal {  
        require(swapOutTokenWhitelist[_checkedRole][_outToken],"token not allowed");
    }

    function check_recipient(address _recipient) internal {
    	require(_recipient == safeAddress, "Not safe address");
    }

    function whitelist_dispatch(bytes1 commandType, bytes memory inputs) internal {
    	uint256 command = uint8(commandType & 0x3f); //0x3f is command mask
    	if (command == V3_SWAP_EXACT_IN) {
    		(address recipient, uint256 amountIn, uint256 amountOutMin, bytes memory path, bool payerIsUser)
                        = abi.decode(inputs, (address, uint256, uint256, bytes, bool));
            (address tokenIn, address tokenOut,) = decodePath(path);
            //require(payerIsUser == true, "Pay not from user"); //make sure fund is from safe
            check_recipient(recipient);
            swapInOutTokenCheck(tokenIn, tokenOut);
            slippageCheck(tokenIn, tokenOut, amountIn, amountOutMin);

    	} else if (command == V3_SWAP_EXACT_OUT) {
    		(address recipient, uint256 amountOut, uint256 amountInMax, bytes memory path, bool payerIsUser)
                        = abi.decode(inputs, (address, uint256, uint256, bytes, bool));
            //require(payerIsUser == true, "Pay not from user"); //make sure fund is from safe
            (address tokenIn, address tokenOut,) = decodePath(path);
            check_recipient(recipient);
            swapInOutTokenCheck(tokenIn, tokenOut);
            slippageCheck(tokenOut, tokenIn, amountInMax, amountOut);

    	} else if (command == V2_SWAP_EXACT_IN) {
    		(address recipient,uint256 amountIn,uint256 amountOutMin,address[] memory path,bool payerIsUser) 
    					= abi.decode(inputs, (address, uint256, uint256, address[], bool));
    		//require(payerIsUser == true, "Pay not from user"); //make sure fund is from safe
    		check_recipient(recipient);
    		address tokenIn = path[0];
    		address tokenOut = path[path.length-1];
    		swapInOutTokenCheck(tokenIn, tokenOut);
            slippageCheck(tokenIn, tokenOut, amountIn, amountOutMin);

    	} else if (command == V2_SWAP_EXACT_OUT) {
    		(address recipient,uint256 amountOut,uint256 amountInmax,address[] memory path,bool payerIsUser) 
    					= abi.decode(inputs, (address, uint256, uint256, address[], bool));
    		//require(payerIsUser == true, "Pay not from user");
    		check_recipient(recipient);
    		address tokenIn = path[0];
    		address tokenOut = path[path.length-1];
    		swapInOutTokenCheck(tokenIn, tokenOut);
            slippageCheck(tokenIn, tokenOut, amountInmax, amountOut);
    	}else if (command == WRAP_ETH) {
    		swapInTokenCheck(weth);
    		(address recipient, /*uint256 amountMin*/) = abi.decode(inputs, (address, uint256));
    		require(recipient == safeAddress || recipient == universal_router_map, "Not valid recipient");
    	} else if (command == UNWRAP_WETH) {
    		(address recipient, /*uint256 amountMin*/) = abi.decode(inputs, (address, uint256));
            swapOutTokenCheck(weth);
    		check_recipient(recipient);
    	} else if (command == PERMIT2_PERMIT) {
    	    (PermitSingle memory permitSingle,) =
                            abi.decode(inputs, (PermitSingle, bytes));
            require(permitSingle.spender == universal_router, "spender not router");
    	} else {
    		require(false, "command not allow");
    	}
    }
    function execute(bytes calldata commands, bytes[] calldata inputs) external onlySelf {
        if (commands.length == 1) {
            bytes1 commandType = commands[0];
            uint256 command = uint8(commandType & 0x3f);
            require(command != WRAP_ETH && command != PERMIT2_PERMIT, "Command not allow");
        }else{
            
            bytes1 first_command_type = commands[0];
            bytes1 second_command_type = commands[1];
            uint256 first_command = uint8(first_command_type & 0x3f);
            uint256 second_command = uint8(second_command_type & 0x3f);
            //incase of [wrapETH wrapETH]
            if (first_command == WRAP_ETH) {
                require(
                    second_command == V3_SWAP_EXACT_IN || 
                    second_command == V3_SWAP_EXACT_OUT ||
                    second_command == V2_SWAP_EXACT_IN ||
                    second_command == V2_SWAP_EXACT_OUT
                    , "Command not allow");
            }
        }
        
    	for(uint256 commandIndex = 0; commandIndex<inputs.length; commandIndex++){
    		bytes1 command = commands[commandIndex];
            bytes memory input = inputs[commandIndex];

            whitelist_dispatch(command, input);
    	}
    }
}