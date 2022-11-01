// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract CBTDaoNFT is Ownable, ERC165, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    uint256 public normalMaxSupply = 800;
    uint256 public superMaxSupply = 200;
    uint256 public normalSupply;
    uint256 public superSupply;

    string private _name = "CBT Dao";

    string private _symbol = "CBT";

    string public baseURI = "";

    string public suffix = ".png";

    enum Type {
        Normal, Super
    }

    struct NFTInfo {
        address owner;
        Type nftType;
        string hash;
    }

    mapping(uint256 => NFTInfo) private _infos;

    mapping(string => uint256) private _hashs;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) public miners;

    modifier onlyMiner {
        require(miners[_msgSender()], "CBTDaoNFT: caller is not the miner");
        _;
    }

    bool lock = false;
    modifier lockMint {
        lock = true;
        _;
        lock = false;
    }

    event MintInfo(address indexed owner, uint256 indexed id, uint8 nftType, string hash);

    constructor() {
        miners[owner()] = true;
    }

    function setMiner(address addr, bool state) public onlyOwner {
        miners[addr] = state;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setSuffix(string memory _suffix) public onlyOwner {
        suffix = _suffix;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "CBTDaoNFT: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _infos[tokenId].owner;
        require(owner != address(0), "CBTDaoNFT: owner query for nonexistent token");
        return owner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns(uint256) {
        return normalSupply + superSupply;
    }

    function hashID(string calldata hash) public view returns(uint256) {
        return _hashs[hash];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "CBTDaoNFT: URI query for nonexistent token");

        string memory hash = _infos[tokenId].hash;
        string memory base = baseURI;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return string(abi.encodePacked(hash, suffix));
        }

        return string(abi.encodePacked(base, hash, suffix));
    }

    function tokenHash(uint256 tokenId) public view returns(string memory) {
        require(_exists(tokenId), "CBTDaoNFT: URI query for nonexistent token");
        return _infos[tokenId].hash;
    }

    function tokenInfo(uint256 tokenId) public view returns(NFTInfo memory) {
        require(_exists(tokenId), "CBTDaoNFT: URI query for nonexistent token");
        return _infos[tokenId];
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = _infos[tokenId].owner;
        require(to != owner, "CBTDaoNFT: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "CBTDaoNFT: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "CBTDaoNFT: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CBTDaoNFT: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CBTDaoNFT: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function mintTo(address target, string memory hash, Type nftType) public onlyMiner lockMint {
        require(_hashs[hash] == 0, "CBTDaoNFT: hash already exists");

        uint256 id;
        if (nftType == Type.Normal) {
            require(normalSupply < normalMaxSupply, "CBTDaoNFT: exceeded the maximum supply");
            id = 1000 + ++normalSupply;
        } else {
            require(superSupply < superMaxSupply, "CBTDaoNFT: exceeded the maximum supply");
            id = 100 + ++superSupply;
        }

        _safeMint(target, id);
        NFTInfo memory info = NFTInfo(target, nftType, hash);
        _infos[id] = info;

        _hashs[hash] = id;

        emit MintInfo(target, id, uint8(nftType), hash);
    }

    function mint(string memory hash, Type nftType) public {
        mintTo(_msgSender(), hash, nftType);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CBTDaoNFT: transfer caller is not owner nor approved");
        _burn(tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "CBTDaoNFT: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _infos[tokenId].owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "CBTDaoNFT: operator query for nonexistent token");
        address owner = _infos[tokenId].owner;
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "CBTDaoNFT: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "CBTDaoNFT: mint to the zero address");
        require(!_exists(tokenId), "CBTDaoNFT: token already minted");

        _balances[to] += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _infos[tokenId].owner;

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        _balances[address(0)] += 1;
        _infos[tokenId].owner = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(_infos[tokenId].owner == from, "CBTDaoNFT: transfer from incorrect owner");
        require(to != address(0), "CBTDaoNFT: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _infos[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_infos[tokenId].owner, to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "CBTDaoNFT: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("CBTDaoNFT: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}