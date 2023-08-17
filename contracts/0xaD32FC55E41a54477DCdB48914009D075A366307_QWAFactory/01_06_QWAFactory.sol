pragma solidity 0.8.19;

import "../interface/factory/ITreasuryAndStakedTokenFactory.sol";
import "../interface/factory/IStakingAndDistributorFactory.sol";
import "../token/QWA.sol";

contract QWAFactory is Ownable {
    /// EVENTS ///

    event Created(
        uint256 creationId,
        address indexed deployer,
        address _QWA,
        address _treasury,
        address _sQWA,
        address _staking,
        address _distributor
    );

    /// STATES VARIABLES ///
    ITreasuryAndStakedTokenFactory public treasuryAndStakedTokenFatory;
    IStakingAndDistributorFactory public stakingAndDistributorFactory;
    IUniswapV2Router02 public uniswapV2Router;

    uint256 public creationId;
    uint256 public maxTokenPercent;
    uint256 public percentNeededForDiscount;

    address public immutable WETH;
    address public immutable QWN;
    address public immutable sQWN;
    address public immutable QWNStaking;
    address public feeAddress;

    address[] public discountTokens;
    uint256[] public discountTokensNeeded;

    mapping(address => bool) public removedFromDiscount;

    mapping(uint256 => CreationDetails) public creationDetails;

    /// STRUCTS ///

    struct CreationDetails {
        address QWA;
        address treasury;
        address sQWA;
        address staking;
        address distributor;
    }

    /// CONSTRUCTOR ///

    constructor(
        address _weth,
        address _qwn,
        address _sQWN,
        address _qwnStaking,
        address _feeAddress
    ) {
        WETH = _weth;
        QWN = _qwn;
        sQWN = _sQWN;
        QWNStaking = _qwnStaking;
        feeAddress = _feeAddress;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;

        percentNeededForDiscount = 15;
        maxTokenPercent = 10;
    }

    /// CREATE FUNCTION ///

    /// @notice                       Create QWA token and contracts
    /// @param _backingTokens         Tokens to be used for backing
    /// @param _backingTokensV3Fee    What pool fee for v3 (0 if v2)
    /// @param _backingAmounts        Backing amount of token
    /// @param _nameAndSymbol         Name and symbol of token
    /// @param _creatorSupplyPercent  Creator percent of supply
    /// @param _owner                 Pass ownership to
    function create(
        address[] memory _backingTokens,
        uint24[] memory _backingTokensV3Fee,
        uint256[] memory _backingAmounts,
        string[2] memory _nameAndSymbol,
        uint256 _creatorSupplyPercent,
        address _owner
    )
        external
        payable
        returns (
            address _QWAAddress,
            address _treasuryAddress,
            address _sQWAAddress,
            address _stakingAddress,
            address _distributorAddress
        )
    {
        require(
            _creatorSupplyPercent <= maxTokenPercent,
            "Can not send team more than max percent"
        );
        require(
            _backingTokens.length == _backingAmounts.length &&
                _backingTokensV3Fee.length == _backingAmounts.length,
            "Different array lengths"
        );

        require(_backingTokens.length > 0, "Can not have no backing tokens");

        require(
            msg.value >= 0.5 ether,
            "Can not add less than 0.5 ETH liquidity"
        );

        for (uint i; i < _backingTokens.length; i++) {
            require(
                _backingAmounts[i] > 0,
                "Backing amount needs to be greater than 0"
            );
            require(
                _backingTokensV3Fee[i] == 0 ||
                    _backingTokensV3Fee[i] == 500 ||
                    _backingTokensV3Fee[i] == 3000 ||
                    _backingTokensV3Fee[i] == 10000,
                "Invalid V3 pool fee (0.05%, 0.3%, 1%)"
            );
        }

        QuantumWealthAcceleratorToken _QWA = new QuantumWealthAcceleratorToken(
            address(this),
            WETH,
            _backingTokens,
            _backingTokensV3Fee,
            _nameAndSymbol[0],
            _nameAndSymbol[1]
        );

        _QWAAddress = address(_QWA);

        bool _qwnBackingToken;
        for (uint i; i < _backingTokens.length; ++i) {
            if (_backingTokens[i] == QWN) {
                _qwnBackingToken = true;
                break;
            }
        }

        (_treasuryAddress, _sQWAAddress) = treasuryAndStakedTokenFatory.create(
            _QWAAddress,
            _backingTokens,
            _backingAmounts,
            _nameAndSymbol,
            _qwnBackingToken
        );

        (_stakingAddress, _distributorAddress) = stakingAndDistributorFactory
            .create(_QWAAddress, _sQWAAddress, _treasuryAddress, _owner);

        _QWA.setTreasury(_treasuryAddress);
        _QWA.transferOwnership(_owner);

        treasuryAndStakedTokenFatory.setDistributorAndInitialize(
            _distributorAddress,
            _stakingAddress,
            _treasuryAddress,
            _sQWAAddress,
            _owner
        );

        if (_creatorSupplyPercent > 0) {
            uint256 _teamMint = (IERC20(_QWAAddress).balanceOf(address(this)) *
                _creatorSupplyPercent) / 100;
            IERC20(_QWAAddress).transfer(_owner, _teamMint);
        }

        uint256 _balance = IERC20(_QWAAddress).balanceOf(address(this));
        IERC20(_QWAAddress).approve(address(uniswapV2Router), _balance);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            _QWAAddress,
            _balance,
            0,
            0,
            _treasuryAddress,
            block.timestamp
        );

        CreationDetails storage _creationDetails = creationDetails[creationId];
        _creationDetails.QWA = _QWAAddress;
        _creationDetails.treasury = _treasuryAddress;
        _creationDetails.sQWA = _sQWAAddress;
        _creationDetails.staking = _stakingAddress;
        _creationDetails.distributor = _distributorAddress;

        emit Created(
            creationId,
            msg.sender,
            _QWAAddress,
            _treasuryAddress,
            _sQWAAddress,
            _stakingAddress,
            _distributorAddress
        );

        creationId++;
    }

    /// OWNER FUNCTION ///

    /// @notice Set factory address
    function setFactoryAddresses(
        address _treasuryAndStakedTokenFatory,
        address _stakingAndDistributorFactory
    ) external onlyOwner {
        require(
            address(treasuryAndStakedTokenFatory) == address(0),
            "Addresses already set"
        );
        treasuryAndStakedTokenFatory = ITreasuryAndStakedTokenFactory(
            _treasuryAndStakedTokenFatory
        );
        stakingAndDistributorFactory = IStakingAndDistributorFactory(
            _stakingAndDistributorFactory
        );
    }

    /// @notice Set fee address to query
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    /// @notice Set max token percent creator can take
    function setMaxTokenPercent(uint256 _maxPercent) external onlyOwner {
        maxTokenPercent = _maxPercent;
    }

    /// @notice Set percent of QWN supply in sQWN to receive discount on fees
    function setPercentNeededForDiscount(uint256 _percent) external onlyOwner {
        percentNeededForDiscount = _percent;
    }

    /// @notice Remove address from having discount on fees
    function setRemovedFromDiscount(
        address _user,
        bool _removed
    ) external onlyOwner {
        removedFromDiscount[_user] = _removed;
    }

    /// @notice Set tokens and amounts to receive discount on QWA fees
    function setDiscountTokens(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(_tokens.length == _amounts.length, "Different array lengths");

        discountTokens = _tokens;
        discountTokensNeeded = _amounts;
    }

    // VIEW FUNCTION ///

    /// @notice           Returns if address has discount on QWA fees
    /// @param _user      Address to check receives discount on fees
    /// @param _discount  Bool if has discount on fees
    function feeDiscount(address _user) external view returns (bool _discount) {
        if (removedFromDiscount[_user]) return false;
        uint256 sQWNBalance = IERC20(sQWN).balanceOf(_user);
        uint256 QWNSupply = IERC20(QWN).totalSupply();
        if (sQWNBalance >= (QWNSupply * percentNeededForDiscount) / 10000)
            return true;

        for (uint i; i < discountTokens.length; ++i) {
            if (
                IERC20(discountTokens[i]).balanceOf(_user) >=
                discountTokensNeeded[i]
            ) return true;
        }
    }

    /// @notice             Returns addrseses of creation
    /// @param _creationId  Creation id to return address for
    function created(
        uint256 _creationId
    ) external view returns (CreationDetails memory) {
        return creationDetails[_creationId];
    }
}