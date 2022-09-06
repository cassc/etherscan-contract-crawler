//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "sudoswap/lib/ReentrancyGuard.sol";

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/interfaces/IERC2981.sol";
// import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "solmate/utils/FixedPointMathLib.sol";

import "./ERC721A.sol";
import "../interfaces/ISSMintableNFT.sol";

error PublicSaleNotActive();

error QuantityMustBeGreaterThanZero();
error QuantityExceedsMaxMintQuantity();
error QuantityExceedsMaxAllowancePerWallet();
error QuantityExceedsTotalSupply();
error NotEnoughETH();

error NotPermissionedMinter();

error WithdrawTransferFailed();

contract SSMintableNFT is ISSMintableNFT, Ownable, ERC721A, IERC2981, ReentrancyGuard {
    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using Strings for uint256;

    /* ====== CONSTANTS ====== */

    uint64 public constant MAX_SUPPLY = 7_000;
    uint64 public constant MAX_MINT_QUANTITY = 4;
    uint64 public constant MAX_MINT_ALLOWANCE = 8;

    address payable private immutable _owner1;
    address payable private immutable _owner2;

    /* ====== VARIABLES ====== */

    address private _ssmw = address(0);
    string  private _customBaseURI = "ipfs://QmZ7hZX4aGTEVFAQMHGaa98tSev929srabDAw6FSktMktX";

    uint256 public PUBLIC_SALE_PRICE;
    bool public isPublicSaleActive = false;

    /* ====== MODIFIERS ====== */

    modifier tokenExists(uint256 tokenId_) {
        require(_exists(tokenId_), "!exist");
        _;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(address owner1_, address owner2_) ERC721A("Face of Sudo", "FOS") {
        _owner1 = payable(owner1_);
        _owner2 = payable(owner2_);
    }

    receive() payable external {}

    function mint(uint256 quantity_)
    external payable
    nonReentrant
    {
        if (!isPublicSaleActive)
            revert PublicSaleNotActive();

        if (quantity_ == 0)
            revert QuantityMustBeGreaterThanZero();
        if (quantity_ > MAX_MINT_QUANTITY)
            revert QuantityExceedsMaxMintQuantity();
        if (_numberMinted(msg.sender) + quantity_ > MAX_MINT_ALLOWANCE)
            revert QuantityExceedsMaxAllowancePerWallet();
        if (totalSupply() + quantity_ > MAX_SUPPLY)
            revert QuantityExceedsTotalSupply();
        if (msg.value < (PUBLIC_SALE_PRICE * quantity_))
            revert NotEnoughETH();

        // Mint NFT
        _safeMint(msg.sender, quantity_);
    }

    function permissionedMint(address receiver_) external {
        if (msg.sender != _ssmw)
            revert NotPermissionedMinter();
        if (totalSupply() >= MAX_SUPPLY)
            revert QuantityExceedsTotalSupply();
            
        _safeMint(receiver_, 1);
    }

    function promotionalMint(address receiver_, uint256 quantity_) external onlyOwner {
        if (quantity_ == 0)
            revert QuantityMustBeGreaterThanZero();
        if (totalSupply() + quantity_ > MAX_SUPPLY)
            revert QuantityExceedsTotalSupply();
        _safeMint(receiver_, quantity_);
    }

    /* ========== VIEW ========== */

    function getBaseURI() external view returns (string memory) {
        return _customBaseURI;
    }

    /* ========== FUNCTION ========== */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _customBaseURI = baseURI_;
    }

    function setIsPublicSaleActive(bool isPublicSaleActive_) external onlyOwner {
        isPublicSaleActive = isPublicSaleActive_;
    }

    function setPublicSalePrice(uint256 price_) external onlyOwner {
        PUBLIC_SALE_PRICE = price_;
    }

    function setSudoSwapMintWrapperContract(address ssmw_) external onlyOwner {
        _ssmw = ssmw_;
    }

    function withdraw() public {
        uint256 split_ = address(this).balance / 2;

        bool success_;
        (success_,) = _owner1.call{value: split_}("");
        if (!success_) revert WithdrawTransferFailed();

        (success_,) = _owner2.call{value: split_}("");
        if (!success_) revert WithdrawTransferFailed();
    }

    function withdrawTokens(IERC20 token) public {
        uint256 balance_ = token.balanceOf(address(this));
        uint256 split_ = balance_ / 2;

        token.safeTransfer(_owner1, split_);
        token.safeTransfer(_owner2, split_);
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