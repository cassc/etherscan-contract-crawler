// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Raffle is VRFConsumerBaseV2, Ownable {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256 randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    uint32 callbackGasLimit = 300000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    struct Result {
        uint256 randomId;
        bool isMatch;
        address raycOwner;
        address zaycOwner;
        uint256 blockNumber;
    }
    Result[] public results; // stores all draws
    uint256[] public simpleResults; // stores only winning IDs
    IERC721 public raycAddress;
    IERC721 public zaycAddress;

    constructor(
        uint64 subscriptionId,
        IERC721 _raycAddress,
        IERC721 _zaycAddress
    ) VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x271682DEB8C4E0901D1a1550aD2e64D568E69909
        );
        s_subscriptionId = subscriptionId;
        raycAddress = _raycAddress;
        zaycAddress = _zaycAddress;
    }

    // in the event of the same ID being selected twice, the second instance should be manually excluded from the raffle
    function requestRandomPair()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: 0,
            exists: true,
            fulfilled: false
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

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords[0] % 10000;
        uint256 tokenId = _randomWords[0] % 10000;
        try raycAddress.ownerOf(tokenId) {
            try zaycAddress.ownerOf(tokenId) {
                if (
                    raycAddress.ownerOf(tokenId) == zaycAddress.ownerOf(tokenId)
                ) {
                    results.push(
                        Result(
                            tokenId,
                            true,
                            raycAddress.ownerOf(tokenId),
                            zaycAddress.ownerOf(tokenId),
                            block.number
                        )
                    );
                    simpleResults.push(tokenId);
                } else {
                    results.push(
                        Result(
                            tokenId,
                            false,
                            raycAddress.ownerOf(tokenId),
                            zaycAddress.ownerOf(tokenId),
                            block.number
                        )
                    );
                }
            } catch {
                results.push(
                    Result(tokenId, false, address(0), address(0), block.number)
                );
            }
        } catch {
            results.push(
                Result(tokenId, false, address(0), address(0), block.number)
            );
        }

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function updateGasLimit(uint32 _val) public onlyOwner {
        callbackGasLimit = _val;
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256 randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getResultsLength() public view returns (uint256 length) {
        return results.length;
    }

    function getSimpleResultsLength() public view returns (uint256 length) {
        return simpleResults.length;
    }

}