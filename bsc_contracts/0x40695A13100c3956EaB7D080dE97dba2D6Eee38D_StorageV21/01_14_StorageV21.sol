// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "./Interfaces/ILogicContract.sol";
import "./Interfaces/AggregatorV3Interface.sol";

contract StorageV21 is Initializable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;

    //struct
    struct DepositStruct {
        mapping(address => uint256) amount;
        mapping(address => int256) tokenTime;
        uint256 iterate;
        uint256 balanceBLID;
        mapping(address => uint256) depositIterate;
    }

    struct EarnBLID {
        uint256 allBLID;
        uint256 timestamp;
        uint256 usd;
        uint256 tdt;
        mapping(address => uint256) rates;
    }

    struct BoostInfo {
        uint256 blidDeposit;
        uint256 rewardDebt;
        uint256 blidOverDeposit;
    }

    /*** events ***/

    event Deposit(address depositor, address token, uint256 amount);
    event Withdraw(address depositor, address token, uint256 amount);
    event UpdateTokenBalance(uint256 balance, address token);
    event TakeToken(address token, uint256 amount);
    event ReturnToken(address token, uint256 amount);
    event AddEarn(uint256 amount);
    event UpdateBLIDBalance(uint256 balance);
    event InterestFee(address depositor, uint256 amount);
    event SetBLID(address blid);
    event AddToken(address token, address oracle);
    event SetLogic(address logic);
    event SetBoostingInfo(
        uint256 maxBlidPerUSD,
        uint256 blidPerBlock,
        uint256 maxActiveBLID
    );
    event DepositBLID(address depositor, uint256 amount);
    event WithdrawBLID(address depositor, uint256 amount);
    event ClaimBoostBLID(address depositor, uint256 amount);
    event SetBoostingAddress(address boostingAddress);
    event SetAdmin(address admin);
    event UpgradeVersion(string version, string purpose);

    constructor() initializer {}

    function initialize() external initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
    }

    mapping(uint256 => EarnBLID) private earnBLID;
    uint256 private countEarns;
    uint256 private countTokens;
    mapping(uint256 => address) private tokens;
    mapping(address => uint256) private tokenBalance;
    mapping(address => address) private oracles;
    mapping(address => bool) private tokensAdd;
    mapping(address => DepositStruct) private deposits;
    mapping(address => uint256) private tokenDeposited;
    mapping(address => int256) private tokenTime;
    uint256 private reserveBLID;
    address private logicContract;
    address private BLID;
    mapping(address => mapping(uint256 => uint256))
        public accumulatedRewardsPerShare;

    // ****** Add from V21 ******

    // Boost2.0
    mapping(address => BoostInfo) private userBoosts;
    uint256 public maxBlidPerUSD;
    uint256 public blidPerBlock;
    uint256 public accBlidPerShare;
    uint256 public lastRewardBlock;
    address public boostingAddress;
    uint256 public totalSupplyBLID;
    uint256 public maxActiveBLID;
    uint256 public activeSupplyBLID;

    address private constant ZERO_ADDRESS = address(0);

    /*** modifiers ***/

    modifier onlyUsedToken(address _token) {
        require(tokensAdd[_token], "E1");
        _;
    }

    modifier isLogicContract(address account) {
        require(logicContract == account, "E2");
        _;
    }

    /*** Owner functions ***/

    /**
     * @notice Set blid in contract
     * @param _blid address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        require(_blid != ZERO_ADDRESS, "E16");
        BLID = _blid;

        emit SetBLID(_blid);
    }

    /**
     * @notice Set blid in contract
     * @param _boostingAddress address of expense
     */
    function setBoostingAddress(address _boostingAddress) external onlyOwner {
        require(_boostingAddress != ZERO_ADDRESS, "E16");
        boostingAddress = _boostingAddress;

        emit SetBoostingAddress(boostingAddress);
    }

    /**
     * @notice Set boosting parameters
     * @param _maxBlidperUSD max value of BLID per USD
     * @param _blidperBlock blid per Block
     * @param _maxActiveBLID max active BLID limit
     */
    function setBoostingInfo(
        uint256 _maxBlidperUSD,
        uint256 _blidperBlock,
        uint256 _maxActiveBLID
    ) external onlyOwner {
        // Initialize lastRewardBlock
        if (lastRewardBlock == 0) {
            lastRewardBlock = block.number;
        }

        _boostingUpdateAccBlidPerShare();

        maxBlidPerUSD = _maxBlidperUSD;
        blidPerBlock = _blidperBlock;
        maxActiveBLID = _maxActiveBLID;

        emit SetBoostingInfo(_maxBlidperUSD, _blidperBlock, _maxActiveBLID);
    }

    /**
     * @notice Triggers stopped state.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Add token and token's oracle
     * @param _token Address of Token
     * @param _oracles Address of token's oracle(https://docs.chain.link/docs/binance-smart-chain-addresses/
     */
    function addToken(address _token, address _oracles) external onlyOwner {
        require(_token != ZERO_ADDRESS && _oracles != ZERO_ADDRESS, "E16");
        require(!tokensAdd[_token], "E6");
        require(IERC20MetadataUpgradeable(_token).decimals() <= 18, "E17");

        oracles[_token] = _oracles;
        tokens[countTokens++] = _token;
        tokensAdd[_token] = true;

        emit AddToken(_token, _oracles);
    }

    /**
     * @notice Set logic in contract(only for upgradebale contract,use only whith DAO)
     * @param _logic Address of Logic Contract
     */
    function setLogic(address _logic) external onlyOwner {
        require(_logic != ZERO_ADDRESS, "E16");

        logicContract = _logic;

        emit SetLogic(_logic);
    }

    /*** User functions ***/

    /**
     * @notice Deposit amount of token for msg.sender
     * @param amount amount of token
     * @param token address of token
     */
    function deposit(
        uint256 amount,
        address token
    ) external onlyUsedToken(token) whenNotPaused {
        _depositInternal(amount, token, msg.sender);
    }

    /**
     * @notice Deposit amount of token on behalf of depositor wallet
     * @param amount amount of token
     * @param token address of token
     * @param accountAddress Address of depositor
     */
    function depositOnBehalf(
        uint256 amount,
        address token,
        address accountAddress
    ) external onlyUsedToken(token) whenNotPaused {
        require(accountAddress != ZERO_ADDRESS, "E16");
        _depositInternal(amount, token, accountAddress);
    }

    /**
     * @notice Withdraw amount of token  from Strategy and receiving earned tokens.
     * @param amount Amount of token
     * @param token Address of token
     */
    function withdraw(
        uint256 amount,
        address token
    ) external onlyUsedToken(token) whenNotPaused {
        uint8 decimals = IERC20MetadataUpgradeable(token).decimals();
        uint256 countEarns_ = countEarns;
        uint256 amountExp18 = amount * 10 ** (18 - decimals);
        bool isEnoughBalance = false;
        DepositStruct storage depositor = deposits[msg.sender];

        require(depositor.amount[token] >= amountExp18 && amount > 0, "E4");

        interestFee(msg.sender);
        if (amountExp18 <= tokenBalance[token]) {
            isEnoughBalance = true;
            tokenBalance[token] -= amountExp18;
        }
        tokenDeposited[token] -= amountExp18;
        tokenTime[token] -= (block.timestamp * (amountExp18)).toInt256();

        if (depositor.depositIterate[token] == countEarns_) {
            depositor.tokenTime[token] -= (block.timestamp * (amountExp18))
                .toInt256();
        } else {
            depositor.tokenTime[token] =
                (depositor.amount[token] * earnBLID[countEarns_ - 1].timestamp)
                    .toInt256() -
                (block.timestamp * (amountExp18)).toInt256();
            depositor.depositIterate[token] = countEarns_;
        }
        depositor.amount[token] -= amountExp18;

        // Claim BoostingRewardBLID
        _claimBoostingRewardBLIDInternal(msg.sender, true);

        // Interaction
        if (isEnoughBalance) {
            IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
        } else {
            ILogicContract(logicContract).returnToken(amount, token);
            IERC20Upgradeable(token).safeTransferFrom(
                logicContract,
                msg.sender,
                amount
            );
        }

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit Withdraw(msg.sender, token, amountExp18);
    }

    /**
     * @notice Claim BLID to accountAddress
     * @param accountAddress account address for claim
     */
    function interestFee(address accountAddress) public {
        require(accountAddress != ZERO_ADDRESS, "E16");

        uint256 balanceUser = balanceEarnBLID(accountAddress);
        require(reserveBLID >= balanceUser, "E5");

        if (balanceUser > 0) {
            DepositStruct storage depositor = deposits[accountAddress];

            //unchecked is used because a check was made in require
            unchecked {
                reserveBLID -= balanceUser;
                depositor.balanceBLID = 0;
            }
            depositor.iterate = countEarns;

            // Interaction
            IERC20Upgradeable(BLID).safeTransfer(accountAddress, balanceUser);

            emit UpdateBLIDBalance(reserveBLID);
            emit InterestFee(accountAddress, balanceUser);
        }
    }

    /*** Boosting User function ***/

    /**
     * @notice Deposit BLID token for boosting.
     * @param amount amount of token
     */
    function depositBLID(uint256 amount) external whenNotPaused {
        require(amount > 0, "E3");
        uint256 usdDepositAmount = balanceOf(msg.sender);
        require(usdDepositAmount > 0, "E11");

        // Claim
        _claimBoostingRewardBLIDInternal(msg.sender, false);

        // Update userBoost
        _boostingAdjustAmount(usdDepositAmount, msg.sender, amount, true);

        // Interaction
        IERC20Upgradeable(BLID).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit DepositBLID(msg.sender, amount);
    }

    /**
     * @notice Withdraw BLID token for boosting.
     * @param amount amount of token
     */
    function withdrawBLID(uint256 amount) external whenNotPaused {
        require(amount > 0, "E3");
        BoostInfo storage userBoost = userBoosts[msg.sender];
        uint256 usdDepositAmount = balanceOf(msg.sender);

        require(
            amount <= userBoost.blidDeposit + userBoost.blidOverDeposit,
            "E12"
        );

        // Claim
        _claimBoostingRewardBLIDInternal(msg.sender, false);

        // Adjust userBoost
        _boostingAdjustAmount(usdDepositAmount, msg.sender, amount, false);

        // Interaction
        IERC20Upgradeable(BLID).safeTransfer(msg.sender, amount);

        emit WithdrawBLID(msg.sender, amount);
    }

    /**
     * @notice Claim Boosting Reward BLID to msg.sender
     */
    function claimBoostingRewardBLID() external {
        _claimBoostingRewardBLIDInternal(msg.sender, true);
    }

    /**
     * @notice get deposited Boosting BLID amount of user
     * @param _user address of user
     */
    function getBoostingBLIDAmount(
        address _user
    ) public view returns (uint256) {
        BoostInfo storage userBoost = userBoosts[_user];
        uint256 amount = userBoost.blidDeposit + userBoost.blidOverDeposit;
        return amount;
    }

    /*** LogicContract function ***/

    /**
     * @notice Transfer amount of token from Storage to Logic Contract.
     * @param amount Amount of token
     * @param token Address of token
     */
    function takeToken(
        uint256 amount,
        address token
    ) external isLogicContract(msg.sender) onlyUsedToken(token) {
        uint8 decimals = IERC20MetadataUpgradeable(token).decimals();
        uint256 amountExp18 = amount * 10 ** (18 - decimals);

        require(tokenBalance[token] >= amountExp18, "E18");

        tokenBalance[token] = tokenBalance[token] - amountExp18;

        // Interaction
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit TakeToken(token, amountExp18);
    }

    /**
     * @notice Transfer amount of token from Logic to Storage Contract.
     * @param amount Amount of token
     * @param token Address of token
     */
    function returnToken(
        uint256 amount,
        address token
    ) external isLogicContract(msg.sender) onlyUsedToken(token) {
        uint8 decimals = IERC20MetadataUpgradeable(token).decimals();
        uint256 amountExp18 = amount * 10 ** (18 - decimals);

        tokenBalance[token] = tokenBalance[token] + amountExp18;

        // Interaction
        IERC20Upgradeable(token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit ReturnToken(token, amountExp18);
    }

    /**
     * @notice Claim all BLID(from strategy and boost) for user
     */
    function claimAllRewardBLID() external {
        interestFee(msg.sender);
        _claimBoostingRewardBLIDInternal(msg.sender, true);
    }

    /**
     * @notice Take amount BLID from Logic contract  and distributes earned BLID
     * @param amount Amount of distributes earned BLID
     */
    function addEarn(uint256 amount) external isLogicContract(msg.sender) {
        reserveBLID += amount;
        int256 _dollarTime = 0;
        uint256 countTokens_ = countTokens;
        uint256 countEarns_ = countEarns;
        EarnBLID storage thisEarnBLID = earnBLID[countEarns_];
        for (uint256 i = 0; i < countTokens_; ) {
            address token = tokens[i];
            AggregatorV3Interface oracle = AggregatorV3Interface(
                oracles[token]
            );
            (, int256 latestAnswer, , , ) = oracle.latestRoundData();
            thisEarnBLID.rates[token] = (uint256(latestAnswer) *
                10 ** (18 - oracle.decimals()));

            // count all deposited token in usd
            thisEarnBLID.usd +=
                tokenDeposited[token] *
                thisEarnBLID.rates[token];

            // convert token time to dollar time
            _dollarTime +=
                tokenTime[token] *
                thisEarnBLID.rates[token].toInt256();

            unchecked {
                ++i;
            }
        }
        require(_dollarTime != 0, "E16");
        thisEarnBLID.allBLID = amount;
        thisEarnBLID.timestamp = block.timestamp;
        thisEarnBLID.tdt = uint256(
            ((((block.timestamp) * thisEarnBLID.usd)).toInt256() -
                _dollarTime) / (1 ether)
        ); // count delta of current token time and all user token time

        for (uint256 i = 0; i < countTokens_; ) {
            address token = tokens[i];
            tokenTime[token] = (tokenDeposited[token] * block.timestamp)
                .toInt256(); // count curent token time
            _updateAccumulatedRewardsPerShareById(token, countEarns_);

            unchecked {
                ++i;
            }
        }
        thisEarnBLID.usd /= (1 ether);
        countEarns++;

        // Interaction
        IERC20Upgradeable(BLID).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit AddEarn(amount);
        emit UpdateBLIDBalance(reserveBLID);
    }

    /*** External function ***/

    /**
     * @notice Counts the number of accrued СSR
     * @param account Address of Depositor
     */
    function _upBalance(address account) external {
        DepositStruct storage depositor = deposits[account];

        depositor.balanceBLID = balanceEarnBLID(account);
        depositor.iterate = countEarns;
    }

    /***  Public View function ***/

    /**
     * @notice Return earned blid
     * @param account Address of Depositor
     */
    function balanceEarnBLID(address account) public view returns (uint256) {
        DepositStruct storage depositor = deposits[account];
        if (depositor.tokenTime[ZERO_ADDRESS] == 0 || countEarns == 0) {
            return 0;
        }
        if (countEarns == depositor.iterate) return depositor.balanceBLID;

        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        uint256 depositorIterate = depositor.iterate;
        for (uint256 j = 0; j < countTokens_; ) {
            address token = tokens[j];
            //if iterate when user deposited
            if (depositorIterate == depositor.depositIterate[token]) {
                sum += _getEarnedInOneDepositedIterate(
                    depositorIterate,
                    token,
                    account
                );
                sum += _getEarnedInOneNotDepositedIterate(
                    depositorIterate,
                    token,
                    account
                );
            } else {
                sum += _getEarnedInOneNotDepositedIterate(
                    depositorIterate - 1,
                    token,
                    account
                );
            }

            unchecked {
                ++j;
            }
        }

        return sum + depositor.balanceBLID;
    }

    /**
     * @notice Return usd balance of account
     * @param account Address of Depositor
     */
    function balanceOf(address account) public view returns (uint256) {
        uint256 countTokens_ = countTokens;
        uint256 sum = 0;

        for (uint256 j = 0; j < countTokens_; ) {
            address token = tokens[j];
            AggregatorV3Interface oracle = AggregatorV3Interface(
                oracles[token]
            );
            (, int256 latestAnswer, , , ) = oracle.latestRoundData();

            sum += ((deposits[account].amount[token] *
                uint256(latestAnswer) *
                10 ** (18 - oracle.decimals())) / (1 ether));

            unchecked {
                ++j;
            }
        }
        return sum;
    }

    /**
     * @notice Return sums of all distribution BLID.
     */
    function getBLIDReserve() external view returns (uint256) {
        return reserveBLID;
    }

    /**
     * @notice Return deposited usd
     */
    function getTotalDeposit() external view returns (uint256) {
        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        for (uint256 j = 0; j < countTokens_; ) {
            address token = tokens[j];
            AggregatorV3Interface oracle = AggregatorV3Interface(
                oracles[token]
            );
            (, int256 latestAnswer, , , ) = oracle.latestRoundData();
            sum +=
                (tokenDeposited[token] *
                    uint256(latestAnswer) *
                    10 ** (18 - oracle.decimals())) /
                (1 ether);

            unchecked {
                ++j;
            }
        }
        return sum;
    }

    /**
     * @notice Returns the balance of token on this contract
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return tokenBalance[token];
    }

    /**
     * @notice Return deposited token from account
     */
    function getTokenDeposit(
        address account,
        address token
    ) external view returns (uint256) {
        return deposits[account].amount[token];
    }

    /**
     * @notice Return true if _token  is in token list
     * @param _token Address of Token
     */
    function _isUsedToken(address _token) external view returns (bool) {
        return tokensAdd[_token];
    }

    /**
     * @notice Return count distribution BLID token.
     */
    function getCountEarns() external view returns (uint256) {
        return countEarns;
    }

    /**
     * @notice Return data on distribution BLID token.
     * First return value is amount of distribution BLID token.
     * Second return value is a timestamp when  distribution BLID token completed.
     * Third return value is an amount of dollar depositedhen  distribution BLID token completed.
     */
    function getEarnsByID(
        uint256 id
    ) external view returns (uint256, uint256, uint256) {
        return (earnBLID[id].allBLID, earnBLID[id].timestamp, earnBLID[id].usd);
    }

    /**
     * @notice Return amount of all deposited token
     * @param token Address of Token
     */
    function getTokenDeposited(address token) external view returns (uint256) {
        return tokenDeposited[token];
    }

    /**
     * @notice Return pending BLID amount for boost to see on frontend
     * @param _user address of user
     */

    function getBoostingClaimableBLID(
        address _user
    ) external view returns (uint256) {
        BoostInfo storage userBoost = userBoosts[_user];
        uint256 _accBLIDpershare = accBlidPerShare;
        if (block.number > lastRewardBlock) {
            uint256 passedBlockCount = block.number - lastRewardBlock + 1; // When claim, 1 block is added because of mining
            _accBLIDpershare =
                accBlidPerShare +
                (
                    activeSupplyBLID <= maxActiveBLID
                        ? (passedBlockCount * blidPerBlock)
                        : ((passedBlockCount * blidPerBlock * maxActiveBLID) /
                            activeSupplyBLID)
                );
        }
        uint256 calcAmount = (userBoost.blidDeposit * _accBLIDpershare) / 1e18;
        return
            calcAmount > userBoost.rewardDebt
                ? calcAmount - userBoost.rewardDebt
                : 0;
    }

    /*** Private Function ***/

    /**
     * @notice deposit token
     * @param amount Amount of deposit token
     * @param token Address of token
     * @param accountAddress Address of depositor
     */
    function _depositInternal(
        uint256 amount,
        address token,
        address accountAddress
    ) internal {
        require(amount > 0, "E3");
        uint256 countEarns_ = countEarns;
        uint8 decimals = IERC20MetadataUpgradeable(token).decimals();
        DepositStruct storage depositor = deposits[accountAddress];

        uint256 amountExp18 = amount * 10 ** (18 - decimals);
        if (depositor.tokenTime[ZERO_ADDRESS] == 0) {
            depositor.iterate = countEarns_;
            depositor.depositIterate[token] = countEarns_;
            depositor.tokenTime[ZERO_ADDRESS] = 1;
            depositor.tokenTime[token] += (block.timestamp * (amountExp18))
                .toInt256();
        } else {
            interestFee(accountAddress);
            if (depositor.depositIterate[token] == countEarns_) {
                depositor.tokenTime[token] += (block.timestamp * (amountExp18))
                    .toInt256();
            } else {
                depositor.tokenTime[token] = (depositor.amount[token] *
                    earnBLID[countEarns - 1].timestamp +
                    block.timestamp *
                    (amountExp18)).toInt256();

                depositor.depositIterate[token] = countEarns_;
            }
        }
        depositor.amount[token] += amountExp18;

        tokenTime[token] += (block.timestamp * (amountExp18)).toInt256();
        tokenBalance[token] += amountExp18;
        tokenDeposited[token] += amountExp18;

        // Claim BoostingRewardBLID
        _claimBoostingRewardBLIDInternal(accountAddress, true);

        // Interaction
        IERC20Upgradeable(token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit Deposit(accountAddress, token, amountExp18);
    }

    // Safe blid transfer function, just in case if rounding error causes pool to not have enough BLIDs.
    function _safeBlidTransfer(address _to, uint256 _amount) internal {
        IERC20Upgradeable(BLID).safeTransferFrom(boostingAddress, _to, _amount);
    }

    /**
     * @notice Count accumulatedRewardsPerShare
     * @param token Address of Token
     * @param id of accumulatedRewardsPerShare
     */
    function _updateAccumulatedRewardsPerShareById(
        address token,
        uint256 id
    ) private {
        EarnBLID storage thisEarnBLID = earnBLID[id];

        if (id == 0) {
            accumulatedRewardsPerShare[token][id] = 0;
        } else {
            //unchecked is used because if id > 0
            unchecked {
                accumulatedRewardsPerShare[token][id] =
                    accumulatedRewardsPerShare[token][id - 1] +
                    ((thisEarnBLID.allBLID *
                        (thisEarnBLID.timestamp - earnBLID[id - 1].timestamp) *
                        thisEarnBLID.rates[token]) / thisEarnBLID.tdt);
            }
        }
    }

    /**
     * @notice Count user rewards in one iterate, when he  deposited
     * @param token Address of Token
     * @param depositIterate iterate when deposit happened
     * @param account Address of Depositor
     */
    function _getEarnedInOneDepositedIterate(
        uint256 depositIterate,
        address token,
        address account
    ) private view returns (uint256) {
        EarnBLID storage thisEarnBLID = earnBLID[depositIterate];
        DepositStruct storage thisDepositor = deposits[account];
        return
            (// all distibution BLID multiply to
            thisEarnBLID.allBLID *
                // delta of  user dollar time and user dollar time if user deposited in at the beginning distibution
                uint256(
                    (thisDepositor.amount[token] *
                        thisEarnBLID.rates[token] *
                        thisEarnBLID.timestamp).toInt256() -
                        thisDepositor.tokenTime[token] *
                        thisEarnBLID.rates[token].toInt256()
                )) /
            //div to delta of all users dollar time and all users dollar time if all users deposited in at the beginning distibution
            thisEarnBLID.tdt /
            (1 ether);
    }

    /**
     * @notice Claim Boosting Reward BLID to msg.sender
     * @param userAccount address of account
     * @param isAdjust true : adjust userBoost.blidDeposit, false : not update userBoost.blidDeposit
     */
    function _claimBoostingRewardBLIDInternal(
        address userAccount,
        bool isAdjust
    ) private {
        _boostingUpdateAccBlidPerShare();
        BoostInfo storage userBoost = userBoosts[userAccount];
        uint256 calcAmount;
        bool transferAllowed = false;

        if (userBoost.blidDeposit > 0) {
            calcAmount = (userBoost.blidDeposit * accBlidPerShare) / 1e18;
            if (calcAmount > userBoost.rewardDebt) {
                calcAmount -= userBoost.rewardDebt;
                transferAllowed = true;
            }
        }

        // Adjust userBoost
        if (isAdjust) {
            uint256 usdDepositAmount = balanceOf(msg.sender);
            _boostingAdjustAmount(usdDepositAmount, userAccount, 0, true);
        }

        // Interaction
        if (transferAllowed) {
            _safeBlidTransfer(userAccount, calcAmount);
        }

        emit ClaimBoostBLID(userAccount, calcAmount);
    }

    /**
     * @notice update Accumulated BLID per share
     */
    function _boostingUpdateAccBlidPerShare() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 passedBlockCount = block.number - lastRewardBlock;
        accBlidPerShare =
            accBlidPerShare +
            (
                activeSupplyBLID <= maxActiveBLID
                    ? (passedBlockCount * blidPerBlock)
                    : ((passedBlockCount * blidPerBlock * maxActiveBLID) /
                        activeSupplyBLID)
            );
        lastRewardBlock = block.number;
    }

    /**
     * @notice Adjust depositBLID, depositOverBlid, totalSupplyBLID, totalActiveBLID
     * @param usdDepositAmount deposit total for user in USD
     * @param accountAddress address of user
     * @param amount new amount
     * @param flag true : deposit, false : withdraw
     */
    function _boostingAdjustAmount(
        uint256 usdDepositAmount,
        address accountAddress,
        uint256 amount,
        bool flag
    ) internal {
        BoostInfo storage userBoost = userBoosts[accountAddress];
        uint256 oldBlidDeposit = userBoost.blidDeposit;
        uint256 blidDepositLimit = (usdDepositAmount * maxBlidPerUSD) / 1e18;
        uint256 totalAmount = oldBlidDeposit + userBoost.blidOverDeposit;

        // Update totalSupply,
        if (flag && amount != 0) {
            totalAmount += amount;
            totalSupplyBLID += amount;
        } else {
            totalAmount -= amount;
            totalSupplyBLID -= amount;
        }

        // Adjust blidOvereDeposit
        if (totalAmount > blidDepositLimit) {
            userBoost.blidDeposit = blidDepositLimit;
            userBoost.blidOverDeposit = totalAmount - blidDepositLimit;
        } else {
            userBoost.blidDeposit = totalAmount;
            userBoost.blidOverDeposit = 0;
        }

        // Update activeSupply
        activeSupplyBLID =
            activeSupplyBLID +
            userBoost.blidDeposit -
            oldBlidDeposit;

        // Save rewardDebt
        userBoost.rewardDebt = (userBoost.blidDeposit * accBlidPerShare) / 1e18;
    }

    /*** Private View Function ***/

    /**
     * @notice Count user rewards in one iterate, when he was not deposit
     * @param token Address of Token
     * @param depositIterate iterate when deposit happened
     * @param account Address of Depositor
     */
    function _getEarnedInOneNotDepositedIterate(
        uint256 depositIterate,
        address token,
        address account
    ) private view returns (uint256) {
        mapping(uint256 => uint256)
            storage accumulatedRewardsPerShareForToken = accumulatedRewardsPerShare[
                token
            ];
        return
            ((accumulatedRewardsPerShareForToken[countEarns - 1] -
                accumulatedRewardsPerShareForToken[depositIterate]) *
                deposits[account].amount[token]) / (1 ether);
    }
}