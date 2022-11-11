// SPDX-License-Identifier: MIT
// Taipe Experience Contracts
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../nft/TaipeNFT.sol";
import "./RandomMinter.sol";

import {TaipeLib} from "../lib/TaipeLib.sol";

contract VRFMinter is RandomMinter, VRFConsumerBaseV2, AccessControl {
    // chainlink configuration
    VRFCoordinatorV2Interface public COORDINATOR;
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 callbackGasLimit = 300000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // access manager
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // state
    mapping(uint => NftRequest) public request;
    uint public inflightRequests;

    event RequestFulfilled(uint requestId, address owner, uint nftId);

    struct NftRequest {
        address owner;
        uint fulfilledNftId;
    }

    constructor(
        TaipeLib.Tier tier,
        address nft,
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash
    ) RandomMinter(tier, nft) VRFConsumerBaseV2(vrfCoordinator) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
    }

    function mint(address owner)
        public
        override
        hasAvailableToken
        onlyRole(MINTER_ROLE)
        returns (uint requestId)
    {
        requestId = _requestRandomNftTo(owner);
    }

    function _requestRandomNftTo(address to) internal returns (uint) {
        uint requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        request[requestId] = NftRequest({owner: to, fulfilledNftId: 0});
        inflightRequests++;
        return requestId;
    }

    function fulfillRandomWords(uint requestId, uint[] memory randomWords)
        internal
        override
    {
        NftRequest storage s = request[requestId];
        uint random = randomWords[0];
        s.fulfilledNftId = _takeRandomNftId(random);
        inflightRequests--;
        emit RequestFulfilled(requestId, s.owner, s.fulfilledNftId);
    }

    // only owner/allowed can call this
    function unpack(uint requestId) public returns (uint) {
        NftRequest storage s = request[requestId];
        require(
            _msgSender() == s.owner || hasRole(MINTER_ROLE, _msgSender()),
            "VRFMinter: caller does not have permission"
        );
        require(s.fulfilledNftId > 0, "VRFMinter: request not fulfilled");

        uint nftId = s.fulfilledNftId;
        _nft.mintTo(s.owner, nftId);
        delete request[requestId];

        return nftId;
    }

    function inflightTokens() public view override returns (uint) {
        return inflightRequests;
    }
}