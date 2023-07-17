//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LPCompVesting is Ownable {
    using SafeMath for uint256;

    IERC20 public xtk;

    uint256 public totalXtkRedeemable;
    uint256 public rxtkSupplyRemaining;

    uint256 public vestingBegin;

    bytes32 public root;

    mapping(uint256 => uint256) _redeemed;

    uint256 private constant ONE_YEAR = 365 days;

    bool private vestingInitiated;

    event Redeemed(
        address indexed user,
        uint256 redeemedBlock,
        uint256 redeemedMask
    );

    constructor(
        IERC20 _xtk,
        bytes32 _root,
        uint256 _totalXtkRedeemable
    ) {
        xtk = _xtk;
        root = _root;

        rxtkSupplyRemaining = _totalXtkRedeemable;
        totalXtkRedeemable = _totalXtkRedeemable;
    }

    function initiateVesting() external onlyOwner {
        require(!vestingInitiated);
        require(xtk.balanceOf(address(this)) == totalXtkRedeemable);
        vestingInitiated = true;
        vestingBegin = block.timestamp;
    }

    // Check if a given reward has already been redeemed
    function redeemed(uint256 index)
        public
        view
        returns (uint256 redeemedBlock, uint256 redeemedMask)
    {
        redeemedBlock = _redeemed[index / 256];
        redeemedMask = (uint256(1) << uint256(index % 256));
        require(
            (redeemedBlock & redeemedMask) == 0,
            "Tokens have already been redeemed"
        );
    }

    // this function should redeem *all* rXTK owned by address
    function redeem(
        uint256 index,
        address recipient,
        uint256 amount,
        bytes32[] memory merkleProof
    ) external {
        require(
            msg.sender == recipient,
            "The reward recipient should be the transaction sender"
        );

        // Make sure the tokens have not already been redeemed
        (uint256 redeemedBlock, uint256 redeemedMask) = redeemed(index);
        _redeemed[index / 256] = redeemedBlock | redeemedMask;

        // Compute the merkle leaf from index, recipient and amount
        bytes32 leaf = keccak256(abi.encodePacked(index, recipient, amount));
        // verify the proof is valid
        require(
            MerkleProof.verify(merkleProof, root, leaf),
            "Proof is not valid"
        );

        uint256 xtkToTransfer = getXtkAmountAvailableByAddress(amount);
        rxtkSupplyRemaining = rxtkSupplyRemaining.sub(amount);
        xtk.transfer(recipient, xtkToTransfer);

        emit Redeemed(recipient, redeemedBlock, redeemedMask);
    }

    /**
     * Return the actual xtk amount which can be redeemed based on rxtkAmount
     */
    function getXtkAmountAvailableByAddress(uint256 rxtkAmount)
        public
        view
        returns (uint256 xtkToDistribute)
    {
        uint256 xtkBalance = xtk.balanceOf(address(this));
        uint256 latestTimestamp =
            min(block.timestamp, vestingBegin.add(ONE_YEAR));

        uint256 totalVestedXtk =
            xtkBalance.mul(latestTimestamp.sub(vestingBegin)).div(ONE_YEAR);
        xtkToDistribute = totalVestedXtk.mul(rxtkAmount).div(
            rxtkSupplyRemaining
        );
    }

    function recoverToken() external onlyOwner {
        xtk.transfer(msg.sender, xtk.balanceOf(address(this)));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}