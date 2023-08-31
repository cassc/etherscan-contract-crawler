// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./interfaces/IPunkBodies.sol";

interface IDistributor {
    function token() external view returns(address);
    function mintReserved(address to, uint16[] memory ids) external;
    function merkleRoot() external view returns(bytes32);
    function claimed(uint256 index) external view returns(bool);
    function withdraw() external;
}

contract PBAirdropExtended is Ownable {
    address immutable distributor;
    bytes32 public immutable merkleRoot; // new merkle root
    address public immutable token;
    uint256 public immutable airdrop_deadline;

    uint256 constant total_count = 10000;
    uint256 constant airdrop_id_start = 8062; // 9999 - airdrop_count + 1

    bool[2000] private _claimed;

    event Claimed(uint256 index, address account, uint256 tokenId);

    constructor(address _distributor, uint256 deadline) {
        distributor = _distributor;
        token = IDistributor(_distributor).token();
        merkleRoot = IDistributor(_distributor).merkleRoot();
        airdrop_deadline = deadline;
    }

    receive() external payable {
    }

    function claim(uint256 index, address account, bytes32[] calldata merkleProof) external {
        require(block.timestamp <= airdrop_deadline, "PBAirdropExtended: Airdrop has ended.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "PBAirdropExtended: Invalid proof.");

        // Mark it claimed and send the token.
        _claimed[index] = true;

        uint16[] memory tokenId = new uint16[](1);
        tokenId[0] = uint16(total_count - uint16(index) - 1); // 9999~ airdrop ids
        IDistributor(distributor).mintReserved(account, tokenId);

        emit Claimed(index, account, tokenId[0]);
    }

    function claimed(uint256 index) external view returns(bool) {
        return _claimed[index] || IDistributor(distributor).claimed(index);
    }

    function mintReserved(address to, uint16[] memory ids) external onlyOwner {
        if(block.timestamp <= airdrop_deadline) {
            for (uint256 i = 0; i < ids.length; i ++) {
                require(ids[i] < airdrop_id_start, "Airdrop not finished.");
            }
        }
        IDistributor(distributor).mintReserved(to, ids);
    }

    function withdraw() external onlyOwner {
        IDistributor(distributor).withdraw();
        msg.sender.transfer(address(this).balance);
    }

    function transferDistributorOwnership(address newOwner) public virtual onlyOwner {
        Ownable(distributor).transferOwnership(newOwner);
    }
}