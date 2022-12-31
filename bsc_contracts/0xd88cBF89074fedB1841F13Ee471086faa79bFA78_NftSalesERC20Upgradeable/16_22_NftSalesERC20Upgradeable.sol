//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./NftTypeUpgradeable.sol";
import "./utils/ProxyableUpgradeable.sol";
import "./utils/WithdrawableUpgradeable.sol";

// Nfts are purchaseable with ERC20 tokens

contract NftSalesERC20Upgradeable is
    Initializable,
    OwnableUpgradeable,
    NftTypeUpgradeable,
    ReentrancyGuardUpgradeable,
    ProxyableUpgradeable,
    WithdrawableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringsUpgradeable for uint256;

    uint8 public constant UNKNOWN_Nft_TYPE = 0;

    bool public saleActive;

    address public paymentToken;
    address public treasury;

    uint256 public maxSupply;
    uint256 public paymentAmount;
    uint256 public revenue;

    event WithdrawRevenue(address indexed sender, uint256 indexed amount);

    error ExceedsMaxSupply();
    error InsufficientTokens(uint256 available, uint256 required);
    error SaleIsClosed();

    function initialize(
        string memory name,
        string memory symbol,
        address _treasury,
        address _paymentToken,
        uint256 _paymentAmount,
        string calldata tokenBaseUri
    ) public initializer notZeroAddress(_treasury) {
        __NftTypeUpgradeable_init(name, symbol);
        treasury = _treasury;
        paymentToken = _paymentToken;
        paymentAmount = _paymentAmount;
        OwnableUpgradeable.__Ownable_init();
        _tokenBaseURI = tokenBaseUri;
    }

    receive() external payable onlyOwner {}

    modifier saleIsActive() {
        if (!saleActive) revert SaleIsClosed();
        _;
    }

    function assignNftType(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes
    ) external onlyProxy {
        _assignNftTypeWithFilter(nftIDs, nftTypes, UNKNOWN_Nft_TYPE);
    }

    // purchase multiple Nfts with ERC20 tokens
    function batchBuy(
        uint16 amount
    ) external saleIsActive nonReentrant returns (uint32[] memory) {
        if (totalSupply + amount > maxSupply) revert ExceedsMaxSupply();
        uint256 requiredAmount = paymentAmount * amount;
        _checkSufficientPayment(requiredAmount);

        IERC20Upgradeable(paymentToken).safeTransferFrom(
            _msgSender(),
            treasury,
            requiredAmount
        );
        return
            _batchMintAndAssignNftType(_msgSender(), amount, UNKNOWN_Nft_TYPE);
    }

    function batchMint(
        address receiver,
        uint32[] calldata nftTypes
    ) external onlyProxy {
        _batchMint(receiver, nftTypes);
    }

    function burn(uint32 tokenId) external {
        _burn(tokenId);
    }

    // purchase single Nft with ERC20 tokens
    function buy() external saleIsActive nonReentrant returns (uint32) {
        if (totalSupply + 1 > maxSupply) revert ExceedsMaxSupply();
        _checkSufficientPayment(paymentAmount);

        IERC20Upgradeable(paymentToken).safeTransferFrom(
            _msgSender(),
            treasury,
            paymentAmount
        );
        revenue += paymentAmount;
        return _mintAndAssignNftType(_msgSender(), UNKNOWN_Nft_TYPE);
    }

    function evolve(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes
    ) external onlyProxy {
        _assignNftType(nftIDs, nftTypes);
    }

    function mint(address receiver, uint32 nftType) external onlyProxy {
        _mintAndAssignNftType(receiver, nftType);
    }

    function setMaxSupply(uint256 value) external onlyOwner {
        maxSupply = value;
    }

    // set the payment token and amount for buying Nfts
    function setPayment(
        address _paymentToken,
        uint256 _paymentAmount
    ) external onlyOwner notZeroAddress(_paymentToken) {
        paymentToken = _paymentToken;
        paymentAmount = _paymentAmount;
    }

    function setPrice(uint256 value) external onlyOwner {
        paymentAmount = value;
    }

    function setSaleActive(bool value) external onlyOwner {
        saleActive = value;
    }

    function setTreasury(
        address _treasury
    ) external onlyOwner notZeroAddress(_treasury) {
        treasury = _treasury;
    }

    function updateConfig(
        uint256 _price,
        bool _saleActive,
        string calldata tokenBaseURI //,
    ) external onlyOwner {
        paymentAmount = _price;
        saleActive = _saleActive;
        _tokenBaseURI = tokenBaseURI;
        //uncrateActive = _uncrateActive;
    }

    function withdrawNativeToTreasury() external onlyOwner {
        _withdrawNativeToTreasury(treasury);
    }

    function withdrawTokensToTreasury(address tokenAddress) external onlyOwner {
        _withdrawTokensToTreasury(treasury, tokenAddress);
    }

    function batchSafeTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds,
        bytes memory data
    ) public {
        for (uint32 i; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i], data);
        }
    }

    function batchTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds
    ) public {
        for (uint32 i; i < tokenIds.length; i++) {
            transferFrom(from, to, tokenIds[i]);
        }
    }

    function isApprovedForAll(
        address _owner,
        address operator
    ) public view override returns (bool) {
        return
            proxyToApproved[operator] ||
            super.isApprovedForAll(_owner, operator);
    }

    function _checkSufficientPayment(uint256 amount) private view {
        uint256 bal = IERC20Upgradeable(paymentToken).balanceOf(_msgSender());
        if (bal < amount)
            revert InsufficientTokens({available: bal, required: amount});
    }
}