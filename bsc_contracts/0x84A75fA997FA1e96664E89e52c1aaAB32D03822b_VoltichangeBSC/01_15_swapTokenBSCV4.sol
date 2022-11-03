// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
struct p2pOrder {
    address _from;
    address _to;
    address _tokenIn;
    uint256 _amountIn;
    address _tokenOut;
    uint256 _amountOut;
    uint256 _expires;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint) external;
}

contract VoltichangeBSC is AccessControlUpgradeable {
    IPancakeFactory factory;
    address private constant PANCAKESWAP_V2_ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant PANCAKESWAP_FACTORY =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    address public wallet;

    // address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    uint256 public fee; // default to 50 bp
    address public VOLT;
    mapping(address => bool) public whitelisted_tokens;
    address internal constant deadAddress =
        0x000000000000000000000000000000000000dEaD;
    p2pOrder[] public p2pOrders;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier validate(address[] memory path) {
        require(path.length >= 2, "INVALID_PATH");
        _;
    }

    function initialize(uint256 _fee, address _addr) public initializer {
        __AccessControl_init();
        fee = _fee;
        wallet = _addr;
        // whitelisted_tokens[IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()] = true;
        // whitelisted_tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; //USDT
        // whitelisted_tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; //USDC
        VOLT = 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(DEVELOPER, msg.sender);
    }

    function burn(uint256 _feeAmount, address[] memory _path) internal {
        address _tokenIn = _path[0];
        address _tokenOut = _path[_path.length - 1];
        if (_tokenIn == IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()) {
            if (_tokenOut != VOLT) {
                uint256 _firstFeeAmount = _feeAmount / 2;
                // console.log("starting second swap");
                IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: _firstFeeAmount
                }(0, _path, deadAddress, block.timestamp);
                // console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                (bool sent, ) = wallet.call{value: _secondFeeAmount}("");
                require(sent, "transfer ETH failed.");
            } else {
                (bool sent, ) = wallet.call{value: _feeAmount}("");
                require(sent, "transfer ETH failed.");
            }
        } else if (
            _tokenOut == IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()
        ) {
            if (_tokenIn == VOLT) {
                IERC20Upgradeable(_tokenIn).safeTransfer(
                    deadAddress,
                    _feeAmount
                );
            } else {
                uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
                uint256 _firstFeeAmount = _feeAmount / 2;
                // console.log("starting second swap");
                IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _firstFeeAmount,
                        0,
                        _path,
                        address(this),
                        block.timestamp
                    );
                (bool sent, ) = wallet.call{
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
                    // console.log("starting third swap");
                    IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            _secondFeeAmount,
                            0,
                            _path,
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
        } else {
            if (_tokenIn == VOLT) {
                IERC20Upgradeable(_tokenIn).safeTransfer(
                    deadAddress,
                    _feeAmount
                );
            } else {
                uint256 _firstFeeAmount = _feeAmount / 2;
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;

                address[] memory wethPath = getWETHPath(_path);

                if (wethPath.length > 0) {
                    uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
                    // console.log("starting second swap");
                    IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            _firstFeeAmount,
                            0,
                            wethPath,
                            address(this),
                            block.timestamp
                        );
                    (bool sent, ) = wallet.call{
                        value: address(this).balance - prev_balance
                    }("");
                    require(sent, "Failed to send Ether");
                    // console.log("second swap done");
                } else {
                    IERC20Upgradeable(_tokenIn).safeTransfer(
                        wallet,
                        _secondFeeAmount
                    );
                }

                if (
                    !whitelisted_tokens[_tokenIn] &&
                    whitelisted_tokens[_tokenOut]
                ) {
                    IERC20Upgradeable(_tokenIn).safeTransfer(
                        deadAddress,
                        _secondFeeAmount
                    );
                } else if (!whitelisted_tokens[_tokenOut]) {
                    uint256 prev_balance = IERC20Upgradeable(_tokenOut)
                        .balanceOf(address(this)); //prev_balance should always be equal to 0;
                    // console.log("starting third swap");
                    IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
                        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                            _secondFeeAmount,
                            0,
                            _path,
                            address(this),
                            block.timestamp
                        );
                    // console.log("third swap done");
                    uint256 curr_balance = IERC20Upgradeable(_tokenOut)
                        .balanceOf(address(this));
                    IERC20Upgradeable(_tokenOut).safeTransfer(
                        deadAddress,
                        curr_balance - prev_balance
                    );
                }
            }
        }
    }

    /*
     *   swap functions (Uniswap V2)
     */
    // TODO to calculate the price of exchange we have to use a secure method: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/trading-from-a-smart-contract
    function swapTokenForToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) external validate(_path) {
        address _tokenIn = _path[0];
        address _tokenOut = _path[_path.length - 1];

        uint256 prev_balance_tokenIn = IERC20Upgradeable(_tokenIn).balanceOf(
            address(this)
        );
        IERC20Upgradeable(_tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        uint256 curr_balance_tokenIn = IERC20Upgradeable(_tokenIn).balanceOf(
            address(this)
        );
        IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
            PANCAKESWAP_V2_ROUTER,
            _amountIn
        );
        uint256 prev_balance = IERC20Upgradeable(_tokenOut).balanceOf(
            address(this)
        ); //prev_balance should always be equal to 0;
        uint256 _realAmountIn = curr_balance_tokenIn - prev_balance_tokenIn;
        uint256 _feeAmount = (_realAmountIn * fee) / 10000;
        uint256 _amountInSub = _realAmountIn - _feeAmount;
        // console.log("starting first swap");
        IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountInSub,
                _amountOutMin,
                _path,
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
        burn(_feeAmount, _path);
    }

    function swapTokenForExactToken(
        uint256 _amountIn,
        uint256 _feeAmount,
        uint256 _amountOut,
        address[] memory _path
    ) external validate(_path) {
        address _tokenIn = _path[0];
        address _tokenOut = _path[_path.length - 1];

        require((_amountIn * fee) / 10000 == _feeAmount);
        uint256 prev_balance = IERC20Upgradeable(_tokenIn).balanceOf(
            address(this)
        );
        IERC20Upgradeable(_tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn + _feeAmount
        );
        uint256 curr_balance = IERC20Upgradeable(_tokenIn).balanceOf(
            address(this)
        );
        _amountIn = curr_balance - prev_balance;
        // console.log("transfer done");
        IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
            PANCAKESWAP_V2_ROUTER,
            _amountIn + _feeAmount
        );
        // console.log("approve done");
        prev_balance = IERC20Upgradeable(_tokenOut).balanceOf(address(this)); //prev_balance should always be equal to 0;
        // console.log("starting first swap");
        IPancakeRouter02(PANCAKESWAP_V2_ROUTER).swapTokensForExactTokens(
            _amountOut,
            _amountIn,
            _path,
            address(this),
            block.timestamp
        );
        // console.log("first swap done");
        curr_balance = IERC20Upgradeable(_tokenOut).balanceOf(address(this));
        IERC20Upgradeable(_tokenOut).safeTransfer(
            msg.sender,
            curr_balance - prev_balance
        );
        // console.log("transfer after first swap done");
        burn(_feeAmount, _path);
    }

    function swapTokenForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) external validate(_path) {
        address _tokenIn = _path[0];
        uint256 _feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - _feeAmount;
        // console.log("entered");
        uint256 prev_balance_tokenIn = IERC20Upgradeable(_tokenIn).balanceOf(
            address(this)
        );
        IERC20Upgradeable(_tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        uint256 curr_balance_tokenIn = IERC20Upgradeable(_tokenIn).balanceOf(
            address(this)
        );
        // console.log("transferFrom");
        if (_tokenIn == IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()) {
            IWETH(IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()).withdraw(
                _amountIn
            );
            (bool sent, ) = msg.sender.call{value: _amountInSub}("");
            require(sent, "Failed to send Ether");
            (sent, ) = wallet.call{value: _feeAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
                PANCAKESWAP_V2_ROUTER,
                _amountIn
            );
            // console.log("approved");
            uint256 _realAmountIn = curr_balance_tokenIn - prev_balance_tokenIn;
            _feeAmount = (_realAmountIn * fee) / 10000;
            _amountInSub = _realAmountIn - _feeAmount;
            // console.log("starting first swap");
            uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
            // console.log("starting first swap");
            IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _amountInSub,
                    _amountOutMin,
                    _path,
                    address(this),
                    block.timestamp
                );
            (bool sent, ) = msg.sender.call{
                value: address(this).balance - prev_balance
            }("");
            require(sent, "Failed to send Ether");
            // console.log("first swap done");
            burn(_feeAmount, _path);
        }
    }

    function swapTokenForExactETH(
        uint256 _amountOut,
        uint256 _amountIn,
        uint256 _feeAmount,
        address[] memory _path
    ) external validate(_path) {
        address _tokenIn = _path[0];
        require((_amountIn * fee) / 10000 == _feeAmount);
        // console.log("entered");
        uint256 prev_balance = IERC20Upgradeable(_tokenIn).balanceOf(
            address(this)
        );
        IERC20Upgradeable(_tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn + _feeAmount
        );
        uint256 curr_balance = IERC20Upgradeable(_tokenIn).balanceOf(
            address(this)
        );
        _amountIn = curr_balance - prev_balance;
        // console.log("transferFrom");
        if (_tokenIn == IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()) {
            IWETH(IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()).withdraw(
                _amountIn
            );
            (bool sent, ) = msg.sender.call{value: _amountIn}("");
            require(sent, "Failed to send Ether");
            (sent, ) = wallet.call{value: _feeAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
                PANCAKESWAP_V2_ROUTER,
                _amountIn
            );
            // console.log("approved");
            prev_balance = address(this).balance; // prev_balance should be always == 0
            // console.log("starting first swap");
            IPancakeRouter02(PANCAKESWAP_V2_ROUTER).swapTokensForExactETH(
                _amountOut,
                _amountIn,
                _path,
                address(this),
                block.timestamp
            );
            (bool sent, ) = msg.sender.call{
                value: address(this).balance - prev_balance
            }("");
            require(sent, "Failed to send Ether");
            // console.log("first swap done");
            burn(_feeAmount, _path);
        }
    }

    function swapETHforToken(uint256 _amountOutMin, address[] memory _path)
        external
        payable
        validate(_path)
    {
        address _tokenOut = _path[_path.length - 1];
        uint256 _feeAmount = (msg.value * fee) / 10000;
        uint256 _amountInSub = msg.value - _feeAmount;

        if (_tokenOut == IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()) {
            IWETH(IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()).deposit{
                value: _amountInSub
            }();
            IERC20Upgradeable(IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH())
                .transfer(msg.sender, _amountInSub);
            (bool sent, ) = wallet.call{value: _feeAmount}("");
            require(sent, "transfer ETH failed.");
        } else {
            // console.log("starting first swap");
            IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: _amountInSub
            }(_amountOutMin, _path, msg.sender, block.timestamp);
            // console.log("first swap done");
            burn(_feeAmount, _path);
        }
    }

    function swapETHforExactToken(
        uint256 _amountOut,
        uint256 _amountIn,
        uint256 _feeAmount,
        address[] memory _path
    ) external payable validate(_path) {
        address _tokenOut = _path[_path.length - 1];
        // console.log("entered");
        require(msg.value == _amountIn + _feeAmount, "must be equal");
        // console.log("require success");
        uint256 _fee = (_amountIn * fee) / 10000;
        // console.log("", _fee);
        // console.log("", _feeAmount);
        require(_fee == _feeAmount, "wrong fee");
        // console.log("require success");
        if (_tokenOut == IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()) {
            IWETH(IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH()).deposit{
                value: _amountIn
            }();
            IERC20Upgradeable(IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH())
                .transfer(msg.sender, _amountIn);
            (bool sent, ) = wallet.call{value: _feeAmount}("");
            require(sent, "transfer ETH failed.");
        } else {
            // console.log("starting first swap");
            uint256[] memory amounts = IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
                .swapETHForExactTokens{value: _amountIn}(
                _amountOut,
                _path,
                msg.sender,
                block.timestamp
            );
            (bool sent, ) = msg.sender.call{value: _amountIn - amounts[0]}("");
            require(sent, "transfer ETH failed.");

            // console.log("first swap done");
            burn(_feeAmount, _path);
        }
    }

    function getPair(address _tokenIn, address _tokenOut)
        external
        view
        returns (address)
    {
        return
            IPancakeFactory(PANCAKESWAP_FACTORY).getPair(_tokenIn, _tokenOut);
    }

    function getAmountIn(uint256 _amountOut, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256[] memory amountsIn = IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
            .getAmountsIn(_amountOut, _path);
        uint256 amount = amountsIn[0];
        return amount;
    }

    function getAmountOutMinWithFees(uint256 _amountIn, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        uint256[] memory amountOutMins = IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
            .getAmountsOut(_amountInSub, _path);
        return amountOutMins[_path.length - 1];
    }

    function getAmountOutMin(uint256 _amountIn, address[] memory _path)
        internal
        view
        returns (uint256)
    {
        uint256[] memory amountOutMins = IPancakeRouter02(PANCAKESWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, _path);

        return amountOutMins[_path.length - 1];
    }

    /*
     *   end swap functions (Uniswap V2)
     */

    function getWETHPath(address[] memory _path)
        internal
        view
        returns (address[] memory wethPath)
    {
        address WETH = IPancakeRouter02(PANCAKESWAP_V2_ROUTER).WETH();
        uint256 index = 0;
        for (uint256 i = 0; i < _path.length; i++) {
            if (_path[i] == WETH) {
                index = i + 1;
                break;
            }
        }
        wethPath = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            wethPath[i] = _path[i];
        }
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