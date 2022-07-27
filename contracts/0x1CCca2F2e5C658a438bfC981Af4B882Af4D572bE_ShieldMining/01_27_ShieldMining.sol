// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./libraries/DecimalsConverter.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IPolicyBookFacade.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/IShieldMining.sol";
import "./interfaces/IUserLeveragePool.sol";
import "./interfaces/ILeveragePortfolioView.sol";
import "./interfaces/ILeveragePortfolio.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract ShieldMining is IShieldMining, OwnableUpgradeable, ReentrancyGuard, AbstractDependant {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using Math for uint256;

    address public policyBookFabric;
    IPolicyBookRegistry public policyBookRegistry;

    mapping(address => ShieldMiningInfo) public shieldMiningInfo;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) internal _rewards;

    /// @dev    block number to reward per block (to substrate) //deprecated
    mapping(address => mapping(uint256 => uint256)) public endOfRewards;

    // new state post v2
    Counters.Counter public lastDepositId;
    mapping(address => EnumerableSet.UintSet) private _usersDepositsId;
    mapping(uint256 => ShieldMiningDeposit) public usersDeposits;

    ILeveragePortfolioView public leveragePortfolioView;

    mapping(address => EnumerableSet.UintSet) internal lastBlockWithRewardList;
    mapping(address => uint256) public userleveragepoolsParticipatedAmounts;

    address public bmiCoverStakingAddress;
    mapping(address => uint256) public userleveragepoolsTotalSupply;

    Networks private _currentNetwork;

    event ShieldMiningAssociated(address indexed policyBook, address indexed shieldToken);
    event ShieldMiningFilled(
        address indexed policyBook,
        address indexed shieldToken,
        address indexed depositor,
        uint256 amount,
        uint256 lastBlockWithReward
    );
    event ShieldMiningClaimed(address indexed user, address indexed policyBook, uint256 reward);
    event ShieldMiningRecovered(address indexed policyBook, uint256 amount);

    modifier shieldMiningEnabled(address _policyBook) {
        require(
            address(shieldMiningInfo[_policyBook].rewardsToken) != address(0),
            "SM: no shield mining associated"
        );
        _;
    }

    modifier updateReward(
        address _policyBook,
        address _userLeveragePool,
        address account
    ) {
        _updateReward(_policyBook, _userLeveragePool, account);
        _;
    }

    modifier onlyBMICoverStaking() {
        require(
            bmiCoverStakingAddress == _msgSender(),
            "SM: Caller is not BMICoverStaking contract"
        );
        _;
    }

    function __ShieldMining_init(Networks _network) external initializer {
        __Ownable_init();
        _currentNetwork = _network;
    }

    function configureNetwork(Networks _network) public onlyOwner {
        _currentNetwork = _network;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        policyBookFabric = _contractsRegistry.getPolicyBookFabricContract();
        leveragePortfolioView = ILeveragePortfolioView(
            _contractsRegistry.getLeveragePortfolioViewContract()
        );
        bmiCoverStakingAddress = _contractsRegistry.getBMICoverStakingContract();
    }

    function blocksWithRewardsPassed(address _policyBook) public view override returns (uint256) {
        uint256 from = shieldMiningInfo[_policyBook].lastUpdateBlock;
        uint256 to;

        if (shieldMiningInfo[_policyBook].nearestLastBlocksWithReward > 0) {
            to = Math.min(block.number, shieldMiningInfo[_policyBook].nearestLastBlocksWithReward);
        } else {
            to = block.number;
        }

        return from >= to ? 0 : to.sub(from);
    }

    function rewardPerToken(address _policyBook) public view override returns (uint256) {
        uint256 totalPoolStaked = shieldMiningInfo[_policyBook].totalSupply;

        if (totalPoolStaked == 0) {
            return shieldMiningInfo[_policyBook].rewardPerTokenStored;
        }

        uint256 accumulatedReward =
            blocksWithRewardsPassed(_policyBook)
                .mul(getCurrentRewardPerBlock(_policyBook))
                .mul(DECIMALS18)
                .div(totalPoolStaked);

        return shieldMiningInfo[_policyBook].rewardPerTokenStored.add(accumulatedReward);
    }

    function earned(
        address _policyBook,
        address _userLeveragePool,
        address _account
    ) public view override returns (uint256) {
        address _userPool = _userLeveragePool != address(0) ? _userLeveragePool : _policyBook;
        uint256 rewardsDifference =
            rewardPerToken(_policyBook).sub(userRewardPerTokenPaid[_account][_userPool]);

        uint256 userLiquidity;

        if (_userLeveragePool == address(0)) {
            userLiquidity = IPolicyBookFacade(IPolicyBook(_policyBook).policyBookFacade())
                .userLiquidity(_account);
        } else {
            uint256 totalSupply = userleveragepoolsTotalSupply[_userLeveragePool];
            if (totalSupply > 0) {
                userLiquidity = IUserLeveragePool(_userLeveragePool).userLiquidity(_account);
                userLiquidity = userLiquidity
                    .mul(userleveragepoolsParticipatedAmounts[_userLeveragePool])
                    .div(totalSupply);
            }
        }

        uint256 newlyAccumulated = userLiquidity.mul(rewardsDifference).div(DECIMALS18);

        return _rewards[_account][_userPool].add(newlyAccumulated);
    }

    function updateTotalSupply(
        address _policyBook,
        address _userLeveragePool,
        address _liquidityProvider
    ) external override updateReward(_policyBook, _userLeveragePool, _liquidityProvider) {
        require(
            policyBookRegistry.isPolicyBookFacade(_msgSender()) ||
                policyBookRegistry.isPolicyBook(_policyBook),
            "SM: No access"
        );
        uint256 _participatedLeverageAmounts;

        IPolicyBook _coveragePool = IPolicyBook(_policyBook);
        IPolicyBookFacade _policyFacade = IPolicyBookFacade(_coveragePool.policyBookFacade());

        uint256 _userLeveragePoolsCount = _policyFacade.countUserLeveragePools();

        if (_userLeveragePoolsCount > 0) {
            address[] memory _userLeverageArr =
                _policyFacade.listUserLeveragePools(0, _userLeveragePoolsCount);
            uint256 _participatedLeverageAmount;
            for (uint256 i = 0; i < _userLeverageArr.length; i++) {
                _participatedLeverageAmount = clacParticipatedLeverageAmount(
                    _userLeverageArr[i],
                    _coveragePool
                );
                userleveragepoolsParticipatedAmounts[
                    _userLeverageArr[i]
                ] = _participatedLeverageAmount;
                _participatedLeverageAmounts = _participatedLeverageAmounts.add(
                    _participatedLeverageAmount
                );
                userleveragepoolsTotalSupply[_userLeverageArr[i]] = IERC20(_userLeverageArr[i])
                    .totalSupply();
            }
        }

        shieldMiningInfo[_policyBook].totalSupply = _participatedLeverageAmounts.add(
            IERC20(_policyBook).totalSupply()
        );
    }

    function clacParticipatedLeverageAmount(address _userLeveragePool, IPolicyBook _coveragePool)
        internal
        view
        returns (uint256)
    {
        IPolicyBookFacade _policyFacade = IPolicyBookFacade(_coveragePool.policyBookFacade());
        uint256 _poolUtilizationRation;
        uint256 _coverageLiq = _coveragePool.totalLiquidity();
        if (_coverageLiq > 0) {
            _poolUtilizationRation = _coveragePool.totalCoverTokens().mul(PERCENTAGE_100).div(
                _coverageLiq
            );
        }

        return
            _policyFacade
                .LUuserLeveragePool(_userLeveragePool)
                .mul(leveragePortfolioView.calcM(_poolUtilizationRation, _userLeveragePool))
                .div(PERCENTAGE_100);
    }

    function associateShieldMining(address _policyBook, address _shieldMiningToken)
        external
        override
    {
        require(_msgSender() == policyBookFabric || _msgSender() == owner(), "SM: no access");
        require(policyBookRegistry.isPolicyBook(_policyBook), "SM: Not a PolicyBook");

        // should revert with "Address: not a contract" if it's an account
        _shieldMiningToken.functionCall(
            abi.encodeWithSignature("totalSupply()", ""),
            "SM: is not an ERC20"
        );

        delete shieldMiningInfo[_policyBook];

        shieldMiningInfo[_policyBook].totalSupply = IERC20(_policyBook).totalSupply();
        shieldMiningInfo[_policyBook].rewardsToken = IERC20(_shieldMiningToken);
        shieldMiningInfo[_policyBook].decimals = ERC20(_shieldMiningToken).decimals();

        emit ShieldMiningAssociated(_policyBook, _shieldMiningToken);
    }

    ///@dev amount should be in decimal18
    function fillShieldMining(
        address _policyBook,
        uint256 _amount,
        uint256 _duration
    ) external override shieldMiningEnabled(_policyBook) {
        require(_duration >= 22 && _duration <= 366, "SM: out of minimum/maximum duration");

        uint256 _tokenDecimals = shieldMiningInfo[_policyBook].decimals;
        uint256 tokenLiquidity = DecimalsConverter.convertFrom18(_amount, _tokenDecimals);

        require(tokenLiquidity > 0, "SM: amount is zero");

        uint256 _blocksAmount = _duration.mul(_getBlocksPerDay()).sub(1);

        uint256 _rewardPerBlock = _amount.div(_blocksAmount);

        shieldMiningInfo[_policyBook].rewardsToken.safeTransferFrom(
            _msgSender(),
            address(this),
            tokenLiquidity
        );

        shieldMiningInfo[_policyBook].rewardTokensLocked = shieldMiningInfo[_policyBook]
            .rewardTokensLocked
            .add(_amount);

        uint256 _lastBlockWithReward =
            _setRewards(_policyBook, _rewardPerBlock, block.number, _blocksAmount);

        lastDepositId.increment();
        _usersDepositsId[_msgSender()].add(lastDepositId.current());
        usersDeposits[lastDepositId.current()] = ShieldMiningDeposit(
            _policyBook,
            _amount,
            _duration,
            _rewardPerBlock,
            block.number,
            _lastBlockWithReward
        );

        emit ShieldMiningFilled(
            _policyBook,
            address(shieldMiningInfo[_policyBook].rewardsToken),
            _msgSender(),
            _amount,
            shieldMiningInfo[_policyBook].lastBlockWithReward
        );
    }

    function getRewardFor(
        address _user,
        address _policyBook,
        address _userLeveragePool
    )
        public
        override
        nonReentrant
        updateReward(_policyBook, _userLeveragePool, _user)
        onlyBMICoverStaking
    {
        _getReward(_user, _policyBook, _userLeveragePool);
    }

    function getRewardFor(address _user, address _userLeveragePool)
        public
        override
        nonReentrant
        onlyBMICoverStaking
    {
        _getRewardFromLeverage(_user, _userLeveragePool, true);
    }

    function getReward(address _policyBook, address _userLeveragePool)
        public
        override
        nonReentrant
        updateReward(_policyBook, _userLeveragePool, _msgSender())
    {
        _getReward(_msgSender(), _policyBook, _userLeveragePool);
    }

    function getReward(address _userLeveragePool) public override nonReentrant {
        _getRewardFromLeverage(_msgSender(), _userLeveragePool, false);
    }

    function _getRewardFromLeverage(
        address _user,
        address _userLeveragePool,
        bool isRewardFor
    ) internal {
        ILeveragePortfolio userLeveragePool = ILeveragePortfolio(_userLeveragePool);
        address[] memory _coveragePools =
            userLeveragePool.listleveragedCoveragePools(
                0,
                userLeveragePool.countleveragedCoveragePools()
            );
        for (uint256 i = 0; i < _coveragePools.length; i++) {
            if (getShieldTokenAddress(_coveragePools[i]) != address(0)) {
                if (isRewardFor) {
                    getRewardFor(_user, _coveragePools[i], _userLeveragePool);
                } else {
                    getReward(_coveragePools[i], _userLeveragePool);
                }
            }
        }
    }

    function _getReward(
        address _user,
        address _policyBook,
        address _userLeveragePool
    ) internal {
        address _userPool = _userLeveragePool != address(0) ? _userLeveragePool : _policyBook;
        uint256 reward = _rewards[_user][_userPool];

        if (reward > 0) {
            delete _rewards[_user][_userPool];

            uint256 _tokenDecimals = shieldMiningInfo[_policyBook].decimals;

            // transfer profit to the user
            shieldMiningInfo[_policyBook].rewardsToken.safeTransfer(
                _user,
                DecimalsConverter.convertFrom18(reward, _tokenDecimals)
            );

            shieldMiningInfo[_policyBook].rewardTokensLocked = shieldMiningInfo[_policyBook]
                .rewardTokensLocked
                .sub(reward);

            emit ShieldMiningClaimed(_user, _policyBook, reward);
        }
    }

    function recoverNonLockedRewardTokens(address _policyBook) public onlyOwner {
        uint256 _tokenDecimals = shieldMiningInfo[_policyBook].decimals;

        uint256 _futureRewardTokens = _getFutureRewardTokens(_policyBook);

        uint256 tokenBalance =
            DecimalsConverter.convertTo18(
                shieldMiningInfo[_policyBook].rewardsToken.balanceOf(address(this)),
                _tokenDecimals
            );

        if (tokenBalance > _futureRewardTokens) {
            uint256 nonLockedTokens = tokenBalance.sub(_futureRewardTokens);

            shieldMiningInfo[_policyBook].rewardsToken.safeTransfer(
                owner(),
                DecimalsConverter.convertFrom18(nonLockedTokens, _tokenDecimals)
            );

            emit ShieldMiningRecovered(_policyBook, nonLockedTokens);
        }
    }

    function getShieldTokenAddress(address _policyBook) public view override returns (address) {
        return address(shieldMiningInfo[_policyBook].rewardsToken);
    }

    function getShieldMiningInfo(address _policyBook)
        external
        view
        override
        returns (
            address _rewardsToken,
            uint256 _decimals,
            uint256 _firstBlockWithReward,
            uint256 _lastBlockWithReward,
            uint256 _lastUpdateBlock,
            uint256 _nearestLastBlocksWithReward,
            uint256 _rewardTokensLocked,
            uint256 _rewardPerTokenStored,
            uint256 _rewardPerBlock,
            uint256 _tokenPerDay,
            uint256 _totalSupply
        )
    {
        _rewardsToken = address(shieldMiningInfo[_policyBook].rewardsToken);
        _decimals = shieldMiningInfo[_policyBook].decimals;
        _firstBlockWithReward = shieldMiningInfo[_policyBook].firstBlockWithReward;
        _lastBlockWithReward = shieldMiningInfo[_policyBook].lastBlockWithReward;
        _lastUpdateBlock = shieldMiningInfo[_policyBook].lastUpdateBlock;
        _nearestLastBlocksWithReward = shieldMiningInfo[_policyBook].nearestLastBlocksWithReward;
        _rewardPerTokenStored = shieldMiningInfo[_policyBook].rewardPerTokenStored;
        _rewardPerBlock = getCurrentRewardPerBlock(_policyBook);
        _tokenPerDay = _rewardPerBlock.mul(_getBlocksPerDay());
        _totalSupply = shieldMiningInfo[_policyBook].totalSupply;
        _rewardTokensLocked = shieldMiningInfo[_policyBook].rewardTokensLocked;
    }

    function getDepositList(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) external view override returns (ShieldMiningDeposit[] memory _depositsList) {
        uint256 nbOfDeposit = _usersDepositsId[_account].length();

        uint256 to = (_offset.add(_limit)).min(nbOfDeposit).max(_offset);
        uint256 size = to.sub(_offset);

        _depositsList = new ShieldMiningDeposit[](size);
        for (uint256 i = _offset; i < to; i++) {
            ShieldMiningDeposit memory smd = usersDeposits[_usersDepositsId[_account].at(i)];
            _depositsList[i].policyBook = smd.policyBook;
            _depositsList[i].amount = smd.amount;
            _depositsList[i].duration = smd.duration;
            _depositsList[i].depositRewardPerBlock = smd.depositRewardPerBlock;
            _depositsList[i].startBlock = smd.startBlock;
            _depositsList[i].endBlock = smd.endBlock;
        }
    }

    /// @notice get count of user deposits
    function countUsersDeposits(address _account) external view override returns (uint256) {
        return _usersDepositsId[_account].length();
    }

    function _setRewards(
        address _policyBook,
        uint256 _rewardPerBlock,
        uint256 _startingBlock,
        uint256 _blocksAmount
    )
        internal
        updateReward(_policyBook, address(0), address(0))
        returns (uint256 _lastBlockWithReward)
    {
        shieldMiningInfo[_policyBook].firstBlockWithReward = _startingBlock;

        _lastBlockWithReward = _startingBlock.add(_blocksAmount);

        if (shieldMiningInfo[_policyBook].lastBlockWithReward < _lastBlockWithReward) {
            shieldMiningInfo[_policyBook].lastBlockWithReward = _lastBlockWithReward;
        }

        shieldMiningInfo[_policyBook].rewardPerBlock[_lastBlockWithReward] = shieldMiningInfo[
            _policyBook
        ]
            .rewardPerBlock[_lastBlockWithReward]
            .add(_rewardPerBlock);
        lastBlockWithRewardList[_policyBook].add(_lastBlockWithReward);
    }

    function _updateReward(
        address _policyBook,
        address _userLeveragePool,
        address _account
    ) internal {
        _updateNearestLastBlocksWithReward(_policyBook);

        uint256 currentRewardPerToken = rewardPerToken(_policyBook);

        shieldMiningInfo[_policyBook].rewardPerTokenStored = currentRewardPerToken;

        uint256 _nearestLastBlocksWithReward =
            shieldMiningInfo[_policyBook].nearestLastBlocksWithReward;

        uint256 _lastBlockWithReward = shieldMiningInfo[_policyBook].lastBlockWithReward;

        if (
            _nearestLastBlocksWithReward != 0 &&
            block.number > _nearestLastBlocksWithReward &&
            _lastBlockWithReward != _nearestLastBlocksWithReward
        ) {
            shieldMiningInfo[_policyBook].lastUpdateBlock = _nearestLastBlocksWithReward;
            lastBlockWithRewardList[_policyBook].remove(_nearestLastBlocksWithReward);
            _updateReward(_policyBook, _userLeveragePool, _account);
        } else {
            shieldMiningInfo[_policyBook].lastUpdateBlock = block.number;
        }

        if (_account != address(0)) {
            address _userPool = _userLeveragePool != address(0) ? _userLeveragePool : _policyBook;

            _rewards[_account][_userPool] = earned(_policyBook, _userLeveragePool, _account);
            userRewardPerTokenPaid[_account][_userPool] = currentRewardPerToken;
        }
    }

    function getCurrentRewardPerBlock(address _policyBook)
        public
        view
        returns (uint256 _rewardPerBlock)
    {
        uint256 _lastUpdateBlock = shieldMiningInfo[_policyBook].lastUpdateBlock;

        for (uint256 i = 0; i < lastBlockWithRewardList[_policyBook].length(); i++) {
            uint256 _lastBlockWithReward = lastBlockWithRewardList[_policyBook].at(i);
            uint256 _firstBlockWithReward = lastBlockWithRewardList[_policyBook].at(i);
            if (_lastBlockWithReward > _lastUpdateBlock && _firstBlockWithReward != block.number) {
                _rewardPerBlock = _rewardPerBlock.add(
                    shieldMiningInfo[_policyBook].rewardPerBlock[_lastBlockWithReward]
                );
            }
        }
    }

    function _updateNearestLastBlocksWithReward(address _policyBook) internal {
        uint256 _lastUpdateBlock = shieldMiningInfo[_policyBook].lastUpdateBlock;

        uint256 _lastBlockWithReward = shieldMiningInfo[_policyBook].lastBlockWithReward;

        uint256 _nearestLastBlocksWithReward = _lastBlockWithReward;
        uint256 _lastBlock;

        for (uint256 i = 0; i < lastBlockWithRewardList[_policyBook].length(); i++) {
            _lastBlock = lastBlockWithRewardList[_policyBook].at(i);
            if (_lastBlock <= _nearestLastBlocksWithReward && _lastUpdateBlock < _lastBlock) {
                _nearestLastBlocksWithReward = _lastBlock;
            }
        }
        shieldMiningInfo[_policyBook].nearestLastBlocksWithReward = _nearestLastBlocksWithReward;
    }

    function _getFutureRewardTokens(address _policyBook)
        internal
        view
        returns (uint256 _futureRewardTokens)
    {
        uint256 _lastUpdateBlock = shieldMiningInfo[_policyBook].lastUpdateBlock;
        for (uint256 i = 0; i < lastBlockWithRewardList[_policyBook].length(); i++) {
            uint256 _lastBlockWithReward = lastBlockWithRewardList[_policyBook].at(i);

            uint256 blocksLeft = _calculateBlocksLeft(_lastUpdateBlock, _lastBlockWithReward);

            _futureRewardTokens = _futureRewardTokens.add(
                (
                    blocksLeft.mul(
                        shieldMiningInfo[_policyBook].rewardPerBlock[_lastBlockWithReward]
                    )
                )
            );
        }
    }

    function _calculateBlocksLeft(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (block.number >= _to) return 0;

        if (block.number < _from) return _to.sub(_from).add(1);

        return _to.sub(block.number);
    }

    function _getBlocksPerDay() internal view returns (uint256 _blockPerDays) {
        if (_currentNetwork == Networks.ETH) {
            _blockPerDays = BLOCKS_PER_DAY;
        } else if (_currentNetwork == Networks.BSC) {
            _blockPerDays = BLOCKS_PER_DAY_BSC;
        } else if (_currentNetwork == Networks.POL) {
            _blockPerDays = BLOCKS_PER_DAY_POLYGON;
        }
    }
}