// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ChainlinkClientUpgradable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./EDataTypes.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "hardhat/console.sol";

contract EventStorage {
    mapping(uint256 => EDataTypes.Event) public events;
    uint256 public nEvents;
}

contract EventStorageV2 {
    bytes32 public jobId;
    address public blocker;
    mapping(uint256 => address) public aggregator;
    mapping(uint256 => int256) public finalResult;
    AggregatorV3Interface internal priceFeed;
}

contract Event is
    EventStorage,
    OwnableUpgradeable,
    ChainlinkClientUpgradable,
    KeeperCompatibleInterface,
    EventStorageV2
{
    using Chainlink for Chainlink.Request;

    function initialize() public initializer {
        nEvents = 0;
        OwnableUpgradeable.__Ownable_init();
        ChainlinkClientUpgradable.__ChainlinkClient_init();
        setBlocker(0xE06b2e5dE69cbB8dbC9b8e22BFd9E8f8A19D64c1);
    }

    function setOracle(
        address _token,
        address _oracle,
        bytes32 _jobId
    ) public onlyOwner {
        setChainlinkToken(_token);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
    }

    function setBlocker(address _blocker) public onlyOwner {
        blocker = _blocker;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function updateEventResult(uint256 _eventId, uint256 _index) external {
        EDataTypes.Event storage _event = events[_eventId];
        require(_index < _event.odds.length, "cannot-find-index");
        require(_event.creator == msg.sender, "unauthorized");
        require(_event.endTime <= block.timestamp, "end_time <= timestamp");
        require(_event.endTime == 0 || _event.endTime + 172800 >= block.timestamp, "end_time + 2 days >= timestamp");
        require(_event.pro == 0, "not pro event");
        require(_event.status != EDataTypes.EventStatus.FINISH, "event already finish");

        _event.finalTime = block.timestamp;
        _event.claimTime = block.timestamp + 172800;
        _event.resultIndex = _index;
        _event.status = EDataTypes.EventStatus.FINISH;

        emit EventResultUpdated(msg.sender, _eventId, _index, _event.finalTime, _event.claimTime);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function info(uint256 _eventId) external view returns (EDataTypes.Event memory _event) {
        _event = events[_eventId];
    }

    function createSingleEvent(
        uint256[5] memory _numInfos,
        address[3] memory _addresses,
        uint256[] calldata _odds,
        string memory _datas,
        bool _affiliate
    ) external returns (uint256 _idx) {
        require(_numInfos[0] < _numInfos[1], "deadline_time > start_time");
        require(_numInfos[1] < _numInfos[2], "end_time > deadline_time");
        _idx = nEvents;

        events[_idx] = EDataTypes.Event(
            _numInfos[0],
            _numInfos[1],
            _numInfos[2],
            0,
            EDataTypes.EventStatus.AVAILABLE,
            _addresses[0],
            _addresses[2],
            _odds,
            _datas,
            _numInfos[3],
            false,
            0,
            0,
            _affiliate,
            _numInfos[4]
        );
        aggregator[_idx] = _addresses[1];
        nEvents++;
    }

    /* ========== CHAIN LINK FUNCTIONS ========== */

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory performData) {
        string memory performString;
        for (uint256 i = 0; i < nEvents; ++i) {
            if (
                events[i].pro > 0 &&
                events[i].endTime != 0 &&
                events[i].endTime <= block.timestamp &&
                events[i].status == EDataTypes.EventStatus.AVAILABLE
            ) {
                upkeepNeeded = true;
                performString = string(bytes.concat(bytes(performString), bytes(Strings.toString(i)), ","));
            }
        }
        performData = bytes(performString);
    }

    function performUpkeep(bytes calldata performData) public override {
        uint256 number = 0;
        bool callOracle = false;
        for (uint256 i = 0; i < performData.length; i++) {
            uint8 c = uint8(performData[i]);
            if (c >= 48 && c < 58) {
                number = number * 10 + c - 48;
            } else {
                if (events[number].pro == 5) {
                    priceFeed = AggregatorV3Interface(aggregator[number]);
                    (, int256 price, , , ) = priceFeed.latestRoundData();
                    for (uint256 i = events[number].odds.length / 2; i < events[number].odds.length; i++) {
                        if (
                            (i != events[number].odds.length - 1 && price < int256(events[number].odds[i])) ||
                            i == events[number].odds.length - 1
                        ) {
                            events[number].finalTime = block.timestamp;
                            events[number].claimTime = block.timestamp;
                            events[number].resultIndex = i - events[number].odds.length / 2;
                            events[number].status = EDataTypes.EventStatus.FINISH;
                            finalResult[number] = price;
                            emit EventResultUpdated(
                                msg.sender,
                                number,
                                events[number].resultIndex,
                                events[number].finalTime,
                                events[number].claimTime
                            );
                            break;
                        }
                    }
                } else {
                    events[number].status = EDataTypes.EventStatus.PROGRESS;
                    callOracle = true;
                }
                number = 0;
            }
        }

        if (callOracle) {
            Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
            req.add("get", string(performData));
            req.add("path", "data");
            sendChainlinkRequest(req, 0);
        }
    }

    /**
     * Receive the response in the form of string
     */
    function fulfill(bytes32 _requestId, string memory _data) public {
        bool pos = false;
        uint256 eventId = 0;
        uint256 number = 0;
        bytes memory data = bytes(_data);

        for (uint256 i = 0; i < data.length; i++) {
            uint8 c = uint8(data[i]);
            if (c >= 48 && c < 58) {
                number = number * 10 + c - 48;
            } else {
                if (!pos) {
                    eventId = number;
                    pos = true;
                } else {
                    events[eventId].finalTime = block.timestamp;
                    events[eventId].claimTime = block.timestamp;
                    if (number == 0) {
                        events[eventId].isBlock = true;
                    } else {
                        events[eventId].resultIndex = number - 1;
                    }
                    events[eventId].status = EDataTypes.EventStatus.FINISH;

                    emit EventResultUpdated(
                        msg.sender,
                        eventId,
                        number,
                        events[eventId].finalTime,
                        events[eventId].claimTime
                    );
                    pos = false;
                }
                number = 0;
            }
        }
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * Block event withdraw
     */
    function blockEvent(uint256 _eventId) public {
        require(blocker == msg.sender, "Blocker: caller is not the blocker");
        require(events[_eventId].finalTime <= block.timestamp, "final_time <= timestamp");
        require(events[_eventId].claimTime >= block.timestamp, "claim_time >= timestamp");
        events[_eventId].isBlock = true;
    }

    /**
     * Block event withdraw
     */
    function unblockEvent(uint256 _eventId) public {
        require(blocker == msg.sender, "Blocker: caller is not the blocker");
        require(events[_eventId].finalTime <= block.timestamp, "final_time <= timestamp");
        require(events[_eventId].claimTime >= block.timestamp, "claim_time >= timestamp");
        events[_eventId].isBlock = false;
        events[_eventId].claimTime = block.timestamp;
    }

    /* =============== EVENTS ==================== */

    event EventResultUpdated(address caller, uint256 eventId, uint256 index, uint256 finalTime, uint256 claimTime);
}