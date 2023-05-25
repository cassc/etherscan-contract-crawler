// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/Operator.sol";
import "./lib/YugaVerifyV3.sol";

interface IBAYCSewerPass {
    function burn(uint256 tokenId) external;
}

interface IHVMTL {
    function mintOne(address to, uint256 tokenId) external;
}

//      |||||\          |||||\               |||||\          |||||\
//      ||||| |         ||||| |              ||||| |         ||||| |
//       \__|||||\  |||||\___\|               \__|||||\  |||||\___\|
//          ||||| | ||||| |                      ||||| | ||||| |
//           \__|||||\___\|       Y u g a         \__|||||\___\|
//              ||||| |             L a b s          ||||| |
//          |||||\___\|       S u m m o n i n g  |||||\___\|
//          ||||| |                              ||||| |
//           \__|||||||||||\                      \__|||||||||||\
//              ||||||||||| |                        ||||||||||| |
//               \_________\|                         \_________\|

error MintIsNotEnabled();
error UnauthorizedOwner();
error InvalidMerkleProof();

/**
 * @title The Summoning
 */
contract TheSummoning is YugaVerifyV3, Operator, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool public isMintEnabled;
    bytes32 public merkleRoot;
    IBAYCSewerPass public immutable sewerPassContract;
    IHVMTL public immutable hvmtlContract;

    struct MintData {
        uint128 sewerPassId;
        uint128 rank;
        bytes32[] merkleProof;
    }

    constructor(
        address _sewerPassContract,
        address _hvmtlContract,
        address _warmContract,
        address _delegateCashContract,
        address operator
    ) YugaVerifyV3(_warmContract, _delegateCashContract) Operator(operator) {
        sewerPassContract = IBAYCSewerPass(_sewerPassContract);
        hvmtlContract = IHVMTL(_hvmtlContract);
    }

    modifier mintable() {
        if (!isMintEnabled) revert MintIsNotEnabled();
        _;
    }

    /**
     * @notice summon one
     * @param sewerPassId token id of sewer pass
     * @param rank sewer pass rank
     * @param merkleProof array of hashes
     */
    function summon(
        uint256 sewerPassId,
        uint256 rank,
        bytes32[] calldata merkleProof
    ) external mintable nonReentrant {
        _mint(sewerPassId, rank, merkleProof);
    }

    /**
     * @notice summon many
     */
    function summonMany(
        MintData[] calldata mintData
    ) external mintable nonReentrant {
        uint256 length = mintData.length;
        uint256 sewerPassId;
        uint256 rank;
        bytes32[] calldata merkeProof;
        for (uint256 i; i < length; ) {
            sewerPassId = mintData[i].sewerPassId;
            rank = mintData[i].rank;
            merkeProof = mintData[i].merkleProof;
            unchecked {
                ++i;
            }
            _mint(sewerPassId, rank, merkeProof);
        }
    }

    function _mint(
        uint256 sewerPassId,
        uint256 rank,
        bytes32[] calldata merkleProof
    ) internal {
        bytes32 node = keccak256(abi.encodePacked(sewerPassId, rank));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node))
            revert InvalidMerkleProof();

        (bool isVerified, address tokenOwnerAddress) = verifyTokenOwner(
            address(sewerPassContract),
            sewerPassId
        );
        if (!isVerified) revert UnauthorizedOwner();

        sewerPassContract.burn(sewerPassId);
        hvmtlContract.mintOne(tokenOwnerAddress, rank);
    }

    // operator functions

    /**
     * @notice turn mint on or off
     */
    function setIsMintEnabled(bool isEnabled) external onlyOperator {
        isMintEnabled = isEnabled;
    }

    /**
     * @notice set merkle root
     * @param _merkleRoot the root of the merkle tree
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOperator {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice withdraw erc-20 tokens
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOperator {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).safeTransfer(operator, balance);
        }
    }
}