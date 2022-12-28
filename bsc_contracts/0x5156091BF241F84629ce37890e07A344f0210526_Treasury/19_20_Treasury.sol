// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IBoardroom.sol";
import "./interfaces/IMainToken.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./lib/SafeMath.sol";
import "./lib/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lpnode/interfaces/ILPNode.sol";

contract Treasury is ContractGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct BoardroomInfo {
        address boardroom;
        uint256 allocPoint;
    }

    BoardroomInfo[] public boardroomInfo;
    uint256 public totalAllocPoint;

    uint256 public constant PERIOD = 6 hours;
    uint256 public constant PERCENTAGE = 10000;

    // governance
    address public operator;
    // flags
    bool public initialized;
    // epoch
    uint256 public startTime;
    uint256 public epoch;
    uint256 public previousEpoch;

    IUniswapV2Router public ROUTER;
    IUniswapV2Factory public FACTORY;
    IUniswapV2Pair public PAIR;

    IMainToken public mainToken;
    address public stableToken;
    address public medalPool;
    address public oracle;

    // price
    uint256 public mainTokenPriceOne;
    uint256 public mainTokenPriceCeiling;

    uint256 public totalEpochAbovePeg;
    uint256 public totalEpochUnderPeg;

    uint256[] public expansionTiersSupplies;
    uint256[] public expansionTiersRates;

    uint256 private constant DECIMALS = 18;
    uint256 private STABLE_DECIMALS;

    uint256 public withdrawLockupEpochs = 6;
    uint256 public rewardLockupEpochs = 3;

    uint256 public previousEpochMainPrice;

    uint256 public devFundPercent;
    uint256 public polFundPercent;
    uint256 public daoFundPercent;

    address public devWallet;
    address public daoWallet;
    address public polWallet;
    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);
    event PolFundFunded(uint256 timestamp, uint256 seigniorage);
    event SetOperator(address indexed account, address newOperator);
    event AddBoardroom(address indexed account, address newBoardroom, uint256 allocPoint);
    event SetBoardroomAllocPoint(uint256 _pid, uint256 oldValue, uint256 newValue);
    event SetMainTokenPriceCeiling(uint256 newValue);
    event SetExpansionTiersSupplies(uint8 _index, uint256 _value);
    event SetExpansionTiersRates(uint8 _index, uint256 _value);
    event SetDevFundPercent(uint256 oldValue, uint256 newValue);
    event SetDaoFundPercent(uint256 oldValue, uint256 newValue);
    event SetPolFundPercent(uint256 oldValue, uint256 newValue);
    event SetWithdrawLockupEpoch(uint256 oldValue, uint256 newValue);
    event SetRewardLockupEpoch(uint256 oldValue, uint256 newValue);
    event SetDaoWallet(address oldWallet, address newWallet);
    event SetPolWallet(address oldWallet, address newWallet);
    event SetDevWallet(address oldWallet, address newWallet);
    event AdminWithdraw(address _tokenAddress, uint256 _amount);

    constructor() {
        initialized = false;
        epoch = 0;
        previousEpoch = 0;
        previousEpochMainPrice = 0;

        totalEpochAbovePeg = 0;
        totalEpochUnderPeg = 0;

        devFundPercent = 1000; // 10%
        polFundPercent = 1000; // 10%
        daoFundPercent = 1000; // 10%
    }

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition() {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch() {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
    }

    modifier checkOperator() {
        require(IBasisAsset(address(mainToken)).operator() == address(this), "Treasury: need more permission");
        uint256 length = boardroomInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(Operator(boardroomInfo[pid].boardroom).operator() == address(this), "Treasury: need more permission");
        }

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() external view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getMainTokenPrice() public view returns (uint256) {
        try IOracle(oracle).consult(address(mainToken), 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult MainToken price from the oracle");
        }
    }

    function initialize(
        address _mainToken,
        address _medalPool,
        address _router,
        address _polWallet,
        address _daoWallet,
        address _devWallet,
        address _oracle,
        address _stableToken,
        uint256 _startTime
    ) external notInitialized {
        require(_mainToken != address(0), "!_mainToken");
        require(_medalPool != address(0), "!_medalPool");
        require(_router != address(0), "!_router");
        require(_polWallet != address(0), "!_polWallet");
        require(_daoWallet != address(0), "!_daoWallet");
        require(_devWallet != address(0), "!_devWallet");
        require(_oracle != address(0), "!_oracle");
        require(_stableToken != address(0), "!_stableToken");

        mainToken = IMainToken(_mainToken);
        stableToken = _stableToken;
        medalPool = _medalPool;
        ROUTER = IUniswapV2Router(_router);
        FACTORY = IUniswapV2Factory(ROUTER.factory());
        address pairAddress = FACTORY.getPair(address(mainToken), stableToken);
        require(pairAddress != address(0), "!pairAddress");
        PAIR = IUniswapV2Pair(pairAddress);
        oracle = _oracle;
        startTime = _startTime;

        polWallet = _polWallet;
        devWallet = _devWallet;
        daoWallet = _daoWallet;

        STABLE_DECIMALS = IERC20Metadata(_stableToken).decimals();

        mainTokenPriceOne = 10**STABLE_DECIMALS; // This is to allow a PEG of 1 MainToken per STABLE
        mainTokenPriceCeiling = mainTokenPriceOne.mul(101).div(100);

        expansionTiersSupplies = [0, 50 ether, 200 ether, 500 ether];
        expansionTiersRates = [10000, 8000, 6000, 4000];

        mainToken.grantRebaseExclusion(address(this)); // excluded

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
        emit SetOperator(msg.sender, _operator);
    }

    function checkBoardroomDuplicate(address _boardroom) internal view {
        uint256 length = boardroomInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(boardroomInfo[pid].boardroom != _boardroom, "Treasury: existing boardroom?");
        }
    }

    function addBoardroom(address _boardroom, uint256 _allocPoint) external onlyOperator {
        require(_boardroom != address(0), "!_boardroom");
        checkBoardroomDuplicate(_boardroom);
        boardroomInfo.push(BoardroomInfo({
            boardroom: _boardroom, 
            allocPoint: _allocPoint
        }));
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        IMainToken(mainToken).grantRebaseExclusion(_boardroom);
        emit AddBoardroom(msg.sender, _boardroom, _allocPoint);
    }

    function setBoardroomAllocPoint(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        BoardroomInfo storage boardroom = boardroomInfo[_pid];
        emit SetBoardroomAllocPoint(_pid, boardroom.allocPoint, _allocPoint);
        totalAllocPoint = totalAllocPoint.sub(boardroom.allocPoint).add(_allocPoint);
        boardroom.allocPoint = _allocPoint;
    }

    function grantRebaseExclusion(address who) external onlyOperator {
        IMainToken(mainToken).grantRebaseExclusion(who);
    }

    function revokeRebaseExclusion(address who) external onlyOperator {
        IMainToken(mainToken).revokeRebaseExclusion(who);
    }

    function setMainTokenPriceCeiling(uint256 _mainTokenPriceCeiling) external onlyOperator {
        require(_mainTokenPriceCeiling >= mainTokenPriceOne.mul(80).div(100) 
            && _mainTokenPriceCeiling <= mainTokenPriceOne.mul(110).div(100), "out of range (0.8, 1.1)"); // [0.8, 1.1]
        mainTokenPriceCeiling = _mainTokenPriceCeiling;
        emit SetMainTokenPriceCeiling(_mainTokenPriceCeiling);
    }

    function getEstimateStableToken(uint256 _mount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(mainToken);
        path[1] = stableToken;

        uint256[] memory amounts = ROUTER.getAmountsOut(_mount, path);
        return amounts[amounts.length - 1];
    }

    function getEstimatedReward(uint256 _pid) external view returns (uint256) {
        uint256 pairAmount = PAIR.balanceOf(address(this));
        // After allocate LP to DAO, POL
        pairAmount = pairAmount.mul(PERCENTAGE - daoFundPercent - polFundPercent).div(PERCENTAGE);
        uint256 medalEstimated = ILPNode(medalPool).getEstimateMedalToken(pairAmount);
        BoardroomInfo storage boardroomPool = boardroomInfo[_pid];
        if (boardroomPool.allocPoint > 0 && medalEstimated > 0) {
            uint256 boardroomRewardPercent = PERCENTAGE - devFundPercent;
            // After allocate MP to DEV
            medalEstimated = medalEstimated.mul(boardroomRewardPercent).div(PERCENTAGE);
            return medalEstimated.mul(boardroomPool.allocPoint).div(totalAllocPoint);
        }

        return 0;
    }

    function sellMainTokenAndAddLp() external { 
        uint256 mainTokenBalanceOf = mainToken.balanceOf(address(this));
        if (mainTokenBalanceOf == 0) return;

        uint256 tokenPrice = getEstimateStableToken(1 ether);
        if (tokenPrice > mainTokenPriceCeiling) {
            address[] memory path = new address[](2);
            path[0] = address(mainToken);
            path[1] = stableToken;

            // Sell mainToken
            uint256 maximumAmountSell = mainToken.circulatingSupply().mul(mainToken.maximumAmountSellPercent()).div(PERCENTAGE);
            uint256 mainTokenAmountToSell = maximumAmountSell.mul(9900).div(PERCENTAGE);
            if (mainTokenBalanceOf < mainTokenAmountToSell) {
                mainTokenAmountToSell = mainTokenBalanceOf;
            }
            _approveTokenIfNeeded(address(mainToken), mainTokenAmountToSell);
            ROUTER.swapExactTokensForTokens(
                mainTokenAmountToSell, 
                0, 
                path, 
                address(this),
                block.timestamp
            );

            uint256 stableTokenBalanceOf = IERC20(stableToken).balanceOf(address(this));
            mainTokenBalanceOf = mainToken.balanceOf(address(this));
            if (stableTokenBalanceOf > 0 && mainTokenBalanceOf > 0) {
                // Add LP
                if (mainTokenBalanceOf > mainTokenAmountToSell) {
                    mainTokenBalanceOf = mainTokenAmountToSell;
                }
                _approveTokenIfNeeded(stableToken, stableTokenBalanceOf);
                _approveTokenIfNeeded(address(mainToken), mainTokenBalanceOf);
                ROUTER.addLiquidity(
                    address(mainToken),
                    stableToken,
                    mainTokenBalanceOf,
                    stableTokenBalanceOf,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            }
        }
    }

    function _allocate() internal {
            // Allocate LP to DAO, POL
            uint256 pairAmount = PAIR.balanceOf(address(this));
            if (pairAmount > 0) {
                uint256 daoFundAmount = pairAmount.mul(daoFundPercent).div(PERCENTAGE);
                uint256 polFundAmount = pairAmount.mul(polFundPercent).div(PERCENTAGE);
                if (daoFundAmount > 0) {
                    IERC20(address(PAIR)).safeTransfer(daoWallet, daoFundAmount);
                    emit DaoFundFunded(block.timestamp, daoFundAmount);
                }

                if (polFundAmount > 0) {
                    IERC20(address(PAIR)).safeTransfer(polWallet, polFundAmount);
                    emit DaoFundFunded(block.timestamp, polFundAmount);
                }

                _depositToLPNode();
                _sendToBoardroom();
            }
    }

    function _depositToLPNode() internal {
        uint256 pairAmount = PAIR.balanceOf(address(this));
        if (pairAmount > 0) {
            PAIR.approve(medalPool, pairAmount);
            ILPNode(medalPool).deposit(pairAmount);
        }
    }

    function _sendToBoardroom() internal {
        uint256 medalTokenBalanceOf = IERC20(medalPool).balanceOf(address(this));
        if (medalTokenBalanceOf > 0) {
            uint256 devFundAmount = medalTokenBalanceOf.mul(devFundPercent).div(PERCENTAGE);
            if (devFundAmount > 0) {
                IERC20(medalPool).safeTransfer(devWallet, devFundAmount);
                emit DevFundFunded(block.timestamp, devFundAmount);
                medalTokenBalanceOf = medalTokenBalanceOf.sub(devFundAmount);
            }

            uint256 length = boardroomInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                BoardroomInfo storage boardroomPool = boardroomInfo[pid];
                if (boardroomPool.allocPoint > 0) {
                    uint256 boardroomReward = medalTokenBalanceOf.mul(boardroomPool.allocPoint).div(totalAllocPoint);
                    uint256 boardRoomAmount = IBoardroom(boardroomPool.boardroom).totalSupply();
                    if (boardroomReward > 0) {
                        if (boardRoomAmount > 0) {             
                            IERC20(medalPool).safeApprove(boardroomPool.boardroom, 0);
                            IERC20(medalPool).safeApprove(boardroomPool.boardroom, boardroomReward);
                            IBoardroom(boardroomPool.boardroom).allocateSeigniorage(boardroomReward);
                        }
                    }
                }
            }
        }
    }

    function _updatePrice() internal {
        try IOracle(oracle).update() {} catch {
            revert("Treasury: failed to update price from the oracle");
        }
    }

    function _approveTokenIfNeeded(address token, uint256 amount) private {
        if (IERC20(token).allowance(address(this), address(ROUTER)) < amount) {
            IERC20(token).safeApprove(address(ROUTER), type(uint256).max);
        }
    }

    function calculateExpansionRate(uint256 _tokenSupply) public view returns (uint256) {
        uint256 expansionRate;
        uint256 expansionTiersTwapsLength = expansionTiersSupplies.length;
        uint256 expansionTiersRatesLength = expansionTiersRates.length;
        require(expansionTiersTwapsLength == expansionTiersRatesLength, "ExpansionTiers data invalid");

        for (uint256 tierId = expansionTiersTwapsLength - 1; tierId >= 0; --tierId) {
            if (_tokenSupply >= expansionTiersSupplies[tierId]) {
                expansionRate = expansionTiersRates[tierId];
                break;
            }
        }
        
        return expansionRate;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updatePrice();
        previousEpochMainPrice = getMainTokenPrice();
        if (epoch > 0) {
            if (previousEpochMainPrice > mainTokenPriceCeiling) {
                totalEpochAbovePeg = totalEpochAbovePeg.add(1);
                // Expansion
                uint256 mainTokenCirculatingSupply = IMainToken(mainToken).circulatingSupply();
                uint256 percentage = previousEpochMainPrice;
                uint256 totalTokenExpansion = mainTokenCirculatingSupply.mul(percentage).div(100).div(10**STABLE_DECIMALS);

                if (totalTokenExpansion > 0) {
                    uint256 expansionRate = calculateExpansionRate(mainTokenCirculatingSupply);
                    totalTokenExpansion = totalTokenExpansion.mul(expansionRate).div(PERCENTAGE);
                    if (totalTokenExpansion > 0) {
                        IMainToken(mainToken).mint(address(this), totalTokenExpansion);
                    }
                }

                _allocate();
            }

            if (previousEpochMainPrice < mainTokenPriceCeiling) {
                totalEpochUnderPeg = totalEpochUnderPeg.add(1);
            }
        }
    }

    function setExpansionTiersSupplies(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        uint256 expansionTiersTwapsLength = expansionTiersSupplies.length;
        require(_index < expansionTiersTwapsLength, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > expansionTiersSupplies[_index - 1], "expansionTiersSupplies[i] has to be lower than expansionTiersSupplies[i + 1]");
        }
        if (_index < expansionTiersTwapsLength - 1) {
            require(_value < expansionTiersSupplies[_index + 1], "expansionTiersSupplies[i] has to be lower than expansionTiersSupplies[i + 1]");
        }
        expansionTiersSupplies[_index] = _value;
        emit SetExpansionTiersSupplies(_index, _value);
        return true;
    }

    function setExpansionTiersRates(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index < expansionTiersRates.length, "Index has to be lower than count of tiers");
        require(_value <= PERCENTAGE, "_value: out of range"); // [_value < 100%]
        expansionTiersRates[_index] = _value;
        emit SetExpansionTiersRates(_index, _value);
        return true;
    }

    function setDevFundPercent(uint256 _value) external onlyOperator {
        require(_value <= 1000, 'Treasury: Max percent is 10%');
        emit SetDevFundPercent(devFundPercent, _value);
        devFundPercent = _value;
    }

    function setPolFundPercent(uint256 _value) external onlyOperator {
        require(_value <= 1000, 'Treasury: Max percent is 10%');
        emit SetPolFundPercent(polFundPercent, _value);
        polFundPercent = _value;
    }

    function setDaoFundPercent(uint256 _value) external onlyOperator {
        require(_value <= 1000, 'Treasury: Max percent is 10%');
        emit SetDaoFundPercent(daoFundPercent, _value);
        daoFundPercent = _value;
    }

    function setPolWallet(address _polWallet) external onlyOperator {
        require(_polWallet != address(0), "_polWallet address cannot be 0 address");
		emit SetPolWallet(polWallet, _polWallet);
        polWallet = _polWallet;
    }

    function setDevWallet(address _devWallet) external onlyOperator {
        require(_devWallet != address(0), "_devWallet address cannot be 0 address");
		emit SetDevWallet(devWallet, _devWallet);
        devWallet = _devWallet;
    }

    function setDaoWallet(address _daoWallet) external onlyOperator {
        require(_daoWallet != address(0), "_daoWallet address cannot be 0 address");
		emit SetDaoWallet(daoWallet, _daoWallet);
        daoWallet = _daoWallet;
    }

    function setWithdrawLockupEpoch(uint256 _value) external onlyOperator {
        require(_value <= 10, "Treasury: Max value is 10");
        emit SetWithdrawLockupEpoch(withdrawLockupEpochs, _value);
        withdrawLockupEpochs = _value;
    }

    function setRewardLockupEpoch(uint256 _value) external onlyOperator {
        require(_value <= 5, "Treasury: Max value is 5");
        emit SetRewardLockupEpoch(rewardLockupEpochs, _value);
        rewardLockupEpochs = _value;
    }

    function adminWithdraw(address _tokenAddress, uint256 _amount) external onlyOperator {
        uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
        if (tokenBalance >= _amount) {
            IERC20(_tokenAddress).safeTransfer(polWallet, _amount);
        } else {
            IERC20(_tokenAddress).safeTransfer(polWallet, tokenBalance);
        }

        emit AdminWithdraw(_tokenAddress, _amount);
    }
}