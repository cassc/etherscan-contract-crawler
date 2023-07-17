// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract WayGate1155 is
    Initializable,
    ERC1155Upgradeable,
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

    string public name;

    string public symbol;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    function initialize() public initializer {
        __ERC1155_init("");
        __Pausable_init();
        __Ownable_init();
        _registerInterface(_INTERFACE_ID_ERC2981);
        priceFeed = AggregatorV3Interface(
            // 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0 // polygon Mainnet
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // Ethereum Mainnet
        );
        name = "WayGate1155";
        symbol = "WGATE";
    }

    modifier onlyMarketplace() {
        require(
            _msgSender() == MARKETPLACE_CONTRACT,
            "WayGate1155: Only Marketplace Contract can call"
        );
        _;
    }

    event NFTsCreated(
        address to,
        string uri,
        uint256 _royaltyPercentage,
        NftType _nftTypeStatus
    );

    mapping(uint256 => uint256) public nftTypeStatus;
    mapping(uint256 => string) tokenURI;

    // royalties
    mapping(uint256 => RoyaltyInfo) private royalties;
    mapping(bytes4 => bool) private _supportedInterfaces;

    function createNFT(
        address to,
        string memory _uri,
        uint256 copies,
        uint256 _royaltyPercentage,
        NftType _nftTypeStatus
    ) external payable whenNotPaused nonReentrant {
        uint256 feeInEth = getMaticPriceFromUsd();
        require(_nftTypeStatus != NftType.TYPE_NULL, "WayGate: Invalid Type");
        require(msg.value == feeInEth, "WayGateERC1155: Invalid Amount");
        require(
            MARKETPLACE_CONTRACT != address(0),
            "WayGate1155: Marketplace Contract Not Set"
        );
        require(
            _royaltyPercentage <= maxRoyaltyPercentage,
            "WayGate1155: Royalty Percentage > Max Royalty Percentage"
        );
        require(
            platformFeeReceiver != address(0),
            "WayGate1155: Zero Address Not Allowed"
        );
        safeMint(to, _uri, copies, _royaltyPercentage, _nftTypeStatus);

        if (feeInEth != 0) {
            payable(platformFeeReceiver).transfer(feeInEth);
        }
        setApprovalForAll(MARKETPLACE_CONTRACT, true);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(
        address to,
        string memory _uri,
        uint256 copies,
        uint256 _royaltyPercentage,
        NftType _nftTypeStatus
    ) internal whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId, copies, "");

        royalties[tokenId].receiver = to;
        royalties[tokenId].rate = _royaltyPercentage;

        nftTypeStatus[tokenId] = uint256(_nftTypeStatus);

        emit NFTsCreated(to, _uri, _royaltyPercentage, _nftTypeStatus);
        setURI(tokenId, _uri);
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
        override(ERC1155Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            _supportedInterfaces[interfaceId];
    }

    function setURI(uint256 _id, string memory _uri) private {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    function setMaxRoyaltyPercentage(
        uint256 _royaltyPercentage
    ) external onlyMarketplace {
        maxRoyaltyPercentage = _royaltyPercentage;
    }

    function setMarketplaceContract(
        address _marketplaceContract
    ) external onlyOwner {
        MARKETPLACE_CONTRACT = _marketplaceContract;
    }

    function setMintingFeeInUsd(uint256 _mintingFeeInUSD) external onlyOwner {
        MINTING_FEE_IN_USD = _mintingFeeInUSD;
    }

    function setPlatformFeeReceiverAddress(
        address _platformFeeReceiver
    ) external onlyOwner {
        platformFeeReceiver = _platformFeeReceiver;
    }

    function getMaticPriceFromUsd() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "WayGate1155: Invalid ETH price");

        uint eth_adjust_price = uint(price) * 1e10;
        uint256 usd = MINTING_FEE_IN_USD * 1e18;

        uint256 feeInEth = ((usd) * 1e18) / eth_adjust_price;
        return feeInEth;
    }

    function getRoyaltyPercentage(
        uint256 _tokenId
    ) external view returns (uint) {
        return royalties[_tokenId].rate;
    }

    function getCreator(uint256 _tokenId) external view returns (address) {
        return royalties[_tokenId].receiver;
    }

    function getMintingFeeInUsd() external view returns (uint256) {
        return MINTING_FEE_IN_USD;
    }

    function getNftTypeStatus(uint256 _tokenId) external view returns (uint) {
        return nftTypeStatus[_tokenId];
    }
}