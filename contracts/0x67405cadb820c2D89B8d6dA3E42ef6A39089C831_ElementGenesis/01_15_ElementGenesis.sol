// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract ElementGenesis is ERC721("Element Genesis", "ELEG"), Ownable, DefaultOperatorFilterer {

    address public immutable MINTER;
    string private baseURI;

    uint256 public constant MAX_SUPPLY = 2500;

    uint256 public maxMintAmountPerUser;
    mapping(address => uint256) public userMinted;

    // 140bits(unused) + 100bits(rareTokenIdFlags) + 16bits(rareTokensSupply)
    uint256 private rareTokens;
    uint256 private otherTokensSupply;

    uint256 public constant minLockingPeriod = 7 days;
    uint256 public constant maxLockingPeriod = 365 days;

    event Locked(
        uint256 indexed tokenId,
        address owner,
        uint256 startedAt,
        uint256 period
    );

    struct Locking {
        uint64 startedAt;
        uint64 period;
    }

    // Mapping tokenId to Locking information
    mapping(uint256 => Locking) public lockingTokens;
    bool public lockingOpen;

    constructor(address minter) {
        MINTER = minter;
        maxMintAmountPerUser = 2;
        baseURI = "";
    }

    function safeMint(address to, uint256 amount) external payable {
        unchecked {
            require(msg.sender == MINTER, "Illegal minter");
            require(tx.origin == to, "Contract mint is not supported");
            require(totalSupply() + amount <= MAX_SUPPLY, "Already sold out");
            require(userMinted[to] + amount <= maxMintAmountPerUser, "Exceeded the maximum mint limit for this account");

            userMinted[to] += amount;
            for (uint256 i; i < amount; i++) {
                _mint(to, _generateTokenId());
            }
        }
    }

    function _generateTokenId() internal returns(uint256) {
        unchecked {
            uint256 otherSupply = otherTokensSupply;

            // 140bits(unused) + 100bits(rareTokenIdFlags) + 16bits(rareTokensSupply)
            uint256 rares = rareTokens;
            uint256 rareSupply = (rares & 0xffff);
            uint256 rareLeft = 100 - rareSupply;

            if (rareLeft == 0) {
                otherTokensSupply = otherSupply + 1;
                return 101 + otherSupply;
            }

            uint256 totalLeft = MAX_SUPPLY - rareSupply - otherSupply;
            uint256 index = uint256(keccak256(abi.encodePacked(
                    blockhash(block.number - rareSupply - 1),
                    block.coinbase,
                    uint96(block.basefee),
                    uint32(block.number),
                    uint32(block.timestamp),
                    uint32(gasleft()),
                    uint32(totalLeft)
                ))) % totalLeft;

            if (index >= rareLeft) {
                otherTokensSupply = otherSupply + 1;
                return 101 + otherSupply;
            }

            uint256 tokenIdFlags = rares >> 16;
            uint256 j;
            for (uint256 i; i < 100; i++) {
                if (tokenIdFlags & (1 << i) == 0) {
                    if (j == index) {
                        // 140bits(unused) + 100bits(rareTokenIdFlags) + 16bits(rareTokensSupply)
                        rareTokens = ((tokenIdFlags | (1 << i)) << 16) + (rareSupply + 1);
                        return i + 1;
                    }
                    j++;
                }
            }
            revert("Mint error");
        }
    }

    function totalSupply() public view returns(uint256) {
        unchecked {
            return (rareTokens & 0xffff) + otherTokensSupply;
        }
    }

    function withdrawETH(address recipient) external onlyOwner {
        require(recipient != address(0), "Recipient error");
        require(address(this).balance > 0, "The balance is zero");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success);
    }

    function setMaxMintAmountPerUser(uint256 amount) external onlyOwner {
        maxMintAmountPerUser = amount;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint256 length = bytes(baseURI).length;
        if (length > 0 && bytes(baseURI)[length - 1] == 0x2f) {
            return super.tokenURI(tokenId);
        }
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseURI;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function setLockingOpen(bool open) external onlyOwner {
        lockingOpen = open;
    }

    function lockTokens(uint256[] calldata tokenIds, uint256[] calldata periods) external {
        require(lockingOpen, "Locking closed");
        require(tokenIds.length == periods.length, "Array length mismatch");

        for (uint256 i; i < tokenIds.length; ) {
            _lockToken(tokenIds[i], periods[i]);
            unchecked { i++; }
        }
    }

    function _lockToken(uint256 tokenId, uint256 period) internal {
        require(period >= minLockingPeriod, "Locking period should gte 7 days");
        require(period <= maxLockingPeriod, "Locking period should lte 365 days");
        require(ERC721.ownerOf(tokenId) == msg.sender, "Only owner can lock token");
        if (isLocking(tokenId)) {
            revert("The token is already locked");
        }

        lockingTokens[tokenId].startedAt = uint64(block.timestamp);
        lockingTokens[tokenId].period = uint64(period);

        emit Locked(tokenId, msg.sender, block.timestamp, period);
    }

    function isLocking(uint256 tokenId) public view returns(bool) {
        unchecked {
            Locking memory info = lockingTokens[tokenId];
            return block.timestamp < (info.startedAt + info.period);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (isLocking(tokenId)) {
            revert("Token is locking");
        }
        super._transfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}