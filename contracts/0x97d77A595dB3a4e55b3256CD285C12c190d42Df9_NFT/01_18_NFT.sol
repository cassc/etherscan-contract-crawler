// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./test/TestMintPass.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

// 1
// 176892, 153819, 153819
// 157255, 136743, 136743
// 157269, 136755, 136755

// 2
// 236114, 205316, 205316
// 216449, 188216, 188216
// 216449, 188216, 188216

// 2 - 2
// 239652, 208393, 208393
// 219987, 191293, 191293

// 4
// 337692, 293645, 293645

// 6
// 455398, 395998, 395998

contract NFT is VRFConsumerBaseV2, ConfirmedOwner, ERC721 {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    TestMintPass public mintPass;

    mapping(uint256 => uint256) public data;

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        address caller;
        uint256[] randomWords;
        uint256 noOfNFTs;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint256 totalAvailable = 1500;

    constructor(
        address vrfCoordinator_,
        uint64 subscriptionId,
        TestMintPass mintPass_,
        bytes32 keyHash_
    )
        VRFConsumerBaseV2(vrfCoordinator_)
        ConfirmedOwner(msg.sender)
        ERC721("NAME", "SYMBOL")
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        s_subscriptionId = subscriptionId;
        mintPass = mintPass_;
        keyHash = keyHash_;
    }

    // Assumes the subscription is funded sufficiently.
    function claim(uint256[] calldata tokenIds)
        external
        returns (uint256 requestId)
    {
        require(tokenIds.length != 0, "atleast one mint pass needed");
        require(tokenIds.length <= 5, "maximum 5 mint passes at a time");
        uint256 last;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (i != 0 && tokenIds[i] <= last) revert("invalid tokenIds array");
            last = tokenIds[i];
            require(
                mintPass.ownerOf(tokenIds[i]) == msg.sender,
                "only pass owner allowed"
            );
        }
        for (uint256 i = 0; i < tokenIds.length; i++)
            mintPass.burn(tokenIds[i]);
        uint32 callbackGasLimit = uint32(tokenIds.length * 110000 + 120000);
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            caller: msg.sender,
            noOfNFTs: tokenIds.length
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        require(!s_requests[_requestId].fulfilled, "request already fulfilled");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        mintNFT(_requestId);
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function mintNFT(uint256 requestId) internal {
        RequestStatus memory request = s_requests[requestId];
        uint256 randomWord = request.randomWords[0];
        for (uint256 i = 0; i < request.noOfNFTs * 2; i++) {
            _mintNFT(request.caller, randomWord);
            randomWord /= totalAvailable;
        }
    }

    function _mintNFT(address owner, uint256 randomWord) internal {
        uint256 primaryId = randomWord % (totalAvailable--);
        uint256 id;
        if (data[primaryId] != 0) id = data[primaryId];
        else id = primaryId;
        if (data[totalAvailable] != 0) data[primaryId] = data[totalAvailable];
        else data[primaryId] = totalAvailable;
        _safeMint(owner, id);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}