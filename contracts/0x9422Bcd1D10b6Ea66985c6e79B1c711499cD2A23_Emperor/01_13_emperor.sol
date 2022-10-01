// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

pragma solidity ^0.8.0;

contract Emperor is ERC721A, Ownable, ReentrancyGuard {
    // declares the maximum amount of tokens that can be minted
    uint256 public constant MAX_TOTAL_TOKENS = 5555;

    // max number of mints per transaction
    uint256 public free_mint_max = 1;
    uint256 public allowlist_mint_max = 5;
    uint256 public pub_mint_max_per_tx = 10;

    // price of mints depending on state of sale
    uint256 public item_price_al = 0.025 ether;
    uint256 public item_price_public = 0.04 ether;

    // merkle roots
    bytes32 public root_al;
    bytes32 public root_free;

    // metadata
    string private baseURI = "";
    string private unrevealedURI = "ipfs://QmUb4UQynrHMMkM8xXfByLEqeQagDj5LnVUEMEumXEvmUg";

    // status
    bool public is_free_active;
    bool public is_allowlist_active;
    bool public is_public_mint_active;
    bool public is_revealed;

    // reserved mints for the team
    mapping (address => uint256) reserved_mints;
    uint256 public total_reserved = 250;

    // staking
    mapping(uint256 => uint256) private stakingStarted; // staking start time, if 0 token is currently unstaked
    mapping(uint256 => uint256) private stakingTotal; // cumulative staking total per token
    uint256 private stakingTransfer = 1; // control for transfers while staking, if set to 2 then transfers are enabled
    bool public stakingOpen = false;

    // errors
    error OnlyOwnerCanTransferWhileStaking();
    error StakingClosed();

    // token staked/unstaked events
    event Staked(uint256 indexed tokenId);
    event Unstaked(uint256 indexed tokenId);

    using Strings for uint256;

    constructor (bytes32 _root_al, bytes32 _root_free) ERC721A("Survive NFT Winter", "SNW") {
        root_al = _root_al;
        root_free = _root_free;

        // don't forget to update total_reserved
        reserved_mints[0xefc41a7A7b75b0cDC9F78471A4BdaDf8796D963c] = 250; // company wallet
    }

    function internalMint(uint256 _amt) external nonReentrant {
        uint256 amt_reserved = reserved_mints[msg.sender];

        require(totalSupply() + _amt <= MAX_TOTAL_TOKENS, "Not enough NFTs left to mint");
        require(amt_reserved >= _amt, "Invalid reservation amount");
        require(amt_reserved <= total_reserved, "Amount exceeds total reserved");

        reserved_mints[msg.sender] -= _amt;
        total_reserved -= _amt;

        _safeMint(msg.sender, _amt);
    }

    function freeMint(bytes32[] calldata _proof, uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_TOTAL_TOKENS - total_reserved, "Not enough NFTs left to mint");
        require(msg.sender == tx.origin, "Minting from contract not allowed");
        require(is_free_active, "Free mint not active");

        uint64 new_claim_total = _getAux(msg.sender) + uint64(_amt);
        require(new_claim_total <= free_mint_max, "Requested mint amount invalid");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, root_free, leaf), "Invalid proof");

        _setAux(msg.sender, new_claim_total);
        _safeMint(msg.sender, _amt);
    }

    function allowlistMint(bytes32[] calldata _proof, uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_TOTAL_TOKENS - total_reserved, "Not enough NFTs left to mint");
        require(msg.sender == tx.origin, "Minting from contract not allowed");
        require(item_price_al * _amt == msg.value,  "Not enough ETH to mint this number of NFTs");
        require(is_allowlist_active, "Allowlist mint not active");

        uint64 new_claim_total = _getAux(msg.sender) + uint64(_amt);
        require(new_claim_total <= allowlist_mint_max, "Requested mint amount invalid");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, root_al, leaf), "Invalid proof");

        _setAux(msg.sender, new_claim_total);
        _safeMint(msg.sender, _amt);
    }

    function publicMint(uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_TOTAL_TOKENS - total_reserved, "Not enough NFTs left to mint");
        require(msg.sender == tx.origin, "Minting from contract not allowed");
        require(item_price_public * _amt == msg.value, "Not enough ETH to mint this number of NFTs");
        require(is_public_mint_active, "Public mint not active");
        require(_amt <= pub_mint_max_per_tx, "Too many NFTs in single transaction");

        _safeMint(msg.sender, _amt);
    }

    function setFreeMintActive(bool _val) external onlyOwner {
        is_free_active = _val;
    }

    function setAllowlistMintActive(bool _val) external onlyOwner {
        is_allowlist_active = _val;
    }

    function setPublicMintActive(bool _val) external onlyOwner {
        is_public_mint_active = _val;
    }

    function setIsRevealed(bool _val) external onlyOwner {
        is_revealed = _val;
    }

    function setNewFreeRoot(bytes32 _root) external onlyOwner {
        root_free = _root;
    }

    function setNewALRoot(bytes32 _root) external onlyOwner {
        root_al = _root;
    }

    function setFreeMintAmount(uint256 _amt) external onlyOwner {
        free_mint_max = _amt;
    }

    function setAllowlistMintAmount(uint256 _amt) external onlyOwner {
        allowlist_mint_max = _amt;
    }

    function setItemPricePublic(uint256 _price) external onlyOwner {
        item_price_public = _price;
    }

    function setItemPriceAL(uint256 _price) external onlyOwner {
        item_price_al = _price;
    }

    function setMaxMintPerTx(uint256 _amt) external onlyOwner {
        pub_mint_max_per_tx = _amt;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function isOnAllowList(bytes32[] calldata _proof, address _user) public view returns (uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        bytes32 root = is_free_active ? root_free : root_al;

        return MerkleProof.verify(_proof, root, leaf) ? 1 : 0;
    }

    function getSaleStatus() public view returns (string memory) {
        if(is_free_active) {
            return "free";
        }
        else if(is_public_mint_active) {
            return "public";
        }
        else if(is_allowlist_active) {
            return "allowlist";
        }
        else {
            return "closed";
        }
    }

    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");

        if(is_revealed) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenID.toString(), ".json")) : "";
        }
        else {
            return unrevealedURI;
        }
    }

    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256 quantity) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(stakingStarted[tokenId] == 0 || stakingTransfer == 2, "Staking Active");
        }
    }

    // returning staking period data
    function stakingPeriod(uint256 tokenId) external view returns (
        bool staking, // whether or not nft is staking
        uint256 current, // current stake period if so
        uint256 total // lifetime stake period
    ) {
        uint256 start = stakingStarted[tokenId];
        if (start != 0) {
            staking = true;
            current = block.timestamp - start;
        }
        total = current + stakingTotal[tokenId];
    }

    // transfer while staking
    function safeTransferWhileStaking(address from, address to, uint256 tokenId
    ) external {
        if (ownerOf(tokenId) != _msgSender()) revert OnlyOwnerCanTransferWhileStaking();
        stakingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        stakingTransfer = 1;
    }

    // open/close staking globally
    function setStakingOpen(bool open) external onlyOwner {
        stakingOpen = open;
    }

    // toggle staking
    function toggleStaking(uint256 tokenId) internal onlyApprovedOrOwner(tokenId) {
        uint256 start = stakingStarted[tokenId];
        if(start == 0) {
            if (!stakingOpen) revert StakingClosed();
            stakingStarted[tokenId] = block.timestamp;
            emit Staked(tokenId);
        }else {
            stakingTotal[tokenId] += block.timestamp - start;
            stakingStarted[tokenId] = 0;
            emit Unstaked(tokenId);
        }
    }

    // toggle staking, callable from frontend w support for multiple tokens
    function toggleStaking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; i++) {
            toggleStaking(tokenIds[i]);
        }
    }

    function withdrawEth() public onlyOwner nonReentrant {
        uint256 total = address(this).balance;

        require(payable(0x452A89F1316798fDdC9D03f9af38b0586F8142e5).send((total * 10) / 100)); // PT
        require(payable(0xefc41a7A7b75b0cDC9F78471A4BdaDf8796D963c).send((total * 90) / 100)); // company
    }

    receive() payable external {
        revert("Contract does not allow receipt of ETH or ERC-20 tokens");
    }

    fallback() payable external {
        revert("An incorrect function was called");
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
            getApproved(tokenId) == _msgSender(),
            "ERC721ACommon: Not approved nor owner"
        );
        _;
    }
}