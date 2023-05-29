//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Airdrop {
    using SafeMath for uint256;

    uint256 public constant APRIL_28_NOON = 1619625600;
    uint256 private constant SIX_WEEKS = 6 weeks;
    uint256 private constant ONE_WEEK = 1 weeks;

    bytes32 public immutable _rootHash;
    IERC20 public immutable _token;
    uint256 public immutable _blockDeadline;
    uint256 public immutable _blockReductionsBegin;
    address public immutable _treasury;

    mapping (uint256 => uint256) _redeemed;

    constructor(IERC20 token, bytes32 rootHash, address treasury) {
        
        _token = token;
        _rootHash = rootHash;
        _treasury = treasury;

        _blockReductionsBegin = APRIL_28_NOON
            .add(SIX_WEEKS);
        
        _blockDeadline = APRIL_28_NOON
            .add(SIX_WEEKS)
            .add(ONE_WEEK);
    }

    function redeemed(uint256 index) public view returns (bool) {
        uint256 redeemedBlock = _redeemed[index / 256];
        uint256 redeemedMask = (uint256(1) << uint256(index % 256));
        return ((redeemedBlock & redeemedMask) != 0);
    }

    function redeemPackage(uint256 index, address recipient, uint256 amount, bytes32[] memory merkleProof) public {

        require(block.timestamp <= _blockDeadline, "Airdrop: Redemption deadline passed.");

        // Make sure this package has not already been claimed (and claim it)
        uint256 redeemedBlock = _redeemed[index / 256];
        uint256 redeemedMask = (uint256(1) << uint256(index % 256));
        require((redeemedBlock & redeemedMask) == 0, "Airdrop: already redeemed");
        _redeemed[index / 256] = redeemedBlock | redeemedMask;

        // Compute the merkle root
        bytes32 node = keccak256(abi.encode(index, recipient, amount));

        uint256 path = index;
        for (uint16 i = 0; i < merkleProof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encode(merkleProof[i], node));
            } else {
                node = keccak256(abi.encode(node, merkleProof[i]));
            }
            path /= 2;
        }

        // Check the merkle proof
        require(node == _rootHash, "Airdrop: Merkle root mismatch");

        // Redeem!
        uint256 sendAmount = amount;
        if (block.timestamp > _blockReductionsBegin) {
            sendAmount = reducedAmount(amount);
        }

        require(
            IERC20(_token).transfer(recipient, sendAmount),
            "Airdrop: Token transfer fail"
        );

    }

    function reducedAmount(uint256 originalAmount)
        public
        view
        returns (uint256)
    {
        uint256 blocksSinceReductionStarted = block.timestamp
            .sub(_blockReductionsBegin);

        uint256 reduceBy = blocksSinceReductionStarted
            .mul(originalAmount)
            .div(ONE_WEEK);

        return originalAmount.sub(reduceBy);
    }

    function sweepPostDeadline(IERC20 token)
        public
    {
        require(block.timestamp > _blockDeadline, "Airdrop: Deadline has not yet passed.");

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        require(
            IERC20(token).transfer(_treasury, tokenBalance),
            "Airdrop: Token transfer to treasury fail"
        );
    }
}