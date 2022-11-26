// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interface/IUniswapFactory.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IHandlerReserve.sol";
import "./interface/IEthHandler.sol";
import "./interface/IBridge.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";
import "./interface/IWETH.sol";
import "./libraries/TransferHelper.sol";
import "./interface/IAugustusSwapper.sol";
import "hardhat/console.sol";

abstract contract IOneSplitView is IOneSplitConsts {
    function getExpectedReturn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) public view virtual returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGas(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        virtual
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}

library DisableFlags {
    function check(uint256 flags, uint256 flag) internal pure returns (bool) {
        return (flags & flag) != 0;
    }
}

contract OneSplitRoot {
    using SafeMathUpgradeable for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20Upgradeable;
    using UniversalERC20 for IWETH;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;

    uint256 internal constant DEXES_COUNT = 4;
    uint256 internal constant DEXES_COUNT_UPDATED = 1;
    IERC20Upgradeable internal constant ZERO_ADDRESS = IERC20Upgradeable(0x0000000000000000000000000000000000000000);

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;
    address internal constant skimAddress = 0xb599a1e294Ec6608d68987fC9A2d4d155eEd9160;

    IWETH public wnativeAddress;
    IERC20Upgradeable public nativeAddress;

    function _findBestDistribution(
        uint256 s, // parts
        int256[][] memory amounts // exchangesReturns
    ) internal pure returns (int256 returnAmount, uint256[] memory distribution) {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint256 i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint256 j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint256 i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint256 i = 1; i < n; i++) {
            for (uint256 j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint256 k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](DEXES_COUNT_UPDATED);

        uint256 partsLeft = s;
        for (uint256 curExchange = n - 1; partsLeft > 0; curExchange--) {
            distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
            partsLeft = parent[curExchange][partsLeft];
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? int256(0) : answer[n - 1][s];
    }

    function _linearInterpolation(uint256 value, uint256 parts) internal pure returns (uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint256 i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function _tokensEqual(IERC20Upgradeable tokenA, IERC20Upgradeable tokenB) internal pure returns (bool) {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}

contract OneSplitView is Initializable, IOneSplitView, OneSplitRoot, UUPSUpgradeable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    using DisableFlags for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using UniversalERC20 for IERC20Upgradeable;

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function getExpectedReturn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    ) public view override returns (uint256 returnAmount, uint256[] memory distribution) {
        (returnAmount, , distribution) = getExpectedReturnWithGas(fromToken, destToken, amount, parts, flags, 0);
    }

    function getExpectedReturnWithGas(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        override
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT_UPDATED);

        if (fromToken == destToken) {
            return (amount, 0, distribution);
        }

        function(IERC20Upgradeable, IERC20Upgradeable, uint256, uint256)
            view
            returns (uint256[] memory, uint256)[DEXES_COUNT_UPDATED]
            memory reserves = _getAllReserves(flags);

        int256[][] memory matrix = new int256[][](DEXES_COUNT_UPDATED);
        uint256[DEXES_COUNT_UPDATED] memory gases;
        bool atLeastOnePositive = false;
        for (uint256 i = 0; i < DEXES_COUNT_UPDATED; i++) {
            uint256[] memory rets;
            (rets, gases[i]) = reserves[i](fromToken, destToken, amount, parts);

            // Prepend zero and sub gas
            int256 gas = int256(gases[i].mul(destTokenEthPriceTimesGasPrice).div(1e18));
            matrix[i] = new int256[](parts + 1);
            for (uint256 j = 0; j < rets.length; j++) {
                matrix[i][j + 1] = int256(rets[j]) - gas;
                atLeastOnePositive = atLeastOnePositive || (matrix[i][j + 1] > 0);
            }
        }

        if (!atLeastOnePositive) {
            for (uint256 i = 0; i < DEXES_COUNT_UPDATED; i++) {
                for (uint256 j = 1; j < parts + 1; j++) {
                    if (matrix[i][j] == 0) {
                        matrix[i][j] = VERY_NEGATIVE_VALUE;
                    }
                }
            }
        }

        (, distribution) = _findBestDistribution(parts, matrix);

        (returnAmount, estimateGasAmount) = _getReturnAndGasByDistribution(
            Args({
                fromToken: fromToken,
                destToken: destToken,
                amount: amount,
                parts: parts,
                flags: flags,
                destTokenEthPriceTimesGasPrice: destTokenEthPriceTimesGasPrice,
                distribution: distribution,
                matrix: matrix,
                gases: gases,
                reserves: reserves
            })
        );
        return (returnAmount, estimateGasAmount, distribution);
    }

    struct Args {
        IERC20Upgradeable fromToken;
        IERC20Upgradeable destToken;
        uint256 amount;
        uint256 parts;
        uint256 flags;
        uint256 destTokenEthPriceTimesGasPrice;
        uint256[] distribution;
        int256[][] matrix;
        uint256[DEXES_COUNT_UPDATED] gases;
        function(IERC20Upgradeable, IERC20Upgradeable, uint256, uint256)
            view
            returns (uint256[] memory, uint256)[DEXES_COUNT_UPDATED] reserves;
    }

    function _getReturnAndGasByDistribution(Args memory args)
        internal
        view
        returns (uint256 returnAmount, uint256 estimateGasAmount)
    {
        bool[DEXES_COUNT_UPDATED] memory exact = [
            true //empty
        ];

        for (uint256 i = 0; i < DEXES_COUNT_UPDATED; i++) {
            if (args.distribution[i] > 0) {
                if (
                    args.distribution[i] == args.parts || exact[i] || args.flags.check(FLAG_DISABLE_SPLIT_RECALCULATION)
                ) {
                    estimateGasAmount = estimateGasAmount.add(args.gases[i]);
                    int256 value = args.matrix[i][args.distribution[i]];
                    returnAmount = returnAmount.add(
                        uint256(
                            (value == VERY_NEGATIVE_VALUE ? int256(0) : value) +
                                int256(args.gases[i].mul(args.destTokenEthPriceTimesGasPrice).div(1e18))
                        )
                    );
                } else {
                    (uint256[] memory rets, uint256 gas) = args.reserves[i](
                        args.fromToken,
                        args.destToken,
                        args.amount.mul(args.distribution[i]).div(args.parts),
                        1
                    );
                    estimateGasAmount = estimateGasAmount.add(gas);
                    returnAmount = returnAmount.add(rets[0]);
                }
            }
        }
    }

    function _getAllReserves(uint256 flags)
        internal
        pure
        returns (
            function(IERC20Upgradeable, IERC20Upgradeable, uint256, uint256)
                view
                returns (uint256[] memory, uint256)[DEXES_COUNT_UPDATED]
                memory
        )
    {
        return [_calculateNoReturn];
    }

    function _calculateUniswapFormula(
        uint256 fromBalance,
        uint256 toBalance,
        uint256 amount
    ) internal pure returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        return amount.mul(toBalance).mul(997).div(fromBalance.mul(1000).add(amount.mul(997)));
    }

    function _calculateSwap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256[] memory amounts,
        IUniswapV2Factory exchangeInstance
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20Upgradeable fromTokenReal = fromToken.isETH() ? wnativeAddress : fromToken;
        IERC20Upgradeable destTokenReal = destToken.isETH() ? wnativeAddress : destToken;
        IUniswapV2Exchange exchange = exchangeInstance.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapV2Exchange(address(0))) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint256 i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return (rets, 50_000);
        }
    }

    function _calculateNoReturn(
        IERC20Upgradeable, /*fromToken*/
        IERC20Upgradeable, /*destToken*/
        uint256, /*amount*/
        uint256 parts
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        this;
        return (new uint256[](parts), 0);
    }
}

contract OneSplit is Initializable, IOneSplit, OneSplitRoot, UUPSUpgradeable, AccessControlUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using DisableFlags for uint256;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    IOneSplitView public oneSplitView;
    address public handlerAddress;
    IHandlerReserve public reserveInstance;
    IBridge public bridgeInstance;
    IEthHandler public _ethHandler;
    mapping(uint256 => address) public flagToAddress;

    event Swap(
        string indexed funcName,
        IERC20Upgradeable[] tokenPath,
        uint256 amount,
        address indexed sender,
        address indexed receiver,
        uint256 finalAmt,
        uint256[] flags,
        uint256 widgetID
    );
    struct DexesArgs {
        IERC20Upgradeable factoryAddress;
        uint256 _exchangeCode;
    }

    bytes32 public constant FACTORY_SETTER_ROLE = keccak256("FACTORY_SETTER_ROLE");

    function initialize(
        IOneSplitView _oneSplitView,
        address _handlerAddress,
        address _reserveAddress,
        address _bridgeAddress,
        IEthHandler ethHandler
    ) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        oneSplitView = _oneSplitView;
        handlerAddress = _handlerAddress;
        reserveInstance = IHandlerReserve(_reserveAddress);
        bridgeInstance = IBridge(_bridgeAddress);
        _ethHandler = ethHandler;
    }

    modifier onlyHandler() {
        require(msg.sender == handlerAddress, "sender must be handler contract");
        _;
    }

    //Function that authorize upgrade caller
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function getExpectedReturn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) public view override returns (uint256 returnAmount, uint256[] memory distribution) {
        (returnAmount, , distribution) = getExpectedReturnWithGas(fromToken, destToken, amount, parts, flags, 0);
    }

    function getExpectedReturnETH(
        IERC20Upgradeable srcStableFromToken,
        uint256 srcStableFromTokenAmount,
        uint256 parts,
        uint256 flags
    ) public view override returns (uint256 returnAmount) {
        if (address(srcStableFromToken) == address(nativeAddress)) {
            srcStableFromToken = wnativeAddress;
        }
        (returnAmount, ) = getExpectedReturn(
            srcStableFromToken,
            wnativeAddress,
            srcStableFromTokenAmount,
            parts,
            flags
        );
        return returnAmount;
    }

    function getExpectedReturnWithGas(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        override
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return
            oneSplitView.getExpectedReturnWithGas(
                fromToken,
                destToken,
                amount,
                parts,
                flags,
                destTokenEthPriceTimesGasPrice
            );
    }

    function getExpectedReturnWithGasMulti(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        override
        returns (
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        uint256[] memory dist;

        returnAmounts = new uint256[](tokens.length - 1);
        for (uint256 i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                returnAmounts[i - 1] = (i == 1) ? amount : returnAmounts[i - 2];
                continue;
            }

            IERC20Upgradeable[] memory _tokens = tokens;

            (returnAmounts[i - 1], amount, dist) = getExpectedReturnWithGas(
                _tokens[i - 1],
                _tokens[i],
                (i == 1) ? amount : returnAmounts[i - 2],
                parts[i - 1],
                flags[i - 1],
                destTokenEthPriceTimesGasPrices[i - 1]
            );
            estimateGasAmount = estimateGasAmount + amount;

            if (distribution.length == 0) {
                distribution = new uint256[](dist.length);
            }

            for (uint256 j = 0; j < distribution.length; j++) {
                distribution[j] = (distribution[j] + dist[j]) << (8 * (i - 1));
            }
        }
    }

    function setHandlerAddress(address _handlerAddress) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(_handlerAddress != address(0), "Recipient can't be null");
        handlerAddress = _handlerAddress;
        return true;
    }

    function setReserveAddress(address _reserveAddress) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(_reserveAddress != address(0), "Address can't be null");
        reserveInstance = IHandlerReserve(_reserveAddress);
        return true;
    }

    function setBridgeAddress(address _bridgeAddress) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(_bridgeAddress != address(0), "Address can't be null");
        bridgeInstance = IBridge(_bridgeAddress);
        return true;
    }

    function setEthHandler(IEthHandler ethHandler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _ethHandler = ethHandler;
    }

    function setGetViewAddress(IOneSplitView _oneSplitView) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(address(_oneSplitView) != address(0), "Address can't be null");
        oneSplitView = _oneSplitView;
        return true;
    }

    function setFlagToFactoryAddress(uint256 _flagCode, address _factoryAddress)
        public
        onlyRole(FACTORY_SETTER_ROLE)
        returns (bool)
    {
        require(_flagCode != 0, "Flag can't be 0");
        flagToAddress[_flagCode] = address(_factoryAddress);
        return true;
    }

    function setFlagToFactoryAddressMulti(DexesArgs[] memory dexesArgs)
        public
        onlyRole(FACTORY_SETTER_ROLE)
        returns (bool)
    {
        for (uint256 i = 0; i < dexesArgs.length; i++) {
            require(dexesArgs[i]._exchangeCode != 0, "Flag can't be 0");
            flagToAddress[dexesArgs[i]._exchangeCode] = address(dexesArgs[i].factoryAddress);
        }
        return true;
    }

    function setWNativeAddresses(address _native, address _wrappedNative)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(_native != address(0), "Address can't be empty");
        require(_wrappedNative != address(0), "Wrapped address can't be empty");
        nativeAddress = IERC20Upgradeable(_native);
        wnativeAddress = IWETH(_wrappedNative);

        return true;
    }

    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public payable override onlyHandler returns (bool) {
        require(tokenAddress != address(0), "Token address can't be null");
        require(recipient != address(0), "Recipient can't be null");

        TransferHelper.safeTransfer(tokenAddress, recipient, amount);
        return true;
    }

    function swap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper
    ) public payable override returns (uint256 returnAmount) {
        returnAmount = _swapInternal(fromToken, destToken, amount, minReturn, flags, dataTx, isWrapper, msg.sender);
        IERC20Upgradeable[] memory path = new IERC20Upgradeable[](2);
        path[0] = fromToken;
        path[1] = destToken;
        uint256[] memory _flags = new uint256[](1);
        _flags[0] = flags;
        emit Swap("swap", path, amount, msg.sender, msg.sender, returnAmount, _flags, 0);
    }

    function swapWithRecipient(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper,
        address recipient
    ) public payable override returns (uint256 returnAmount) {
        require(recipient != address(0), "Recipient Address cannot be null");
        returnAmount = _swapInternal(fromToken, destToken, amount, minReturn, flags, dataTx, isWrapper, recipient);
        IERC20Upgradeable[] memory path = new IERC20Upgradeable[](2);
        path[0] = fromToken;
        path[1] = destToken;
        uint256[] memory _flags = new uint256[](1);
        _flags[0] = flags;

        emit Swap("swapWithRecipient", path, amount, msg.sender, recipient, returnAmount, _flags, 0);
    }

    function _swapInternal(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper,
        address recipient
    ) internal returns (uint256 returnAmount) {
        if (!isWrapper) {
            fromToken.universalTransferFrom(msg.sender, address(this), amount);
        }

        if (destToken.isETH() && msg.sender == address(reserveInstance)) {
            require(false, "OneSplit: Native transfer not allowed");
        }

        uint256 confirmed = fromToken.universalBalanceOf(address(this));
        _swapFloor(fromToken, destToken, confirmed, flags, dataTx);
        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "RA: actual return amount is less than minReturn");

        uint256 userBalanceOld = destToken.universalBalanceOf(recipient);
        destToken.universalTransfer(recipient, returnAmount);
        uint256 userBalanceNew = destToken.universalBalanceOf(recipient);
        require(userBalanceNew - userBalanceOld >= minReturn, "ERROR:1003");

        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
        return userBalanceNew - userBalanceOld;
    }

    function swapInSameChain(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper,
        address recipient,
        uint256 widgetID
    ) public payable returns (uint256 returnAmount) {
        returnAmount = swapMultiWithRecipient(tokens, amount, minReturn, flags, dataTx, isWrapper, recipient);
        emit Swap("swapInSameChain", tokens, amount, msg.sender, recipient, returnAmount, flags, widgetID);
    } 

    function swapMulti(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper
    ) public payable override returns (uint256 returnAmount) {
        returnAmount = _swapMultiInternal(tokens, amount, minReturn, flags, dataTx, isWrapper, msg.sender);
        emit Swap("swapMulti", tokens, amount, msg.sender, msg.sender, returnAmount, flags, 0);
    }

    function swapMultiWithRecipient(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper,
        address recipient
    ) public payable override returns (uint256 returnAmount) {
        require(recipient != address(0), "Recipient Address cannot be null");
        returnAmount = _swapMultiInternal(tokens, amount, minReturn, flags, dataTx, isWrapper, recipient);
        emit Swap("swapMultiWithRecipient", tokens, amount, msg.sender, recipient, returnAmount, flags, 0);
    }

    function _swapMultiInternal(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper,
        address recipient
    ) internal returns (uint256 returnAmount) {
        if (!isWrapper) {
            tokens[0].universalTransferFrom(msg.sender, address(this), amount);
        }

        if (tokens[tokens.length - 1].isETH() && msg.sender == address(reserveInstance)) {
            require(false, "OneSplit: Native transfer not allowed");
        }

        returnAmount = tokens[0].universalBalanceOf(address(this));
        for (uint256 i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                continue;
            }
            _swapFloor(tokens[i - 1], tokens[i], returnAmount, flags[i - 1], dataTx[i - 1]);
            returnAmount = tokens[i].universalBalanceOf(address(this));
            tokens[i - 1].universalTransfer(msg.sender, tokens[i - 1].universalBalanceOf(address(this)));
        }

        require(returnAmount >= minReturn, "RA: actual return amount is less than minReturn");

        uint256 userBalanceOld = tokens[tokens.length - 1].universalBalanceOf(recipient);
        tokens[tokens.length - 1].universalTransfer(recipient, returnAmount);
        uint256 userBalanceNew = tokens[tokens.length - 1].universalBalanceOf(recipient);
        require(userBalanceNew - userBalanceOld >= minReturn, "ERROR:1003");
        returnAmount = userBalanceNew - userBalanceOld;
    }

    function _swapFloor(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 flags,
        bytes memory _data
    ) internal {
        _swap(fromToken, destToken, amount, 0, flags, _data);
    }

    function _getReserveExchange(uint256 flag)
        internal
        pure
        returns (function(IERC20Upgradeable, IERC20Upgradeable, uint256, bytes memory, uint256))
    {
        if (flag < 0x07D1 && flag > 0x03E9) {
            return _swapOnOneInch;
        } else if (flag < 0x03E9 && flag >= 0x0001) {
            return _swapOnUniswapV2;
        } else if (flag < 0x0BB9 && flag > 0x07D1 ) {
            return _swapOnParaswap;
        }
        revert("RA: Exchange not found");
    }

    function _swap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory _data
    ) internal returns (uint256 returnAmount) {
        if (fromToken == destToken) {
            return amount;
        }

        if (
            (reserveInstance._contractToLP(address(destToken)) == address(fromToken)) &&
            (destToken.universalBalanceOf(address(reserveInstance)) > amount)
        ) {
            bridgeInstance.unstake(handlerAddress, address(destToken), amount);
            return amount;
        }

        if (reserveInstance._lpToContract(address(destToken)) == address(fromToken)) {
            fromToken.universalApprove(address(reserveInstance), amount);
            bridgeInstance.stake(handlerAddress, address(fromToken), amount);
            return amount;
        }

        function(IERC20Upgradeable, IERC20Upgradeable, uint256, bytes memory, uint256) reserve = _getReserveExchange(
            flags
        );

        uint256 remainingAmount = fromToken.universalBalanceOf(address(this));
        reserve(fromToken, destToken, remainingAmount, _data, flags);

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "Return amount was not enough");
    }

    receive() external payable {}

    function _swapOnExchangeInternal(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 flagCode
    ) internal returns (uint256 returnAmount) {
        if (fromToken.isETH()) {
            wnativeAddress.deposit{ value: amount }();
        }

        address dexAddress = flagToAddress[flagCode];
        require(dexAddress != address(0), "RA: Exchange not found");
        IUniswapV2Factory exchangeInstance = IUniswapV2Factory(address(dexAddress));

        IERC20Upgradeable fromTokenReal = fromToken.isETH() ? wnativeAddress : fromToken;
        IERC20Upgradeable toTokenReal = destToken.isETH() ? wnativeAddress : destToken;
        IUniswapV2Exchange exchange = exchangeInstance.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(skimAddress);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(uint160(address(fromTokenReal))) < uint256(uint160(address(toTokenReal)))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            // wnativeAddress.withdraw(wnativeAddress.balanceOf(address(this)));
            uint256 balanceThis = wnativeAddress.balanceOf(address(this));
            wnativeAddress.transfer(address(_ethHandler), wnativeAddress.balanceOf(address(this)));
            _ethHandler.withdraw(address(wnativeAddress), balanceThis);
        }
    }

    function _swapOnUniswapV2(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data,
        uint256 flags
    ) internal {
        _swapOnExchangeInternal(fromToken, destToken, amount, flags);
    }

    function _swapOnOneInch(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data,
        uint256 flagCode
    ) internal {
        require(_data.length > 0, "data should not be empty");

        address oneInchSwap = flagToAddress[flagCode];
        require(oneInchSwap != address(0), "RA: Exchange not found");

        if (fromToken.isETH()) {
            wnativeAddress.deposit{ value: amount }();
        }
        IERC20Upgradeable fromTokenReal = fromToken.isETH() ? wnativeAddress : fromToken;
        fromTokenReal.universalApprove(address(oneInchSwap), type(uint256).max);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(oneInchSwap).call(_data);
        if (destToken.isETH()) {
            // wnativeAddress.withdraw(wnativeAddress.balanceOf(address(this)));
            uint256 balanceThis = wnativeAddress.balanceOf(address(this));
            wnativeAddress.transfer(address(_ethHandler), wnativeAddress.balanceOf(address(this)));
            _ethHandler.withdraw(address(wnativeAddress), balanceThis);
        }
    }

    function _swapOnParaswap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data,
        uint256 flagCode
    ) internal {
        require(_data.length > 0, "RA: Data is empty");

        address paraswap = flagToAddress[flagCode];
        require(paraswap != address(0), "RA: Exchange not found");

        if (fromToken.isETH()) {
            wnativeAddress.deposit{ value: amount }();
        }
        IERC20Upgradeable fromTokenReal = fromToken.isETH() ? wnativeAddress : fromToken;

        fromTokenReal.universalApprove(IAugustusSwapper(paraswap).getTokenTransferProxy(), type(uint256).max);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(paraswap).call(_data);
        if (destToken.isETH()) {
            // wnativeAddress.withdraw(wnativeAddress.balanceOf(address(this)));
            uint256 balanceThis = wnativeAddress.balanceOf(address(this));
            wnativeAddress.transfer(address(_ethHandler), wnativeAddress.balanceOf(address(this)));
            _ethHandler.withdraw(address(wnativeAddress), balanceThis);
        }
    }
}