// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract Climate is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    address public owner;
    mapping(string => string) public hashes;

    string private currentRequestHash;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this method");
        _;
    }

    constructor() {
        //setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10**18; // (Varies by network and job)
        owner = msg.sender;
    }

    function setJobId(string memory _jobId) external onlyOwner {
        jobId = stringToBytes32(_jobId);
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    receive() external payable {}

    function encodeRequest(
        string memory _stationId,
        string memory _height,
        string memory _startDate,
        string memory _endDate,
        string memory _startTime,
        string memory _endTime
    ) public pure returns (string memory result) {
        bytes32 bytesResult = keccak256(
            abi.encodePacked(
                _stationId,
                _height,
                _startDate,
                _endDate,
                _startTime,
                _endTime
            )
        );
        result = bytes32ToString(bytesResult);
        return result;
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

    function requestFileHash(
        string memory _stationId,
        string memory _height,
        string memory _startDate,
        string memory _endDate,
        string memory _startTime,
        string memory _endTime
    ) public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        request.add("stationId", _stationId);
        request.add("height", _height);
        request.add("startDate", _startDate);
        request.add("endDate", _endDate);
        request.add("startTime", _startTime);
        request.add("endTime", _endTime);

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(
        bytes32 _requestId,
        string memory _requestHash,
        string memory _responseHash
    ) public recordChainlinkFulfillment(_requestId) {
        hashes[_requestHash] = _responseHash;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());

        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}