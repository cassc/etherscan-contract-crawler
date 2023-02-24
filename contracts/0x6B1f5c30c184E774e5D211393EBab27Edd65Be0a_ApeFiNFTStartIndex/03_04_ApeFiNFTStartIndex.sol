// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApeFiNFTStartIndex is Ownable {
    uint256 public constant DURATION = 1 days;
    uint256 public constant MAX_SUPPLY = 10000;

    IERC721A public immutable apeFiNFT;

    uint256 public startIndex;
    uint256 public startTime;
    string public provenanceHash;

    event NumberGenerated(uint256 randomNumber, address user);
    event StartTimeSet(uint256 startTime);
    event ProvenanceHashSet(string provenanceHash);

    constructor(address apeFiNFT_) {
        apeFiNFT = IERC721A(apeFiNFT_);
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "contract cannot generate");
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice User generates a random number.
     */
    function generate() public onlyEOA returns (uint256) {
        require(startTime != 0, "start time not set");
        require(block.timestamp >= startTime, "event not started");
        require(block.timestamp < startTime + DURATION, "event closed");

        uint256 randomNum = getRandomNumber() % MAX_SUPPLY;

        startIndex += randomNum;
        if (startIndex > MAX_SUPPLY) {
            startIndex %= MAX_SUPPLY;
        }

        emit NumberGenerated(randomNum, msg.sender);

        return randomNum;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Admin sets the start time.
     * @param _startTime The start time
     */
    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > 0, "invalid start time");
        startTime = _startTime;

        emit StartTimeSet(_startTime);
    }

    /**
     * @notice Admin sets the provenance hash.
     * @param _provenanceHash The provenance hash
     */
    function setProvenanceHash(
        string memory _provenanceHash
    ) external onlyOwner {
        provenanceHash = _provenanceHash;

        emit ProvenanceHashSet(_provenanceHash);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev the random number = keccak256(user address, block number, timestamp, previous block hash)
     */
    function getRandomNumber() internal view virtual returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        msg.sender,
                        block.number,
                        block.timestamp,
                        blockhash(block.number - 1)
                    )
                )
            );
    }
}