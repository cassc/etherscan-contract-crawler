// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../interfaces/IBasicMint.sol";
import "../base/Base721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AllowlistFixedPrice721 is Base721, IERC2981 {
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];
    bytes32 public claimMerkleRoot;
    uint256 public immutable mintPrice;
    uint256 public mintLimit;
    uint256 public royalty; // Basis points royalty fee
    bool public mintActivated;
    bool public anyoneCanMint;
    address private treasury;
    mapping(address => uint256) public mintedByAccount;
    event TreasuryUpdated(address oldTreasury, address newTreasury);
    event RoyaltyUpdated(uint256 oldFee, uint256 newFee);
    event AllowlistUpdated(bytes32 oldRoot, bytes32 newRoot);
    event MintLimitUpdated(uint256 oldLimit, uint256 newLimit);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _mp,
        uint256 _ml,
        uint256 _ms,
        bytes32 _merkleRoot
    ) Base721(_name, _symbol, _uri, _ms) {
        treasury = _msgSender();
        mintPrice = _mp;
        mintLimit = _ml;
        claimMerkleRoot = _merkleRoot;
        royalty = 500;
    }

    receive() external payable {
        revert("Accidental send prevented");
    }

    function mintActive() public view returns (bool) {
        return mintActivated && (_tokenIdTracker.current() <= maxSupply);
    }

    function mintData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (mintPrice, mintLimit, maxSupply);
    }

    function _limitedMint(address target, uint256 quantity) internal {
        require(msg.value >= mintPrice * quantity, "Not enough money");
        mintedByAccount[target] += quantity;    
        require(
            mintedByAccount[target] <= mintLimit,
            "Exceeds mint limit per account"
        );
        _mintToTarget(target, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(mintActivated, "Mint is not active");
        require(anyoneCanMint, "Allowlist only");
        _limitedMint(_msgSender(), quantity);
    }

    function _leafHash(address account, uint256 quantity)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, quantity));
    }

    function allowlistMint(
        address account,
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable {
        require(mintActivated, "Mint is not active");
        require(
            MerkleProof.verify(
                proof,
                claimMerkleRoot,
                _leafHash(account, mintLimit)
            ),
            "Invalid proof supplied"
        );
        _limitedMint(account, quantity);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (_salePrice * royalty) / 10000;
        return (treasury, royaltyAmount);
    }

    // Admin
    function toggleActive() external onlyOwner {
        mintActivated = !mintActivated;
    }

    function togglePublicMint() external onlyOwner {
        anyoneCanMint = !anyoneCanMint;
    }

    function adminMint(uint256 quantity, address target) external onlyOwner {
        _mintToTarget(target, quantity);
    }

    function airdrop(address[] calldata targets) external onlyOwner {
        uint256 len = targets.length;
        require(
            len + _tokenIdTracker.current() <= maxSupply,
            "Maximum supply reached"
        );
        for (uint256 i; i < len; i++) {
            _tokenIdTracker.increment();
            _mint(targets[i], _tokenIdTracker.current());
        }
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != treasury, "Same treasury address");
        require(newTreasury != address(0), "Treasury cannot be zero address");
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }

    function setRoyalty(uint256 newFee) external onlyOwner {
        require(newFee < 10001, "Fee cannot be greater than 100%");
        emit RoyaltyUpdated(royalty, newFee);
        royalty = newFee;
    }

    function setAllowlistRoot(bytes32 newRoot) external onlyOwner {
        emit AllowlistUpdated(claimMerkleRoot, newRoot);
        claimMerkleRoot = newRoot;
    }

    function setMintLimit(uint256 newLimit) external onlyOwner {
        require(mintLimit < newLimit, "New limit must be greater than previous limit");
        emit MintLimitUpdated(mintLimit, newLimit);
        mintLimit = newLimit;
    }

    function setAllowlistAndMintLimit(bytes32 newRoot, uint256 newLimit) external onlyOwner {
        require(mintLimit < newLimit, "New limit must be greater than previous limit");
        emit AllowlistUpdated(claimMerkleRoot, newRoot);
        claimMerkleRoot = newRoot;
        emit MintLimitUpdated(mintLimit, newLimit);
        mintLimit = newLimit;
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Base721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}