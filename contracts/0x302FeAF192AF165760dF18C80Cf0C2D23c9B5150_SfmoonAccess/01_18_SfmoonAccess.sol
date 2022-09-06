// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SfmoonAccess is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, Pausable, ReentrancyGuard {
    struct Access {
        uint256 tokenId;
        uint256 lockedUntil;
        uint256 lockedAmount;
    }

    struct Waits {
        uint256 wait30;
        uint256 wait45;
        uint256 wait90;
        uint256 wait180;
    }

    struct Prices {
        uint256 price30;
        uint256 price45;
        uint256 price90;
        uint256 price180;
    }

    IERC20 public immutable token;
    Waits public waits;
    Prices public prices;
    uint256 private nfts = 0;
    uint256 public stakers = 0;
    uint256 public airdroppers = 0;
    uint256 public maxSupply;
    bytes32 public merkleRoot;

    mapping(address => Access) private accesses;

    modifier canStake(uint256 price) {
        Access memory access = accesses[msg.sender];
        require(balanceOf(msg.sender) == 0 && access.tokenId == 0 && access.lockedUntil == 0, "you already staked");
        require(stakers < maxSupply, "no more places");
        require(token.balanceOf(msg.sender) >= price, "insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= price, "!approved");
        _;
    }

    modifier canClaimNft() {
        Access memory access = accesses[msg.sender];
        require(balanceOf(msg.sender) == 0 && access.tokenId == 0, "you already have nft");
        require(stakers <= maxSupply, "no more places"); // FIXME: ????? REMOVE ?????
        require(block.timestamp >= access.lockedUntil, "wait period is not finished");
        require(access.lockedAmount > 0, "you did not staked");
        _;
    }

    modifier canClaimAirdropNft(bytes32[] calldata _merkleProof) {
        Access memory access = accesses[msg.sender];
        require(isEligibleForAirdrop(_merkleProof), "not eligible");
        require(
            balanceOf(msg.sender) == 0 && access.tokenId == 0 && access.lockedUntil == 0 && access.lockedAmount == 0,
            "you already staked or have nft"
        );
        _;
    }

    modifier canUnstake() {
        Access memory access = accesses[msg.sender];
        require(_exists(access.tokenId) && access.tokenId != 0, "nft does not exist");
        require(access.lockedAmount > 0, "airdrop can not be unstaked");
        require(ownerOf(access.tokenId) == msg.sender, "you aint nft owner");
        require(block.timestamp >= access.lockedUntil, "wait period is not finished");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _token,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _wait
    ) ERC721(_name, _symbol) {
        require(_token != address(0), "token cannot be zero address");
        require(_maxSupply > 0, "maxSupply cannot be zero");
        require(_price > 0, "price cannot be zero");
        require(_wait > 0, "wait cannot be zero");

        token = IERC20(_token);
        maxSupply = _maxSupply;

        prices.price30 = _price;
        prices.price45 = (_price / 4) * 3; // 75% of full price
        prices.price90 = _price / 2; // 50% of full price
        prices.price180 = _price / 4; // 25% of full price

        waits.wait30 = _wait;
        waits.wait45 = (_wait * 3) / 2; // x1.5
        waits.wait90 = _wait * 3; // x3
        waits.wait180 = _wait * 6; // x6
    }

    function stake30() public nonReentrant whenNotPaused canStake(prices.price30) {
        Access storage access = accesses[msg.sender];
        access.lockedAmount = prices.price30;
        stakers += 1;
        access.lockedUntil = block.timestamp + waits.wait30;
        token.transferFrom(msg.sender, address(this), prices.price30);
    }

    function stake45() public nonReentrant whenNotPaused canStake(prices.price45) {
        Access storage access = accesses[msg.sender];
        access.lockedAmount = prices.price45;
        stakers += 1;
        access.lockedUntil = block.timestamp + waits.wait45;
        token.transferFrom(msg.sender, address(this), prices.price45);
    }

    function stake90() public nonReentrant whenNotPaused canStake(prices.price90) {
        Access storage access = accesses[msg.sender];
        access.lockedAmount = prices.price90;
        stakers += 1;
        access.lockedUntil = block.timestamp + waits.wait90;
        token.transferFrom(msg.sender, address(this), prices.price90);
    }

    function stake180() public nonReentrant whenNotPaused canStake(prices.price180) {
        Access storage access = accesses[msg.sender];
        access.lockedAmount = prices.price180;
        stakers += 1;
        access.lockedUntil = block.timestamp + waits.wait180;
        token.transferFrom(msg.sender, address(this), prices.price180);
    }

    function claimNft() public nonReentrant whenNotPaused canClaimNft {
        Access storage access = accesses[msg.sender];
        nfts += 1;
        access.tokenId = nfts;
        _safeMint(msg.sender, nfts);
    }

    function claimAirdropNft(bytes32[] calldata _merkleProof)
        public
        nonReentrant
        whenNotPaused
        canClaimAirdropNft(_merkleProof)
    {
        Access storage access = accesses[msg.sender];
        nfts += 1;
        airdroppers += 1;
        access.tokenId = nfts;
        _safeMint(msg.sender, nfts);
    }

    function unstake() public nonReentrant whenNotPaused canUnstake {
        Access storage access = accesses[msg.sender];
        token.transfer(msg.sender, access.lockedAmount);
        burn(access.tokenId);
        stakers -= 1;
        access.tokenId = 0;
        access.lockedUntil = 0;
        access.lockedAmount = 0;
    }

    function info() public view returns (Access memory) {
        Access memory access = accesses[msg.sender];
        return access;
    }

    function isEligibleForAirdrop(bytes32[] memory _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(merkleRoot != 0, "merkleRoot not set");
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * ONLY OWNER
     */
    function setPrices(uint256 _price) public onlyOwner {
        require(_price > 0, "price cannot be zero");

        prices.price30 = _price;
        prices.price45 = (_price / 4) * 3; // 75% of full price
        prices.price90 = _price / 2; // 50% of full price
        prices.price180 = _price / 4; // 25% of full price
    }

    function setWaits(uint256 _wait) public onlyOwner {
        require(_wait > 0, "price cannot be zero");

        waits.wait30 = _wait;
        waits.wait45 = (_wait * 3) / 2; // x1.5
        waits.wait90 = _wait * 3; // x3
        waits.wait180 = _wait * 6; // x6
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply > maxSupply, "maxSupply cannot be lower");
        maxSupply = _maxSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * OVERRIDES
     */
    function burn(uint256 tokenId) public override(ERC721Burnable) {
        super.burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(to == msg.sender || to == address(0), "transfer prohibited");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}