//   _____    _           _       ____             _
//  |  ___|__| |_ ___ ___| |__   |  _ \ ___   ___ | |
//  | |_ / _ \ __/ __/ __| '_ \  | |_) / _ \ / _ \| |
//  |  _|  __/ || (_| (__| | | | |  __/ (_) | (_) | |___
//  |_|  \___|\__\___\___|_| |_| |_|   \___/ \___/|_____|

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../FetcchBridge.sol";
import "./IFetcchPool.sol";
import "../CommLayerAggregator/CommLayerAggregator.sol";
import "../Dex/OneInchProvider.sol";
import "../Structs.sol";
import "../FetcchFeeLibrary.sol";
import "solmate/mixins/ERC4626.sol";

contract FetcchUSDTPool is IFetcchPool, ERC4626, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Float handler to handle percent calculations
    uint256 constant FLOAT_HANDLER_TEN_4 = 10000;

    /// @notice LCM of decimals
    uint256 immutable sharedDecimals;

    /// @notice Common decimals for major tokens
    uint256 immutable localDecimals;

    /// @notice Rate to convert input decimals to required decimals
    uint256 immutable convertRate;

    ///@notice keeps track of liquidity available in this pool
    uint256 public availableLiquidity;

    /// @notice keeps of incentives collected by this pool
    uint256 public incentivePool;

    /// @notice keeps track of lp fee collected by this pool
    uint256 public lpFeePool;

    /// @notice keeps track of platform fee collected by this pool
    uint256 public platformFeePool;

    /// @notice Address for native token
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    mapping(address => bool) internal isValidCommLayer;

    /// @notice Fetcch bridge address
    FetcchBridge public bridge;

    /// @notice communication layer aggregator address
    CommLayerAggregator public commLayer;

    /// @notice OneInch implementation address
    OneInchProvider public dex;

    /// @notice Fetcch fee library address
    FetcchFeeLibrary public feeLib;

    /// @dev Initializes the contract by setting asset address, localDecimals, sharedDecimals, dex and fee library
    constructor(
        address _asset,
        uint256 _localDecimals,
        uint256 _sharedDecimals,
        address _dex,
        address _feeLib
    ) ERC4626(ERC20(_asset), "Fetcch USDT", "FUSDT") {
        dex = OneInchProvider(_dex);
        feeLib = FetcchFeeLibrary(_feeLib);
        localDecimals = _localDecimals;
        sharedDecimals = _sharedDecimals;
        convertRate = 10**(localDecimals.sub(sharedDecimals));
    }

    modifier onlyCommLayer() {
        require(msg.sender == address(commLayer));
        _;
    }

    modifier onlyBridge() {
        require(msg.sender == address(bridge));
        _;
    }

    function changeBridge(address _bridge) external onlyOwner {
        bridge = FetcchBridge(_bridge);
    }

    function setCommLayers(address _commLayer) external onlyOwner {
        isValidCommLayer[_commLayer] = true;
    }

    /// @notice This function is responsible for chaning communication layer aggregator address
    /// @dev onlyOwner is allowed to call this function
    /// @param _commLayer Communication layer aggregator address
    function changeCommLayer(address _commLayer) external onlyOwner {
        commLayer = CommLayerAggregator(_commLayer);
    }

    /// @notice This function is responsible for changing OneInch implementation addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _dex New OneInch implementation address
    function changeDex(address _dex) external onlyOwner {
        dex = OneInchProvider(_dex);
    }

    /// @notice This function is responsible for changing Fee library addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _feeLib New OneInch implementation address
    function changeFeeLib(address _feeLib) external onlyOwner {
        feeLib = FetcchFeeLibrary(_feeLib);
    }

    /// @notice This function is responsible for converting amount from shared decimals to local decimals
    /// @param _amount Amount of tokens
    function amountSDtoLD(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(convertRate);
    }

    /// @notice This function is responsible for converting amount from local decimals to shared decimals
    /// @param _amount Amount of tokens
    function amountLDtoSD(uint256 _amount) internal view returns (uint256) {
        return _amount.div(convertRate);
    }

    /// @notice This function returns totalAssets available in this pool
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        suppliedLiquidity += assets;
        availableLiquidity += assets;
    }

    /// @notice This function is responsible for depositing tokens in pool and sending message using commLayer
    /// @dev This function can be called only by Fetcch bridge
    /// @param _tokenIn Address of token to deposit
    /// @param _amount Amount of token to deposit
    /// @param _commLayerId Id of communication layer
    /// @param _toChain Destination chain data
    /// @param _extraParams Encoded extra parameters
    function swap(
        address _tokenIn,
        uint256 _amount,
        uint256 _commLayerId,
        ToChainData memory _toChain,
        bytes memory _extraParams
    ) external payable onlyBridge {
        require(_tokenIn == address(asset), "Token not supported");
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amount);

        availableLiquidity = availableLiquidity.add(_amount);
        uint256 _eqRewards = feeLib.getEqRewards(
            address(this),
            _tokenIn,
            _amount,
            suppliedLiquidity,
            availableLiquidity,
            incentivePool
        );
        incentivePool = incentivePool.sub(_eqRewards);
        uint256 _amountIn = amountLDtoSD(_amount).add(_eqRewards);

        bytes memory _payload = abi.encode(
            _toChain._fromToken,
            _toChain._toToken,
            _amountIn,
            _toChain._receiver,
            _toChain._dex
        );

        commLayer.sendMsg{value: msg.value}(
            _commLayerId,
            _toChain._destination,
            _payload,
            _extraParams
        );
    }

    /// @notice This function is responsible for releasing the token after receiving message
    /// @dev This function can only be called by commLayer
    /// @param _fromToken Address of receiving token
    /// @param _toToken Address of required token by the user
    /// @param _amount Amount of tokens
    /// @param _receiver Address of receiver
    /// @param _dex Dex data required to perform same chain swap
    function release(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        address _receiver,
        DexData memory _dex
    ) external {
        require(
            isValidCommLayer[msg.sender],
            "Not a valid communication layer"
        );
        uint256 _eqFees = feeLib.getEqFees(
            address(this),
            _fromToken,
            _amount,
            suppliedLiquidity,
            availableLiquidity
        );
        incentivePool = incentivePool.add(_eqFees);

        uint256 _lpFees = feeLib.getLPFee(_amount);
        lpFeePool = lpFeePool.add(_lpFees);
        uint256 _platformFees = feeLib.getPlatformFee(_amount);
        platformFeePool = platformFeePool.add(_platformFees);
        uint256 _amountOut = amountSDtoLD(_amount)
            .sub(_eqFees)
            .sub(_lpFees)
            .sub(_platformFees);
        availableLiquidity = availableLiquidity.sub(_amountOut);

        if (_fromToken != _toToken) {
            IERC20(_fromToken).safeIncreaseAllowance(address(dex), _amountOut);
            dex.swapERC20(_dex._executor, _dex._desc, _dex._data);
        } else {
            IERC20(_toToken).safeTransfer(_receiver, _amountOut);
        }
    }

    function beforeWithdraw(uint256 assets, uint256 shares)
        internal
        view
        override
        returns (uint256 rewards)
    {
        uint256 LpShare = uint256(100).mul(assets).div(totalAssets());
        rewards = LpShare.div(100).mul(lpFeePool);
    }

    function withdrawPlatformFees(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice function responsible to rescue funds if any
    /// @param  tokenAddr address of token
    function rescueFunds(address tokenAddr) external onlyOwner {
        if (tokenAddr == NATIVE_TOKEN_ADDRESS) {
            uint256 balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            uint256 balance = IERC20(tokenAddr).balanceOf(address(this));
            IERC20(tokenAddr).safeTransfer(msg.sender, balance);
        }
    }
}