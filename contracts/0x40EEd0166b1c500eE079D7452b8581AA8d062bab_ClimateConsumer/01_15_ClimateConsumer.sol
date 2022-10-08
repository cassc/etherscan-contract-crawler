// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol";

/// A file hash for this Climate input request already exists
/// @param requestHash hash of the request inputs.
/// @param responseHash results.
error RequestAlreadyExists(string requestHash, string responseHash);

contract ClimateConsumer is
    ChainlinkClient,
    ConfirmedOwnerWithProposal,
    ConfirmedOwner
{
    using Chainlink for Chainlink.Request;

    uint256 public ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY;

    bytes32 public currentRequestHash;
    mapping(bytes32 => bytes32) public hashes;
    address public oracle;
    bytes32 public jobId;

    constructor(address _oracle, string memory _jobId)
        ConfirmedOwner(msg.sender)
    {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
    }

    function setOracle(address _oracle) public {
        oracle = _oracle;
    }

    function setJobId(string memory _jobId) public {
        jobId = stringToBytes32(_jobId);
    }

    function setOracleFee(uint256 oracleFee) public {
        ORACLE_PAYMENT = oracleFee;
    }

    function generateRequestHash(
        string memory _stationId,
        string memory _height,
        string memory _startDate,
        string memory _endDate,
        string memory _startTime,
        string memory _endTime
    ) public pure returns (bytes32) {
        bytes memory currentRequestInput = abi.encodePacked(
            bytes(_stationId),
            bytes(_height),
            bytes(_startDate),
            bytes(_endDate),
            bytes(_startTime),
            bytes(_endTime)
        );
        return keccak256(currentRequestInput);
    }

    function requestClimateHash(
        string memory _stationId,
        string memory _height,
        string memory _startDate,
        string memory _endDate,
        string memory _startTime,
        string memory _endTime
    ) public onlyOwner {
        currentRequestHash = generateRequestHash(
            _stationId,
            _height,
            _startDate,
            _endDate,
            _startTime,
            _endTime
        );
        if (hashes[currentRequestHash] > 0) {
            revert("Data for this request already exists");
        }
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillClimateHash.selector
        );

        string memory link = "https://climate-ui-dev.hyphen.earth/api/stations";

        string[] memory extPathParams = new string[](7);
        extPathParams[0] = _stationId;
        extPathParams[1] = "only-hash";
        extPathParams[2] = _height;
        extPathParams[3] = _startDate;
        extPathParams[4] = _endDate;
        extPathParams[5] = _startTime;
        extPathParams[6] = _endTime;
        req.add("get", link);
        req.addStringArray("extPath", extPathParams);
        req.add("path", "data.0.hash");
        sendChainlinkRequestTo(oracle, req, ORACLE_PAYMENT);
    }

    function getFileHashForParams(
        string memory _stationId,
        string memory _height,
        string memory _startDate,
        string memory _endDate,
        string memory _startTime,
        string memory _endTime
    ) public view returns (string memory) {
        bytes32 requestHash = generateRequestHash(
            _stationId,
            _height,
            _startDate,
            _endDate,
            _startTime,
            _endTime
        );

        bytes32 responseHash = hashes[requestHash];
        string memory responseHashStr = bytes32ToString(responseHash);
        return responseHashStr;
    }

    function getFilehashForKey(string memory _keyString)
        public
        view
        returns (bytes32, string memory)
    {
        bytes32 k = stringToBytes32(_keyString);
        require(hashes[k] > 0, "This key does not exist");
        bytes32 v = hashes[k];
        string memory valueString = bytes32ToString(v);

        return (v, valueString);
    }

    function bytes32ToString(bytes32 _bytes32)
        private
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function fulfillClimateHash(bytes32 _requestId, bytes32 _hash)
        public
        recordChainlinkFulfillment(_requestId)
    {
        hashes[currentRequestHash] = _hash;
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}