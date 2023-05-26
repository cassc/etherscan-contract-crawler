/**
 *Submitted for verification at Etherscan.io on 2020-11-26
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'SafeMath: modulo by zero');
        return a % b;
    }
}

contract dgKeeper {

    using SafeMath for uint256;

    address public gateKeeper;
    address public gateOverseer;
    address public distributionToken;

    uint256 public totalRequired;
    uint256 immutable MIN_TIME_FRAME;

    struct KeeperInfo {
        uint256 keeperRate;
        uint256 keeperFrom;
        uint256 keeperTill;
        uint256 keeperBalance;
        uint256 keeperPayouts;
        bool isImmutable;
    }

    mapping(address => KeeperInfo) public keeperList;

    modifier onlyGateKeeper() {
        require(
            msg.sender == gateKeeper,
            'dgKeeper: keeper denied!'
        );
        _;
    }

    modifier onlyGateOverseer() {
        require(
            msg.sender == gateOverseer,
            'dgKeeper: overseer denied!'
        );
        _;
    }

    event tokensScraped (
        address indexed scraper,
        uint256 scrapedAmount,
        uint256 timestamp
    );

    event recipientCreated (
        address indexed recipient,
        uint256 timeLock,
        uint256 timeReward,
        uint256 instantReward,
        uint256 timestamp,
        bool isImmutable
    );

    event recipientDestroyed (
        address indexed recipient,
        uint256 timestamp
    );

    constructor(
        address _distributionToken,
        address _gateOverseer,
        address _gateKeeper,
        uint256 _minTimeFrame
    ) {
        require(
            _minTimeFrame > 0,
            'dgKeeper: increase _timeFrame'
        );
        distributionToken = _distributionToken;
        gateOverseer = _gateOverseer;
        gateKeeper = _gateKeeper;
        MIN_TIME_FRAME = _minTimeFrame;
    }

    function allocateTokensBulk(
        address[] memory _recipients,
        uint256[] memory _tokensOpened,
        uint256[] memory _tokensLocked,
        uint256[] memory _timeFrame,
        bool[] memory _immutable
    )
        external
        onlyGateKeeper
    {
        for(uint i = 0; i < _recipients.length; i++) {
            allocateTokens(
                _recipients[i],
                _tokensOpened[i],
                _tokensLocked[i],
                _timeFrame[i],
                _immutable[i]
            );
        }
    }

    function allocateTokens(
        address _recipient,
        uint256 _tokensOpened,
        uint256 _tokensLocked,
        uint256 _timeFrame,
        bool _isImmutable
    )
        public
        onlyGateKeeper
    {
        require(
            _timeFrame >= MIN_TIME_FRAME,
            'dgKeeper: _timeFrame below minimum'
        );

        require(
            keeperList[_recipient].keeperFrom == 0,
            'dgKeeper: _recipient is active'
        );

        totalRequired =
        totalRequired
            .add(_tokensOpened)
            .add(_tokensLocked);

        safeBalanceOf(
            distributionToken,
            address(this),
            totalRequired
        );

        keeperList[_recipient].keeperFrom = getNow();
        keeperList[_recipient].keeperTill = getNow().add(_timeFrame);
        keeperList[_recipient].keeperRate = _tokensLocked.div(_timeFrame);
        keeperList[_recipient].keeperBalance = _tokensLocked.mod(_timeFrame);
        keeperList[_recipient].isImmutable = _isImmutable;

        keeperList[_recipient].keeperBalance = 
        keeperList[_recipient].keeperBalance.add(_tokensOpened);

        emit recipientCreated (
            _recipient,
            _timeFrame,
            _tokensLocked,
            _tokensOpened,
            block.timestamp,
            _isImmutable
        );
    }

    function scrapeMyTokens()
        external
    {
        _scrapeTokens(msg.sender);
    }

    function scrapeTokens(
        address _recipient
    ) 
        external
        onlyGateOverseer
    {
        _scrapeTokens(
            _recipient
        );
    }

    function _scrapeTokens(
        address _recipient
    )
        internal
    {
       uint256 scrapeAmount =
        availableBalance(_recipient);

        keeperList[_recipient].keeperPayouts =
        keeperList[_recipient].keeperPayouts.add(scrapeAmount);

        safeTransfer(
            distributionToken,
            _recipient,
            scrapeAmount
        );

        totalRequired =
        totalRequired.sub(scrapeAmount);

        emit tokensScraped (
            _recipient,
            scrapeAmount,
            block.timestamp
        );
    }

    function destroyRecipient(
        address _recipient
    )
        external
        onlyGateOverseer
    {
        require(
            keeperList[_recipient].isImmutable == false,
            'dgKeeper: _recipient is immutable'
        );

        _scrapeTokens(_recipient);

        totalRequired =
        totalRequired.sub(
            lockedBalance(_recipient)
        );

        delete keeperList[_recipient];
        
        emit recipientDestroyed (
            _recipient,
            block.timestamp
        );
    }

    function availableBalance(
        address _recipient
    )
        public
        view
        returns (uint256)
    {
        uint256 timePassed =
            getNow() < keeperList[_recipient].keeperTill
                ? getNow()
                    .sub(keeperList[_recipient].keeperFrom)
                : keeperList[_recipient].keeperTill
                    .sub(keeperList[_recipient].keeperFrom);

        return keeperList[_recipient].keeperRate
            .mul(timePassed)
            .add(keeperList[_recipient].keeperBalance)
            .sub(keeperList[_recipient].keeperPayouts);
    }

    function lockedBalance(address _recipient)
        public
        view
        returns (uint256)
    {
        uint256 timeRemaining =
            keeperList[_recipient].keeperTill > getNow() ?
            keeperList[_recipient].keeperTill - getNow() : 0;

        return keeperList[_recipient].keeperRate
            .mul(timeRemaining);
    }

    function getNow()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function changeDistributionToken(
        address _newDistributionToken
    )
        external
        onlyGateKeeper
    {
        distributionToken = _newDistributionToken;
    }

    function renounceKeeperOwnership()
        external
        onlyGateKeeper
    {
        gateKeeper = address(0x0);
    }

    function renounceOverseerOwnership()
        external
        onlyGateOverseer
    {
        gateOverseer = address(0x0);
    }

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    bytes4 private constant BALANCEOF = bytes4(
        keccak256(
            bytes(
                'balanceOf(address)'
            )
        )
    );

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        private
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            'dgKeeper: TRANSFER_FAILED'
        );
    }

    function safeBalanceOf(
        address _token,
        address _owner,
        uint256 _required
    )
        private
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                BALANCEOF,
                _owner
            )
        );

        require(
            success && abi.decode(
                data, (uint256)
            ) >= _required,
            'dgKeeper: BALANCEOF_FAILED'
        );
    }
}