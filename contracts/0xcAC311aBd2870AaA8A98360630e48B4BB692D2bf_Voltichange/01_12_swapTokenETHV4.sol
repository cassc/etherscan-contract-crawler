// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract Voltichange is AccessControlUpgradeable {
    uint256[100] private __gap;
    IUniswapV2Factory factory;
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    uint256 public fee/* = 500*/;
    address public WETH;
    address public VOLT;
    mapping(address => bool) public whitelisted_tokens;

    function initialize(uint256 _fee) public initializer {
        __AccessControl_init();
        fee = _fee;
        WETH = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
        VOLT = 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;
        whitelisted_tokens[WETH] = true;
        whitelisted_tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; //USDT
        whitelisted_tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; //USDC
        _grantRole(
            DEFAULT_ADMIN_ROLE,
            msg.sender
        );
        _grantRole(ADMIN, msg.sender);
        _grantRole(DEVELOPER, msg.sender);
    }

    // TODO to calculate the price of exchange we have to use a secure method: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/trading-from-a-smart-contract
    // TODO review the fees strategies for token-to-token swap and token-to-ETH swap
    function swapTokenForToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        require(IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn), "transferFrom failed.");
        require(IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn), "approve failed.");

        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        address[] memory path = createPath(_tokenIn, _tokenOut);
        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokens(
                _amountInSub,
                _amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );

        uint256 _feeAmountHalf = feeAmount / 2;

        /*
        * Burn destination token if not in whitelist. Otherwise the 0.25% of Input token remains on the smart contract
        */
        bool whitelisted = whitelisted_tokens[_tokenIn];
        if(!whitelisted) {
            uint256 _tokenAmountOutMin = getAmountOutMin(_feeAmountHalf, WETH, _tokenOut);
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactTokensForTokens(
                    _feeAmountHalf,
                    _tokenAmountOutMin,
                    path,
                    deadAddress,
                    block.timestamp
                );
        }

        /*
        * Burn VOLT
        */
        path = createPath(_tokenIn, VOLT);
        uint256 _voltAmountMin = getAmountOutMin(_feeAmountHalf, WETH, VOLT);
        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokens(
                _feeAmountHalf,
                _voltAmountMin,
                path,
                deadAddress,
                block.timestamp
            );
    }

    function swapETHforToken(
        address _tokenOut,
        uint256 _amountOutMin
    ) external payable {
        require(msg.value > 0, "Please send ETH.");
        uint256 feeAmount = (msg.value * fee) / 10000;
        uint256 _amountInSub = msg.value - feeAmount;

        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenOut;

        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactETHForTokens{value: _amountInSub}(
                _amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );

        uint256 _feeAmountHalf = feeAmount / 2;
        uint256 _tokenAmountOutMin = getAmountOutMin(_feeAmountHalf, WETH, _tokenOut);
        
        /*
        * Burn destination token if not in whitelist. Else buy the token
        */
        bool whitelisted = whitelisted_tokens[_tokenOut];
        if(!whitelisted) {
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactETHForTokens{value: _feeAmountHalf}(
                    _tokenAmountOutMin,
                    path,
                    deadAddress,
                    block.timestamp
                );
        } else {
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactETHForTokens{value: _feeAmountHalf}(
                    _tokenAmountOutMin,
                    path,
                    address(this),
                    block.timestamp
                );
        }

        /*
        * Burn VOLT
        */
        path[1] = VOLT;
        uint256 _voltAmountMin = getAmountOutMin(_feeAmountHalf, WETH, VOLT);
        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactETHForTokens{value: _feeAmountHalf}(
                _voltAmountMin,
                path,
                deadAddress,
                block.timestamp
            );
    }

    function swapTokenForETH(address _tokenIn, uint256 _amountIn, uint256 _amountOutMin) external {
        require(IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn), "transferFrom failed.");
        require(IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn), "approve failed."); 

        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        address[] memory path = createPath(_tokenIn, WETH);

        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactTokensForETH(
                _amountInSub,
                _amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );

        uint256 _feeAmountHalf = feeAmount / 2;

        // /*
        // * Buy 0.25% of ETH
        // */
        // uint256 _ETHAmountOutMin = getAmountOutMin(_feeAmountHalf, _tokenIn, WETH);
        // IUniswapV2Router02(UNISWAP_V2_ROUTER)
        //     .swapExactTokensForETH(
        //         _feeAmountHalf,
        //         _ETHAmountOutMin,
        //         path,
        //         address(this),
        //         block.timestamp
        //     );

        /*
        * Burn VOLT
        */
        // path = createPath(_tokenIn, VOLT);
        // uint256 _voltAmountMin = getAmountOutMin(_feeAmountHalf, _tokenIn, VOLT);
        // IUniswapV2Router02(UNISWAP_V2_ROUTER)
        //     .swapExactTokensForETH(
        //         _feeAmountHalf,
        //         _voltAmountMin,
        //         path,
        //         deadAddress,
        //         block.timestamp
        //     );
    }

    function getPair(address _tokenIn, address _tokenOut)
        external
        view 
        returns (address)
    {
        return IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut);
    }

    function getAmountOutMin(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint256) {

        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        address[] memory path = createPath(_tokenIn, _tokenOut);

        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountInSub, path);
        return amountOutMins[path.length - 1];
    }

    function getAmountOutMinWithoutFees(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view onlyRole(DEVELOPER) returns (uint256) {
        address[] memory path = createPath(_tokenIn, _tokenOut);
        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);

        return amountOutMins[path.length - 1];
    }

    function createPath(address _tokenIn, address _tokenOut) internal view returns (address[] memory) {
        address[] memory path;
        if (IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut) != address(0)) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        return path;
    }

    /* this function can be used to:
     * - withdraw
     * - send refund to users in case something goes 
     */
    function sendEthToAddr(uint256 _amount, address payable _to) external payable onlyRole(ADMIN)
    {
        require(
            _amount <= address(this).balance,
            "amount must be <= than balance."
        );
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function sendTokenToAddr(uint256 _amount, address _tokenAddress, address _to) external onlyRole(ADMIN) {
        require(IERC20(_tokenAddress).transferFrom(address(this), _to, _amount), "transferFrom failed.");
    }

    function addWhitelistAddr(address _addr) public onlyRole(DEVELOPER) {
        whitelisted_tokens[_addr] = true;
    }

    function removeWhitelistAddr(address _addr) public onlyRole(DEVELOPER) {
        delete whitelisted_tokens[_addr];
    }

    function setFees(uint256 _fee) external onlyRole(DEVELOPER) {
        fee = _fee;
    }

    function setVoltAddr(address _addr) external onlyRole(DEVELOPER) {
        VOLT = _addr;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() payable external {}
}