// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

////////////////////////////////////////////////////
//////////////////New Web3 Social///////////////////
//////////////W//G//F//S//O//C//I//A//L/////////////
/////////////// www.wgfsocial.com //////////////////
////////////////////////////////////////////////////
////////////////////////////////////////////////////

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract WGFNFT is
    ERC721,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ERC721Burnable,
    ERC721Enumerable
{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct AddressMinted {
        uint256 freeMinted;
        uint256 paidMinted;
    }

    mapping(address => AddressMinted) private _addressMinted;

    uint256 public PAY_COUNT;
    uint256 public FREE_COUNT;
    uint256 public constant MAX_FREE_MINT = 1000;
    uint256 public constant MAX_TOTAL_MINT = 9001;
    uint256 public constant PRICE = 50 * 10 ** 6;
    uint256 public constant LIMIT = 1;
    uint256 public constant FREE_LIMIT = 1;
    bool public _mintingEnabled = true;
    bytes32 public ROOT;

    IERC20 public USDT;

    address public constant REPURCHASE_ADDRESS =
        0x69348663d65d2504c9A52857Ec644D9c8b681ca8;
    uint256 public constant REPURCHASE_PRICE = 50 ether;

    address public constant MARKET_WALLET =
        0x69348663d65d2504c9A52857Ec644D9c8b681ca8;

    constructor(bytes32 _root, address _usdt) ERC721("WGF Social", "WGF") {
        ROOT = _root;
        USDT = IERC20(_usdt);
    }

    function setRoot(bytes32 _root) public onlyOwner {
        ROOT = _root;
    }

    function isWhitelisted(
        address account,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, ROOT, leaf);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMintingEnabled(bool enabled) external onlyOwner {
        _mintingEnabled = enabled;
    }

    function freeMint(bytes32[] memory _proof) external {
        require(isWhitelisted(_msgSender(), _proof), "Not in whitelist");
        require(_mintingEnabled, "Minting is not enabled");
        require(
            _tokenIdCounter.current() < MAX_FREE_MINT,
            "Max total mint reached"
        );
        require(
            _addressMinted[_msgSender()].freeMinted < FREE_LIMIT,
            "Max free mint per address reached"
        );
        _addressMinted[_msgSender()].freeMinted++;

        FREE_COUNT++;

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function payMint() public whenNotPaused {
        require(_mintingEnabled, "Minting is not enabled");
        require(
            _addressMinted[_msgSender()].paidMinted < LIMIT,
            "Max mint per address reached"
        );

        require(
            USDT.balanceOf(_msgSender()) >= PRICE,
            "USDT Insufficient balance"
        );

        require(
            USDT.allowance(_msgSender(), address(this)) >= PRICE,
            "Insufficient allowable quantity"
        );

        bool success = USDT.transferFrom(_msgSender(), MARKET_WALLET, PRICE);
        require(success, "Transfer failed");

        _addressMinted[_msgSender()].paidMinted++;

        PAY_COUNT++;

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function merge(
        address _to,
        uint256 _tokenId1,
        uint256 _tokenId2
    ) external onlyOwner {
        require(_mintingEnabled, "Minting is not enabled");

        _burn(_tokenId1);
        _burn(_tokenId2);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
    }

    function repurchase(uint256 tokenId) public whenNotPaused {
        require(_msgSender() == ownerOf(tokenId), "You do not own this NFT.");

        transferFrom(_msgSender(), REPURCHASE_ADDRESS, tokenId);

        bool success = USDT.transfer(_msgSender(), REPURCHASE_PRICE);
        require(success, "USDT Transfer failed");
    }

    function getAddressMinted(
        address account
    ) external view returns (AddressMinted memory) {
        return _addressMinted[account];
    }

    function mint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.wgfsocial.com/token/";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}