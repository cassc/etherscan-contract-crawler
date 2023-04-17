// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../token/ERC721/PistisScore.sol";

contract UpdatePistisRating is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    PistisScore public pistisScore;

    struct RequestStatus {
        bool fulfilled;
        uint256 token;
        uint256 provider;
        uint256 providerRating;
        uint256 globalRating;
    }

    event RatingUpdated(
        bytes32 requestId,
        uint256 token,
        uint256 provider,
        uint256 providerRating,
        uint256 globalRating
    );

    mapping(bytes32 => RequestStatus) public s_requests;

    constructor(PistisScore _pistisScore) {
        setChainlinkToken(0x404460C6A5EdE2D891e8297795264fDe62ADBB75);
        setChainlinkOracle(0x95F936Cdc6e2513D8e238c5aC69b502C49DeD262);

        pistisScore = _pistisScore;
    }

    function updateTokenRating(
        uint256 _token,
        uint256 _provider,
        uint256 _rating
    ) external returns (bytes32 requestId) {
        require(
            pistisScore.checkProviderTrustedAddress(_provider, msg.sender) ==
                true,
            "Sender not in trusted addresses"
        );

        pistisScore.addNewTokenPointByProvider(_token, _provider, _rating);

        Chainlink.Request memory req = buildChainlinkRequest(
            "dda63b140044433fa793942b3d050069", // job id
            address(this),
            this.fulfillMultipleParameters.selector
        );

        req.addUint("token", _token);
        req.addUint("provider", _provider);

        requestId = sendChainlinkRequest(req, 0);

        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            token: _token,
            provider: _provider,
            providerRating: 0,
            globalRating: 0
        });

        return requestId;
    }

    function fulfillMultipleParameters(
        bytes32 requestId,
        uint256 _providerRating,
        uint256 _globalRating
    ) public recordChainlinkFulfillment(requestId) {
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].providerRating = _providerRating;
        s_requests[requestId].globalRating = _globalRating;

        pistisScore.updateTokenRating(
            s_requests[requestId].token,
            s_requests[requestId].provider,
            _providerRating,
            _globalRating
        );

        emit RatingUpdated(
            requestId,
            s_requests[requestId].token,
            s_requests[requestId].provider,
            _providerRating,
            _globalRating
        );
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}