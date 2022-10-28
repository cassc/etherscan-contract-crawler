// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/IUniswapRouterV2.sol";
import "./helpers/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title A PlanetexToken, symbol TPTX

contract NFTPlanetex is ERC721A, Ownable, ReentrancyGuard {
    struct TokenMetaData {
        string uri;
    }

    using Address for address;
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    IUniswapV2Router public swapRouter;

    string private baseUri; // nft token base Uri
    uint256 public totalSupplyNFT; // the maximum amount of mint
    uint256 public totalMinted; // how many tokens at the moment
    uint256 public purchasePrice; // nft token purchase price
    uint256 public saleStartTime; // nft sale start time
    address public usdt; // usdt or busd address
    address public proccedsRecipient; // procceds recipient wallet address
    address[] public path; // path for get price eth or bnb
    uint256[] public distributionCount; // distribution count NFT
    uint256[] public countAvailableNFT; // available count NFT

    mapping(uint256 => TokenMetaData) public tokenMetaDatas; // token metadata by id
    mapping(uint256 => TokenMetaData) public characters; // nft token types

    //// @dev - unequal length of arrays
    error InvalidArrayLengths(string err);
    /// @dev - address to the zero;
    error ZeroAddress(string err);
    /// @dev - amount to the zero;
    error ZeroNumber(string err);
    /// @dev - sold out
    error SoldOut(string err);
    /// @dev - Non exist token
    error NonExistToken(string err);
    /// @dev - Not enough purchase tokens
    error NotEnough(string err);
    /// @dev - failed to sent ether
    error FailedSentEther(string err);
    /// @dev - sale not started
    error SaleNotStarted(string err);

    event SetBaseURI(string indexed baseURI);
    event UpdatePurchasePrice(uint256 indexed newPurchasePrice);
    event BuyNFT(
        uint256 indexed tokenId,
        uint256 indexed tokenType,
        string uri
    );
    event UpdateURI(uint256 tokenId, string newUri);
    event UpdateSaleStart(uint256 newStartTime);

    constructor(
        uint256 totalSupply_, // nft tokens total supply
        uint96 fee_, // royalty fee percent
        uint256 purchasePrice_, // purchase price
        uint256 saleStartTime_, // sale start time
        address swapRouter_, // swap router address
        address usdt_, // usdt or busd token address
        address proccedsRecipient_, // procceds recipient wallet address
        string memory baseUri_, // base uri string
        uint256[] memory distributionCount_, // distribution count array
        uint256[] memory countAvailableNFT_, // count available for mint array
        string[] memory charactersUris_ // array of characters uris
    ) ERC721A("PlanetexNFT", "PLTEX") {
        if (
            distributionCount_.length != countAvailableNFT_.length ||
            distributionCount_.length != charactersUris_.length
        ) {
            revert InvalidArrayLengths("TPTX: Invalid array lengths");
        }

        if (
            usdt_ == address(0) ||
            swapRouter_ == address(0) ||
            proccedsRecipient_ == address(0)
        ) {
            revert ZeroAddress("TPTX: Zero Address");
        }
        if (purchasePrice_ == 0 || totalSupply_ == 0) {
            revert ZeroNumber("TPTX: Zero Number");
        }
        _setDefaultRoyalty(owner(), fee_);
        totalSupplyNFT = totalSupply_;
        baseUri = baseUri_;
        swapRouter = IUniswapV2Router(swapRouter_);
        usdt = usdt_;
        proccedsRecipient = proccedsRecipient_;
        purchasePrice = purchasePrice_;
        saleStartTime = saleStartTime_;
        distributionCount = distributionCount_;
        countAvailableNFT = countAvailableNFT_;
        for (uint256 i; i <= charactersUris_.length - 1; i++) {
            TokenMetaData storage charactersInfo = characters[i];
            charactersInfo.uri = charactersUris_[i];
        }

        address[] memory _path = new address[](2);
        _path[0] = IUniswapV2Router(swapRouter_).WETH();
        _path[1] = usdt_;
        path = _path;
    }

    receive() external payable {}

    //================================ External functions ========================================

    /**
    @dev The function performs the purchase of nft tokens for usdt or busd tokens
    */
    function buyForErc20() external {
        if (totalMinted == totalSupplyNFT) {
            revert SoldOut("TPTX: All sold out");
        }
        if (!isSaleStarted()) {
            revert SaleNotStarted("TPTX: Sale not started");
        }
        if (IERC20(usdt).balanceOf(msg.sender) < purchasePrice) {
            revert NotEnough("TPTX: Not enough tokens");
        }

        IERC20(usdt).safeTransferFrom(
            msg.sender,
            proccedsRecipient,
            purchasePrice
        );

        _mintAndSetMetaData(msg.sender);
    }

    /**
    @dev The function performs the purchase of nft tokens for eth or bnb tokens
    */
    function buyForEth() external payable nonReentrant {
        if (totalMinted == totalSupplyNFT) {
            revert SoldOut("TPTX: All sold out");
        }

        if (!isSaleStarted()) {
            revert SaleNotStarted("TPTX: Sale not started");
        }

        uint256 ethAmount = msg.value;

        uint256[] memory amounts = swapRouter.getAmountsIn(purchasePrice, path);
        if (ethAmount < amounts[0]) {
            revert NotEnough("TPTX: Not enough tokens");
        }
        (bool sent, ) = proccedsRecipient.call{value: amounts[0]}("");
        if (!sent) {
            revert FailedSentEther("Failed to send Ether");
        }
        if (ethAmount > amounts[0]) {
            uint256 turnBackValue = ethAmount - amounts[0];
            (bool sentBack, ) = msg.sender.call{value: turnBackValue}("");
            if (!sentBack) {
                revert FailedSentEther("Failed to send Ether");
            }
        }
        _mintAndSetMetaData(msg.sender);
    }

    /** 
    @dev The function mints the nft token and sets its metadata. Only owner can call it.
    @param to - recipient wallet address
     */
    function mint(address to) external onlyOwner {
        _mintAndSetMetaData(to);
    }

    /** 
    @dev The function updates the purchase price of the nft token. Only owner can call it.
    @param newPrice new purchase price
     */
    function updatePurchasePrice(uint256 newPrice) external onlyOwner {
        purchasePrice = newPrice;
        emit UpdatePurchasePrice(newPrice);
    }

    /** 
    @dev Sets the royalty information that all ids in this contract will default to. 
    Only owner can call it.
    @param receiver procceds fee recipient
    @param feeNumerator fee percent 
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     * Only owner can call it.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Removes royalty information for a specific token id.
     */
    function deleteTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev function sets the base URI. Only owner can call it.
     * @param baseURI_ - new baseURI
     */
    function setBaseURI(string memory baseURI_) external virtual onlyOwner {
        baseUri = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    /**
     * @dev This function updates the uri for a specific token.
     * Only owner can call it.
     * @param tokenId - token id
     * @param uri - new token uri
     */
    function updateURI(uint256 tokenId, string memory uri) public onlyOwner {
        TokenMetaData storage metaData = tokenMetaDatas[tokenId];
        metaData.uri = uri;
        emit UpdateURI(tokenId, uri);
    }

    /**
     * @dev This function performs a batch update of the token uri.
     * Only owner can call it.
     * @param tokenIds - array of token ids
     * @param urls - array of token uris
     */
    function updateUriBatch(uint256[] memory tokenIds, string[] memory urls)
        public
        onlyOwner
    {
        if (tokenIds.length != urls.length) {
            revert InvalidArrayLengths("TPTX: Invalid array lengths");
        }
        for (uint256 i; i < tokenIds.length; i++) {
            TokenMetaData storage metaData = tokenMetaDatas[tokenIds[i]];
            metaData.uri = urls[i];
            emit UpdateURI(tokenIds[i], urls[i]);
        }
    }

    /**
     * @dev The function updates the date of the start of the sale of nft tokens.
     * Only owner can call it.
     * @param newStartTime - new start time timestamp
     */
    function updateSaleStartTime(uint256 newStartTime) external onlyOwner {
        saleStartTime = newStartTime;
        emit UpdateSaleStart(newStartTime);
    }

    //=================== Public functions ================================

    /**
     * @dev The ETH amount equal purchase price.
     */

    function getEthPurchaseAmount() public view returns (uint256) {
        uint256[] memory amounts = swapRouter.getAmountsIn(purchasePrice, path);
        return amounts[0];
    }

    /**
     * @dev The function returns true if the token sale has started, false if not.
     */
    function isSaleStarted() public view returns (bool) {
        return block.timestamp >= saleStartTime;
    }

    /**
     * @dev The function returns the number of tokens created.
     */
    function totalSupply() public view virtual returns (uint256) {
        return totalMinted;
    }

    /**
     * @dev The getter function returns an array with a distribution of nft tokens and their types
     */
    function getDistributionCount() public view returns (uint256[] memory) {
        return distributionCount;
    }

    /**
     * @dev The getter function returns an array of free tokens with their types that can still be obtained
     */
    function getAvailableCount() public view returns (uint256[] memory) {
        return countAvailableNFT;
    }

    /**
     * @dev return base uri for nft tokens
     */
    function baseURI() public view virtual returns (string memory) {
        return baseUri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert NonExistToken("TPTX: URI query for nonexistent token");
        }
        string memory _tokenURI = tokenMetaDatas[tokenId].uri;
        string memory base = baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return string(abi.encodePacked(base, tokenId.toString()));
    }

    //======================== Internal functions =====================================

    /**
     * @dev Mints `tokenId` and transfers it to `to` and set token metadata.
     */
    function _mintAndSetMetaData(address to) internal {
        uint256 nftType = _checkEmptyNFT();
        totalMinted++;
        TokenMetaData storage character = characters[nftType];
        TokenMetaData storage mintedNft = tokenMetaDatas[totalMinted];
        _mint(to, totalMinted);
        _saveDistributionCount(nftType);
        mintedNft.uri = character.uri;
        emit BuyNFT(totalMinted, nftType, mintedNft.uri);
    }

    /**
     * @dev This function performs semi-randomization in order to distribute
     * different types of nft between minters.
     * @param modul - maximum value for random
     */
    function _randomCount(uint256 modul) internal view returns (uint256) {
        if (modul == 0) {
            return 0;
        } else {
            uint256 random = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.coinbase,
                        block.difficulty,
                        block.gaslimit,
                        block.timestamp
                    )
                )
            ) % modul;
            return random;
        }
    }

    /**
     * @dev This function checks for mint-free NFT types before the random is called.
     */
    function _checkEmptyNFT() internal view returns (uint256) {
        uint256[] memory availableArr = new uint256[](distributionCount.length);
        uint8 insertIndex;
        for (uint256 i = 0; i < distributionCount.length; i++) {
            if (distributionCount[i] < countAvailableNFT[i]) {
                availableArr[insertIndex] = i;
                ++insertIndex;
            }
        }
        uint256 freeCount = _randomCount(insertIndex);
        return availableArr[freeCount];
    }

    /**
     * @dev This function updates information about NFT tokens available to the Mint.
     */
    function _saveDistributionCount(uint256 number) internal {
        distributionCount[number] += 1;
    }
}