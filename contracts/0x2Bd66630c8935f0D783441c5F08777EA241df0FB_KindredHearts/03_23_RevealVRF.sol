// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

abstract contract RevealVRF is VRFConsumerBase {
    constructor(
        address _vrfCoordinator,
        address _link,
        uint256 _linkVrfFee,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyHash;
        linkVrfFee = _linkVrfFee;
    }

    event Revealed(
        bytes32 traitseed,
        uint256 randomness,
        uint256 block,
        uint256 time
    );

    // traitseed is used to generate traits. it can only be set once.

    /**
    * @dev for layers 1-17, traitseed is set by VRF once, card=keccak256(traitseed,tokenId)
    */
    bytes32 public traitseed; // set with VRF, for layers 0-15
    /**
    * @dev for layers 16-32, generated with 
    * cardTraitsB=keccak256(keccak256(traitseed),tokenId)
    */
    bytes32 public traitseed2; // set with VRF, for layers 16-32
    uint256 public linkVrfFee = 0.01 ether; // fee for the reveal
    bytes32 public keyHash; // VRF: keyHash
    bytes32 public getTraitReqId;

    // // must be implemented in ExtremeNFT
    // function _doRevealStep2(bytes32) internal virtual;

    // function _setTraitSeed(bytes32 seed) internal virtual;
    
    /**
    * @dev update vrf config if necessary
    */
    function _updateVrfConfig(uint256 _linkFee, bytes32 _keyHash) internal {
        require(traitseed == 0, "already revealed");
        linkVrfFee = _linkFee;
        keyHash = _keyHash;
    }

    /**
    * @dev canonical card trait seed, level 2 (layers 1-17)
    */
    function getCanonicalCardTraits(uint256 tokenId_)
        public
        view
        returns (bytes32)
    {
        require(traitseed != 0, "not revealed yet");
        return keccak256(abi.encode(traitseed, tokenId_));
    }

    /**
    * @dev canonical card trait seed, level 2 (layers 17+)
    */
    function getCanonicalCardTraits2(uint256 tokenId_)
        public
        view
        returns (bytes32)
    {
        require(traitseed2 != 0, "not revealed yet");
        return keccak256(abi.encode(traitseed2, tokenId_));
    }

    /**
    * @dev internal: send reveal request
    */
    function _doReveal() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= linkVrfFee, "Not enough LINK");
        requestId = requestRandomness(keyHash, linkVrfFee);
        getTraitReqId = requestId;
        return requestId;
    }

    // called by rawFulfillRandomness by VRFCoordinator
    function fulfillRandomness(bytes32, uint256 randomness)
        internal
        virtual
        override
    {
        require(traitseed == 0, "trait seed already set");

        traitseed = keccak256( // solhint-disable-next-line
            abi.encode(randomness, block.timestamp, block.number)
        );
        traitseed2 = keccak256(abi.encode(traitseed)); // solhint-disable-next-line
        emit Revealed(traitseed, randomness, block.number, block.timestamp); // solhint-disable-line
    }
}