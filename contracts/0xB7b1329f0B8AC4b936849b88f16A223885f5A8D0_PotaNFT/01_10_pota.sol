// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "solady/src/utils/ECDSA.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeTransferLib.sol";

/// @title POTA NFT
contract PotaNFT is ERC721A, ERC721AQueryable, Ownable {
    using ECDSA for bytes32;

    uint256 public constant PRICE_UNIT = 0.001 ether;

    string private _tokenURI;

    address public signer;

    uint8 public maxPerWallet = 2;
    uint8 public maxPerTransaction = 2;
    uint16 public maxSupply = 500;
    uint16 private _whitelistPriceUnits = _toPriceUnits(0.025 ether);
    uint16 private _publicPriceUnits = _toPriceUnits(0.025 ether);

    bool public paused = true;
    bool public mintLocked;
    bool public maxSupplyLocked;
    bool public tokenURILocked;

    constructor() ERC721A("POTA", "POTA") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        return LibString.replace(_tokenURI, "{id}", _toString(tokenId));
    }

    function publicPrice() external view returns (uint256) {
        return _toPrice(_publicPriceUnits);
    }

    function whitelistPrice() external view returns (uint256) {
        return _toPrice(_whitelistPriceUnits);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     MINTING FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function potaMint(uint256 quantity)
        external
        payable
        mintNotPaused
        requireMintable(quantity)
        requireUserMintable(quantity)
        requireExactPayment(_publicPriceUnits, quantity)
    {
        _mint(msg.sender, quantity);
    }

    function potaList(uint256 quantity)
        external
        payable
        mintNotPaused
        requireMintable(quantity)
        requireUserMintable(quantity)
        requireExactPayment(_whitelistPriceUnits, quantity)
    {
        _mint(msg.sender, quantity);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          HELPERS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _toPriceUnits(uint256 price) private pure returns (uint16) {
        unchecked {
            require(price % PRICE_UNIT == 0, "Price must be a multiple of PRICE_UNIT.");
            require((price /= PRICE_UNIT) <= type(uint16).max, "Overflow.");
            return uint16(price);
        }
    }

    function _toPrice(uint16 priceUnits) private pure returns (uint256) {
        return uint256(priceUnits) * PRICE_UNIT;
    }

    modifier requireUserMintable(uint256 quantity) {
        unchecked {
            require(quantity <= maxPerTransaction, "Max per transaction reached.");
            require(_numberMinted(msg.sender) + quantity <= maxPerWallet, "Max number minted reached.");
        }
        _;
    }

    modifier requireMintable(uint256 quantity) {
        unchecked {
            require(mintLocked == false, "Locked.");
            require(_totalMinted() + quantity <= maxSupply, "Out of stock!");
        }
        _;
    }

    modifier requireExactPayment(uint16 priceUnits, uint256 quantity) {
        unchecked {
            require(quantity <= 100, "Quantity too high.");
            require(msg.value == _toPrice(priceUnits) * quantity, "Wrong Ether value.");
        }
        _;
    }

    modifier requireSignature(bytes calldata signature) {
        require(
            keccak256(abi.encode(msg.sender)).toEthSignedMessageHash().recover(signature) == signer,
            "Invalid signature."
        );
        _;
    }

    modifier mintNotPaused() {
        require(paused == false, "Paused.");
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ADMIN FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function airdrop(address[] calldata to, uint256 quantity) external onlyOwner requireMintable(quantity * to.length) {
        unchecked {
            for (uint256 i; i != to.length; ++i) {
                _mint(to[i], quantity);
            }
        }
    }

    function setTokenURI(string calldata value) external onlyOwner {
        require(tokenURILocked == false, "Locked.");

        _tokenURI = value;
    }

    function setMaxSupply(uint16 value) external onlyOwner {
        require(maxSupplyLocked == false, "Locked.");

        maxSupply = value;
    }

    function setMaxPerWallet(uint8 value) external onlyOwner {
        maxPerWallet = value;
    }

    function setMaxPerTransaction(uint8 value) external onlyOwner {
        maxPerTransaction = value;
    }

    function setPaused(bool value) external onlyOwner {
        if (value == false) {
            require(maxSupply != 0, "Max supply not set.");
            require(signer != address(0), "Signer not set.");
        }
        paused = value;
    }

    function setSigner(address value) external onlyOwner {
        require(value != address(0), "Signer must not be the zero address.");

        signer = value;
    }

    function lockMint() external onlyOwner {
        mintLocked = true;
    }

    function lockMaxSupply() external onlyOwner {
        maxSupplyLocked = true;
    }

    function lockTokenURI() external onlyOwner {
        tokenURILocked = true;
    }

    function setWhitelistPrice(uint256 value) external onlyOwner {
        _whitelistPriceUnits = _toPriceUnits(value);
    }

    function setPublicPrice(uint256 value) external onlyOwner {
        _publicPriceUnits = _toPriceUnits(value);
    }

    function withdraw() external payable onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }
}