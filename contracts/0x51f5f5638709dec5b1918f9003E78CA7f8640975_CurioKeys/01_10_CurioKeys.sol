// SPDX-License-Identifier: UNLICENSED
// Copyright 2022 Just Imagine, Inc.
pragma solidity >=0.8.10 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// @title Curio Keys
// @author @curiotools
contract CurioKeys is Ownable, ERC721A, ERC2981 {
    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply
    ) ERC721A(name, symbol) {
        maxSupply = _maxSupply;
        _setDefaultRoyalty(0x418383378efc463902fe54D0Cef822C2d0b3D669, 1000);
    }

    // =============================================================
    //                             STATE
    // =============================================================

    /**
    @dev Max token supply for collection.
     */
    uint256 public immutable maxSupply;

    /**
    @dev Flag indicating whether minting is open.
     */
    bool public mintingOpen = false;

    /**
    @dev Merkle root hash to enforce allowlist.
     */
    bytes32 public merkleRoot;

    /**
    @dev Users who have claimed their token.
     */
    mapping(address => uint256) public claims;

    /**
    @dev Base token URI used as prefix for `tokenURI` method. 
     */
    string public baseTokenURI;

    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
    @dev Emitted when minting is enabled or disabled. 
     */
    event MintingOpen(bool indexed open);

    // =============================================================
    //                             WRITE
    // =============================================================

    /**
    @notice Mint token.
     */
    function mint(bytes32[] calldata proof) external onlyUser {
        require(mintingOpen, "Minting is closed");
        require(claims[msg.sender] == 0, "You already minted");
        require(totalSupply() + 1 <= maxSupply, "Reached max supply");
        require(_verify(proof, msg.sender), "You are not on the allowlist");
        _mint(msg.sender, 1);
        claims[msg.sender] = 1;
    }

    /**
    @notice Mint token(s) as owner
     */
    function mintOwner(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Reached max supply");
        _mint(to, amount);
    }

    /**
    @notice Toggles the `mintingOpen` flag.
     */
    function setMintingOpen(bool open) external onlyOwner {
        require(mintingOpen != open, "Cannot change to same status");
        mintingOpen = open;
        emit MintingOpen(open);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(address(this), feeBasisPoints);
    }

    /**
    @notice Sets the merkle root hash.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    @notice Sets the base token URI prefix.
     */
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // =============================================================
    //                             READ
    // =============================================================

    /**
    @dev Returns true if account has claimed mint.
     */
    function claimed(address account) public view returns (bool) {
        return claims[account] == 1;
    }

    /**
    @dev Required override.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    /**
    @dev Ensure that caller is not contract.
     */
    modifier onlyUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // =============================================================
    //                          INTERNAL
    // =============================================================

    /**
    @dev Start tokenId at 1 instead of 0.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
    @dev Verify Merkle proof for account.
     */
    function _verify(bytes32[] memory proof, address account)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}