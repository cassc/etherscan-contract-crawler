pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IQWA.sol";
import "./interface/IWETH.sol";
import "./interface/IStaking.sol";
import "./interface/IUniswapV2Router02.sol";

/// @title   QWATreasury
/// @notice  QWA TREASURY
contract QWATreasury is Ownable {
    /// STATE VARIABLS ///

    /// @notice Address of UniswapV2Router
    IUniswapV2Router02 private immutable uniswapV2Router;
    /// @notice QWN address
    address private immutable QWN;
    /// @notice sQWN address
    address private immutable sQWN;
    /// @notice QWN staking address
    address private immutable QWNStaking;
    /// @notice WETH address
    address private immutable WETH;

    /// @notice QWA address
    address public immutable QWA;
    /// @notice QWA/ETH LP
    address public immutable uniswapV2Pair;

    /// @notice Distributor
    address public distributor;

    /// @notice Time to wait before removing liquidity again
    uint256 private constant TIME_TO_WAIT = 1 days;

    /// @notice Max percent of liqudity that can be removed at one time
    uint256 private constant MAX_REMOVAL = 10;

    /// @notice Timestamp of last liquidity removal
    uint256 public lastRemoval;

    /// @notice Array of backing tokens
    address[] public backingTokens;
    /// @notice Array of corresponding backing token amount needed per token
    uint256[] public backingTokenAmounts;

    bool private qwnBackingToken;

    /// CONSTRUCTOR ///

    /// @param _QWN                  Address of QWN
    /// @param _sQWN                 Address of sQWN
    /// @param _QWNStaking           Address of QWN Staking
    /// @param _QWA                  Address of QWA
    /// @param _WETH                 Address of WETH
    /// @param _backingTokens        Array of backing tokens
    /// @param _backingTokenAmounts  Array of backing token amount
    /// @param _qwnBackingToken      Bool if QWN is a backing token
    constructor(
        address _QWN,
        address _sQWN,
        address _QWNStaking,
        address _QWA,
        address _WETH,
        address[] memory _backingTokens,
        uint256[] memory _backingTokenAmounts,
        bool _qwnBackingToken
    ) {
        QWN = _QWN;
        sQWN = _sQWN;
        QWNStaking = _QWNStaking;
        QWA = _QWA;
        WETH = _WETH;
        backingTokens = _backingTokens;
        backingTokenAmounts = _backingTokenAmounts;
        uniswapV2Pair = IQWA(QWA).uniswapV2Pair();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;

        qwnBackingToken = _qwnBackingToken;
    }

    /// RECEIVE ///

    /// @notice Allow to receive ETH
    receive() external payable {}

    /// MINTER FUNCTION ///

    /// @notice         Distributor mints QWA
    /// @param _to      Address where to mint QWA
    /// @param _amount  Amount of QWA to mint
    function mintQWA(address _to, uint256 _amount) external {
        require(msg.sender == distributor, "not distributor");
        IQWA(QWA).mint(_to, _amount);

        if (qwnBackingToken) {
            uint256 balance = IERC20(QWN).balanceOf(address(this));
            IERC20(QWN).approve(QWNStaking, balance);
            IStaking(QWNStaking).stake(address(this), balance);
        }
    }

    /// VIEW FUNCTION ///

    /// @notice          Returns amount of excess reserves
    /// @return excess_  Excess reserves
    function excessReserves() external view returns (uint256 excess_) {
        uint256[] memory _balances = new uint256[](backingTokens.length);
        uint256[] memory _values = new uint256[](backingTokens.length);

        uint256 _totalSupply = IERC20(QWA).totalSupply();
        uint256 _mintableValue;

        for (uint i; i < backingTokens.length; ++i) {
            uint256 _balance = IERC20(backingTokens[i]).balanceOf(
                address(this)
            );
            if (backingTokens[i] == QWN)
                _balance += IERC20(sQWN).balanceOf(address(this));
            _balances[i] = _balance;
            uint256 _value = (_balance * 1e9) / backingTokenAmounts[i];
            if (_totalSupply > _value) return 0;

            _values[i] = _value;

            if (i == 0) _mintableValue = _value;
            else if (_value < _values[i - 1]) _mintableValue = _value;
        }

        return (_mintableValue - IERC20(QWA).totalSupply());
    }

    /// MUTATIVE FUNCTIONS ///

    /// @notice         Redeem QWA for backing
    /// @param _amount  Amount of QWA to redeem
    function redeemQWA(uint256 _amount) external {
        IQWA(QWA).burnFrom(msg.sender, _amount);
        for (uint i; i < backingTokens.length; ++i) {
            uint256 amountToSend = (_amount * backingTokenAmounts[i]) / 1e9;
            if (backingTokens[i] == QWN) {
                IERC20(sQWN).approve(QWNStaking, amountToSend);
                IStaking(QWNStaking).unstake(
                    address(this),
                    amountToSend,
                    false
                );
            }
            IERC20(backingTokens[i]).transfer(msg.sender, amountToSend);
        }
    }

    /// @notice Wrap any ETH in conract
    function sendETHToToken() public {
        uint256 ethBalance_ = address(this).balance;
        bool success;
        if (ethBalance_ > 0)
            (success, ) = address(QWA).call{value: ethBalance_}("");
    }

    /// OWNER FUNCTIONS ///

    /// @notice         Withdraw stuck token from treasury
    /// @param _amount  Amount of token to remove
    /// @param _token   Address of token to remove
    function withdrawStuckToken(
        uint256 _amount,
        address _token
    ) external onlyOwner {
        require(_token != uniswapV2Pair);
        if (qwnBackingToken) require(_token != sQWN);
        for (uint i; i < backingTokens.length; ++i) {
            require(_token != backingTokens[i]);
        }
        IERC20(_token).transfer(msg.sender, _amount);
    }

    /// @notice              Set QWA distributor
    /// @param _distributor  Address of QWA distributor
    function setDistributor(address _distributor) external onlyOwner {
        require(distributor == address(0));
        distributor = _distributor;
    }

    /// @notice         Remove liquidity and add to backing
    /// @param _amount  Amount of liquidity to remove
    function removeLiquidity(uint256 _amount) external onlyOwner {
        uint256 balance = IERC20(uniswapV2Pair).balanceOf(address(this));
        require(_amount <= (balance * MAX_REMOVAL) / 100, "10% of liquidity");
        require(block.timestamp > lastRemoval + TIME_TO_WAIT, "1 day lock");
        lastRemoval = block.timestamp;

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), _amount);

        uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
            QWA,
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        sendETHToToken();

        _burnQWA();
    }

    /// INTERNAL FUNCTION ///

    /// @notice Burn QWA from Treasury to increase backing
    /// @dev    Invoked in `removeLiquidity()`
    function _burnQWA() internal {
        uint256 balance = IERC20(QWA).balanceOf(address(this));
        IQWA(QWA).burn(balance);
    }
}