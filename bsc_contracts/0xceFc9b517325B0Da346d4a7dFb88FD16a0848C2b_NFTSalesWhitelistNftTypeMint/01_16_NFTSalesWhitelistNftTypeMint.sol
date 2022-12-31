// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721Min.sol";
import "./interfaces/INftSales.sol";

contract NFTSalesWhitelistNftTypeMint is Ownable, ERC721Min, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) proxyToApproved; // proxy allowance for interaction with future contract
    address public treasuryAddress;
    bool public useBaseUriOnly = true;
    string private _contractURI;
    string private _tokenBaseURI = ""; // SET TO THE METADATA URI
    mapping(uint256 => string) public TokenURIMap; // allows for assigning individual/unique metada per token

    uint16 public maxPerAddress;
    uint16 public maxPerMint;
    uint16 maxPerAddressForThree;
    uint16 maxMint;
    uint16 public maxMintForOne;
    uint16 maxMintForThree;
    bool public saleActive;
    uint256 public price;
    uint256 priceForThree;

    address public paymentToken;
    uint256 public priceWithToken;
    uint256 public priceForThreeWithToken;

    bool public disableSalesWithETH;
    bool public disableSalesWithToken = true;

    // whitelist
    mapping(address => bool) public Whitelist;
    mapping(address => uint256) public WhitelistMints;
    bool whitelistEnabled = true;
    uint256 public whitelistMax = 3;

    struct FeeRecipient {
        address recipient;
        uint256 basisPoints;
    }

    mapping(uint256 => FeeRecipient) public FeeRecipients;
    uint256 feeRecipientCount;
    uint256 totalFeeBasisPoints;
    bool public transferDisabled;

    address public nftTypeContract;
    uint32 public nftTypeToMint;

    constructor(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address _nftTypeContract,
        uint32 _nftTypeToMint
    ) ERC721Min(name_, symbol_) {
        treasuryAddress = treasury_;
        nftTypeContract = _nftTypeContract;
        nftTypeToMint = _nftTypeToMint;
    }

    function totalSupply() external view returns (uint256) {
        return _owners.length;
    }

    // ** - CORE - ** //

    function buyOne() external payable {
        require(saleActive, "SALE_CLOSED");
        require(!disableSalesWithETH, "NO_ETH_SALES");
        require(price == msg.value, "INCORRECT_ETH");
        require(maxMintForOne > _owners.length, "EXCEED_MAX_SALE_SUPPLY");
        require(
            maxPerAddress == 0 || balanceOf(_msgSender()) < maxPerAddress,
            "EXCEED_MAX_PER_USER"
        );
        if (whitelistEnabled) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(
                WhitelistMints[_msgSender()] < whitelistMax,
                "MAX_WL_MINTED"
            );
            WhitelistMints[_msgSender()]++;
        }
        _mint(address(this));
    }

    function buyThree() external payable {
        require(saleActive, "SALE_CLOSED");
        require(!disableSalesWithETH, "NO_ETH_SALES");
        require(priceForThree == msg.value, "INCORRECT_ETH");
        require(maxMintForThree > _owners.length, "EXCEED_MAX_SALE_SUPPLY");
        require(
            maxPerAddress == 0 ||
                balanceOf(_msgSender()) < maxPerAddressForThree,
            "EXCEED_MAX_PER_USER"
        );
        if (whitelistEnabled) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(
                WhitelistMints[_msgSender()] + 4 < whitelistMax,
                "MAX_WL_MINTED"
            );
            WhitelistMints[_msgSender()] += 5;
        }
        _mint(address(this));
        _mint(address(this));
        _mint(address(this));
    }

    function buy(uint8 amount) external payable {
        require(saleActive, "SALE_CLOSED");
        require(!disableSalesWithETH, "NO_ETH_SALES");
        require(price * amount == msg.value, "INCORRECT_ETH");
        require(maxMint > _owners.length + amount, "EXCEED_MAX_SALE_SUPPLY");
        require(amount < maxPerMint, "EXCEED_MAX_PER_MINT");
        require(
            maxPerAddress == 0 ||
                balanceOf(_msgSender()) + amount - 1 < maxPerAddress,
            "EXCEED_MAX_PER_USER"
        );
        if (whitelistEnabled) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(
                WhitelistMints[_msgSender()] + amount - 1 < whitelistMax,
                "MAX_WL_MINTED"
            );
            WhitelistMints[_msgSender()] += amount;
        }
        for (uint256 i = 0; i < amount; i++) {
            _mint(address(this));
        }
    }

    function buyOneWithToken() external {
        require(saleActive, "SALE_CLOSED");
        require(!disableSalesWithToken, "NO_TOKEN_SALES");
        IERC20(paymentToken).transferFrom(
            msg.sender,
            address(this),
            priceWithToken
        );
        require(maxMintForOne > _owners.length, "EXCEED_MAX_SALE_SUPPLY");
        require(
            maxPerAddress == 0 || balanceOf(_msgSender()) < maxPerAddress,
            "EXCEED_MAX_PER_USER"
        );
        if (whitelistEnabled) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(
                WhitelistMints[_msgSender()] < whitelistMax,
                "MAX_WL_MINTED"
            );
            WhitelistMints[_msgSender()]++;
        }
        _mint(address(this));
    }

    function buyThreeWithToken() external {
        require(saleActive, "SALE_CLOSED");
        require(!disableSalesWithToken, "NO_TOKEN_SALES");
        IERC20(paymentToken).transferFrom(
            msg.sender,
            address(this),
            priceForThreeWithToken
        );
        require(maxMintForThree > _owners.length, "EXCEED_MAX_SALE_SUPPLY");
        require(
            maxPerAddress == 0 ||
                balanceOf(_msgSender()) < maxPerAddressForThree,
            "EXCEED_MAX_PER_USER"
        );
        _mint(address(this));
        _mint(address(this));
        _mint(address(this));
        if (whitelistEnabled) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(
                WhitelistMints[_msgSender()] + 4 < whitelistMax,
                "MAX_WL_MINTED"
            );
            WhitelistMints[_msgSender()] += 5;
        }
    }

    function buyWithToken(uint16 amount) external {
        require(saleActive, "SALE_CLOSED");
        require(!disableSalesWithToken, "NO_TOKEN_SALES");
        IERC20(paymentToken).transferFrom(
            msg.sender,
            address(this),
            priceWithToken * amount
        );
        require(maxMint > _owners.length + amount, "EXCEED_MAX_SALE_SUPPLY");
        require(amount < maxPerMint, "EXCEED_MAX_PER_MINT");
        require(
            maxPerAddress == 0 ||
                balanceOf(_msgSender()) + amount - 1 < maxPerAddress,
            "EXCEED_MAX_PER_USER"
        );
        for (uint256 i = 0; i < amount; i++) {
            _mint(address(this));
        }
        if (whitelistEnabled) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(
                WhitelistMints[_msgSender()] + amount - 1 < whitelistMax,
                "MAX_WL_MINTED"
            );
            WhitelistMints[_msgSender()] += amount;
        }
    }

    // ** - PROXY - ** //

    function mintOne(address receiver) external onlyProxy {
        _mint(receiver);
    }

    function mintThree(address receiver) external onlyProxy {
        _mint(receiver);
        _mint(receiver);
        _mint(receiver);
    }

    function mint(address receiver, uint16 amount) external onlyProxy {
        for (uint256 i = 0; i < amount; i++) {
            _mint(receiver);
        }
    }

    // ** - ADMIN - ** //

    function addFeeRecipient(address recipient, uint256 basisPoints)
        external
        onlyOwner
    {
        feeRecipientCount++;
        FeeRecipients[feeRecipientCount].recipient = recipient;
        FeeRecipients[feeRecipientCount].basisPoints = basisPoints;
        totalFeeBasisPoints += basisPoints;
    }

    function editFeeRecipient(
        uint256 id,
        address recipient,
        uint256 basisPoints
    ) external onlyOwner {
        require(id <= feeRecipientCount, "INVALID_ID");
        totalFeeBasisPoints =
            totalFeeBasisPoints -
            FeeRecipients[id].basisPoints +
            basisPoints;
        FeeRecipients[id].recipient = recipient;
        FeeRecipients[id].basisPoints = basisPoints;
    }

    function distributeETH() public {
        require(feeRecipientCount > 0, "RECIPIENTS_NOT_SET");
        uint256 bal = address(this).balance;
        for (uint256 x = 1; x <= feeRecipientCount; x++) {
            uint256 amount = (bal * FeeRecipients[x].basisPoints) /
                totalFeeBasisPoints;
            amount = amount > address(this).balance
                ? address(this).balance
                : amount;
            (bool sent, ) = FeeRecipients[x].recipient.call{value: amount}("");
            require(sent, "FAILED_SENDING_FUNDS");
        }
        emit DistributeETH(_msgSender(), bal);
    }

    function distributeTokens() public {
        require(feeRecipientCount > 0, "RECIPIENTS_NOT_SET");
        uint256 bal = IERC20(paymentToken).balanceOf(address(this));
        for (uint256 x = 1; x <= feeRecipientCount; x++) {
            uint256 amount = (bal * FeeRecipients[x].basisPoints) /
                totalFeeBasisPoints;
            amount = amount > address(this).balance
                ? address(this).balance
                : amount;
            IERC20(paymentToken).transfer(FeeRecipients[x].recipient, amount);
        }
        emit DistributeTokens(_msgSender(), bal);
    }

    function withdrawETH() public {
        require(
            _msgSender() == owner() ||
                _msgSender() == treasuryAddress ||
                proxyToApproved[_msgSender()],
            "NOT_ALLOWED"
        );
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        uint256 bal = address(this).balance;
        (bool sent, ) = treasuryAddress.call{value: bal}("");
        require(sent, "FAILED_SENDING_FUNDS");
        emit WithdrawETH(_msgSender(), bal);
    }

    function withdrawTokens(address _token) external nonReentrant {
        require(
            _msgSender() == owner() ||
                _msgSender() == treasuryAddress ||
                proxyToApproved[_msgSender()],
            "NOT_ALLOWED"
        );
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        IERC20(_token).safeTransfer(
            treasuryAddress,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function gift(address[] calldata receivers, uint256[] memory amounts)
        external
        onlyOwner
    {
        for (uint256 x = 0; x < receivers.length; x++) {
            for (uint256 i = 0; i < amounts[x]; i++) {
                _mint(receivers[x]);
            }
        }
    }

    function setDisableSalesWithETH(bool value) external onlyOwner {
        disableSalesWithETH = value;
    }

    function setDisableSalesWithToken(bool value) external onlyOwner {
        disableSalesWithToken = value;
    }

    function updateConfig(
        uint16 _maxMint,
        uint16 _maxPerMint,
        uint256 _price,
        uint16 _maxPerAddress,
        bool _saleActive,
        string calldata _uri,
        address _paymentToken,
        uint256 _priceWithToken
    ) external onlyOwner {
        maxMint = _maxMint + 1;
        maxMintForOne = _maxMint;
        maxMintForThree = _maxMint - 2;
        maxPerMint = _maxPerMint + 1;
        price = _price;
        priceForThree = _price * 3;
        maxPerAddress = _maxPerAddress > 0 ? _maxPerAddress : 0;
        maxPerAddressForThree = _maxPerAddress > 1 ? _maxPerAddress - 2 : 0;
        saleActive = _saleActive;
        _tokenBaseURI = _uri;
        paymentToken = _paymentToken;
        priceWithToken = _priceWithToken;
        priceForThreeWithToken = _priceWithToken * 3;
    }

    function updateToken(address _paymentToken, uint256 _priceWithToken)
        external
        onlyOwner
    {
        paymentToken = _paymentToken;
        priceWithToken = _priceWithToken;
        priceForThreeWithToken = _priceWithToken * 3;
    }

    /**** WHITELIST ****/

    function whitelistAdd(address[] calldata addresses) external onlyOwner {
        for (uint256 x; x < addresses.length; x++) {
            Whitelist[addresses[x]] = true;
        }
        emit WhitelistAdd(_msgSender(), addresses);
    }

    function whitelistRemove(address[] calldata addresses) external onlyOwner {
        for (uint256 x; x < addresses.length; x++) {
            Whitelist[addresses[x]] = false;
        }
        emit WhitelistRemove(_msgSender(), addresses);
    }

    function setWhitelistMax(uint256 value) external onlyOwner {
        require(value > 0, "AMOUNT=0");
        whitelistMax = value;
    }

    function setWhitelistSaleActive() external onlyOwner {
        whitelistEnabled = true;
        saleActive = true;
    }

    function setPublicSaleActive() external onlyOwner {
        whitelistEnabled = false;
        saleActive = true;
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setMaxPerMint(uint16 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function setMaxMint(uint16 maxMint_) external onlyOwner {
        maxMint = maxMint_ + 1;
        maxMintForOne = maxMint_;
        maxMintForThree = maxMint_ - 2;
    }

    function setMaxPerAddress(uint16 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress > 0 ? _maxPerAddress : 0;
        maxPerAddressForThree = _maxPerAddress > 1
            ? _maxPerAddress - 2
            : maxPerAddress;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        priceForThree = _price * 3;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    function isProxyToApproved(address proxyAddress)
        external
        view
        onlyOwner
        returns (bool)
    {
        return proxyToApproved[proxyAddress];
    }

    // ** - SETTERS - ** //

    function setVaultAddress(address addr) external onlyOwner {
        treasuryAddress = addr;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // ** - MISC - ** //

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setNftTypeContract(address value) external onlyOwner {
        nftTypeContract = value;
    }

    function setNftTypeToMint(uint32 value) external onlyOwner {
        nftTypeToMint = value;
    }

    function toggleUseBaseUri() external onlyOwner {
        useBaseUriOnly = !useBaseUriOnly;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenBaseURI;
    }

    function setTokenUri(uint256 tokenId, string calldata _uri)
        external
        onlyOwner
    {
        TokenURIMap[tokenId] = _uri;
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }
        return true;
    }

    function setTransferDisabled(bool _transferDisabled) external onlyOwner {
        transferDisabled = _transferDisabled;
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public override {
        require(
            !transferDisabled ||
                _msgSender() == owner() ||
                proxyToApproved[_msgSender()],
            "TRANSFER_DISABLED"
        );
        super.batchSafeTransferFrom(_from, _to, _tokenIds, data_);
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public override {
        require(
            !transferDisabled ||
                _msgSender() == owner() ||
                proxyToApproved[_msgSender()],
            "TRANSFER_DISABLED"
        );
        super.batchTransferFrom(_from, _to, _tokenIds);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            !transferDisabled ||
                _msgSender() == owner() ||
                proxyToApproved[_msgSender()],
            "TRANSFER_DISABLED"
        );
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            !transferDisabled ||
                _msgSender() == owner() ||
                proxyToApproved[_msgSender()],
            "TRANSFER_DISABLED"
        );
        super.transferFrom(from, to, tokenId);
    }

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()] == true, "onlyProxy");
        _;
    }

    function _mint(address recipient) private {
        _mintMin2(recipient);
        INftSales(nftTypeContract).mint(_msgSender(), nftTypeToMint);
    }

    event DistributeETH(address indexed sender, uint256 indexed balance);
    event DistributeTokens(address indexed sender, uint256 indexed balance);
    event WithdrawETH(address indexed sender, uint256 indexed balance);
    event WhitelistAdd(address indexed user, address[] indexed addresses);
    event WhitelistRemove(address indexed user, address[] indexed addresses);
}