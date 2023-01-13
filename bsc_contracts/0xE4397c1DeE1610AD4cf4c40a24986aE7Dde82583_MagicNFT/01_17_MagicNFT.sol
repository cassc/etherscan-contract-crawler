//SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./ERC721AUpgradeable.sol";
import "./MagicSigner.sol";

contract MagicNFT is
    MagicSigner,
    ERC721AUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    string public baseTokenURI;

    uint8 public maxWhiteListMintForEach;
    uint8 public maxPublicMintForEach;

    uint256 public MAX_SUPPLY;

    uint256 public whiteListPriceForEach;
    uint256 public publicMintPriceForEach;

    address public designatedSigner;
    address payable public treasure;

    uint256 public whiteListMinted;
    uint256 public publicMinted;
    uint256 public ownerMinted;

    bool public isWhiteListSale;
    bool public isPublicSale;

    uint96 public constant ROYALTY_PERCENT = 750;

    mapping(address => uint256) public whiteListSpotBought;
    mapping(address => uint256) public publicMintSpotBought;
    mapping(address => bool) public minters;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    uint256 public discountPercent;
    uint256 public discountStartTime;
    uint256 public discountDuration;
    uint256 public DISCOUNT_DIVIDER;
    uint256 public discountMinted;

    mapping(address => uint256) public vcInfo;

    modifier onlyMinter() {
        require(minters[msg.sender], "Invalid minter");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only wallet can call function");
        _;
    }

    modifier notOverMaxSupply(uint256 _amount) {
        require(_amount + totalSupply() <= MAX_SUPPLY, "Max Supply Limit Exceeded");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address treasure_,
        address designatedSigner_
    ) public initializer {
        require(designatedSigner_ != address(0), "Invalid designated signer address");
        require(treasure_ != address(0), "Invalid treasure address");

        __ReentrancyGuard_init();
        __MagicSigner_init();
        __ERC721A_init(name_, symbol_);
        __Ownable_init();

        maxWhiteListMintForEach = 1;
        maxPublicMintForEach = 1;

        isWhiteListSale = true;
        isPublicSale = false;

        MAX_SUPPLY = maxSupply_;

        treasure = payable(treasure_);
        designatedSigner = designatedSigner_;
        whiteListPriceForEach = 0.75 ether;
        publicMintPriceForEach = 0.75 ether;
    }

    function ownerMint(uint256 _amount) external onlyOwner notOverMaxSupply(_amount) {
        ownerMinted += _amount;
        _mint(_msgSender(), _amount);
    }

    function whiteListMint(WhiteList memory _whitelist, uint256 _amount)
        external
        payable
        nonReentrant
        notOverMaxSupply(_amount)
    {
        require(isWhiteListSale, "Whitelist sale is not open yet");
        require(getSigner(_whitelist) == designatedSigner, "Invalid Signature");
        require(_whitelist.userAddress == _msgSender(), "Not A Whitelisted Address");
        require(
            _amount + whiteListSpotBought[_whitelist.userAddress] <= maxWhiteListMintForEach,
            "Max WhiteList Spot Bought"
        );
        require(msg.value == _amount * whiteListPriceForEach, "Pay Exact Amount");
        whiteListMinted += _amount;
        whiteListSpotBought[_whitelist.userAddress] += _amount;

        for (uint256 i = _currentIndex; i <= _currentIndex + _amount; i++) {
            _setTokenRoyalty(i, msg.sender, ROYALTY_PERCENT);
        }

        _mint(_whitelist.userAddress, _amount);
    }

    function publicMint(uint256 _amount)
        external
        payable
        onlyEOA
        nonReentrant
        notOverMaxSupply(_amount)
    {
        require(isPublicSale, "Public sale is not open yet");

        uint256 mintPrice = publicMintPriceForEach;
        bool isVCSale = vcInfo[msg.sender] != 0;
        if (isVCSale) {
            // 15% percent discount for VC sale
            mintPrice = (mintPrice * 85) / 100;
            if (vcInfo[msg.sender] < _amount) _amount = vcInfo[msg.sender];

            require(msg.value == mintPrice * _amount, "Pay Exact Amount");
            publicMintSpotBought[_msgSender()] += _amount;
            publicMinted += _amount;
            vcInfo[msg.sender] -= _amount;
        } else {
            require(
                _amount + publicMintSpotBought[_msgSender()] <= maxPublicMintForEach,
                "Max Public Mint Spot Bought"
            );
            require(msg.value == mintPrice * _amount, "Pay Exact Amount");

            publicMintSpotBought[_msgSender()] += _amount;
            publicMinted += _amount;
        }

        // 10% discount by sending one more NFT per 10 NFTs
        if (!isVCSale) _amount += _amount / 10;

        for (uint256 i = _currentIndex; i <= _currentIndex + _amount; i++) {
            _setTokenRoyalty(i, msg.sender, ROYALTY_PERCENT);
        }

        _mint(_msgSender(), _amount);
    }

    function mint(address[] memory _account, uint256[] memory _amount)
        external
        nonReentrant
        onlyMinter
    {
        require(_account.length == _amount.length, "Invalid array length");

        for (uint256 i = 0; i < _account.length; i++) {
            require(totalSupply() + _amount[i] <= MAX_SUPPLY, "Token all minted");
            require(_account[i] != address(0), "Invalid receiver address");

            for (uint256 j = _currentIndex; j <= _currentIndex + _amount[i]; j++) {
                _setTokenRoyalty(j, _account[i], ROYALTY_PERCENT);
            }

            _mint(_account[i], _amount[i]);
        }
    }

    ///@dev withdraw funds from contract to treasure
    function withdraw() external onlyOwner {
        require(treasure != address(0), "Treasure address not set");
        treasure.transfer(address(this).balance);
    }

    function setBaseURI(string memory baseURI_) public onlyMinter {
        require(bytes(baseURI_).length > 0, "Invalid base URI");
        baseTokenURI = baseURI_;
    }

    function setTreasure(address _treasure) external onlyOwner {
        require(_treasure != address(0), "Invalid address for signer");
        treasure = payable(_treasure);
    }

    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address for signer");
        designatedSigner = _signer;
    }

    function setVCInfo(address _vcAccount, uint256 _amount) external onlyOwner {
        require(_vcAccount != address(0), "Invalid address for vc account");
        vcInfo[_vcAccount] = _amount;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    /////////////////
    /// Set Price ///
    /////////////////

    function setPublicMintPriceForEach(uint256 _price) external onlyOwner {
        publicMintPriceForEach = _price;
    }

    function setWhitelistPriceForEach(uint256 _price) external onlyOwner {
        whiteListPriceForEach = _price;
    }

    ////////////////////
    /// Set Discount ///
    ////////////////////
    function setDiscountPercent(uint256 _percent) external onlyOwner {
        require(_percent < DISCOUNT_DIVIDER, "Invalid percent");
        discountPercent = _percent;
    }

    function setDiscountStartTime(uint256 _timestamp) external onlyOwner {
        require(_timestamp >= block.timestamp, "Invalid start time");
        discountStartTime = _timestamp;
    }

    function setDiscountDuration(uint256 _durationInDay) external onlyOwner {
        discountDuration = _durationInDay * 3600 * 24;
    }

    function setDiscountMaxDivider() external onlyOwner {
        DISCOUNT_DIVIDER = 10000;
    }

    ///////////////
    /// Set Max ///
    ///////////////

    function setMaxWhiteListMintForEach(uint8 _amount) external onlyOwner {
        maxWhiteListMintForEach = _amount;
    }

    function setMaxPublicMintForEach(uint8 _amount) external onlyOwner {
        maxPublicMintForEach = _amount;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        require(MAX_SUPPLY >= totalSupply(), "Invalid max supply number");
        MAX_SUPPLY = amount;
    }

    function setMinter(address _account, bool _isMinter) external onlyOwner {
        minters[_account] = _isMinter;
    }

    ///@dev Toggle contract pause
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    ///@dev set public sale
    function setPublicSale(bool _isOpen) external onlyOwner {
        require(isPublicSale != _isOpen, "Your value is the same with current one");
        isPublicSale = _isOpen;
    }

    ///@dev set whitelist sale
    function setWhiteSale(bool _isOpen) external onlyOwner {
        require(isWhiteListSale != _isOpen, "Your value is the same with current one");
        isWhiteListSale = _isOpen;
    }

    ///@dev Override Function
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    ///////////////
    /// Royalty ///
    ///////////////

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}