// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./WCNFTToken.sol";

/**
 * @dev utility contract for white list/allow list using merkle trees
 *
 * 3 merkle variations are possible, but only 1 can be used with a given merkle root
 * Type A: [address]
 * - for use with a fixed number of mints for all addresses
 * Type B: [address, uint256]
 * - for use with a variable number of mints per address
 * Type C: [address, uint256, uint256]
 * - for use with variable number of mints and an additional parameter per address (ex. different
 *  pricing)
 *
 * If the root corresponds to type A, use the A functions ("mintAllowListA()"...).
 * If the root corresponds to type B or C, use the B or C functions respectively ("onAllowListB()",
 *  ableToClaimC()" etc)
 *
 * setting the merkle root resets the mint counts, and cannot be set when the allow list is active.
 * To set a new merkle root without resetting user mint counts use setAllowListPreserveBalances()
 */
contract WCNFTMerkle is WCNFTAccessControl {
    struct Claimer {
        uint224 amount;
        uint32 nonce;
    }

    bytes32 public merkleRoot;
    uint32 private _nonce;
    bool public allowListActive = false;

    mapping(address => Claimer) private _allowListNumMinted;

    /// Attempted access to inactive presale
    error AllowListIsNotActive();

    /// Attempted to set merkle while allow list is active
    error AllowListIsActive();

    /// Exceeds allow list quota
    error ExceedsAllowListQuota();

    /// Merkle proof and user do not resolve to merkleRoot
    error NotOnAllowList();

    /**
     * @dev emitted when an account has claimed some tokens
     */
    event Claimed(address indexed account, uint256 amount);

    /**
     * @dev emitted when the merkle root has changed
     */
    event MerkleRootChanged(bytes32 merkleRoot);

    /**
     * @dev throws when allow list is not active
     */
    modifier isAllowListActive() {
        if (!allowListActive) revert AllowListIsNotActive();
        _;
    }

    /**
     * @dev throws when number of tokens exceeds total token amount
     * @param to the address to check
     * @param numberOfTokens the number of tokens to be minted
     * @param tokenQuota the amount of tokens allowed
     */
    modifier tokensAvailable(
        address to,
        uint256 numberOfTokens,
        uint256 tokenQuota
    ) {
        uint256 claimed = getAllowListMinted(to);
        if (claimed + numberOfTokens > tokenQuota)
            revert ExceedsAllowListQuota();
        _;
    }

    /**
     * @dev throws when parameters sent by claimer is incorrect
     * @param claimer the address of the claimer
     * @param proof the merkle proof
     */
    modifier ableToClaimA(address claimer, bytes32[] memory proof) {
        if (!onAllowListA(claimer, proof)) revert NotOnAllowList();
        _;
    }

    /**
     * @dev throws when parameters sent by claimer is incorrect
     * @param claimer the address of the claimer
     * @param b additional uint256 parameter
     * @param proof the merkle proof
     */
    modifier ableToClaimB(
        address claimer,
        uint256 b,
        bytes32[] memory proof
    ) {
        if (!onAllowListB(claimer, b, proof)) revert NotOnAllowList();
        _;
    }

    /**
     * @dev throws when parameters sent by claimer is incorrect
     * @param claimer the address of the claimer
     * @param b additional uint256 parameter
     * @param c additional uint256 parameter
     * @param proof the merkle proof
     */
    modifier ableToClaimC(
        address claimer,
        uint256 b,
        uint256 c,
        bytes32[] memory proof
    ) {
        if (!onAllowListC(claimer, b, c, proof)) revert NotOnAllowList();
        _;
    }

    /**
     * @dev sets the state of the allow list
     * @param allowListActive_ the state of the allow list
     */
    function _setAllowListActive(bool allowListActive_) internal virtual {
        allowListActive = allowListActive_;
    }

    /**
     * @dev sets the merkle root. reverts when allow list is active
     * @param merkleRoot_ the merkle root
     * @param preserveBalances set to true if merkle root was changed and nonce does not need to be
     *  updated
     */
    function _setAllowList(bytes32 merkleRoot_, bool preserveBalances)
        internal
        virtual
    {
        if (allowListActive) revert AllowListIsActive();
        merkleRoot = merkleRoot_;

        if (!preserveBalances) {
            _nonce += 1;
        }

        emit MerkleRootChanged(merkleRoot);
    }

    /**
     * @dev adds the number of tokens to the incoming address
     * @param to the address
     * @param numberOfTokens the number of tokens to be minted
     */
    function _setAllowListMinted(address to, uint256 numberOfTokens)
        internal
        virtual
    {
        Claimer storage claimer = _allowListNumMinted[to];

        // if nonce isn't equal, set the nonce
        if (_nonce != claimer.nonce) {
            claimer.nonce = _nonce;
            claimer.amount = uint224(numberOfTokens);
        } else {
            claimer.amount += uint224(numberOfTokens);
        }

        emit Claimed(to, numberOfTokens);
    }

    /**
     * @dev starts and stops allow list minting
     * @param state the state of the allow list
     */
    function setAllowListActive(bool state) external onlyRole(SUPPORT_ROLE) {
        _setAllowListActive(state);
    }

    /**
     * @notice set the merkle root without resetting allow list mint counts
     * @dev sets the merkle root for the allow list, without resetting the nonce value. Allows the
     *   support role to update the merkle root while preserving balances
     * @param merkleRoot_ the merkle root
     */
    function setAllowListPreserveBalances(bytes32 merkleRoot_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _setAllowList(merkleRoot_, true);
    }

    /**
     * @notice set the merkle root and reset allow list mint counts
     * @dev sets the merkle root for the allow list
     * @param merkleRoot_ the merkle root
     */
    function setAllowList(bytes32 merkleRoot_) external onlyRole(SUPPORT_ROLE) {
        _setAllowList(merkleRoot_, false);
    }

    /**
     * @dev gets the number of tokens from the address
     * @param from the address to check
     */
    function getAllowListMinted(address from)
        public
        view
        virtual
        returns (uint256)
    {
        Claimer memory claimer = _allowListNumMinted[from];

        return (_nonce != claimer.nonce) ? 0 : claimer.amount;
    }

    /**
     * @dev checks if the claimer has a valid proof
     * @param claimer the address of the claimer
     * @param proof the merkle proof
     */
    function onAllowListA(address claimer, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @dev checks if the claimer has a valid proof
     * @param claimer the address of the claimer
     * @param b additional uint256 parameter
     * @param proof the merkle proof
     */
    function onAllowListB(
        address claimer,
        uint256 b,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer, b));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @dev checks if the claimer has a valid proof
     * @param claimer the address of the claimer
     * @param b additional uint256 parameter
     * @param c additional uint256 parameter
     * @param proof the merkle proof
     */
    function onAllowListC(
        address claimer,
        uint256 b,
        uint256 c,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer, b, c));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}