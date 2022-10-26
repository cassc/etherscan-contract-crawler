// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";

abstract contract ContractGlossary2 {
    function getAddress(string memory name)
        public
        view
        virtual
        returns (address);
}

abstract contract Horser {
    function addRandNums(address to, uint256[] memory ids) public virtual;
}

contract VRFV2 is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    ContractGlossary2 Index;

    event VRFFulfilled(address to, uint256[] randNums);

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Mainnet coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 s_keyHash;

    uint256 callbackGasLimit;
    uint256 baseGas;
    uint256 gasPerWord;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    address s_owner;

    mapping(uint256 => address) private requests;

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @dev NETWORK: Mainnet
     *
     * @param subscriptionId subscription id that this consumer contract can use
     */
    constructor(
        uint64 subscriptionId,
        address _vrfCoordinator,
        bytes32 _s_keyHash,
        address indexContract
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
        s_keyHash = _s_keyHash;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        Index = ContractGlossary2(indexContract);
        baseGas = 200000;
        gasPerWord = 20000;
    }

    function setIndexContract(address contractAddress) public onlyOwner {
        Index = ContractGlossary2(contractAddress);
    }

    function setGas(
        uint256 _baseGas,
        uint256 _gasPerWord,
        bytes32 _s_keyhash
    ) public onlyOwner {
        baseGas = _baseGas;
        gasPerWord = _gasPerWord;
        s_keyHash = _s_keyhash;
    }

    function rollDice(uint256 num_req, address to) public returns (uint256) {
        require(msg.sender == Index.getAddress("Horse"));
        // Will revert if subscription is not set and funded.
        callbackGasLimit = gasPerWord * num_req + baseGas;
        uint256 requestID = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            uint32(callbackGasLimit),
            uint32(num_req)
        );
        requests[requestID] = to;
        return requestID;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        emit VRFFulfilled(requests[requestId], randomWords);
        Horser Horse = Horser(Index.getAddress("Horse"));
        Horse.addRandNums(requests[requestId], randomWords);
        delete requests[requestId];
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}