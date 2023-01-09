// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract NFT721 is Ownable, IERC721, IERC721Metadata, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;

    string public override name;
    string public override symbol;
    string private baseURI;
    address private platform;
    uint256 public maxSupply;
    uint256 public totalSupply;
    // true：unlimited，false：limited
    bool public unlimitedSupply;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {
        name = "NFT721";
        symbol = "NFT721";
        maxSupply = 10000;
        unlimitedSupply = false;
        totalSupply = 0;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved)
        external
        override
    {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    function _approve(
        address owner,
        address to,
        uint256 tokenId
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint256 tokenId
    ) private view returns (bool) {
        return (spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]);
    }

    function _transfer(
        address owner,
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the zero address");
        _approve(owner, address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _transfer(owner, from, to, tokenId);
    }

    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private {
        _transfer(owner, from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "not ERC721Receiver"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (unlimitedSupply) {
            require(maxSupply >= totalSupply + 1, "maximum supply exceeded");
        }
        require(_owners[tokenId] == address(0), "token already minted");
        require(to != address(0), "mint to zero address");
        _balances[to] += 1;
        _owners[tokenId] = to;
        totalSupply += 1;
        emit Transfer(address(0), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            return
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                ) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_owners[tokenId] != address(0), "Token Not Exist");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        baseURI = baseURI_;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    function _setPlatform(address _platform) internal virtual {
        platform = _platform;
    }

    function setPlatform(address _platform) external onlyOwner {
        _setPlatform(_platform);
    }

    function _isLaunchpadPlatform(address spender)
        internal
        view
        virtual
        returns (bool)
    {
        return (spender == platform);
    }

    function setBaseURIByLaunchpadPlatform(string calldata _baseURI)
        external
        nonReentrant
    {
        if (_isLaunchpadPlatform(_msgSender())) {
            _setBaseURI(_baseURI);
        }
    }

    function mintByLaunchpadPlatform(address to, uint256 tokenId)
        external
        nonReentrant
    {
        if (_isLaunchpadPlatform(_msgSender())) {
            _safeMint(to, tokenId);
        }
    }
}