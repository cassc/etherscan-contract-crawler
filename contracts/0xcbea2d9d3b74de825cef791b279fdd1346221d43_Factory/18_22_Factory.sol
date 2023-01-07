// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../contracts/tokens/THERUGGAME.sol";

contract Factory is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    AutomationCompatibleInterface
{
    uint256 private _gameEndTime;
    uint256 private _winnerTotalRewards;
    uint16 public constant MAX_TAX = 400;
    uint16 public requestConfirmations;
    uint32 public callbackGasLimit;
    uint32 public numWords;
    uint256 public burnTax;
    uint256 public cultTax;
    uint256 public gameStartTime;
    uint256 public rewardTax;
    uint256 public trgTax;
    uint256 public slippage;
    address public cult;
    address public dCult;
    address public trg;
    address public sTrg;
    address public linkAddress;
    address public wrapperAddress;
    address public previousWinner;
    address public previousLoser;
    bool public rugDaysRequestStatus;

    LinkTokenInterface private LINK;
    VRFV2WrapperInterface private VRF_V2_WRAPPER;

    mapping(address => uint256) public winnerTotalRewards;
    mapping(address => uint256) public dividendPerToken;

    uint256[] private _rugDays;
    address[] public gameTokens;
    address[] public activeTokens;
    address[] public eliminatedTokens;

    error InvalidAddress();
    error InvalidEliminationDay();
    error InvalidIndex();
    error InvalidSlippage();
    error InvalidTax();
    error InvalidTime();
    error InvalidWrapperVRF();

    event CultUpdated(address indexed updatedCult);
    event DCultUpdated(address indexed updatedDCult);
    event EliminationTimeUpdated(uint256 indexed updatedTime);
    event TaxesUpdated(
        uint256 burnTax,
        uint256 cultTax,
        uint256 rewardTax,
        uint256 trgTax
    );
    event TokenCreated(address indexed token);
    event TrgUpdated(address indexed updatedTrg);
    event STrgUpdated(address indexed updatedSTrg);
    event SlippageUpdated(uint256 indexed slippage);

    function initialize(
        address _trg,
        address _sTrg,
        address _cult,
        address _dCult,
        uint256 _burnTax,
        uint256 _cultTax,
        uint256 _rewardTax,
        uint256 _trgTax
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        if (_trg == address(0) || _cult == address(0) || _dCult == address(0))
            revert InvalidAddress();

        if (_burnTax + _cultTax + _rewardTax + _trgTax > MAX_TAX)
            revert InvalidTax();

        trg = _trg;
        sTrg = _sTrg;
        cult = _cult;
        dCult = _dCult;
        burnTax = _burnTax;
        cultTax = _cultTax;
        rewardTax = _rewardTax;
        trgTax = _trgTax;
        slippage = 50;

        updateVrfConfiguration(
            100000,
            3,
            10,
            0x514910771AF9Ca656af840dff83E8264EcF986CA,
            0x5A861794B927983406fCE1D062e00b9368d97Df6
        );
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint256 amountToken,
        uint256 amountWETH
    ) external onlyOwner {
        address _token = address(
            new THERUGGAME(name, symbol, amountToken, address(this))
        );

        if (
            block.timestamp <= gameStartTime + _gameEndTime ||
            (block.timestamp > gameStartTime + _gameEndTime &&
                eliminatedTokens.length != _rugDays.length &&
                eliminatedTokens.length != 0)
        ) revert InvalidTime();

        gameTokens.push(_token);
        activeTokens.push(_token);
        Liquidity.addLiquidity(
            _token,
            Liquidity.WETH,
            amountToken,
            amountWETH,
            address(this)
        );

        gameStartTime = block.timestamp;
        _gameEndTime = 0;

        emit TokenCreated(_token);
    }

    function _getPoints(address _token) private view returns (uint256) {
        return THERUGGAME(_token).points();
    }

    function _getWethReward(address _token) private view returns (uint256) {
        return THERUGGAME(_token).wethReward();
    }

    function _getWinnerAndLoser()
        private
        view
        returns (
            address winnerToken,
            address loserToken,
            uint256 winnerPoints,
            uint256 loserPoints,
            uint256 winnerIndex,
            uint256 loserIndex
        )
    {
        loserPoints = type(uint256).max;
        for (uint256 i = 0; i < activeTokens.length; i++) {
            if (activeTokens[i] != address(0)) {
                if (_getPoints(activeTokens[i]) >= winnerPoints) {
                    winnerPoints = _getPoints(activeTokens[i]);
                    winnerToken = activeTokens[i];
                    winnerIndex = i;
                }
                if (_getPoints(activeTokens[i]) <= loserPoints) {
                    loserPoints = _getPoints(activeTokens[i]);
                    loserToken = activeTokens[i];
                    loserIndex = i;
                }
            }
        }
        loserPoints = loserPoints == type(uint256).max ? 0 : loserPoints;
    }

    function isValidBribe(address _token) external view returns (bool) {
        for (uint8 i = 0; i < eliminatedTokens.length; i++) {
            if (eliminatedTokens[i] == _token) return true;
        }
        return false;
    }

    function distributeRewardsAndRugLoser() private {
        (
            address winnerToken,
            address loserToken,
            ,
            ,
            ,
            uint256 index
        ) = _getWinnerAndLoser();

        if (winnerToken == address(0) || loserToken == address(0))
            revert InvalidAddress();

        _distributeRewards(winnerToken);
        _rugLoser(loserToken, index);

        previousWinner = winnerToken;
        previousLoser = loserToken;
    }

    function _distributeRewards(address _winnerToken) private {
        uint256 totalReward;
        for (uint256 i = 0; i < gameTokens.length; i++) {
            totalReward += _getWethReward(gameTokens[i]);
        }

        uint256 totalActiveReward = totalReward - _winnerTotalRewards;

        transferIERC20(Liquidity.WETH, _winnerToken, totalActiveReward);

        address pair = Liquidity.getPair(_winnerToken, Liquidity.WETH);
        uint256 validSupply = IERC20(_winnerToken).totalSupply() -
            balanceOfIERC20(_winnerToken, pair) +
            balanceOfIERC20(_winnerToken, Liquidity.DEAD_ADDRESS) +
            balanceOfIERC20(_winnerToken, _winnerToken);

        _winnerTotalRewards += totalActiveReward;
        winnerTotalRewards[_winnerToken] += totalActiveReward;
        if (validSupply > 0)
            dividendPerToken[_winnerToken] +=
                (totalActiveReward * 1e18) /
                validSupply;
    }

    function _rugLoser(address _loserToken, uint256 _index) private {
        (, uint256 amountB) = Liquidity.removeLiquidity(
            _loserToken,
            Liquidity.WETH,
            address(this)
        );

        eliminatedTokens.push(_loserToken);
        delete activeTokens[_index];

        uint256 swappedTrg = Liquidity.swap(
            Liquidity.WETH,
            trg,
            amountB,
            slippage,
            address(this)
        );
        transferIERC20(trg, sTrg, swappedTrg);
    }

    function updateCult(address _cult) external onlyOwner {
        if (_cult == address(0)) revert InvalidAddress();
        cult = _cult;

        emit CultUpdated(_cult);
    }

    function updateDCult(address _dCult) external onlyOwner {
        if (_dCult == address(0)) revert InvalidAddress();
        dCult = _dCult;

        emit DCultUpdated(_dCult);
    }

    function updateTrg(address _trg) external onlyOwner {
        if (_trg == address(0)) revert InvalidAddress();
        trg = _trg;

        emit TrgUpdated(_trg);
    }

    function updateSTrg(address _sTrg) external onlyOwner {
        if (_sTrg == address(0)) revert InvalidAddress();
        sTrg = _sTrg;

        emit STrgUpdated(_sTrg);
    }

    function updateSlippage(uint256 _slippage) external onlyOwner {
        if (_slippage > 1000 && _slippage < 40) revert InvalidSlippage();
        slippage = _slippage;

        emit SlippageUpdated(_slippage);
    }

    function updateTaxes(
        uint256 _burnTax,
        uint256 _cultTax,
        uint256 _rewardTax,
        uint256 _trgTax
    ) external onlyOwner {
        if (_burnTax + _cultTax + _rewardTax + _trgTax > MAX_TAX)
            revert InvalidTax();

        burnTax = _burnTax;
        cultTax = _cultTax;
        rewardTax = _rewardTax;
        trgTax = _trgTax;

        emit TaxesUpdated(_burnTax, _cultTax, _rewardTax, _trgTax);
    }

    function balanceOfIERC20(address _token, address _user)
        private
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_user);
    }

    function transferIERC20(
        address _token,
        address _to,
        uint256 _amount
    ) private returns (bool) {
        return IERC20(_token).transfer(_to, _amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // chainlink
    function updateVrfConfiguration(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        address _linkAddress,
        address _wrapperAddress
    ) public onlyOwner {
        if (_linkAddress == address(0) || _wrapperAddress == address(0))
            revert InvalidAddress();

        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
        linkAddress = _linkAddress;
        wrapperAddress = _wrapperAddress;

        LINK = LinkTokenInterface(_linkAddress);
        VRF_V2_WRAPPER = VRFV2WrapperInterface(_wrapperAddress);
    }

    function requestRandomness(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) internal returns (uint256 requestId) {
        LINK.transferAndCall(
            address(VRF_V2_WRAPPER),
            VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
            abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
        );
        return VRF_V2_WRAPPER.lastRequestId();
    }

    function requestRugDays() external onlyOwner {
        if (_rugDays.length + numWords != activeTokens.length)
            revert InvalidTime();

        requestRandomness(callbackGasLimit, requestConfirmations, numWords);
        rugDaysRequestStatus = false;
    }

    function fulfillRandomWords(
        uint256, /* _requestId */
        uint256[] memory _randomWords
    ) internal {
        for (uint8 i = 0; i < numWords; i++) {
            uint256 day = ((_randomWords[i] % 30) + 31) * 1 days;
            _gameEndTime += day;
            _rugDays.push(_gameEndTime);
        }
        rugDaysRequestStatus = true;
    }

    function rawFulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) external {
        if (msg.sender != address(VRF_V2_WRAPPER)) revert InvalidWrapperVRF();
        fulfillRandomWords(_requestId, _randomWords);
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))));
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        performData = "";
        if (
            _rugDays.length == 0 ||
            _rugDays[eliminatedTokens.length] == 0 ||
            _gameEndTime == 0
        ) upkeepNeeded = false;
        else if (
            block.timestamp > gameStartTime + _gameEndTime &&
            eliminatedTokens.length == _rugDays.length
        ) upkeepNeeded = false;
        else {
            uint256 validTime = gameStartTime +
                (_rugDays[eliminatedTokens.length]);

            upkeepNeeded = block.timestamp >= validTime;
        }
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        bool upkeepNeeded;
        if (
            _rugDays.length == 0 ||
            _rugDays[eliminatedTokens.length] == 0 ||
            _gameEndTime == 0
        ) upkeepNeeded = false;
        else if (
            block.timestamp > gameStartTime + _gameEndTime &&
            eliminatedTokens.length == _rugDays.length
        ) upkeepNeeded = false;
        else {
            uint256 validTime = gameStartTime +
                (_rugDays[eliminatedTokens.length]);

            upkeepNeeded = block.timestamp >= validTime;
        }

        if (!upkeepNeeded) {
            revert InvalidEliminationDay();
        }
        distributeRewardsAndRugLoser();
    }
}