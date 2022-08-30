// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "lib/solmate/src/auth/Owned.sol";
import "./utils/Receivable.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";


contract BMRMinter is Owned, Receivable {

    address public immutable bmrnft;

    constructor(address bmrnft_) Owned(msg.sender) {
        bmrnft = bmrnft_;
    }

    /**
     *  @dev mint logic
     */

    uint256 public mintIndex;
    uint256 public mintPrice;

    bytes32 public merkleRoot;
    mapping(address => uint256) public merkleProofClaimed;

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function mintByOwner(uint256 numberOfTokens) external onlyOwner {
        require(mintIndex + numberOfTokens <= 300, "NOT_ENOUGH");
        for (uint256 i=1; i<=numberOfTokens; ++i) {
            IBMRNFT(bmrnft).mint(msg.sender, mintIndex + i);
        }
        mintIndex += numberOfTokens;
    }

    function mintWithProof(
        bytes32[] calldata _merkleProof,
        uint256 numberOfTokens
    ) external {
        // check index
        require(mintIndex >= 300 && mintIndex + numberOfTokens <= 666, "MINT_CLOSED");
        // check quota
        merkleProofClaimed[msg.sender] += numberOfTokens;
        require(merkleProofClaimed[msg.sender] <= 2, "QUOTA_EXCEEDED");
        // verify proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "INVALID_PROOF");
        // mint
        for (uint256 i=1; i<=numberOfTokens; ++i) {
            IBMRNFT(bmrnft).mint(msg.sender, mintIndex + i);
        }
        mintIndex += numberOfTokens;
    }

    function mint(uint256 numberOfTokens) external payable {
        // check index
        require(mintIndex >= 666 && mintIndex + numberOfTokens <= 6666, "MINT_CLOSED");
        require(mintPrice > 0, "MINT_PRICE_NOT_SET");
        require(msg.value >= mintPrice * numberOfTokens, "INSUFFICIENT_VALUE");
        // mint
        for (uint256 i=1; i<=numberOfTokens; ++i) {
            IBMRNFT(bmrnft).mint(msg.sender, mintIndex + i);
        }
        mintIndex += numberOfTokens;
    }

    /**
     *  @dev destroy itself after mint ends
     */

    function selfDestruct() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

}

interface IBMRNFT {
    function mint(address to, uint256 tokenId) external;
}