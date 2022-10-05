// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "../Interfaces/IPVRF.sol";

contract PVRF is IPVRF, VRFConsumerBaseV2, KeeperCompatibleInterface, Ownable {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    uint64 s_subscriptionId;

    // goerli
    // address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    // mainnet
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

    // Goerli LINK token
    // address link_token_contract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // Mainnet link token
    address link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // goerli 30gwei
    // bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    // mainnet 200gwei
    bytes32 keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    uint32 callbackGasLimit = 600000;

    uint16 requestConfirmations = 3;

    using SafeMath for uint256;

    string private _name = "P-VRF";

    using Counters for Counters.Counter;

    Counters.Counter private _configsCounter;

    mapping(uint256 => VRFConfig) private VRFConfigs;

    mapping(uint256 => VRFData) private VRFs;

    mapping(uint256 => uint256[]) private requests;

    mapping(uint256 => uint256) private indexMap;

    constructor(
        uint64 subscriptionId,
        uint256 startBlock_,
        uint256 intervalBlocks_
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;

        VRFConfig memory vrfconfig;

        vrfconfig.startBlock = startBlock_;
        vrfconfig.intervalBlocks = intervalBlocks_;
        vrfconfig.startIndex = 0;

        vrfconfig.lastRequestBlock = startBlock_.sub(intervalBlocks_);
        VRFConfigs[_configsCounter.current()] = vrfconfig;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function startBlock() public view returns (uint256) {
        return VRFConfigs[_configsCounter.current()].startBlock;
    }

    function startIndex() public view returns (uint256) {
        return VRFConfigs[_configsCounter.current()].startIndex;
    }

    function intervalBlocks() public view returns (uint256) {
        return VRFConfigs[_configsCounter.current()].intervalBlocks;
    }

    function lastRequestBlock() public view returns (uint256) {
        return VRFConfigs[_configsCounter.current()].lastRequestBlock;
    }

    function getVRFConfig(uint256 configIndex)
        public
        view
        returns (VRFConfig memory)
    {
        return VRFConfigs[configIndex];
    }

    function getVRFConfigCurrentIndex() public view returns (uint256) {
        return _configsCounter.current();
    }

    function getVRFInfo(uint256 blockNumber)
        public
        view
        returns (VRFSTATE, VRFData memory)
    {
        VRFData memory vrfData = VRFs[blockNumber];
        VRFSTATE VRFState;
        if (block.number < blockNumber) {
            VRFState = VRFSTATE.NOT_REACH_GENERATE_BLOCK;
        } else if (vrfData.randomWord > 0) {
            VRFState = VRFSTATE.GENERATED;
        } else if (vrfData.requestId == 0) {
            VRFState = VRFSTATE.NOT_REQUEST;
        } else if (vrfData.randomWord == 0) {
            VRFState = VRFSTATE.NOT_GENERATE;
        }
        return (VRFState, vrfData);
    }

    function getNextBlockNumber() public view returns (uint256) {
        if (block.number < startBlock()) {
            return startBlock();
        } else {
            return
                block.number.add(
                    intervalBlocks().sub(
                        block.number.sub(startBlock()).mod(intervalBlocks())
                    )
                );
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        uint256 lastNeedRequestBlock = getNextBlockNumber() - intervalBlocks();
        upkeepNeeded = lastRequestBlock() < lastNeedRequestBlock;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        uint256 lastRequestBlock_ = lastRequestBlock();
        uint256 intervalBlocks_ = intervalBlocks();
        uint256 lastNeedRequestBlock = getNextBlockNumber() - intervalBlocks_;

        require(lastRequestBlock_ < lastNeedRequestBlock, "nothing to request");

        uint32 numWords = uint32(
            lastNeedRequestBlock.sub(lastRequestBlock_).div(intervalBlocks_)
        );
        if (numWords > 5) {
            numWords = 5;
        }

        uint256 clRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        uint256 nextRequestBlock;
        for (uint256 i = 1; i <= numWords; i++) {
            nextRequestBlock = lastRequestBlock_.add(intervalBlocks_.mul(i));
            requests[clRequestId].push(nextRequestBlock);
            VRFs[nextRequestBlock].requestId = clRequestId;
        }

        VRFConfigs[getVRFConfigCurrentIndex()]
            .lastRequestBlock = nextRequestBlock;

        emit VRFRequest(
            lastRequestBlock_.add(intervalBlocks_),
            numWords,
            msg.sender
        );
    }

    function fulfillRandomWords(
        uint256 s_requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 blockNumber;
        uint256 requestnum = requests[s_requestId].length;
        for (uint256 i = 0; i < requestnum; i++) {
            blockNumber = requests[s_requestId][i];
            VRFs[blockNumber].randomWord = randomWords[i];
            emit VRFGenerated(blockNumber, randomWords[i]);
        }
    }

    function setIntervalBlocks(uint256 intervalBlocks_) public onlyOwner {
        require(intervalBlocks_ > 0, "intervalBlocks too small");
        VRFConfig memory vrfconfig;
        vrfconfig.startBlock = lastRequestBlock() + intervalBlocks_;
        vrfconfig.intervalBlocks = intervalBlocks_;
        if (lastRequestBlock() < startBlock()) {
            vrfconfig.startIndex = startIndex();
        } else if (lastRequestBlock() == startBlock()) {
            vrfconfig.startIndex = startIndex().add(1);
        } else {
            vrfconfig.startIndex = startIndex().add(
                lastRequestBlock().sub(startBlock()).div(intervalBlocks()).add(
                    1
                )
            );
        }
        vrfconfig.lastRequestBlock = vrfconfig.startBlock.sub(
            vrfconfig.intervalBlocks
        );

        _configsCounter.increment();
        VRFConfigs[_configsCounter.current()] = vrfconfig;
    }
}