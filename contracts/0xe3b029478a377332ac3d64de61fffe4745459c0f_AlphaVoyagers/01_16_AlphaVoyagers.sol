//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/openZeppelin/IERC20.sol";
import "./interfaces/openZeppelin/IERC2981.sol";

import "./libraries/openZeppelin/Ownable.sol";
import "./libraries/openZeppelin/ReentrancyGuard.sol";
import "./libraries/openZeppelin/SafeERC20.sol";
import "./libraries/FixedPointMathLib.sol";

import "./types/ERC721A.sol";

contract AlphaVoyagers is Ownable, ERC721A, IERC2981, ReentrancyGuard {
    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using Strings for uint256;

    /* ====== CONSTANTS ====== */

    uint64 public constant MAX_SUPPLY = 10_000;
    uint64 public constant MAX_MINT_QUANTITY = 10;
    uint64 public constant MAX_PROMOTIONAL_QUANTITY = 1_500;

    uint64 public constant PUBLIC_SALE_PRICE = 0.005 ether;

    // Treasury
    address payable private immutable _treasury;

    // Owners
    address payable private immutable _owner1;
    address payable private immutable _owner2;
    address payable private immutable _owner3;

    // Dev
    address payable private immutable _dev;

    /* ====== ERRORS ====== */

    string private constant ERROR_TRANSFER_FAILED = "transfer failed";

    /* ====== VARIABLES ====== */

    string private _customBaseURI = "ipfs://QmQmgm5gzRqyDyRrmAz1fd24MhMfhan4vZF1qRB6SLb7Ts";

    uint64 internal _currentPromotionalIndex;

    bool public isPublicSaleActive = false;
    bool public isFreeMint = false;

    /* ====== MODIFIERS ====== */

    modifier tokenExists(uint256 tokenId_) {
        require(_exists(tokenId_), "AV: !exist");
        _;
    }

    modifier publicSaleActive() {
        require(isPublicSaleActive, "AV: !active");
        _;
    }

    modifier maxMintsPerTX(uint256 quantity_) {
        require(quantity_ <= MAX_MINT_QUANTITY, "AV: max mint exceeded");
        _;
    }

    modifier canMintNFTs(uint256 quantity_) {
        require(quantity_ > 0, "AV: !must mint at least one NFT");
        require(totalSupply() + quantity_ <= MAX_SUPPLY, "AV: quantity exceeded totalSupply()");
        _;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(address treasury_, address owner1_, address owner2_, address owner3_, address dev_) ERC721A("Alpha Voyagers", "AV") {
        _treasury = payable(treasury_);

        _owner1 = payable(owner1_);
        _owner2 = payable(owner2_);
        _owner3 = payable(owner3_);

        _dev = payable(dev_);
    }

    receive() payable external {}

    function mint(uint256 quantity_)
    external payable
    nonReentrant
    publicSaleActive
    maxMintsPerTX(quantity_)
    canMintNFTs(quantity_)
    {
        if (!isFreeMint) {
            // Check free voyagers left & check owner AUX
            if (_currentPromotionalIndex < MAX_PROMOTIONAL_QUANTITY && _getAux(msg.sender) == 0) {
            unchecked {
                _currentPromotionalIndex += 1;
            }

                // Set owner aux to 1
                _setAux(msg.sender, 1);

                require((PUBLIC_SALE_PRICE * (quantity_ - 1)) == msg.value, "AV: !enough eth");
            } else {
                require((PUBLIC_SALE_PRICE * quantity_) == msg.value, "AV: !enough eth");
            }
        }

        // Mint AV NFT
        _safeMint(msg.sender, quantity_);
    }

    function promotionalMint(address receiver_, uint256 quantity_)
    external onlyOwner
    canMintNFTs(quantity_)
    {
        _safeMint(receiver_, quantity_);
    }

    /* ========== VIEW ========== */

    function getBaseURI() external view returns (string memory) {
        return _customBaseURI;
    }

    function freeMintsRemaining() external view returns (uint256) {
        return MAX_PROMOTIONAL_QUANTITY - _currentPromotionalIndex;
    }

    function hasClaimedFreeToken(address wallet_) external view returns (bool) {
        return _getAux(wallet_) == 1;
    }

    /* ========== FUNCTION ========== */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _customBaseURI = baseURI_;
    }

    function setIsPublicSaleActive(bool isPublicSaleActive_) external onlyOwner {
        isPublicSaleActive = isPublicSaleActive_;
    }

    function setIsFreeMint(bool isFreeMint_) external onlyOwner {
        isFreeMint = isFreeMint_;
    }

    function withdraw() public {
        uint256 split_ = address(this).balance / 5;

        bool success_;
        (success_,) = _treasury.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _owner1.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _owner2.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _owner3.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _dev.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);
    }

    function withdrawPartial(uint16 basisPoints_) public {
        uint256 balance_ = (address(this).balance).mulDivDown(basisPoints_, 10000);
        uint256 split_ = balance_ / 5;

        bool success_;
        (success_,) = _treasury.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _owner1.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _owner2.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _owner3.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _dev.call{value: split_}("");
        require(success_, ERROR_TRANSFER_FAILED);
    }

    function withdrawTokens(IERC20 token) public {
        uint256 balance_ = token.balanceOf(address(this));
        uint256 split_ = balance_ / 5;

        token.safeTransfer(_treasury, split_);
        token.safeTransfer(_owner1, split_);
        token.safeTransfer(_owner2, split_);
        token.safeTransfer(_owner3, split_);
        token.safeTransfer(_dev, split_);
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC721A, IERC165) returns (bool) {
        return interfaceId_ == type(IERC2981).interfaceId || super.supportsInterface(interfaceId_);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId_) public view virtual override tokenExists(tokenId_) returns (string memory) {
        return string(abi.encodePacked(_customBaseURI, "/", tokenId_.toString(), ".json"));
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
    external view override
    tokenExists(tokenId_)
    returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), salePrice_.mulDivDown(75, 1000));
    }
}