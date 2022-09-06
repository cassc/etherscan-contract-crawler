// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleDistributorV2 {
    bytes32 public merkleRoot;
    bool public allowListActive = false;

    mapping(address => uint256) private _allowListNumMinted;

    /**
     * allow list is not active
     */
    error AllowListIsNotActive();

    /**
     * cannot mint if not on allow list
     */
    error NotOnAllowList();

    /**
     * cannot mint past number of tokens allotted
     */
    error PurchaseWouldExceedMaximumAllowListMint();

    /**
     * @dev emitted when an account has claimed some tokens
     */
    event Claimed(address indexed account, uint256 amount);

    /**
     * @dev emitted when the merkle root has changed
     */
    event MerkleRootChanged(bytes32 merkleRoot);

    /**
     * @notice throws when allow list is not active
     */
    modifier isAllowListActive() {
        if (!allowListActive) revert AllowListIsNotActive();
        _;
    }

    /**
     * @notice throws when number of tokens and the amount to claim exceeds total token amount
     * @param to the address to check
     * @param numberOfTokens the number of tokens to be minted
     * @param totalTokenAmount the total amount allowed
     */
    modifier tokensAvailable(
        address to,
        uint256 numberOfTokens,
        uint256 totalTokenAmount
    ) {
        uint256 claimed = getAllowListMinted(to);
        if (claimed + numberOfTokens > totalTokenAmount) revert PurchaseWouldExceedMaximumAllowListMint();
        _;
    }

    /**
     * @notice throws when merkle parameters sent by claimer is incorrect
     * @param claimer the address of the claimer
     * @param proof the merkle proof
     */
    modifier ableToClaim(address claimer, bytes32[] memory proof) {
        if (!onAllowList(claimer, proof)) revert NotOnAllowList();
        _;
    }

    /**
     * @notice sets the state of the allow list
     * @param allowListActive_ the state of the allow list
     */
    function _setAllowListActive(bool allowListActive_) internal virtual {
        allowListActive = allowListActive_;
    }

    /**
     * @notice sets the merkle root
     * @param merkleRoot_ the merkle root
     */
    function _setAllowList(bytes32 merkleRoot_) internal virtual {
        merkleRoot = merkleRoot_;

        emit MerkleRootChanged(merkleRoot);
    }

    /**
     * @notice adds the number of tokens to the incoming address
     * @param to the address
     * @param numberOfTokens the number of tokens to be minted
     */
    function _setAllowListMinted(address to, uint256 numberOfTokens) internal virtual {
        _allowListNumMinted[to] += numberOfTokens;

        emit Claimed(to, numberOfTokens);
    }

    /**
     * @notice gets the number of tokens from the address
     * @param from the address to check
     */
    function getAllowListMinted(address from) public view virtual returns (uint256) {
        return _allowListNumMinted[from];
    }

    /**
     * @notice checks if the claimer has a valid proof
     * @param claimer the address of the claimer
     * @param proof the merkle proof
     */
    function onAllowList(address claimer, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}