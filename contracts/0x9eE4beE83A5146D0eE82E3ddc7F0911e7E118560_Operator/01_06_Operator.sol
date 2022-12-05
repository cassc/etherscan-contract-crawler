// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/TransferHelper.sol";
import "./FundsBasic.sol";
// import "hardhat/console.sol";

contract Operator is Ownable, FundsBasic {
    using TransferHelper for address;

    event FlipRunning(bool _prev, bool _curr);
    event SwapFeeTo(address _prev, address _curr);
    event GasFeeTo(address _prev, address _curr);
    event SetWhitelist(address _addr, bool _isWhitelist);
    event FundsProvider(address _prev, address _curr);

    event Swap(
        bytes id,
        bytes uniqueId,
        ACTION action,
        address srcToken,
        address dstToken,
        address tokenFrom,
        address tokenTo,
        uint256 retAmt,
        uint256 srcAmt,
        uint256 feeAmt
    );

    // 1inch router address: 0x1111111254fb6c44bAC0beD2854e76F90643097d
    address public immutable oneInchRouter;

    // USDT intermediate token
    address public immutable imToken;

    // swap fee will tranfer to this address, provided by Finance Team
    address public swapFeeTo;

    // used for cross swap, provided by Finance Team
    address public gasFeeTo;

    // used for cross swap, this is a usdt vault
    address public getFundsProvider;

    // running or pause, false by default
    bool public isRunning;

    // used for cross swap, provided by Wallet Team
    mapping(address => bool) public whitelist;

    // used for emit event
    enum ACTION {
        // swap in a specific blockchain
        INNER_SWAP,
        // swap for cross chain scenario, this is the first step, transfer token from EOA to FundsProvider
        CROSS_FIRST,
        // swap for cross chain scenario, this is the second step, transfer token from FundsProvider to EOA
        CROSS_SECOND
    }

    // ACCESS CONTROL
    modifier onlyRunning() {
        require(isRunning, "not running!");
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "not an eoa!");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[_msgSender()], "not in whitelist!");
        _;
    }

    // @notice this is the function we call 1inch
    // function swap( IAggregationExecutor caller, SwapDescription calldata desc, bytes calldata data ) external payable returns ( uint256 returnAmount, uint256 spentAmount, uint256 gasLeft )
    // ONEINCH_SELECTOR = bytes4(keccak256(bytes("swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)")));
    bytes4 private constant ONEINCH_SELECTOR = 0x7c025200;

    constructor(
        address _oneInchRouter,
        address _imToken,
        address _fundsProvider,
        address payable _swapFeeTo,
        address payable _gasFeeTo
    ) {
        oneInchRouter = _oneInchRouter;
        imToken = _imToken;
        getFundsProvider = _fundsProvider;
        swapFeeTo = _swapFeeTo;
        gasFeeTo = _gasFeeTo;

        emit FundsProvider(address(0), getFundsProvider);
        emit SwapFeeTo(address(0), swapFeeTo);
        emit GasFeeTo(address(0), gasFeeTo);
    }

    /**
     * @notice swap for inner swap, will be called by user EOA, no access limitation
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _swapFeeAmt fee changed by us
     * @param _data data provided by 1inch api
     */
    function doSwap(
        bytes memory _id,
        bytes memory _uniqueId,
        uint256 _swapFeeAmt,
        bytes calldata _data
    ) external payable onlyRunning onlyEOA {
        _swap(_id, _uniqueId, _msgSender(), swapFeeTo, _swapFeeAmt, _data);
    }

    /**
     * @notice when usdt as src token to do cross swap
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _amt swap amount
     * @param _swapFeeAmt fee changed by us
     */
    function fromUCross(
        bytes memory _id,
        bytes memory _uniqueId,
        uint256 _amt,
        uint256 _swapFeeAmt
    ) external onlyRunning onlyEOA {
        require(_amt > 0, "invalid amt!");
        address(imToken).safeTransferFrom(_msgSender(), getFundsProvider, _amt);

        if (_swapFeeAmt > 0) {
            address(imToken).safeTransferFrom(
                _msgSender(),
                swapFeeTo,
                _swapFeeAmt
            );
        }

        emit Swap(
            _id,
            _uniqueId,
            ACTION.CROSS_FIRST,
            address(imToken),
            address(imToken),
            _msgSender(),
            getFundsProvider,
            _amt,
            _amt,
            _swapFeeAmt
        );
    }

    /**
     * @notice for cross chain swap, can only be called by bybit special EOA
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _gasFeeAmt usdt fee changed by us
     * @param _data data provided by 1inch api
     */
    function crossSwap(
        bytes memory _id,
        bytes memory _uniqueId,
        uint256 _gasFeeAmt,
        bytes calldata _data
    ) external onlyRunning onlyWhitelist {
        _swap(_id, _uniqueId, getFundsProvider, gasFeeTo, _gasFeeAmt, _data);
    }

    /**
     * @notice when usdt as dst token to do cross swap
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _amt usdt amount that will send to user EOA directly
     * @param _gasFeeAmt usdt fee changed by us
     */
    function toUCross(
        bytes memory _id,
        bytes memory _uniqueId,
        uint256 _amt,
        uint256 _gasFeeAmt,
        address _to
    ) external onlyRunning onlyWhitelist {
        require(_amt > 0, "invalid amt!");
        address(imToken).safeTransferFrom(getFundsProvider, _to, _amt);

        if (_gasFeeAmt > 0) {
            address(imToken).safeTransferFrom(
                getFundsProvider,
                gasFeeTo,
                _gasFeeAmt
            );
        }
        emit Swap(
            _id,
            _uniqueId,
            ACTION.CROSS_SECOND,
            address(imToken),
            address(imToken),
            _msgSender(),
            getFundsProvider,
            _amt,
            _amt,
            _gasFeeAmt
        );
    }

    struct LocalVars {
        uint256 value;
        bool success;
        bytes retData;
        uint256 retAmt;
    }

    // 1inch Data Struct
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver; // don't use
        address payable dstReceiver;
        uint256 amount;
        uint256 minretAmt;
        uint256 flags;
        bytes permit;
    }

    /**
     * @notice internal swap function, will call 1inch
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _payer could be EOA or funds provider
     * @param _feeTo _feeTo can either be swapFee or gasFee
     * @param _feeAmt _feeAmt
     * @param _data data provided by 1inch api
     */
    function _swap(
        bytes memory _id,
        bytes memory _uniqueId,
        address _payer,
        address _feeTo,
        uint256 _feeAmt,
        bytes calldata _data
    ) internal {
        LocalVars memory vars;
        require(
            _data.length > 4 && bytes4(_data[0:4]) == ONEINCH_SELECTOR,
            "invalid selector!"
        );

        SwapDescription memory desc;
        (, desc, ) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        require(
            address(desc.srcToken) != address(0) &&
                address(desc.dstToken) != address(0) &&
                desc.amount != 0 &&
                desc.dstReceiver != address(0),
            "invalid calldata!"
        );

        // default: INNER_SWAP
        ACTION action;

        if (desc.dstReceiver == getFundsProvider) {
            // receiver is fundsProvider means this is the first step for cross swap
            action = ACTION.CROSS_FIRST;
        } else if (_payer == getFundsProvider) {
            // when fundsProvider provide usdt means this is the second step for cross swap
            action = ACTION.CROSS_SECOND;
        } else {
            // means this is a inner swap, thus the payer should be equal to the receiver
            require(_payer == desc.dstReceiver, "fromAddr should be eaqul to toAddr!");
        }

        // From EOA NATIVE_TOKEN
        if (address(desc.srcToken) == NATIVE_TOKEN) {
            require(
                msg.value == desc.amount + _feeAmt,
                "msg.value should eaqul to amount set in api"
            );

            // transfer fee to 'feeTo'
            if (_feeAmt > 0) {
                address(_feeTo).safeTransferETH(_feeAmt);
            }

            // will pass to 1inch
            vars.value = desc.amount;
        } else {
            // From EOA ERC20 Token
            require(msg.value == 0, "msg.value should be 0");

            // fetch token that will be used for swapping
            // need funds provider Approve to OP first
            address(desc.srcToken).safeTransferFrom(
                _payer,
                address(this),
                desc.amount
            );

            if (_feeAmt > 0) {
                // transfer fee to '_feeTo'
                address(desc.srcToken).safeTransferFrom(
                    _payer,
                    _feeTo,
                    _feeAmt
                );
            }

            // approve uint256 max to 1inch for erc20
            // op will not keep money, so it would be safe
            if (
                desc.srcToken.allowance(address(this), oneInchRouter) <
                desc.amount
            ) {
                address(desc.srcToken).safeApprove(
                    oneInchRouter,
                    type(uint256).max
                );
            }
        }

        // call swap
        (vars.success, vars.retData) = oneInchRouter.call{value: vars.value}(
            _data
        );
        if (!vars.success) revert("1inch swap failed");

        // function swap( IAggregationExecutor caller, SwapDescription calldata desc, bytes calldata data )
        // external
        // payable
        // returns ( uint256 returnAmount, uint256 spentAmount, uint256 gasLeft )

        vars.retAmt = abi.decode(vars.retData, (uint256));
        require(vars.retAmt > 0, "swap retAmt should not be 0!");

        emit Swap(
            _id,
            _uniqueId,
            action,
            address(desc.srcToken),
            address(desc.dstToken),
            _payer,
            desc.dstReceiver,
            vars.retAmt,
            desc.amount,
            _feeAmt
        );
    }

    /**
     * @notice start or stop this operator
     */
    function flipRunning() external onlyOwner {
        isRunning = !isRunning;
        emit FlipRunning(!isRunning, isRunning);
    }

    /**
     * @notice set new swapFeeTo
     * @param _newSwapFeeTo new address
     */
    function setSwapFeeTo(address _newSwapFeeTo) external onlyOwner {
        emit SwapFeeTo(swapFeeTo, _newSwapFeeTo);
        swapFeeTo = _newSwapFeeTo;
    }

    /**
     * @notice set new gasFeeTo
     * @param _newGasFeeTo new address
     */
    function setGasFeeTo(address _newGasFeeTo) external onlyOwner {
        emit GasFeeTo(gasFeeTo, _newGasFeeTo);
        gasFeeTo = _newGasFeeTo;
    }

    /**
     * @notice set special caller whitelist
     * @param _addrArr new address array
     * @param _flags new state array for addresses
     */
    function setWhitelist(address[] calldata _addrArr, bool[] calldata _flags)
        external
        onlyOwner
    {
        require(_addrArr.length == _flags.length, "input length mismatch!");
        for (uint256 i; i < _addrArr.length; i++) {
            whitelist[_addrArr[i]] = _flags[i];
            emit SetWhitelist(_addrArr[i], _flags[i]);
        }
    }

    /**
     * @notice set new funds provider
     * @param _newFundsProvider new address
     */
    function setFundsProvider(address _newFundsProvider) external onlyOwner {
        emit FundsProvider(getFundsProvider, _newFundsProvider);
        getFundsProvider = _newFundsProvider;
    }

    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external override onlyOwner returns (uint256 amt) {
        amt = _pull(_token, _amt, _to);
    }

    // will delete later
    function useless() external pure returns (uint256) {
        return 1;
    }
}