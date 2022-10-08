//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./NFTTypeUpgradeable.sol";
import "./utils/ProxyableUpgradeable.sol";

contract NFTSalesERC20Upgradeable is
    Initializable,
    OwnableUpgradeable,
    NFTTypeUpgradeable,
    ReentrancyGuardUpgradeable,
    ProxyableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringsUpgradeable for uint256;

    uint8 public constant UNKNOWN_NFT_TYPE = 0;
    uint8 public constant LOOT_CRATE_NFT_TYPE = 1;

    bool public lcSaleActive;
    bool public uncrateActive;
    uint8 public nftsPerLootCrate;
    address public lcPaymentToken;
    uint256 public lcPaymentAmount;
    address public treasury;
    uint256 public uncratePrice;

    event Uncrate(address indexed user, string ids);
    event WithdrawRevenue(address indexed sender, uint256 indexed amount);

    error SaleIsClosed();
    error InsufficientNFTs(uint256 available, uint256 required);
    error NotLootCrate(uint32 tokenID);
    error InsufficientPayment(uint256 sent, uint256 required);

    function initialize(
        string memory name,
        string memory symbol,
        address _treasury,
        address paymentToken,
        uint256 paymentAmount
    ) public initializer notZeroAddress(_treasury) {
        __NFTTypeUpgradeable_init(name, symbol);
        treasury = _treasury;
        lcPaymentToken = paymentToken;
        lcPaymentAmount = paymentAmount;
        OwnableUpgradeable.__Ownable_init();
        nftsPerLootCrate = 3;
        uncratePrice = 250000000000000000;
    }

    receive() external payable onlyOwner {}

    modifier saleIsActive() {
        if (!lcSaleActive) revert SaleIsClosed();
        _;
    }

    function assignNFTType(uint32[] calldata nftIDs, uint32[] calldata nftTypes)
        external
        onlyProxy
    {
        _assignNFTTypeWithFilter(nftIDs, nftTypes, UNKNOWN_NFT_TYPE);
    }

    function batchMint(address receiver, uint32[] calldata nftTypes)
        external
        onlyProxy
    {
        _batchMint(receiver, nftTypes);
    }

    function mint(address receiver, uint32 nftType) external onlyProxy {
        _mintAndAssignNFTType(receiver, nftType);
    }

    // purchase single loot crate NFT with ERC1155 NFT
    function buyLootCrate() external saleIsActive nonReentrant {
        _checkSufficientPayment(lcPaymentAmount);

        IERC20Upgradeable(lcPaymentToken).safeTransferFrom(
            _msgSender(),
            treasury,
            lcPaymentAmount
        );
        _mintAndAssignNFTType(_msgSender(), LOOT_CRATE_NFT_TYPE);
    }

    // purchase multiple loot crate NFTs with ERC1155 NFTs
    function batchBuyLootCrate(uint8 amount)
        external
        saleIsActive
        nonReentrant
    {
        uint256 requiredAmount = lcPaymentAmount * amount;
        _checkSufficientPayment(requiredAmount);

        IERC20Upgradeable(lcPaymentToken).safeTransferFrom(
            _msgSender(),
            treasury,
            requiredAmount
        );
        _batchMintAndAssignNFTType(_msgSender(), amount, LOOT_CRATE_NFT_TYPE);
    }

    function evolve(uint32[] calldata nftIDs, uint32[] calldata nftTypes)
        external
        onlyProxy
    {
        _assignNFTType(nftIDs, nftTypes);
    }

    // set the ERC115 contract and token ID used for purchasing Loot Crates
    function setLootCratePayment(
        address _lcPaymentToken,
        uint256 _lcPaymentAmount
    ) external onlyOwner notZeroAddress(_lcPaymentToken) {
        lcPaymentToken = _lcPaymentToken;
        lcPaymentAmount = _lcPaymentAmount;
    }

    function setLootCratePrice(uint256 value) external onlyOwner {
        lcPaymentAmount = value;
    }

    function setNFTsPerLootCrate(uint8 value) external onlyOwner {
        nftsPerLootCrate = value;
    }

    function setSaleActive(bool value) external onlyOwner {
        lcSaleActive = value;
    }

    function setTreasury(address _treasury)
        external
        onlyOwner
        notZeroAddress(_treasury)
    {
        treasury = _treasury;
    }

    function setUncrateActive(bool value) external onlyOwner {
        uncrateActive = value;
    }

    function setUncratePrice(uint256 value) external onlyOwner {
        uncratePrice = value;
    }

    // when uncrating, NFTs are minted with NFT type "unknownNFTType", which is 0
    // NFT type is updated by NFT randomization service
    function uncrate(uint32 id) external payable senderOwnsToken(id) {
        _isLootCrate(id);
        _paymentAmountValid(1);
        // convert NFT from Loot Crate to Unknown, allowing it be reassigned
        tokenIDToNFTType[id] = UNKNOWN_NFT_TYPE;
        // increment for converted Loot Crate NFTs to Unknown
        _incrementNFTTypeCountForAddress(UNKNOWN_NFT_TYPE, _msgSender(), 1);
        // remove Loot Crates from counts
        _decrementNFTTypeCountForAddress(LOOT_CRATE_NFT_TYPE, _msgSender(), 1);
        uint8 _nftsPerLootCrate = nftsPerLootCrate;
        uint16 nftsToMint = _nftsPerLootCrate - 1;
        uint256 nextTokenID = _owners.length;
        string memory unknownIDs = string.concat(uint256(id).toString(), ",");
        for (uint x; x < nftsToMint; x++) {
            unknownIDs = string.concat(
                unknownIDs,
                (nextTokenID + x).toString(),
                ","
            );
        }
        _batchMintAndAssignNFTType(_msgSender(), nftsToMint, UNKNOWN_NFT_TYPE);
        emit Uncrate(_msgSender(), unknownIDs);
    }

    function uncrateBatch(uint32[] calldata ids)
        external
        payable
        senderOwnsTokens(ids)
    {
        uint16 amount = uint16(ids.length);
        _paymentAmountValid(amount);
        uint8 _nftsPerLootCrate = nftsPerLootCrate;

        // add new minted NFT IDs to unknown list
        uint16 nftsToMint = (_nftsPerLootCrate - 1) * amount;
        uint256 nextTokenID = _owners.length;
        //uint256[] memory unknownIDs = new uint256[](_nftsPerLootCrate * amount);
        string memory unknownIDs = "";
        for (uint x; x < nftsToMint; x++) {
            unknownIDs = string.concat(
                unknownIDs,
                (nextTokenID + x).toString(),
                ","
            );
        }

        for (uint256 x; x < ids.length; x++) {
            _isLootCrate(ids[x]);
            // convert NFT from Loot Crate to Unknown, allowing it be reassigned
            tokenIDToNFTType[ids[x]] = UNKNOWN_NFT_TYPE;
            // add Loot Crate ID to unknown list
            unknownIDs = string.concat(
                unknownIDs,
                uint256(ids[x]).toString(),
                ","
            );
        }

        // increment for converted Loot Crate NFTs to Unknown
        _incrementNFTTypeCountForAddress(
            UNKNOWN_NFT_TYPE,
            _msgSender(),
            amount
        );
        // remove Loot Crates from counts
        _decrementNFTTypeCountForAddress(
            LOOT_CRATE_NFT_TYPE,
            _msgSender(),
            amount
        );

        _batchMintAndAssignNFTType(_msgSender(), nftsToMint, UNKNOWN_NFT_TYPE);
        emit Uncrate(_msgSender(), unknownIDs);
    }

    function updateLootCrateConfig(
        uint256 _price,
        bool _saleActive,
        string calldata tokenBaseURI,
        bool _uncrateActive
    ) external onlyOwner {
        lcPaymentAmount = _price;
        lcSaleActive = _saleActive;
        _tokenBaseURI = tokenBaseURI;
        uncrateActive = _uncrateActive;
    }

    // withdraw native to treasury
    function withdrawRevenue() external {
        require(
            _msgSender() == owner() ||
                _msgSender() == treasury ||
                proxyToApproved[_msgSender()],
            "Not allowed"
        );
        uint256 amount = address(this).balance;
        if (amount == 0) return;
        (bool success, ) = treasury.call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawRevenue(_msgSender(), amount);
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            proxyToApproved[operator] ||
            super.isApprovedForAll(_owner, operator);
    }

    function _checkSufficientPayment(uint256 amount) private view {
        uint256 bal = IERC20Upgradeable(lcPaymentToken).balanceOf(_msgSender());
        if (bal < amount)
            revert InsufficientNFTs({available: bal, required: amount});
    }

    function _isLootCrate(uint32 id) private view {
        if (tokenIDToNFTType[id] != LOOT_CRATE_NFT_TYPE)
            revert NotLootCrate({tokenID: id});
    }

    function _paymentAmountValid(uint256 nftAmount) private view {
        uint256 requiredAmount = nftAmount * uncratePrice;
        if (requiredAmount != msg.value)
            revert InsufficientPayment({
                sent: msg.value,
                required: requiredAmount
            });
    }
}