// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IERC20 } from "./token/ERC20/IERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract USDCMerkleDistributor {

    address public immutable USDC;
    bytes32 public merkleRoot;
    // Packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    address public immutable kakubiSafe; 

    event Claimed(uint256 index, address account, uint256 amount);
    event RootChanged(address account, bytes32 merkleRoot);

    constructor(address _USDCAddress, address _kakubiSafe){
        USDC = _USDCAddress;
        kakubiSafe = _kakubiSafe;
    }

    function setRoot(bytes32 _merkleRoot) external onlySafe {
        merkleRoot = _merkleRoot;
        emit RootChanged(msg.sender, _merkleRoot);
    }

    // delete from 0 to maxIndex with 256 step
    function clearClaimedBitMapWord(uint256 index) external onlySafe {
        uint256 claimedWordIndex = index / 256;
        delete claimedBitMap[claimedWordIndex];
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }  

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!isClaimed(index), 'KKBMerkleDistributor: Drop already claimed');

        address account = msg.sender;

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'KKBMerkleDistributor: Invalid proof');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(USDC).transfer(account, amount), 'MerkleDistributor: Transfer failed');
        emit Claimed(index, account, amount);
    }

    modifier onlySafe() {
        require(msg.sender == kakubiSafe, "ERC20Kakubi: Called by account other than the safe");
        _;
    }
}