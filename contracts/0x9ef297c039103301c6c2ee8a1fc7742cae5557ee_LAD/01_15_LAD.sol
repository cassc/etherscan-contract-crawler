// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract LAD is ERC721A, ERC721AQueryable, ERC721ABurnable, Ownable, Pausable {
    // The signer address
    address private _signer;

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    // keccak256("Mint(address owner,uint256 mintQty,uint256 allowQty,uint256 totalPrice,uint256 expireAt)")
    bytes32 private constant MINT_TYPE_HASH = keccak256("Mint(address owner,uint256 mintQty,uint256 allowQty,uint256 totalPrice,uint256 expireAt)");

    bytes32 private constant STAKE_TYPE_HASH = keccak256("Stake(bool flag,address owner,uint256 id,uint256 expireAt)");

    bytes32 private constant SALT = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;

    bytes32 private immutable _cachedDomainSeparator;

    // The base token uri
    string private _baseTokenURI;

    uint256 private _availableSupply;

    mapping(address => uint256) private _mints;

    mapping(uint256 => bool) private _stakes;

    struct MintData {
        address owner;
        uint256 mintQty;
        uint256 allowQty;
        uint256 totalPrice;
        uint256 expireAt;
    }

    struct StakeData {
        bool flag;
        address owner;
        uint256 id;
        uint256 expireAt;
    }

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint256 initAvailableSupply) ERC721A(name_, symbol_) {
        _signer = msg.sender;
        _availableSupply = initAvailableSupply;
        _cachedDomainSeparator = _buildDomainSeparator();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function stake(
        bool _flag,
        uint256 _id,
        uint256 _expireAt,
        bytes memory signature) external {
        require(block.timestamp < _expireAt, "Expired");
        require(ownerOf(_id) == msg.sender, "Permission denied");
        require(_flag != _stakes[_id], "Duplicate action");
        require(getApproved(_id) == address(0), "Unapproval first");

        _verifySign(StakeData(_flag, msg.sender, _id, _expireAt), signature);
        _stakes[_id] = _flag;
    }

    function approve(address to, uint256 tokenId) public payable virtual override {
        require(_stakes[tokenId] == false, "Unstake first");
        super.approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        require(_stakes[tokenId] == false, "Unstake first");
        super.transferFrom(from, to, tokenId);
    }

    function mint(
        address _to,
        uint256 _mintQty,
        uint256 _allowQty,
        uint256 _expireAt,
        bytes memory signature
    ) external payable whenNotPaused {
        require(block.timestamp < _expireAt, "Expired");
        _checkMintable(_to, _mintQty, _allowQty);
        _verifySign(MintData(_to, _mintQty, _allowQty, msg.value, _expireAt), signature);
        _mint(_to, _mintQty);
        _mints[_to] += _mintQty;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSigner(address addr) public onlyOwner {
        _signer = addr;
    }

    function setAvailableSupply(uint256 availableSupply_) public onlyOwner {
        _availableSupply = availableSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return getBaseURI();
    }

    function getBaseURI() public view returns (string memory) {
        bytes memory tempURI = bytes(_baseTokenURI);
        if (tempURI.length == 0) {
            return "https://metadata.lootadog.com/";
        }

        return _baseTokenURI;
    }

    function getSigner() external view returns (address) {
        return _signer;
    }

    function availableSupply() external view returns (uint256) {
        return _availableSupply;
    }

    function stakeFlag(uint256 id) external view returns (bool) {        
        return _stakes[id];
    }

    function qtyOfMinted(address minter) external view returns (uint256) {
        return _mints[minter];
    }

    function _verifySign(
        MintData memory data,
        bytes memory signature
    ) internal view {
        require(_signer == ECDSA.recover(_hashTypedDataV4(_encodeMintData(data)), signature), "Invalid signer");
    }

    function _verifySign(
        StakeData memory data,
        bytes memory signature
    ) internal view {
        require(_signer == ECDSA.recover(_hashTypedDataV4(_encodeStakeData(data)), signature), "Invalid signer");
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (_signer == address(this)) {
            return _cachedDomainSeparator;
        }

        return _buildDomainSeparator();
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function _buildDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes("LOOTaDOG Dapp")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this),
                    SALT
                )
            );
    }

    function _encodeMintData(MintData memory data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MINT_TYPE_HASH,
                    data.owner,
                    data.mintQty,
                    data.allowQty,
                    data.totalPrice,
                    data.expireAt
                )
            );
    }

    function _encodeStakeData(StakeData memory data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    STAKE_TYPE_HASH,
                    data.flag,
                    data.owner,
                    data.id,
                    data.expireAt
                )
            );
    }

    function _checkMintable(address _to, uint256 _mintQty, uint256 _allowQty) internal view {
        require(_availableSupply >= totalSupply() + _mintQty, "Stock shortage");
        require(_allowQty >= _mints[_to] + _mintQty, "Maximum limit exceeded"); 
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}