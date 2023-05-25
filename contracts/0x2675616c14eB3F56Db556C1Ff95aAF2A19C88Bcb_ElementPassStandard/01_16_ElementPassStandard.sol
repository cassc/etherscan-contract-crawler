// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract ElementPassStandard is ERC721A("Element Pass Standard", "EPS"), Ownable, DefaultOperatorFilterer {

    string private baseURI;
    address public immutable MINTER;

    uint256 public constant MAX_SUPPLY = 20000;
    uint256 public constant MIN_LOCKING_PERIOD = 7 days;
    uint256 public constant MAX_LOCKING_PERIOD = 365 days;

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
        baseURI = "";
    }

    function safeMint(address to, uint256 amount) external payable {
        unchecked {
            require(msg.sender == MINTER, "Illegal minter");
            require(tx.origin == to, "Contract mint is not supported");
            require(totalSupply() + amount <= MAX_SUPPLY, "Already sold out");

            _mint(to, amount);
        }
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint256 length = bytes(baseURI).length;
        if (length > 0 && bytes(baseURI)[length - 1] == 0x2f) {
            return super.tokenURI(tokenId);
        }
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return baseURI;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function withdrawETH(address recipient) external onlyOwner {
        require(recipient != address(0), "Recipient error");
        require(address(this).balance > 0, "The balance is zero");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success);
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
        require(period >= MIN_LOCKING_PERIOD, "Locking period should gte 7 days");
        require(period <= MAX_LOCKING_PERIOD, "Locking period should lte 365 days");
        require(ERC721A.ownerOf(tokenId) == msg.sender, "Only owner can lock token");
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

    function _beforeTokenTransfers(
        address from,
        address /* to */,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        if (from != address(0) && quantity == 1) {
            if (isLocking(startTokenId)) {
                revert("Token is locking");
            }
        }
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
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