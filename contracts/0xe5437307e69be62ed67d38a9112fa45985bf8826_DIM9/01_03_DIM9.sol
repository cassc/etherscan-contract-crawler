// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "erc721a/contracts/ERC721A.sol";

contract DIM9 is ERC721A {
    address public owner;
    string public baseTokenURI;
    uint256 public constant MAX_SUPPLY = 199;
    mapping(address => uint256) public addressLockedTime;

    constructor(string memory _baseTokenUri) ERC721A("DIM9", "DIM9") {
        baseTokenURI = _baseTokenUri;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyUnLocked(address addr) {
        require(block.timestamp > addressLockedTime[addr], "Locking period");
        _;
    }

    function ownerMint(
        address to,
        uint256 amount,
        uint256 year
    ) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Over supply");
        addressLockedTime[to] = year * 365 days + block.timestamp;
        _mint(to, amount);
    }

    function approve(address to, uint256 tokenId)
        public
        payable
        virtual
        override
        onlyUnLocked(msg.sender)
    {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyUnLocked(msg.sender)
    {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override onlyUnLocked(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override onlyUnLocked(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override onlyUnLocked(from) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}