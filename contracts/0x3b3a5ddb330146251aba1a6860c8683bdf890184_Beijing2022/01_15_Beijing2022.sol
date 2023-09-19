// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *
 *
 * 巴丢草 Badiucao
 *
 * Beijing Olympics 2022 NFT
 *
 * https://beijing2022.art
 *
 * Five unique artworks in editions of 2022.
 *
 * Collectors have the opportunity to write their own
 * message of opposition to China’s authoritarian regime
 * onto the blockchain as part of the minting process,
 * preserving it as a public decentralized record of protest.
 *
 *
 */
contract Beijing2022 is Context, ERC721, Ownable, IERC2981, ERC165Storage {
    using Counters for Counters.Counter;
    event Mint(
        uint256 indexed tokenId,
        uint256 artwork,
        string msg,
        address to
    );

    // artwork supply and price
    uint256 public maxSupplyEachArtwork = 2022;
    uint256 public maxDevMintsPerArtwork = 220;
    uint256 public price = 0.2022 * 10**18;

    // minting open/closed
    bool private _mintOpen;

    // token counters
    Counters.Counter private _tokenIds;
    Counters.Counter[5] private _artworks;
    Counters.Counter[5] private _artworkDevMints;

    // message mapping
    mapping(uint256 => string) public tokenIdToMessage;
    mapping(uint256 => uint256) public tokenIdToArtwork;

    // base token uri
    string private _baseTokenURI;
    string private _contractURI;

    // secondary market royalties
    address public royaltiesAddress = 0x74e513db7C1856f179AaBFd475e85c27FEF69D8A;
    uint256 public royaltiesPercentage = 10;

    // Bytes4 Code for ERC interfaces
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /**
     * @dev Beijing2022
     * @param name_ - Token Name
     * @param symbol_ - Token Symbol
     * @param baseTokenURI_ - Base token URI for metadata
     * @param contractURI_ - Contract metadata URI
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        string memory contractURI_
    ) ERC721(name_, symbol_) {
        _baseTokenURI = baseTokenURI_;
        _contractURI = contractURI_;

        // register the supported ERC interfaces
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC2981);

        // deploy with mint closed
        _mintOpen = false;
    }

    /**
     * @dev get contractURI
     * @return the contractURI string
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev (OnlyOwner) Mint a reserved mint token
     * @param artwork_ - the artwork
     * @param msg_ - the message
     * @param to_ - the receiving address
     */
    function devMint(
        uint256 artwork_,
        string memory msg_,
        address to_
    ) public onlyOwner {
        require(artwork_ >= 1 && artwork_ <= 5, "Artwork id must be 1 thru 5");

        // increment dev mint counter
        _artworkDevMints[artwork_ - 1].increment();
        uint256 devMintCounterId = _artworkDevMints[artwork_ - 1].current();
        require(
            devMintCounterId <= maxDevMintsPerArtwork,
            "Dev mint supply exhausted"
        );
        _mint(artwork_, msg_, to_);
    }

    /**
     * @dev Mint an artwork with a message
     * @param artwork_ - the id of the artwork
     * @param msg_ - the spell string
     */
    function mint(uint256 artwork_, string memory msg_) public payable {
        require(_mintOpen, "Minting is closed");
        require(artwork_ >= 1 && artwork_ <= 5, "Artwork id must be 1 thru 5");

        // increment artwork counter
        _artworks[artwork_ - 1].increment();
        uint256 artworkCounterId = _artworks[artwork_ - 1].current();
        require(
            artworkCounterId + maxDevMintsPerArtwork <= maxSupplyEachArtwork,
            "Artwork Supply Depleted"
        );

        require(msg.value >= price, "Must pay for minting");
        (bool success, ) = owner().call{value: msg.value}("");
        require(success, "Transfer Failed");
        _mint(artwork_, msg_, _msgSender());
    }

    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId_ - the NFT asset queried for royalty information
     * @param salePrice_ - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return donationAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
        external
        view
        override(IERC2981)
        returns (address receiver, uint256 donationAmount)
    {
        require(_exists(tokenId_), "ERC721: Nonexistent Token ID");
        receiver = royaltiesAddress;
        donationAmount = (salePrice_ * royaltiesPercentage) / 100;
    }

    /**
     * @dev set public minting open or closed
     * @param isOpen_  - boolean open or closed
     */
    function setMintOpen(bool isOpen_) public onlyOwner {
        _mintOpen = isOpen_;
    }

    /**
     * @dev get mint open or closed
     */
    function getMintOpen() public view returns (bool) {
        return _mintOpen;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, ERC165Storage)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev set baseTokenURI
     */
    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }

    /**
     * @dev set contractURI
     */
    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    /**
     * @dev set royalties address
     */
    function setRoyaltiesAddress(address address_) public onlyOwner {
        royaltiesAddress = address_;
    }

    /**
     * @dev set royalty percentage amount
     */
    function setRoyaltiesPercentage(uint256 percentage_) public onlyOwner {
        royaltiesPercentage = percentage_;
    }

    /**
     * @dev Get total token supply
     * @return _tokenID.current() - the current position of the _tokenIDs counter
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev get tokenURI
     * @param tokenId - the tokenid
     * @return the tokenURI string
     */
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
        string memory baseTokenURI = _baseURI();
        string memory id = Strings.toString(tokenIdToArtwork[tokenId]);
        return
            bytes(baseTokenURI).length > 0
                ? string(abi.encodePacked(baseTokenURI, id, ".json"))
                : "";
    }

    /**
     * @dev Get baseTokenURI
     * @return _baseTokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Mint token, emits a Mint event
     * @param artwork_ - the artwork id
     * @param msg_ - the spell string
     * @param to_ - the receiving address
     */
    function _mint(
        uint256 artwork_,
        string memory msg_,
        address to_
    ) private {
        // increment token id
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        // store message if exists
        bytes memory stringMem = bytes(msg_);
        if (stringMem.length > 0) {
            tokenIdToMessage[tokenId] = msg_;
        }

        // store artwork id
        tokenIdToArtwork[tokenId] = artwork_;

        _safeMint(to_, tokenId);
        emit Mint(tokenId, artwork_, msg_, to_);
    }
}