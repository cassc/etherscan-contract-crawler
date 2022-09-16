// SPDX-License-Identifier: MIT
// Author: Luca Di Domenico: twitter.com/luca_dd7
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint) external;
}

contract Voltichange is AccessControlUpgradeable {
    uint256[100] private __gap;
    IUniswapV2Factory factory;
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address public wallet;

    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    uint256 public fee; // default to 50 bp
    address public VOLT;
    mapping(address => bool) public whitelisted_tokens;

    address internal constant deadAddress =
        0x000000000000000000000000000000000000dEaD;

    // event PathCreated(address[] path);
    // event Swap(
    //     address tokenIn,
    //     address tokenOut,
    //     address receiver,
    //     uint256 amountIn
    // );

    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(uint256 _fee, address _addr) public initializer {
        __AccessControl_init();
        fee = _fee;
        wallet = _addr;
        // whitelisted_tokens[IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()] = true;
        // whitelisted_tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; //USDT
        // whitelisted_tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; //USDC
        VOLT = 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(DEVELOPER, msg.sender);
    }

    // TODO to calculate the price of exchange we have to use a secure method: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/trading-from-a-smart-contract
    function swapTokenForToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        uint256 _feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - _feeAmount;
        IERC20Upgradeable(_tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _amountInSub
        );
        IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
            UNISWAP_V2_ROUTER,
            _amountIn
        );
        address[] memory path = createPath(_tokenIn, _tokenOut);
        uint256 prev_balance = IERC20Upgradeable(_tokenOut).balanceOf(
            address(this)
        ); //prev_balance should always be equal to 0;
        // console.log("starting first swap");
        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountInSub,
                _amountOutMin,
                path,
                address(this),
                block.timestamp
            );
        uint256 curr_balance = IERC20Upgradeable(_tokenOut).balanceOf(
            address(this)
        );
        IERC20Upgradeable(_tokenOut).safeTransfer(
            msg.sender,
            curr_balance - prev_balance
        );
        // console.log("first swap done");
        if (_tokenIn == VOLT) {
            IERC20Upgradeable(_tokenIn).safeTransfer(deadAddress, _feeAmount);
        } else {
            uint256 _firstFeeAmount = _feeAmount / 2;
            uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
            prev_balance = address(this).balance; // prev_balance should be always == 0
            _amountOutMin = getAmountOutMin(
                _firstFeeAmount,
                _tokenIn,
                IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
            );
            path = createPath(_tokenIn, IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH());
            // console.log("starting second swap");
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _firstFeeAmount,
                    _amountOutMin,
                    path,
                    address(this),
                    block.timestamp
                );
            (bool sent, ) = wallet.call{
                value: address(this).balance - prev_balance
            }("");
            require(sent, "Failed to send Ether");
            // console.log("second swap done");
            if (
                !whitelisted_tokens[_tokenIn] && whitelisted_tokens[_tokenOut]
            ) {
                IERC20Upgradeable(_tokenIn).safeTransfer(
                    deadAddress,
                    _secondFeeAmount
                );
            } else if (!whitelisted_tokens[_tokenOut]) {
                path = createPath(_tokenIn, _tokenOut);
                prev_balance = IERC20Upgradeable(_tokenOut).balanceOf(
                    address(this)
                ); //prev_balance should always be equal to 0;
                _amountOutMin = getAmountOutMin(
                    _secondFeeAmount,
                    _tokenIn,
                    IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
                );
                // console.log("starting third swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        _amountOutMin,
                        path,
                        address(this),
                        block.timestamp
                    );
                curr_balance = IERC20Upgradeable(_tokenOut).balanceOf(
                    address(this)
                );
                IERC20Upgradeable(_tokenOut).safeTransfer(
                    deadAddress,
                    _secondFeeAmount
                );
                // console.log("third swap done");
            }
        }
    }

    function swapTokenForExactToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _feeAmount,
        uint256 _amountOut
    ) external {
        IERC20Upgradeable(_tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn + _feeAmount
        );
        console.log("transfer done");
        IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
            UNISWAP_V2_ROUTER,
            _amountIn + _feeAmount
        );
        console.log("approve done");
        address[] memory path = createPath(_tokenIn, _tokenOut);
        uint256 prev_balance = IERC20Upgradeable(_tokenOut).balanceOf(
            address(this)
        ); //prev_balance should always be equal to 0;
        console.log("starting first swap");
        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapTokensForExactTokens(
                _amountOut,
                _amountIn,
                path,
                address(this),
                block.timestamp
            );
        console.log("first swap done");
        uint256 curr_balance = IERC20Upgradeable(_tokenOut).balanceOf(
            address(this)
        );
        IERC20Upgradeable(_tokenOut).safeTransfer(
            msg.sender,
            curr_balance - prev_balance
        );
        console.log("transfer after first swap done");
        if (_tokenIn == VOLT) {
            IERC20Upgradeable(_tokenIn).safeTransfer(deadAddress, _feeAmount);
        } else {
            uint256 _firstFeeAmount = _feeAmount / 2;
            uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
            prev_balance = address(this).balance; // prev_balance should be always == 0
            uint256 _amountOutMin = getAmountOutMin(
                _firstFeeAmount,
                _tokenIn,
                IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
            );
            path = createPath(_tokenIn, IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH());
            console.log("starting second swap");
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _firstFeeAmount,
                    _amountOutMin,
                    path,
                    address(this),
                    block.timestamp
                );
            (bool sent, ) = wallet.call{
                value: address(this).balance - prev_balance
            }("");
            require(sent, "Failed to send Ether");
            console.log("second swap done");
            if (
                !whitelisted_tokens[_tokenIn] && whitelisted_tokens[_tokenOut]
            ) {
                IERC20Upgradeable(_tokenIn).safeTransfer(
                    deadAddress,
                    _secondFeeAmount
                );
            } else if (!whitelisted_tokens[_tokenOut]) {
                path = createPath(_tokenIn, _tokenOut);
                prev_balance = IERC20Upgradeable(_tokenOut).balanceOf(
                    address(this)
                ); //prev_balance should always be equal to 0;
                _amountOutMin = getAmountOutMin(
                    _secondFeeAmount,
                    _tokenIn,
                    IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
                );
                console.log("starting third swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        _amountOutMin,
                        path,
                        address(this),
                        block.timestamp
                    );
                curr_balance = IERC20Upgradeable(_tokenOut).balanceOf(
                    address(this)
                );
                IERC20Upgradeable(_tokenOut).safeTransfer(
                    deadAddress,
                    _secondFeeAmount
                );
                console.log("third swap done");
            }
        }
    }

    function swapTokenForETH(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        uint256 _feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - _feeAmount;
        // console.log("entered");
        IERC20Upgradeable(_tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        // console.log("transferFrom");
        if (_tokenIn == IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()) {
            IWETH(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()).withdraw(
                _amountIn
            );
            (bool sent, ) = msg.sender.call{value: _amountInSub}("");
            require(sent, "Failed to send Ether");
            (sent, ) = wallet.call{value: _feeAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
                UNISWAP_V2_ROUTER,
                _amountIn
            );
            // console.log("approved");
            address[] memory path = createPath(
                _tokenIn,
                IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
            );
            // console.log("path created");
            uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
            // console.log("starting first swap");
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _amountInSub,
                    _amountOutMin,
                    path,
                    address(this),
                    block.timestamp
                );
            (bool sent, ) = msg.sender.call{
                value: address(this).balance - prev_balance
            }("");
            require(sent, "Failed to send Ether");
            // console.log("first swap done");
            if (_tokenIn == VOLT) {
                IERC20Upgradeable(_tokenIn).safeTransfer(
                    deadAddress,
                    _feeAmount
                );
            } else {
                prev_balance = address(this).balance; // prev_balance should be always == 0
                uint256 _firstFeeAmount = _feeAmount / 2;
                _amountOutMin = getAmountOutMin(
                    _firstFeeAmount,
                    _tokenIn,
                    IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
                );
                // console.log("starting second swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _firstFeeAmount,
                        _amountOutMin,
                        path,
                        address(this),
                        block.timestamp
                    );
                (sent, ) = wallet.call{
                    value: address(this).balance - prev_balance
                }("");
                require(sent, "Failed to send Ether");
                // console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                if (!whitelisted_tokens[_tokenIn]) {
                    IERC20Upgradeable(_tokenIn).safeTransfer(
                        deadAddress,
                        _secondFeeAmount
                    );
                } else {
                    prev_balance = address(this).balance; // prev_balance should be always == 0
                    _amountOutMin = getAmountOutMin(
                        _secondFeeAmount,
                        _tokenIn,
                        IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
                    );
                    // console.log("starting third swap");
                    IUniswapV2Router02(UNISWAP_V2_ROUTER)
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            _secondFeeAmount,
                            _amountOutMin,
                            path,
                            address(this),
                            block.timestamp
                        );
                    (sent, ) = wallet.call{
                        value: address(this).balance - prev_balance
                    }("");
                    require(sent, "Failed to send Ether");
                    // console.log("third swap done");
                }
            }
        }
    }

    function swapTokenForExactETH(
        address _tokenIn,
        uint256 _amountOut,
        uint256 _amountIn,
        uint256 _feeAmount
    ) external {
        require(_amountIn * fee / 10000 == _feeAmount);
        // console.log("entered");
        IERC20Upgradeable(_tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn + _feeAmount
        );
        // console.log("transferFrom");
        if (_tokenIn == IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()) {
            IWETH(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()).withdraw(
                _amountIn
            );
            (bool sent, ) = msg.sender.call{value: _amountIn}("");
            require(sent, "Failed to send Ether");
            (sent, ) = wallet.call{value: _feeAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
                UNISWAP_V2_ROUTER,
                _amountIn
            );
            // console.log("approved");
            address[] memory path = createPath(
                _tokenIn,
                IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
            );
            // console.log("path created");
            uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
            // console.log("starting first swap");
            IUniswapV2Router02(UNISWAP_V2_ROUTER).
                swapTokensForExactETH(
                    _amountOut,
                    _amountIn,
                    path,
                    address(this),
                    block.timestamp
                );
            (bool sent, ) = msg.sender.call{
                value: address(this).balance - prev_balance
            }("");
            require(sent, "Failed to send Ether");
            // console.log("first swap done");
            if (_tokenIn == VOLT) {
                IERC20Upgradeable(_tokenIn).safeTransfer(
                    deadAddress,
                    _feeAmount
                );
            } else {
                prev_balance = address(this).balance; // prev_balance should be always == 0
                uint256 _firstFeeAmount = _feeAmount / 2;
                uint256 _amountOutMin = getAmountOutMin(
                    _firstFeeAmount,
                    _tokenIn,
                    IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
                );
                // console.log("starting second swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _firstFeeAmount,
                        _amountOutMin,
                        path,
                        address(this),
                        block.timestamp
                    );
                (sent, ) = wallet.call{
                    value: address(this).balance - prev_balance
                }("");
                require(sent, "Failed to send Ether");
                // console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                if (!whitelisted_tokens[_tokenIn]) {
                    IERC20Upgradeable(_tokenIn).safeTransfer(
                        deadAddress,
                        _secondFeeAmount
                    );
                } else {
                    prev_balance = address(this).balance; // prev_balance should be always == 0
                    _amountOutMin = getAmountOutMin(
                        _secondFeeAmount,
                        _tokenIn,
                        IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()
                    );
                    // console.log("starting third swap");
                    IUniswapV2Router02(UNISWAP_V2_ROUTER)
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            _secondFeeAmount,
                            _amountOutMin,
                            path,
                            address(this),
                            block.timestamp
                        );
                    (sent, ) = wallet.call{
                        value: address(this).balance - prev_balance
                    }("");
                    require(sent, "Failed to send Ether");
                    // console.log("third swap done");
                }
            }
        }
    }

    function swapETHforToken(address _tokenOut, uint256 _amountOutMin)
        external
        payable
    {
        uint256 _feeAmount = (msg.value * fee) / 10000;
        uint256 _amountInSub = msg.value - _feeAmount;

        if (_tokenOut == IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()) {
            IWETH(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()).deposit{
                value: _amountInSub
            }();
            IERC20Upgradeable(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH())
                .transfer(msg.sender, _amountInSub);
            (bool sent, ) = wallet.call{value: _feeAmount}("");
            require(sent, "transfer ETH failed.");
        } else {
            address[] memory path;
            path = new address[](2);
            path[0] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
            path[1] = _tokenOut;

            // console.log("starting first swap");
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: _amountInSub
            }(_amountOutMin, path, msg.sender, block.timestamp);
            // console.log("first swap done");
            if (_tokenOut != VOLT) {
                uint256 _firstFeeAmount = _feeAmount / 2;
                _amountOutMin = getAmountOutMin(
                    _firstFeeAmount,
                    IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH(),
                    _tokenOut
                );
                console.log("starting second swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: _firstFeeAmount
                }(_amountOutMin, path, deadAddress, block.timestamp);
                console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                (bool sent, ) = wallet.call{value: _secondFeeAmount}("");
                require(sent, "transfer ETH failed.");
            } else {
                (bool sent, ) = wallet.call{value: _feeAmount}("");
                require(sent, "transfer ETH failed.");
            }
        }
    }

    function swapETHforExactToken(address _tokenOut, uint256 _amountOut, uint256 _amountIn, uint256 _feeAmount)
        external
        payable
    {
        console.log("entered");
        require(msg.value == _amountIn + _feeAmount, "must be equal");
        console.log("require success");
        uint256 _fee = (_amountIn * fee) / 10000;
        console.log("", _fee);
        console.log("", _feeAmount);
        require( _fee == _feeAmount, "wrong fee");
        console.log("require success");
        if (_tokenOut == IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()) {
            IWETH(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()).deposit{
                value: _amountIn
            }();
            IERC20Upgradeable(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH())
                .transfer(msg.sender, _amountIn);
            (bool sent, ) = wallet.call{value: _feeAmount}("");
            require(sent, "transfer ETH failed.");
        } else {
            address[] memory path;
            path = new address[](2);
            path[0] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
            path[1] = _tokenOut;

            console.log("starting first swap");
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapETHForExactTokens{
                value: _amountIn
            }(_amountOut, path, msg.sender, block.timestamp);
            console.log("first swap done");
            if (_tokenOut != VOLT) {
                uint256 _firstFeeAmount = _feeAmount / 2;
                uint256 _amountOutMin = getAmountOutMin(
                    _firstFeeAmount,
                    IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH(),
                    _tokenOut
                );
                console.log("starting second swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: _firstFeeAmount
                }(_amountOutMin, path, deadAddress, block.timestamp);
                console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                (bool sent, ) = wallet.call{value: _secondFeeAmount}("");
                require(sent, "transfer ETH failed.");
            } else {
                (bool sent, ) = wallet.call{value: _feeAmount}("");
                require(sent, "transfer ETH failed.");
            }
        }
    }

    function getPair(address _tokenIn, address _tokenOut)
        external
        view
        returns (address)
    {
        return IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut);
    }

    function getAmountIn(
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint256) {
        address[] memory path = createPath(_tokenIn, _tokenOut);
        uint256[] memory amountsIn = IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsIn(_amountOut, path);
        uint256 amount = amountsIn[0];
        return amount;
    }

    function getAmountOutMinWithFees(
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

    function getAmountOutMin(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view returns (uint256) {
        address[] memory path = createPath(_tokenIn, _tokenOut);
        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);

        return amountOutMins[path.length - 1];
    }

    function createPath(address _tokenIn, address _tokenOut)
        internal
        view
        returns (address[] memory)
    {
        address[] memory path;
        if (
            IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut) !=
            address(0)
        ) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
            path[2] = _tokenOut;
        }
        return path;
    }

    /* this function can be used to:
     * - withdraw
     * - send refund to users in case something goes
     */
    function sendEthToAddr(uint256 _amount, address payable _to)
        external
        payable
        onlyRole(ADMIN)
    {
        require(
            _amount <= address(this).balance,
            "amount must be <= than balance."
        );
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function sendTokenToAddr(
        uint256 _amount,
        address _tokenAddress,
        address _to
    ) external onlyRole(ADMIN) {
        require(
            IERC20Upgradeable(_tokenAddress).transferFrom(
                address(this),
                _to,
                _amount
            ),
            "transferFrom failed."
        );
    }

    function setWallet(address _wallet) external onlyRole(ADMIN) {
        wallet = _wallet;
    }

    // function addWhitelistAddr(address _addr) public onlyRole(DEVELOPER) {
    //     whitelisted_tokens[_addr] = true;
    // }

    // function removeWhitelistAddr(address _addr) public onlyRole(DEVELOPER) {
    //     delete whitelisted_tokens[_addr];
    // }

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

    receive() external payable {}
}