// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../token/ERC721/PistisScore.sol";

contract PNSOperations is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    PistisScore public pistisScore;

    bytes32 private jobId;

    struct RequestStatus {
        bool fulfilled;
        bool set;
        uint256 token;
        string name;
    }

    event PNSSet(bytes32 indexed requestId, bool result);

    mapping(bytes32 => RequestStatus) public s_requests;

    constructor(PistisScore _pistisScore) ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x404460C6A5EdE2D891e8297795264fDe62ADBB75);
        setChainlinkOracle(0x95F936Cdc6e2513D8e238c5aC69b502C49DeD262);
        jobId = "6242d8df6e3b460680bca4d9d30a0c6b";

        pistisScore = _pistisScore;
    }

    function setPNSName(
        uint256 _token,
        string calldata _name
    ) external returns (bytes32 requestId) {
        require(
            pistisScore.checkTokenExists(_token),
            "ERC721Metadata: The token doesn't exist"
        );
        require(
            pistisScore.addressInTokenExists(_token, msg.sender),
            "You aren't the token owner"
        );
        require(!pistisScore.checkNameExists(_name), "Name already exist");

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add("name", _name);

        requestId = sendChainlinkRequest(req, 0);

        s_requests[requestId] = RequestStatus({
            token: _token,
            name: _name,
            fulfilled: false,
            set: false
        });

        return requestId;
    }

    function fulfill(
        bytes32 _requestId,
        bool _result
    ) public recordChainlinkFulfillment(_requestId) {
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].set = _result;

        if (_result) {
            pistisScore.setPNSName(
                s_requests[_requestId].token,
                s_requests[_requestId].name
            );
        }

        emit PNSSet(_requestId, _result);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}