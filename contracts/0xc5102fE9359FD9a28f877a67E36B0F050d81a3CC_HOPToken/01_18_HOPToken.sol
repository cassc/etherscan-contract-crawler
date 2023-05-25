// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
 * @dev An ERC20 token for HOP.
 *      Besides the addition of voting capabilities, we make a couple of customisations:
 *       - Airdrop claim functionality via `claimTokens`. At creation time the tokens that
 *         should be available for the airdrop are transferred to the token contract address;
 *         airdrop claims are made from this balance.
 *       - Support for the owner (the DAO) to mint new tokens.
 */
contract HOPToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    using BitMaps for BitMaps.BitMap;


    bytes32 public merkleRoot;
    uint256 public claimPeriodEnds; // Timestamp
    BitMaps.BitMap private claimed;

    event MerkleRootChanged(bytes32 merkleRoot);
    event Claim(address indexed claimant, uint256 amount);

    /**
     * @dev Constructor.
     * @param freeSupply The number of tokens to issue to the contract deployer.
     * @param airdropSupply The number of tokens to reserve for the airdrop.
     * @param _claimPeriodEnds The timestamp at which tokens are no longer claimable.
     */
    constructor(
        uint256 freeSupply,
        uint256 airdropSupply,
        uint256 _claimPeriodEnds
    )
        ERC20("Hop", "HOP")
        ERC20Permit("Hop")
    {
        _mint(msg.sender, freeSupply);
        _mint(address(this), airdropSupply);
        claimPeriodEnds = _claimPeriodEnds;
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param delegate The address the tokenholder wants to delegate their votes to.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(uint256 amount, address delegate, bytes32[] calldata merkleProof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        (bool valid, uint256 index) = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "HOP: Valid proof required.");
        require(!isClaimed(index), "HOP: Tokens already claimed.");
        
        claimed.set(index);
        emit Claim(msg.sender, amount);

        _delegate(msg.sender, delegate);
        _transfer(address(this), msg.sender, amount);
    }

    /**
     * @dev Allows the owner to sweep unclaimed tokens after the claim period ends.
     * @param dest The address to sweep the tokens to.
     */
    function sweep(address dest) external onlyOwner {
        require(block.timestamp > claimPeriodEnds, "HOP: Claim period not yet ended");
        _transfer(address(this), dest, balanceOf(address(this)));
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param index The index into the merkle tree.
     */
    function isClaimed(uint256 index) public view returns (bool) {
        return claimed.get(index);
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(merkleRoot == bytes32(0), "HOP: Merkle root already set");
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @dev Mints new tokens.
     * @param dest The address to mint the new tokens to.
     * @param amount The quantity of tokens to mint.
     */
    function mint(address dest, uint256 amount) external onlyOwner {
        _mint(dest, amount);
    }

    /**
     * @dev Burns the owner's tokens.
     * @param amount The quantity of tokens to burn.
     */
    function burn(uint256 amount) external onlyOwner {
        _burn(owner(), amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}