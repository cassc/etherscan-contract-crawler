// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainLinkRandom is Ownable, VRFConsumerBase {
    event TokenSeed(uint256 seed);

    uint256 public seed;

    uint256 internal fee;
    bytes32 internal keyHash;

    bytes32 private _requestId;
    bool private _requesting;

    constructor(
        address _VRFCoordinator,
        address _LINKToken,
        bytes32 _keyHash
    ) public VRFConsumerBase(_VRFCoordinator, _LINKToken) {
        keyHash = _keyHash;
        fee = 2 * 10**18; // 2 LINK token
        _requesting = false;
        seed = 0;
    }

    /**
     * @dev backup seed generator if the ChainLink is experiencing difficulties
     */
    function feedSeed() external onlyOwner {
        require(_requesting == true, "not requesting");
        require(seed == 0, "received random number");
        _requesting = false;
        seed = uint256(blockhash(block.number - 1));
        emit TokenSeed(seed);
    }

    /**
     * @dev receive random number from chainlink
     * @notice random number will greater than zero
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        require(_requesting == true, "not requesting");
        require(requestId == _requestId, "not my request");
        _requesting = false;
        if (randomNumber > 0) seed = randomNumber;
        else seed = 1;
        emit TokenSeed(seed);
    }

    function _generateRandomSeed() internal {
        require(LINK.balanceOf(address(this)) >= fee, "not enought LINK token");
        _requestId = requestRandomness(keyHash, fee);
        _requesting = true;
    }

    /**
     * @dev compute element with shuffle with id
     */
    function shuffleId(
        uint256 _TOTAL_SUPPLY,
        uint256 _id,
        uint256 _start
    ) internal view returns (uint256) {
        uint256 random = generateRandomNumber(_id);
        return random.mod(_TOTAL_SUPPLY.sub(_start)).add(_start);
    }

    /**
     * @dev return random number from seed and _id
     */
    function generateRandomNumber(uint256 _id) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(seed, _id)));
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }
}