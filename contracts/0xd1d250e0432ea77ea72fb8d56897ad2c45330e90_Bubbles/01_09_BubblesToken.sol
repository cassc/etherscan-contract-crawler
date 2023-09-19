// SPDX-License-Identifier: MIT

// Bubbles 
//  Built with the latest next-gen, dynamic reflection tokenomics combining gambling and ultra addictive features.
// Twitter: https://twitter.com/bubbles_erc
// Website: https://bubbles.run/

pragma solidity ^0.8.19;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bubbles is IERC20, Ownable {
    using SafeMath for uint256;
    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event EventStart(string evt);
    event EventFinish(string evt, uint256 amountReflectionAccumulated);
    event ReflectAccumulated(
        uint256 amountAdded,
        uint256 totalAmountAccumulated
    );
    event ReflectDistributed(uint256 amountDistributer);
    event ReflectNotification(string message);
    event ModeChanged(string mode);
    event HolderMinimumChanged(uint256 newMinimum);
    event LogInfo(string info);
    event LogError(string error);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    uint256 constant MAX_FEE = 10;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable UNISWAP_V2_PAIR;

    struct Fee {
        uint8 reflection;
        uint8 teamOracle;
        uint8 lp;
        uint8 burn;
        uint128 total;
    }

    struct HolderInfo {
        uint256 balance;
        uint256 eventReflection;
        uint256 baseReflection;
        uint256 holdingTime;
        uint256 lastBuy;
        uint256 lastSell;
        uint256 keyIndex;
        bool isHolder;
    }

    string _name = "Bubbles";
    string _symbol = "Bubbles";

    uint256 _totalSupply = 100_000_000 ether;

    uint256 public _swapThreshold = (_totalSupply * 2) / 10000;

    uint256 public _minSupplyHolding = 100_000 ether;

    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _baseReflection;
    mapping(address => uint256) public _eventReflection;
    mapping(address => uint256) public _historyReflectionTransfered;
    mapping(address => uint256) public _holdingTime;
    mapping(address => uint256) public _lastBuy;
    mapping(address => uint256) public _lastSell;
    mapping(address => uint256) public _keyIndex;
    mapping(address => bool) public _isHolder;

    address[] public addressesParticipantEvent;
    address[] public holderAddresses;

    uint256 public totalReflections = 0;
    uint256 public eventReflectedToken = 0;
    uint256 public normalReflectedToken = 0;
    uint256 public totalRemainder = 0;

    string public currentTokenMode = "chill";
    string public nextTokenMode = "ngmi";
    uint256 public lastTimeMode = 0;
    uint256 public lastTimeGenesis = 0;
    string public eventNameInProgress = "";
    bool public eventInProgress = false;
    string[] public eventHistory;
    string[] public modeHistory;
    uint256 public eventTokenAmountDistributedBatching;
    uint256 public timeEventStart = 0;
    uint256 public timeEventStop = 0;
    uint256 public highestReflectionEventValue = 0;
    uint256 public highestReflectionEventTime = 0;
    string public highestReflectionEventName = "";

    mapping(address => mapping(address => uint256)) _allowances;

    bool public enableTrading = false;
    bool public enableAutoAdjust = false;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isReflectionExempt;

    Fee public chill =
        Fee({reflection: 1, teamOracle: 3, lp: 1, burn: 0, total: 5});

    Fee public ngmiBuy =
        Fee({reflection: 2, teamOracle: 0, lp: 0, burn: 2, total: 4});
    Fee public ngmiSell =
        Fee({reflection: 3, teamOracle: 7, lp: 0, burn: 0, total: 10});

    Fee public apeBuy =
        Fee({reflection: 0, teamOracle: 0, lp: 0, burn: 0, total: 0});
    Fee public apeSell =
        Fee({reflection: 1, teamOracle: 3, lp: 0, burn: 1, total: 5});

    Fee public buyFee;
    Fee public sellFee;

    address private teamOracleFeeReceiver;
    address private lpFeeReceiver;
    address private airDropAddress;

    address private msAddress;

    bool public claimingFees = true;
    bool inSwap;
    mapping(address => bool) public blacklists;

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor() {
        // create uniswap pair
        address _uniswapPair = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        UNISWAP_V2_PAIR = _uniswapPair;

        _allowances[address(this)][address(UNISWAP_V2_ROUTER)] = type(uint256)
            .max;
        _allowances[address(this)][msg.sender] = type(uint256).max;

        teamOracleFeeReceiver = address(
            0x57458ac14b039cFa4F80740591A0DFe527D0260a
        ); // 0x57458ac14b039cFa4F80740591A0DFe527D0260a
        lpFeeReceiver = address(0xCF035a92cB2A8e115D59D01b66FEBb6c4F35ABA9); // 0xCF035a92cB2A8e115D59D01b66FEBb6c4F35ABA9
        airDropAddress = address(0xD73D1BF6131f0E9b01fCd31FF0aB4F81029d026E); // 0xD73D1BF6131f0E9b01fCd31FF0aB4F81029d026E

        isFeeExempt[msg.sender] = true;
        isFeeExempt[teamOracleFeeReceiver] = true;
        isFeeExempt[lpFeeReceiver] = true;
        isFeeExempt[airDropAddress] = true;
        isFeeExempt[ZERO] = true;
        isFeeExempt[DEAD] = true;

        isReflectionExempt[address(this)] = true;
        isReflectionExempt[address(UNISWAP_V2_ROUTER)] = true;
        isReflectionExempt[_uniswapPair] = true;
        isReflectionExempt[msg.sender] = true;
        isReflectionExempt[teamOracleFeeReceiver] = true;
        isReflectionExempt[lpFeeReceiver] = true;
        isReflectionExempt[airDropAddress] = true;
        isReflectionExempt[ZERO] = true;
        isReflectionExempt[DEAD] = true;

        buyFee = chill;
        sellFee = chill;

        uint256 distribute = (_totalSupply * 45) / 100;
        _balances[msg.sender] = distribute;
        emit Transfer(address(0), msg.sender, distribute);

        distribute = (_totalSupply * 0) / 100;
        _balances[teamOracleFeeReceiver] = distribute;
        emit Transfer(address(0), teamOracleFeeReceiver, distribute);

        distribute = (_totalSupply * 55) / 100;
        _balances[airDropAddress] = distribute;
        emit Transfer(address(0), airDropAddress, distribute);

        lastTimeMode = block.timestamp;
        emit ModeChanged(currentTokenMode);
    }

    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(
                _allowances[sender][msg.sender] >= amount,
                "ERC20: insufficient allowance"
            );
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balanceNormalReflection = 0;
        if (isHolder(account)) {
            if (holderAddresses.length > 0 && normalReflectedToken > 0) {
                uint256 baseReflection = 0;
                if (_baseReflection[account] > 0) {
                    baseReflection = _baseReflection[account];
                }
                uint256 calculatePersonnalReflection = normalReflectedToken /
                    holderAddresses.length;
                if (calculatePersonnalReflection > baseReflection) {
                    balanceNormalReflection =
                        calculatePersonnalReflection -
                        baseReflection;
                }
            }
        }

        uint256 totalBalance = _balances[account];
        if (balanceNormalReflection > 0) {
            totalBalance += balanceNormalReflection;
        }
        uint256 eventBalance = _eventReflection[account];
        if (eventBalance > 0) {
            totalBalance += eventBalance;
        }

        return totalBalance;
    }

    function getHolderNormalReflection(
        address account
    ) public view returns (uint256) {
        uint256 balanceNormalReflection = 0;
        if (isHolder(account)) {
            if (holderAddresses.length > 0 && normalReflectedToken > 0) {
                uint256 baseReflection = 0;
                if (_baseReflection[account] > 0) {
                    baseReflection = _baseReflection[account];
                }
                uint256 calculatePersonnalReflection = normalReflectedToken /
                    holderAddresses.length;
                if (calculatePersonnalReflection > baseReflection) {
                    balanceNormalReflection =
                        calculatePersonnalReflection -
                        baseReflection;
                }
            }
        }
        return balanceNormalReflection;
    }

    function getHolderEventReflection(
        address account
    ) public view returns (uint256) {
        return _eventReflection[account];
    }

    function getHolderHistoryReflectionTransfered(
        address account
    ) public view returns (uint256) {
        return _historyReflectionTransfered[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function isHolder(address holderAddress) public view returns (bool) {
        if (isReflectionExempt[holderAddress] || blacklists[holderAddress]) {
            return false;
        }
        return _balances[holderAddress] >= _minSupplyHolding;
    }

    function isHolderInArray(address holderAddress) public view returns (bool) {
        return _isHolder[holderAddress];
    }

    function addressToString(
        address _address
    ) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */

    function setMode(
        string calldata modeName,
        string calldata nextMode
    ) external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );

        if (compareStrings(modeName, "chill")) {
            buyFee = chill;
            sellFee = chill;
        } else if (compareStrings(modeName, "ngmi")) {
            buyFee = ngmiBuy;
            sellFee = ngmiSell;
        } else if (compareStrings(modeName, "ape")) {
            buyFee = apeBuy;
            sellFee = apeSell;
        }

        currentTokenMode = modeName;
        nextTokenMode = nextMode;

        modeHistory.push(modeName);
        if (modeHistory.length > 10) {
            delete modeHistory[0];
            for (uint i = 0; i < modeHistory.length - 1; i++) {
                modeHistory[i] = modeHistory[i + 1];
            }
            modeHistory.pop();
        }
        lastTimeMode = block.timestamp;
        emit ModeChanged(modeName);
    }

    function switchNextMode() external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );

        string memory modeName = nextTokenMode;
        string memory nextMode = "";
        if (compareStrings(nextTokenMode, "chill")) {
            if (compareStrings(currentTokenMode, "ngmi")) {
                nextMode = "ape";
            } else {
                nextMode = "ngmi";
            }
        } else {
            nextMode = "chill";
        }

        if (compareStrings(modeName, "chill")) {
            buyFee = chill;
            sellFee = chill;
        } else if (compareStrings(modeName, "ngmi")) {
            buyFee = ngmiBuy;
            sellFee = ngmiSell;
        } else if (compareStrings(modeName, "ape")) {
            buyFee = apeBuy;
            sellFee = apeSell;
        }

        currentTokenMode = modeName;
        nextTokenMode = nextMode;

        modeHistory.push(modeName);
        if (modeHistory.length > 10) {
            delete modeHistory[0];
            for (uint i = 0; i < modeHistory.length - 1; i++) {
                modeHistory[i] = modeHistory[i + 1];
            }
            modeHistory.pop();
        }
        lastTimeMode = block.timestamp;
        emit ModeChanged(modeName);
    }

    function getModeHistoryList() external view returns (string[] memory) {
        return modeHistory;
    }

    function getCurrentMode() external view returns (string memory) {
        return currentTokenMode;
    }

    function getNextMode() external view returns (string memory) {
        return nextTokenMode;
    }

    function getLastTimeMode() external view returns (uint256) {
        return lastTimeMode;
    }

    function getHighestReflectionEventValue() external view returns (uint256) {
        return highestReflectionEventValue;
    }

    function getHighestReflectionEventName()
        external
        view
        returns (string memory)
    {
        return highestReflectionEventName;
    }

    function getHighestReflectionEventTime() external view returns (uint256) {
        return highestReflectionEventTime;
    }

    function getHolder(
        address holderAddress
    ) external view returns (HolderInfo memory) {
        HolderInfo memory holder;
        holder.balance = _balances[holderAddress];
        holder.baseReflection = _baseReflection[holderAddress];
        holder.eventReflection = _eventReflection[holderAddress];
        holder.holdingTime = _holdingTime[holderAddress];
        holder.lastBuy = _lastBuy[holderAddress];
        holder.lastSell = _lastSell[holderAddress];
        holder.keyIndex = _keyIndex[holderAddress];
        holder.isHolder = _isHolder[holderAddress];
        return holder;
    }

    function getArrayHolder() external view returns (address[] memory) {
        return holderAddresses;
    }

    function getArrayParticipant() external view returns (address[] memory) {
        return addressesParticipantEvent;
    }

    function stopEvent() external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        require(
            eventInProgress == true,
            "There is not event started actually."
        );
        if (eventReflectedToken > highestReflectionEventValue) {
            highestReflectionEventValue = eventReflectedToken;
            highestReflectionEventTime = block.timestamp;
            highestReflectionEventName = eventNameInProgress;
        }
        emit EventFinish(eventNameInProgress, eventReflectedToken);
        eventNameInProgress = "";
        eventInProgress = false;
        eventTokenAmountDistributedBatching = 0;
        timeEventStop = block.timestamp;
    }

    function startEventName(
        string calldata eventName,
        address[] calldata selectedAddresses
    ) external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        require(
            eventInProgress == false,
            "Please finish the event before start another one."
        );
        delete addressesParticipantEvent;
        addressesParticipantEvent = selectedAddresses;
        eventNameInProgress = eventName;
        eventInProgress = true;
        eventHistory.push(eventName);
        if (eventHistory.length > 10) {
            delete eventHistory[0];
            for (uint i = 0; i < eventHistory.length - 1; i++) {
                eventHistory[i] = eventHistory[i + 1];
            }
            eventHistory.pop();
        }
        timeEventStart = block.timestamp;
        if (compareStrings(eventName, "genesis")) {
            lastTimeGenesis = block.timestamp;
        }
        emit EventStart(eventName);
    }

    function getEventHistoryList() external view returns (string[] memory) {
        return eventHistory;
    }

    function getEventTimeStart() external view returns (uint256) {
        return timeEventStart;
    }

    function getEventTimeStop() external view returns (uint256) {
        return timeEventStop;
    }

    function getLastTimeGenesis() external view returns (uint256) {
        return lastTimeGenesis;
    }

    function shouldDistributeEventReflections(
        address[] calldata batchingParticipants,
        bool isLastCall
    ) external returns (bool) {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        require(
            eventInProgress == false,
            "Please finish the event before distribute."
        );

        uint256 totalParticipantsEvent = addressesParticipantEvent.length;

        if (eventReflectedToken < totalParticipantsEvent) {
            totalRemainder = totalRemainder + eventReflectedToken;
            eventReflectedToken = 0;
            emit ReflectNotification(
                "[NOT_ENOUGH_TOKENS] Not enough tokens to distribute to every participant, tokens will be send randomly in a special event."
            );
            return false;
        }

        uint256 reflectionsPerHolder = eventReflectedToken.div(
            totalParticipantsEvent
        );
        for (uint i = 0; i < batchingParticipants.length; i++) {
            address participant = batchingParticipants[i];
            if (isHolder(participant)) {
                _eventReflection[participant] = _eventReflection[participant]
                    .add(reflectionsPerHolder);
            } else {
                totalRemainder = totalRemainder + reflectionsPerHolder;
            }

            eventTokenAmountDistributedBatching =
                eventTokenAmountDistributedBatching +
                reflectionsPerHolder;
            if (eventTokenAmountDistributedBatching >= eventReflectedToken) {
                emit ReflectDistributed(eventReflectedToken);
                eventReflectedToken = 0;
                eventTokenAmountDistributedBatching = 0;
                emit ReflectNotification(
                    "[NOT_ENOUGH_TOKENS] Not enough tokens to distribute to every participant, tokens will be send randomly in a special event."
                );
                return false;
            }
        }
        if (isLastCall) {
            uint256 remainder = eventReflectedToken % totalParticipantsEvent;
            if (remainder > 0) {
                totalRemainder = totalRemainder + remainder;
            }
            if (eventReflectedToken > eventTokenAmountDistributedBatching) {
                uint256 remainder2 = eventReflectedToken -
                    eventTokenAmountDistributedBatching;
                if (remainder2 > 0) {
                    totalRemainder = totalRemainder + remainder2;
                }
            }

            emit ReflectDistributed(eventReflectedToken);
            eventReflectedToken = 0;
            eventTokenAmountDistributedBatching = 0;
        }

        return true;
    }

    function sendRemainderTokens(address winner, uint256 amount) external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        _basicTransfer(address(this), winner, amount);
    }

    function clearStuckBalance() external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function clearStuckToken() external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        _transferFrom(address(this), msg.sender, balanceOf(address(this)));
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _pt
    ) external onlyOwner {
        claimingFees = _enabled;
        _swapThreshold = (_totalSupply * _pt) / 10000;
    }

    function manualSwapBack() external onlyOwner {
        if (_shouldSwapBack()) {
            _swapBack();
        }
    }

    function startTrading() external onlyOwner {
        enableTrading = true;
    }

    function setMSAddress(address ad) external onlyOwner {
        msAddress = ad;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsReflectionExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isReflectionExempt[holder] = exempt;
    }

    function setFeeReceivers(address ot_, address lp_) external onlyOwner {
        teamOracleFeeReceiver = ot_;
        lpFeeReceiver = lp_;
    }

    function setMinSupplyHolding(uint256 h_) external onlyOwner {
        _minSupplyHolding = (_totalSupply * h_) / 10000;
        emit HolderMinimumChanged(_minSupplyHolding);
    }

    function setEnableAutoAdjust(bool e_) external onlyOwner {
        enableAutoAdjust = e_;
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function airdrop(address recipient, uint256 amount) external {
        require(
            msg.sender == owner() ||
                msg.sender == teamOracleFeeReceiver ||
                msg.sender == airDropAddress,
            "Forbidden"
        );
        require(_balances[msg.sender] >= amount, "Insufficient Balance");
        _balances[msg.sender] = _balances[msg.sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        updateStateHolder(recipient);
        _lastBuy[recipient] = block.timestamp;
        emit Transfer(msg.sender, recipient, amount);
    }

    function airdropMultiple(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(
            msg.sender == owner() ||
                msg.sender == teamOracleFeeReceiver ||
                msg.sender == airDropAddress,
            "Forbidden"
        );
        require(recipients.length == amounts.length, "Invalid input");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            require(_balances[msg.sender] >= amount, "Insufficient Balance");

            _balances[msg.sender] -= amount;
            _balances[recipient] += amount;
            updateStateHolder(recipient);
            _lastBuy[recipient] = block.timestamp;
            emit Transfer(msg.sender, recipient, amount);
        }
    }

    function sendAutoAjustHolding() external onlyOwner {
        adjustMinimumHolding();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */

    function adjustMinimumHolding() internal {
        address[] memory path = new address[](2);
        path[0] = UNISWAP_V2_ROUTER.WETH();
        path[1] = address(this);

        uint256[] memory amounts = UNISWAP_V2_ROUTER.getAmountsOut(
            0.05 ether,
            path
        );

        uint256 amountAdjusted = amounts[1];

        _minSupplyHolding = amountAdjusted;
    }

    function _claim(address holder) internal {
        uint256 balanceNormalReflection = 0;
        if (isHolder(holder)) {
            if (holderAddresses.length > 0 && normalReflectedToken > 0) {
                uint256 baseReflection = 0;
                if (_baseReflection[holder] > 0) {
                    baseReflection = _baseReflection[holder];
                }
                uint256 calculatePersonnalReflection = normalReflectedToken /
                    holderAddresses.length;
                if (calculatePersonnalReflection > baseReflection) {
                    balanceNormalReflection =
                        calculatePersonnalReflection -
                        baseReflection;
                }
            }
        }

        uint256 totalBalance = _balances[holder];
        if (balanceNormalReflection > 0) {
            totalBalance += balanceNormalReflection;
        }
        uint256 eventBalance = _eventReflection[holder];
        if (eventBalance > 0) {
            totalBalance += eventBalance;
        }

        uint256 amountReflection = balanceNormalReflection + eventBalance;
        if (amountReflection > 0) {
            _basicTransfer(address(this), holder, amountReflection);
            _historyReflectionTransfered[holder] =
                _historyReflectionTransfered[holder] +
                amountReflection;
            if (balanceNormalReflection > 0) {
                _baseReflection[holder] =
                    _baseReflection[holder] +
                    balanceNormalReflection;
                normalReflectedToken -= balanceNormalReflection;
            }
            _eventReflection[holder] = 0;
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!blacklists[recipient] && !blacklists[sender], "Blacklisted");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(sender != DEAD && sender != ZERO, "Please use a good address");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!enableTrading) {
            if (
                sender == owner() ||
                sender == teamOracleFeeReceiver ||
                sender == airDropAddress ||
                sender == msAddress
            ) {
                emit LogInfo("bypass enableTrading");
                return _basicTransfer(sender, recipient, amount);
            } else {
                revert(
                    string(
                        abi.encodePacked(
                            "Trading not enabled yet, please wait. Sender: ",
                            addressToString(sender),
                            " Recipient: ",
                            addressToString(recipient)
                        )
                    )
                );
            }
        } else {
            if (
                sender == owner() ||
                sender == teamOracleFeeReceiver ||
                sender == airDropAddress ||
                sender == msAddress
            ) {
                return _basicTransfer(sender, recipient, amount);
            }
        }

        if (_shouldSwapBack()) {
            _swapBack();
        }

        if (!isReflectionExempt[sender]) {
            _claim(sender);
        }

        require(_balances[sender] >= amount, "Insufficient Real Balance");
        _balances[sender] = _balances[sender] - amount;

        updateStateHolder(sender);

        if (sender != UNISWAP_V2_PAIR) {
            // WHEN SELL
            _lastSell[sender] = block.timestamp;
        }

        uint256 fees = _takeFees(sender, recipient, amount);
        uint256 amountWithoutFees = amount;
        if (fees > 0) {
            amountWithoutFees -= fees;
            _balances[address(this)] = _balances[address(this)] + fees;
            emit Transfer(sender, address(this), fees);
        }

        _balances[recipient] = _balances[recipient] + amountWithoutFees;

        updateStateHolder(recipient);

        if (sender == UNISWAP_V2_PAIR) {
            // WHEN BUY
            _lastBuy[recipient] = block.timestamp;
        }

        emit Transfer(sender, recipient, amountWithoutFees);
        if (sender == UNISWAP_V2_PAIR || recipient == UNISWAP_V2_PAIR) {
            if (enableAutoAdjust) {
                adjustMinimumHolding();
            }
        }
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;
        updateStateHolder(sender);
        _balances[recipient] = _balances[recipient] + amount;
        updateStateHolder(recipient);
        _lastBuy[recipient] = block.timestamp;
        emit Transfer(sender, recipient, amount);
        if (sender == UNISWAP_V2_PAIR || recipient == UNISWAP_V2_PAIR) {
            if (enableAutoAdjust) {
                adjustMinimumHolding();
            }
        }
        return true;
    }

    function _takeFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 fees = 0;
        Fee memory __buyFee = buyFee;
        Fee memory __sellFee = sellFee;
        if (_shouldTakeFee(sender, recipient)) {
            uint256 proportionReflected = 0;
            if (sender == UNISWAP_V2_PAIR) {
                fees = amount.mul(__buyFee.total).div(100);
                proportionReflected = fees.mul(__buyFee.reflection).div(
                    __buyFee.total
                );
            } else {
                fees = amount.mul(__sellFee.total).div(100);
                proportionReflected = fees.mul(__sellFee.reflection).div(
                    __sellFee.total
                );
            }

            if (proportionReflected > 0) {
                totalReflections += proportionReflected;
                if (eventInProgress) {
                    eventReflectedToken += proportionReflected;
                } else {
                    normalReflectedToken += proportionReflected;
                }
                emit ReflectAccumulated(proportionReflected, totalReflections);
            }
        }
        return fees;
    }

    function _checkBalanceForSwapping() internal view returns (bool) {
        uint256 totalBalance = _balances[address(this)];
        uint256 totatToSub = eventReflectedToken +
            normalReflectedToken +
            totalRemainder;
        if (totatToSub > totalBalance) {
            return false;
        }
        totalBalance -= totatToSub;
        return totalBalance >= _swapThreshold;
    }

    function _shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != UNISWAP_V2_PAIR &&
            !inSwap &&
            claimingFees &&
            _checkBalanceForSwapping();
    }

    function _swapBack() internal swapping {
        Fee memory __sellFee = sellFee;

        uint256 __swapThreshold = _swapThreshold;
        uint256 amountToBurn = (__swapThreshold * __sellFee.burn) /
            __sellFee.total;
        uint256 amountToSwap = __swapThreshold - amountToBurn;
        approve(address(UNISWAP_V2_ROUTER), amountToSwap);

        // burn
        if (amountToBurn > 0) {
            _basicTransfer(address(this), DEAD, amountToBurn);
        }

        // swap
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalSwapFee = __sellFee.total -
            __sellFee.reflection -
            __sellFee.burn;
        uint256 amountETHTeamOracle = (amountETH * __sellFee.teamOracle) /
            totalSwapFee;
        uint256 amountETHLP = (amountETH * __sellFee.lp) / totalSwapFee;

        // send
        if (amountETHTeamOracle > 0) {
            (bool tmpSuccess, ) = payable(teamOracleFeeReceiver).call{
                value: amountETHTeamOracle
            }("");
        }
        if (amountETHLP > 0) {
            (bool tmpSuccess, ) = payable(lpFeeReceiver).call{
                value: amountETHLP
            }("");
        }
    }

    function _shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /* -------------------------------------------------------------------------- */
    /*                                   public                                   */
    /* -------------------------------------------------------------------------- */

    function updateStateHolder(address holder) public {
        if (!isReflectionExempt[holder]) {
            if (isHolder(holder)) {
                if (_isHolder[holder] == false) {
                    _isHolder[holder] = true;
                    _holdingTime[holder] = block.timestamp;
                    holderAddresses.push(holder);
                    _keyIndex[holder] = holderAddresses.length - 1;
                }
            } else {
                if (_isHolder[holder] == true) {
                    _isHolder[holder] = false;
                    _holdingTime[holder] = 0;
                    _keyIndex[
                        holderAddresses[holderAddresses.length - 1]
                    ] = _keyIndex[holder];
                    holderAddresses[_keyIndex[holder]] = holderAddresses[
                        holderAddresses.length - 1
                    ];
                    holderAddresses.pop();
                }
            }
        }
    }
}