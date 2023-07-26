//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTKey is ERC721URIStorage, EIP712, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using Address for address;

    string private constant SIGNING_DOMAIN = "NFTKey";
    string private constant SIGNING_VERSION = "1";
    address public recipient;
    uint256 public totalRevenue;
    bool public isDeprecated = false;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => bool) public minters;
    mapping(bytes => bool) private _signatureExists;

    modifier isNotDeprecated() {
        require(!isDeprecated, "Is Deprecated");
        _;
    }

    struct NFTVoucher {
        uint256 externalId;
        string tokenURI;
        address recipient;
        uint256 minPrice;
        uint256 expire;
        bytes signature;
    }

    event tokenMint(uint256 indexed tokenId, address indexed sender, NFTVoucher voucher);

    constructor(string memory tokenName, string memory symbol, address ownerAddress, address recipientAddress, address[] memory minterAddresses) ERC721(tokenName, symbol) EIP712(SIGNING_DOMAIN, SIGNING_VERSION)
    {
        _transferOwnership(ownerAddress);
        recipient = recipientAddress;
        for(uint256 i = 0; i < minterAddresses.length; i++){
            minters[minterAddresses[i]] = true;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function _burn(uint256 tokenId) internal virtual override{
        super._burn(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override isNotDeprecated{
        super._transfer(from,to,tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mint(NFTVoucher calldata voucher) external payable nonReentrant isNotDeprecated returns (uint256)
    {
        require(voucher.expire > 0 && block.timestamp < voucher.expire, "Voucher expired");
        require(!_signatureExists[voucher.signature], "Voucher minted");
        _signatureExists[voucher.signature] = true;
        require(minters[_verifyVoucher(voucher)], "Permission denied");
        require(minters[msg.sender] || msg.value >= voucher.minPrice, "Insufficient funds");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        totalRevenue += msg.value;
        emit tokenMint(tokenId, msg.sender, voucher);

        _safeMint(voucher.recipient, tokenId);
        _setTokenURI(tokenId, voucher.tokenURI);
        if(msg.value > 0){
            Address.sendValue(payable(recipient), msg.value);
        }

        return tokenId;
    }

    function deprecate(bool deprecated) external nonReentrant onlyOwner
    {
        isDeprecated = deprecated;
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _verifyVoucher(NFTVoucher calldata voucher) internal view returns (address)
    {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(uint256 externalId,string tokenURI,address recipient,uint256 minPrice,uint256 expire)"),
            voucher.externalId,
            keccak256(abi.encodePacked(voucher.tokenURI)),
            voucher.recipient,
            voucher.minPrice,
            voucher.expire
        )));
        return ECDSA.recover(digest, voucher.signature);
    }
}