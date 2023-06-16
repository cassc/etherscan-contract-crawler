// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *
 *
 *  ╔═══╗       ╔╗                ╔╗
 *  ║╔═╗║       ║║                ║║
 *  ║╚═╝╠═╦══╦╗╔╣╚═╦══╦══╦══╦══╗  ║╠══╦═══╦═══╗
 *  ║╔══╣╔╣╔╗║╚╝║╔╗║╔╗║╔╗║╔╗║╔╗║╔╗║║╔╗╠══║╠══║║
 *  ║║  ║║║╔╗║║║║╚╝║╔╗║║║║╔╗║║║║║╚╝║╔╗║║══╣║══╣
 *  ╚╝  ╚╝╚╝╚╩╩╩╩══╩╝╚╩╝╚╩╝╚╩╝╚╝╚══╩╝╚╩═══╩═══╝
 *
 * This code is part of Prambanan Jazz NFT project (https://nft.prambananjazz.com).
 *
 * Developed by Tiyasan Nusantara Teknologi (tiyasannusantara.com).
 *
 * Prambanan Jazz NFT is a collection of 1000 digital collectible items with exclusive benefits.
 *
 * NFT owners automatically become honored guests of Prambanan Jazz.
 * Prambanan Jazz NFTs represent various benefits such as lifetime access to all Rajawali Indonesia concerts,
 * lifetime access to Prambanan Jazz itself, merchandise, Skip the lines at festival,
 * exclusive meet and greets with all performers, as well as VVIP place in Prambanan Jazz Festival.
 *
 */
import "ERC721.sol";
import "ERC721Enumerable.sol";
import "IERC721Enumerable.sol";
import "IERC721Metadata.sol";
import "Ownable.sol";
import "HasAdmin.sol";
import "SigVerifier.sol";
import "MarketplaceWhitelist.sol";

contract PJF is ERC721, Ownable, HasAdmin, SigVerifier, MarketplaceWhitelist {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public constant DISCOUNT_PRICE = 0.01 ether;
    uint256 public constant NORMAL_PRICE_BASE = 0.02 ether;
    uint256 public publicMintStartTime;

    string public baseTokenURI;
    uint32 public totalWhitelistMinted = 0;
    uint16 public totalSupply = 0;
    uint16 public maxMintPerAccount = 5;

    mapping(address => uint16) private _mintedByAccounts;

    event Mint(uint256 indexed tokenId, address indexed owner);

    constructor(
        string memory _baseTokenURI,
        address admin
    ) ERC721("Prambanan Jazz", "PJAZZ") {
        baseTokenURI = _baseTokenURI;
        _setAdmin(admin);
        publicMintStartTime = 1651424399; // May 2st, 2022
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        _setAdmin(newAdmin);
    }

    function whitelistMint(
        address to,
        uint16 qty,
        uint64 nonce,
        bool discount,
        Sig memory sig
    ) external payable returns (bool) {
        require(qty <= 5, "Max 5 NFTs can be minted at a time");
        require(totalSupply + qty <= MAX_SUPPLY, "Total limit reached");

        uint256 amount = msg.value;

        if (discount) {
            require(amount >= qty * DISCOUNT_PRICE, "Not enough amount to pay");
        } else {
            require(
                amount >= qty * _calculatedPrice(),
                "Not enough amount to pay"
            );
        }
        require(nonce >= uint64(block.timestamp) / 30, "invalid nonce");

        uint16 accountMinted = _mintedByAccounts[to];

        require(
            accountMinted + qty <= maxMintPerAccount,
            "Max mint per account reached"
        );

        bytes32 message = sigPrefixed(
            keccak256(abi.encodePacked(_msgSender(), to, qty, nonce, discount))
        );

        require(_isSigner(admin(), message, sig), "invalid signature");

        uint32 _totalWhitelistMinted = totalWhitelistMinted;
        uint16 _totalSupply = totalSupply;

        for (uint32 i = 0; i < qty; i++) {
            uint256 tokenId = _totalSupply + 1;
            _safeMint(to, tokenId);
            emit Mint(tokenId, to);
            ++_totalWhitelistMinted;
            ++_totalSupply;
        }

        totalWhitelistMinted = _totalWhitelistMinted;
        totalSupply = _totalSupply;
        _mintedByAccounts[to] = accountMinted + qty;

        return true;
    }

    function setMaxMintPerAccount(uint16 _maxMintPerAccount)
        external
        onlyOwner
    {
        maxMintPerAccount = _maxMintPerAccount;
    }

    function mintedByAccount(address account) external view returns (uint16) {
        return _mintedByAccounts[account];
    }

    function isPublicMintActivated() public view returns (bool) {
        return
            publicMintStartTime > 0 && block.timestamp >= publicMintStartTime;
    }

    modifier publicMintActive() {
        require(isPublicMintActivated(), "PJF: Public mint not open yet");
        _;
    }

    function setPublicMintTime(uint256 _startTime)
        external
        onlyOwner
        returns (bool)
    {
        publicMintStartTime = _startTime;
        return true;
    }

    function publicMint(address to, uint32 qty)
        external
        payable
        publicMintActive
        returns (bool)
    {
        uint256 amount = msg.value;

        require(qty <= 5, "Max 5 NFTs can be minted at a time");
        require(totalSupply + qty <= MAX_SUPPLY, "Max supply reached");
        require(qty > 0, "Min qty is 1");
        require(amount >= qty * _calculatedPrice(), "Not enough amount to pay");
        require(tx.origin == _msgSender(), "Contracts not allowed");

        uint16 _totalSupply = totalSupply;

        for (uint32 i = 0; i < qty; i++) {
            uint256 tokenId = _totalSupply + 1;

            _safeMint(to, tokenId);
            emit Mint(tokenId, to);

            ++_totalSupply;
        }

        totalSupply = _totalSupply;

        return true;
    }

    function exclusiveMint(address to, uint32 qty)
        external
        onlyOwner
        returns (bool)
    {
        require(totalSupply + qty <= MAX_SUPPLY, "Max supply reached");
        require(qty > 0, "Min qty is 1");

        uint16 _totalSupply = totalSupply;

        for (uint32 i = 0; i < qty; i++) {
            uint256 tokenId = _totalSupply + 1;

            _safeMint(to, tokenId);
            emit Mint(tokenId, to);

            ++_totalSupply;
        }

        totalSupply = _totalSupply;

        return true;
    }

    function _calculatedPrice() internal view returns (uint256) {
        // Gunakan harga dasar sebelum 2 Mei 2022
        if (block.timestamp < 1651363200) {
            return NORMAL_PRICE_BASE;
        }
        // Setelah tanggal 1 Mei, harga akan naik 0.005 ETH per hari
        return
            NORMAL_PRICE_BASE +
            ((((1 * 10**16) * (block.timestamp - 1651363200)) / 86400) /
                10**16) *
            10**16;
    }

    function getPrice() public view returns (uint256) {
        return _calculatedPrice();
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No amount to withdraw");
        payable(_msgSender()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @dev Whitelist OpenSea or LooksRare to enable gas-less listings,
     *      so users don't need to pay additional gas for listing on those platforms.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (approveOpenSea) {
            ProxyRegistry proxyRegistry = ProxyRegistry(openSeaProxyAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        if (approveLooksRare) {
            if (looksRareAddress == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }
}