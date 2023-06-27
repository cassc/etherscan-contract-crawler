// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract WayGate721 is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    IERC2981Upgradeable,
    ReentrancyGuardUpgradeable
{
    enum NftType {
        TYPE_NULL,
        TYPE_2D,
        TYPE_3D
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    AggregatorV3Interface internal priceFeed;

    struct RoyaltyInfo {
        address receiver;
        uint rate;
    }

    uint256 private maxRoyaltyPercentage;

    uint256 MINTING_FEE_IN_USD;

    address MARKETPLACE_CONTRACT;
    address platformFeeReceiver;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    mapping(bytes4 => bool) private _supportedInterfaces;

    mapping(uint256 => uint256) nftTypeStatus;

    mapping(uint256 => RoyaltyInfo) private royalties;

    mapping(uint256 => bool) whiteListTokenIdStatus;
    mapping(uint256 => bool) specialNftTokenIdStatus;
    mapping(address => bool) whiteListAddresses;
    mapping(address => bool) adminAddresses;
    mapping(uint256 => address) airdropOwners;
    mapping(address => uint256) tokenIds;

    uint256[] whiteListTokenIds;

    event NftCreated(
        address to,
        string uri,
        uint256 _royaltyPercentage,
        NftType _nftTypeStatus
    );

    modifier onlyMarketplace() {
        require(
            _msgSender() == MARKETPLACE_CONTRACT,
            "WayGate721: Only Marketplace Contract can call"
        );
        _;
    }

    function initialize() public initializer {
        __ERC721_init("WayGate721", "WGATE");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        _registerInterface(_INTERFACE_ID_ERC2981);
        // priceFeed = AggregatorV3Interface(
        //     // 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0    // polygon Mainnet
        //     // 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // Ethereum Mainnet
        //     // 0x694AA1769357215DE4FAC081bf1f309aDC325306 // Sepolia Testnet
        //     // 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada // mumbai Testnet
        // );
    }

    function addToWhiteList(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "WayGate721: Cannot add zero address");
            require(
                !whiteListAddresses[entry],
                "WayGate721: Cannot add duplicate address"
            );

            whiteListAddresses[entry] = true;
        }
    }

    function removeWhiteListAddresses(address entry) external onlyOwner {
        require(entry != address(0), "WayGate721: Zero address");
        require(
            tokenIds[entry] == 0,
            "WayGate721: WayGate721: Airdrop NFT Holder: Not Allowed To Remove"
        );
        delete whiteListAddresses[entry];
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = royalties[_tokenId].receiver;
        if (
            royalties[_tokenId].rate > 0 &&
            royalties[_tokenId].receiver != address(0)
        ) {
            royaltyAmount = (_salePrice * royalties[_tokenId].rate) / 1000;
        }
    }

    function createAirdropNFT(
        address to,
        string memory _uri,
        NftType _nftTypeStatus
    ) external payable whenNotPaused {
        require(
            tokenIds[_msgSender()] == 0 &&
                whiteListAddresses[_msgSender()] == true,
            "WayGate Airdrop: Not Allowed to Mint The NFT"
        );
        _createNFT(to, _uri, 0, _nftTypeStatus);

        uint256 tokenId = _tokenIdCounter.current();
        whiteListTokenIdStatus[tokenId] = true;
        tokenIds[_msgSender()] = tokenId;
        airdropOwners[tokenId] = to;
        whiteListTokenIds.push(tokenId);
    }

    function createSpecialNFT(
        address to,
        string memory _uri,
        uint256 _royaltyPercentage,
        NftType _nftTypeStatus
    ) external payable whenNotPaused {
        require(
            adminAddresses[_msgSender()],
            "WayGate721: : Only Admin Allowed"
        );
        _createNFT(to, _uri, _royaltyPercentage, _nftTypeStatus);

        uint256 tokenId = _tokenIdCounter.current();
        specialNftTokenIdStatus[tokenId] = true;
    }

    function createNFT(
        address to,
        string memory _uri,
        uint256 _royaltyPercentage,
        NftType _nftTypeStatus
    ) external payable whenNotPaused {
        _createNFT(to, _uri, _royaltyPercentage, _nftTypeStatus);
    }

    function setAdminWallet(
        address[] calldata adminWallets
    ) external onlyOwner {
        for (uint256 i = 0; i < adminWallets.length; i++) {
            address admin = adminWallets[i];
            require(admin != address(0), "WayGate721: Cannot add zero address");
            require(
                !adminAddresses[admin],
                "WayGate721: Cannot add duplicate address"
            );
            adminAddresses[admin] = true;
        }
    }

    function removeAdminAddresses(address _adminWallet) external onlyOwner {
        require(_adminWallet != address(0), "WayGate721: Zero address");
        delete adminAddresses[_adminWallet];
    }

    function _createNFT(
        address _to,
        string memory _uri,
        uint256 _royaltyPercentage,
        NftType _nftTypeStatus
    ) internal nonReentrant {
        // uint256 feeInEth = getMaticPriceFromUsd();
        require(
            _nftTypeStatus != NftType.TYPE_NULL,
            "WayGate: Invalid Type"
        );
        require(msg.value == mintFee, "WayGate721: Invalid Amount");
        require(
            MARKETPLACE_CONTRACT != address(0),
            "WayGate721: Please set Marketplace Contract"
        );
        require(
            _royaltyPercentage <= maxRoyaltyPercentage,
            "WayGate721: Royalty Percentage > Max Royalty Percentage"
        );
        require(
            platformFeeReceiver != address(0),
            "WayGate721: Zero Address Not Allowed"
        );
        safeMint(_to, _uri, _royaltyPercentage, _nftTypeStatus);

        setApprovalForAll(MARKETPLACE_CONTRACT, true);
        emit NftCreated(_to, _uri, _royaltyPercentage, _nftTypeStatus);
        if (mintFee != 0) {
            payable(platformFeeReceiver).transfer(mintFee);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(
        address to,
        string memory uri,
        uint256 _royaltyPercentage,
        NftType _nftTypeStatus
    ) internal whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        royalties[tokenId].receiver = to;
        royalties[tokenId].rate = _royaltyPercentage;

        nftTypeStatus[tokenId] = uint(_nftTypeStatus);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) {
        super.transferFrom(from, to, tokenId);
        setAirdropOwners(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId);
        setAirdropOwners(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId, data);
        setAirdropOwners(tokenId);
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            _supportedInterfaces[interfaceId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        whenNotPaused
    {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setMaxRoyaltyPercentage(
        uint256 _royaltyPercentage
    ) external onlyMarketplace {
        maxRoyaltyPercentage = _royaltyPercentage;
    }

    function setMintingFeeInUsd(uint256 _mintingFeeInUSD) public onlyOwner {
        MINTING_FEE_IN_USD = _mintingFeeInUSD;
    }

    function setMarketplaceContract(
        address _marketplaceContract
    ) external onlyOwner {
        MARKETPLACE_CONTRACT = _marketplaceContract;
    }

    function setAirdropOwners(uint256 _tokenId) internal {
        address airDropTokenIdOwner = ownerOf(_tokenId);
        if (airDropTokenIdOwner != MARKETPLACE_CONTRACT) {
            airdropOwners[_tokenId] = airDropTokenIdOwner;
        }
    }

    function setPlatformFeeReceiverAddress(
        address _platformFeeReceiver
    ) external onlyOwner {
        platformFeeReceiver = _platformFeeReceiver;
    }

    function getWhitelistTokenIdStatus(
        uint256 _tokenId
    ) external view returns (bool) {
        return whiteListTokenIdStatus[_tokenId];
    }

    function getSpecialNftTokenIdStatus(
        uint256 _tokenId
    ) external view returns (bool) {
        return specialNftTokenIdStatus[_tokenId];
    }

    function getWhiteListTokenIds() external view returns (uint256[] memory) {
        return whiteListTokenIds;
    }

    function getMaticPriceFromUsd() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "WayGate721: Invalid ETH price");

        uint eth_adjust_price = uint(price) * 1e10;
        uint256 usd = MINTING_FEE_IN_USD * 1e18;
        uint256 feeInEth = ((usd) * 1e18) / eth_adjust_price;
        return feeInEth;
    }

    function getMintingFeeInUsd() public view returns (uint256) {
        return MINTING_FEE_IN_USD;
    }

    function getRoyaltyPercentage(uint256 _tokenId) public view returns (uint) {
        return royalties[_tokenId].rate;
    }

    function getCreator(uint256 _tokenId) public view returns (address) {
        return royalties[_tokenId].receiver;
    }

    function getErc721airdropTokenIdOwner(
        uint _tokenId
    ) external view returns (address) {
        return airdropOwners[_tokenId];
    }

    function getNftTypeStatus(uint256 _tokenId) public view returns (uint) {
        return nftTypeStatus[_tokenId];
    }

    uint public mintFee;
    function setMintFee(uint _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }
}