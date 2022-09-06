// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "hardhat/console.sol";
import "./interfaces/IPicniqVesting.sol";
import "./libraries/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PicniqTokenClaim {
    using MerkleProof for bytes32[];

    ClaimDecay private _decayData;

    uint256 public leftover;
    uint256 public end;
    address private _treasury;

    IERC20 public immutable SNACK;
    IPicniqVesting public immutable VESTING;

    bytes32 internal _merkleRoot;
    mapping(address => bool) internal _claims;

    struct MerkleItem {
        address account;
        uint256 amount;
    }

    struct ClaimDecay {
        uint64 decayTime;
        uint64 decayRate;
    }

    constructor(IERC20 token, address vesting, bytes32 merkleRoot_, address treasury) {
        SNACK = token;
        VESTING = IPicniqVesting(vesting);

        _merkleRoot = merkleRoot_;
        _treasury = treasury;
        _decayData.decayTime = uint64(block.timestamp + (2628000 * 6));
        _decayData.decayRate = 5e15;

        end = block.timestamp + (2628000 * 12);
    }

    function claimTokens(bytes32[] calldata proof, uint256 amount) external
    {
        require(checkProof(msg.sender, proof, amount), "Proof failed");
        require(block.timestamp < end, "Claiming is over");

        uint256 decay = currentDecayPercent();
        uint256 decayed = amount * 10 * decay / 1e18;
        uint256 max = amount * 10 * 1.25e18 / 1e18;
        uint256 sendAmount = amount * 10 - decayed;

        leftover += max - sendAmount;

        SNACK.transfer(msg.sender, sendAmount);
    }

    function claimAndVest(bytes32[] calldata proof, uint256 amount, uint8 length) external
    {
        require(length == 6 || length == 12, "Length must be 6 or 12 months");
        require(checkProof(msg.sender, proof, amount), "Proof failed");
        require(block.timestamp < end, "Claiming is over");

        uint256 decay = currentDecayPercent();

        uint256 bonus = length == 6 ? 1.1e18 : 1.25e18;
        uint256 decayed = amount * 10 * decay / 1e18 * bonus / 1e18;
        uint256 max = (amount * 10) * 1.25e18 / 1e18;
        uint256 total = amount * 10 * bonus / 1e18 - decayed;
        uint256 vested = total / 2;

        leftover += max - total;

        SNACK.approve(address(VESTING), vested);
        VESTING.vestTokens(msg.sender, vested, length);
        SNACK.transfer(msg.sender, total - vested);
    }

    function currentDecayPercent() public view returns (uint256)
    {

        if (block.timestamp > _decayData.decayTime) {
            uint256 delta = block.timestamp - _decayData.decayTime;
            if (delta > 86400) {
                uint256 newRate = (delta / 86400) * _decayData.decayRate;
                if (newRate < (1e18 / 2)) {
                    return newRate;
                } else {
                    return 1e18 / 2;
                }
            }
        }

        return 0;
    }

    function checkClaimed(address account) public view returns (bool)
    {
        return _claims[account];
    }

    function checkProof(address account, bytes32[] calldata proof, uint256 amount) public returns (bool)
    {
        require(!checkClaimed(account), "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        require(MerkleProof.verify(proof, _merkleRoot, leaf), "Proof failed");

        _claims[account] = true;
        
        return true;
    }

    function withdrawLeftover() external
    {
        require(msg.sender == _treasury, "Only treasury address can withdraw");

        if (block.timestamp > end) {
            uint256 balance = SNACK.balanceOf(address(this));
            SNACK.transfer(_treasury, balance);
            leftover = 0;
        } else {
            uint256 sendAmount = leftover;
            leftover = 0;
            SNACK.transfer(_treasury, sendAmount);
        }
    }
}