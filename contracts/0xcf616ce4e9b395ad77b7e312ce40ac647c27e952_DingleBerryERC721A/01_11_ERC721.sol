// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IDingleERC20.sol";

// ████████▄   ▄█  ███▄▄▄▄      ▄██████▄   ▄█          ▄████████      ▀█████████▄     ▄████████    ▄████████    ▄████████ ▄██   ▄
// ███   ▀███ ███  ███▀▀▀██▄   ███    ███ ███         ███    ███        ███    ███   ███    ███   ███    ███   ███    ███ ███   ██▄
// ███    ███ ███▌ ███   ███   ███    █▀  ███         ███    █▀         ███    ███   ███    █▀    ███    ███   ███    ███ ███▄▄▄███
// ███    ███ ███▌ ███   ███  ▄███        ███        ▄███▄▄▄           ▄███▄▄▄██▀   ▄███▄▄▄      ▄███▄▄▄▄██▀  ▄███▄▄▄▄██▀ ▀▀▀▀▀▀███
// ███    ███ ███▌ ███   ███ ▀▀███ ████▄  ███       ▀▀███▀▀▀          ▀▀███▀▀▀██▄  ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ▀▀███▀▀▀▀▀   ▄██   ███
// ███    ███ ███  ███   ███   ███    ███ ███         ███    █▄         ███    ██▄   ███    █▄  ▀███████████ ▀███████████ ███   ███
// ███   ▄███ ███  ███   ███   ███    ███ ███▌    ▄   ███    ███        ███    ███   ███    ███   ███    ███   ███    ███ ███   ███
// ████████▀  █▀    ▀█   █▀    ████████▀  █████▄▄██   ██████████      ▄█████████▀    ██████████   ███    ███   ███    ███  ▀█████▀
//                                        ▀                                                       ███    ███   ███    ███

// =============================================================
//                       ERRORS
// =============================================================

/// When public Minting has not yet started
error MintingIsPaused();

/// Zero NFTs mint. Wallet can mint at least one NFT.
error ZeroTokensMint();

/// For price check. msg.value should be greater than or equal to mint price
error LowPrice();

/// Max supply limit exceed error
error BerriesExceeded();

/// Whitelist and public mint limit exceed error
error MintLimitExceeded();

// =============================================================
//       Dingle Berry ERC721A Contract
// =============================================================

contract DingleBerryERC721A is ERC721A, Ownable, IERC2981 {
    using Strings for uint256;

    IDingleERC20 public DingleERC20; // ERC20 token instance

    uint16 public constant maxBerriesSupply = 10000;
    uint16 private _totalPublicBerries; // number of tokens mint from public supply
    uint16 private _berriesTax = 420; // royalties 4.2% in bps

    // public spwan price
    uint256 public mintPrice = 0.006 ether; // mint price per token
    uint16 public mintLimit = 10; // tokens per address are allowd to mint.
    uint16 public freeMintLimit = 1; // free tokens per address
    bool public isMinting;

    address public berriesTaxCollector; // EOA for as royalties receiver for collection

    string public baseURI; // token base uri

    mapping(address => uint16) private freeMintOf; // to check if wallet has mint free NFTs

    // =============================================================
    //                       FUNCTIONS
    // =============================================================

    /**
     * @dev  It will mint from tokens allocated for public
     * @param volume is the quantity of tokens to be mint
     * @param _doubleRewards is the boolean to double erc20 tokens on mint
     */
    function mint(uint16 volume, bool _doubleRewards) external payable {
        bool isFreeMintClaimed = _mintRequirements(volume, _doubleRewards);
        _safeMint(_msgSender(), volume);

        uint256 rewards = DingleERC20.calculateRewards(
            volume,
            isFreeMintClaimed,
            _doubleRewards
        );

        bool success = DingleERC20.transfer(_msgSender(), rewards);
        require(success, "ERC20 transfer failed");
    }

    // =============================================================
    //                     PRIVATE FUNCTIONS
    // =============================================================

    /**
     * @dev check mint requirements and returns true if mint claimed otherwise false.
     */
    function _mintRequirements(
        uint16 volume,
        bool _doubleRewards
    ) private returns (bool isFreeMintClaimed) {
        if (!isMinting) revert MintingIsPaused();
        if (volume == 0) revert ZeroTokensMint();
        // max supply check
        if (_totalMinted() + volume > maxBerriesSupply)
            revert BerriesExceeded();

        isFreeMintClaimed = isFreeMintComplete(_msgSender());

        uint16 freeMints = freeMintLimit - freeMintOf[_msgSender()];
        freeMintOf[_msgSender()] += freeMints;

        uint256 value = 0; // fee to pay for mint
        uint256 paidMint = volume - freeMints;

        // if call is for double rewards the user should pay additional 0.003 ether.
        if (_doubleRewards) {
            value = (mintPrice * (paidMint)) + (paidMint * (mintPrice / 2));
        } else {
            value = mintPrice * paidMint;
        }

        if (msg.value < value) {
            revert LowPrice();
        }

        uint256 requestedVolume = _numberMinted(_msgSender()) + volume;
        if (requestedVolume > mintLimit) {
            revert MintLimitExceeded();
        }
    }

    // =============================================================
    //                      ADMIN FUNCTIONS
    // =============================================================

    /**
     * @dev it is only callable by Contract owner. it will toggle mint status
     */
    function toggleMintingStatus() external onlyOwner {
        isMinting = !isMinting;
    }

    /**
     * @dev it will update mint price
     * @param _mintPrice is new value for mint
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev it will update the mint limit aka amount of nfts a wallet can hold
     * @param _mintLimit is new value for the limit
     */
    function setMintLimit(uint16 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    /**
     * @dev it will update the mint limit aka amount of nfts a wallet can hold
     * @param _mintLimit is new value for the limit
     */
    function setFreeMintLimit(uint16 _mintLimit) external onlyOwner {
        freeMintLimit = _mintLimit;
    }

    /**
     * @dev it will update baseURI for tokens
     * @param _uri is new URI for tokens
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev it will update the address for royalties receiver
     * @param _berriesTaxCollector is new royalty receiver
     */
    function setBerriesTaxReceiver(
        address _berriesTaxCollector
    ) external onlyOwner {
        require(_berriesTaxCollector != address(0));
        berriesTaxCollector = _berriesTaxCollector;
    }

    /**
     * @dev it will update the royalties for token
     * @param berriesTax_ is new percentage of royalties. it should be  in bps (1% = 1 *100 = 100). 6.9% => 6.9 * 100 = 690
     */
    function setBerriesTax(uint16 berriesTax_) external onlyOwner {
        require(berriesTax_ > 0, "should be > 0");
        _berriesTax = berriesTax_;
    }

    /**
     * @dev transfers ETH balace of contract to caller. Only callable by contract owner.
     */
    function withdraw() external onlyOwner {
        bool success = payable(_msgSender()).send(address(this).balance);
        require(success, "Transfer failed!");
    }

    /**
     * @dev transfers all ERC20 tokens to caller from contract. Only callable by contract owner.
     */
    function withdrawERC20Tokens() external onlyOwner {
        uint256 balance = DingleERC20.balanceOf(address(this));
        bool success = DingleERC20.transfer(_msgSender(), balance);
        require(success, "Transfer failed!");
    }

    /**
     * @dev creates new instance of ERC20 token. Only callable by contract owner
     * @param _address should be the address of ERC20 token
     */
    function setERC20TokenAddress(address _address) external onlyOwner {
        DingleERC20 = IDingleERC20(_address);
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens minted by `owner`.
     */
    function totalMintOf(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    /**
     * @dev check if free mint is claimed or not. If free mint is completed, it will return true otherwise it will return false.
     */
    function isFreeMintComplete(address _wallet) public view returns (bool) {
        return freeMintOf[_wallet] == freeMintLimit ? true : false;
    }

    /**
     * @dev it will return tokenURI for given tokenIdToOwner
     * @param _tokenId is valid token id mint in this contract
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     *  @dev it retruns the amount of royalty the owner will receive for given tokenId
     *  @param _tokenId is valid token number
     *  @param _salePrice is amount for which token will be traded
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        require(
            _exists(_tokenId),
            "ERC2981RoyaltyStandard: Royalty info for nonexistent token"
        );
        return (berriesTaxCollector, (_salePrice * _berriesTax) / 10000);
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // =============================================================
    //                      CONSTRUCTOR
    // =============================================================

    constructor(
        address _erc20Address,
        string memory uri_
    ) ERC721A("Dingle Berry", "DB") {
        berriesTaxCollector = msg.sender;
        baseURI = uri_;

        DingleERC20 = IDingleERC20(_erc20Address);
    }
}