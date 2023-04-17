// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//              ,ggg,                                                                                         ,gggggggggggg,
//            dP""8I   ,dPYb,                                          I8                                   dP"""88""""""Y8b,
//           dP   88   IP'`Yb                                          I8                                   Yb,  88       `8b,
//          dP    88   I8  8I                                    gg 88888888                                 `"  88        `8b gg                 gg
//         ,8'    88   I8  8'                                    ""    I8                                        88         Y8 ""                 ""
//         d88888888   I8 dP    ,gggg,gg    ,ggggg,   ,gggggg,   gg    I8    ,ggg,,ggg,,ggg,     ,ggggg,         88         d8 gg      ggg    gg  gg    ,ggg,,ggg,     ,ggggg,
//   __   ,8"     88   I8dP    dP"  "Y8I   dP"  "Y8gggdP""""8I   88    I8   ,8" "8P" "8P" "8,   dP"  "Y8ggg      88        ,8P 88     d8"Yb   88bg88   ,8" "8P" "8,   dP"  "Y8ggg
//  dP"  ,8P      Y8   I8P    i8'    ,8I  i8'    ,8I ,8'    8I   88   ,I8,  I8   8I   8I   8I  i8'    ,8I        88       ,8P' 88    dP  I8   8I  88   I8   8I   8I  i8'    ,8I
//  Yb,_,dP       `8b,,d8b,_ ,d8,   ,d8I ,d8,   ,d8',dP     Y8,_,88,_,d88b,,dP   8I   8I   Yb,,d8,   ,d8'        88______,dP'_,88,_,dP   I8, ,8I_,88,_,dP   8I   Yb,,d8,   ,d8'
//   "Y8P"         `Y88P'"Y88P"Y8888P"888P"Y8888P"  8P      `Y88P""Y88P""Y88P'   8I   8I   `Y8P"Y8888P"         888888888P"  8P""Y88"     "Y8P" 8P""Y88P'   8I   `Y8P"Y8888P"
//                                  ,d8I'
//                                ,dP'8I
//                               ,8"  8I
//                               I8   8I
//                               `8, ,8I
//                                `Y8P"

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract DVN is ERC721, ERC721URIStorage, ERC721Enumerable, ERC721Royalty, Ownable, DefaultOperatorFilterer, PaymentSplitter, ChainlinkClient {
    error InvalidPrice(address emitter);
    error SaleNotStarted(address emitter);
    error SoldOut(address emitter);
    error EtherTransferFail(address emitter);

    event Sold(address indexed to, uint256 price, uint256 tokenId);
    event MetadataUpdate(uint256 _tokenId);
    event StableDilutionMetadataRequested(uint256 _tokenId);
    event StableDilutionMetadataReceived(uint256 _tokenId);
    event PermanentURI(string _value, uint256 indexed _id);

    using Strings for uint256;
    using Chainlink for Chainlink.Request;

    uint256 private constant STARTING_INDEX = 1;
    uint256 public constant MAX_SUPPLY = 333;
    uint256 public constant AUCTION_PRICE_CHANGE_TIME = 10 minutes;
    uint256[] public AUCTION_PRICES = [0.69 ether, 0.51 ether, 0.38 ether, 0.28 ether, 0.21 ether, 0.15 ether, 0.11 ether];

    bool metadataFrozen = false;
    bool preminted = false;
    uint256 private currentMintTokenId = STARTING_INDEX;

    string public placeholderTokenUri;
    uint256 public saleStartTime;

    bytes32 private jobId;
    uint256 private fee;

    mapping(bytes32 => uint256) requestToTokenId;

    struct ChainlinkInformation {
        address chainlinkToken;
        address chainlinkOracle;
        bytes32 jobId;
        uint256 fee;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _placeholderTokenUri,
        uint256 _saleStartTime,
        address _royalReceiver,
        uint96 _royalFeeNumerator,
        address[] memory payees,
        uint256[] memory shares_,
        ChainlinkInformation memory chainlinkInformation
    ) payable ERC721(_name, _symbol) PaymentSplitter(payees, shares_) {
        placeholderTokenUri = _placeholderTokenUri;
        saleStartTime = _saleStartTime;

        if (_royalReceiver != address(0)) {
            _setDefaultRoyalty(_royalReceiver, _royalFeeNumerator);
        }

        setChainlinkToken(chainlinkInformation.chainlinkToken);
        setChainlinkOracle(chainlinkInformation.chainlinkOracle);
        jobId = chainlinkInformation.jobId;
        fee = chainlinkInformation.fee;
    }

    function preMint(address to) public onlyOwner {
        if (totalSupply() >= MAX_SUPPLY) revert SoldOut(address(this));
        require(!preminted, "Only one premint is allowed");
        preminted = true;
        mintInternal(to);
    }

    function mint() public payable {
        if (totalSupply() >= MAX_SUPPLY) revert SoldOut(address(this));
        if (block.timestamp < saleStartTime) {
            revert SaleNotStarted(address(this));
        }

        uint256 price = currentPrice();
        if (msg.value != price) revert InvalidPrice(address(this));

        emit Sold(msg.sender, price, currentMintTokenId);
        mintInternal(msg.sender);
    }

    function setLinkFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function mintInternal(address to) private {
        _safeMint(to, currentMintTokenId);
        requestStableDilutionMetadata(currentMintTokenId, to);
        _setTokenURI(currentMintTokenId, placeholderTokenUri);
        ++currentMintTokenId;
    }

    function currentPrice() public view returns (uint256) {
        if (block.timestamp < saleStartTime)
            return AUCTION_PRICES[0];

        uint256 index = (block.timestamp - saleStartTime) / AUCTION_PRICE_CHANGE_TIME;
        uint256 priceIndex = index >= AUCTION_PRICES.length ? AUCTION_PRICES.length - 1 : index;
        return AUCTION_PRICES[priceIndex];
    }

    function auctionPrices() public view returns (uint256[] memory) {
        uint256 priceCount = AUCTION_PRICES.length;
        uint256[] memory _prices = new uint256[](priceCount);
        for (uint256 i; i < priceCount; ++i) {
            _prices[i] = AUCTION_PRICES[i];
        }
        return _prices;
    }

    function requestStableDilutionMetadata(uint256 tokenId, address to) public returns (bytes32 requestId) {
        emit StableDilutionMetadataRequested(tokenId);

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add(
            "get",
                string(abi.encodePacked("https://www.stable-dilution.art/nft/item/generation/6/", Strings.toString(tokenId), "/", Strings.toHexString(uint256(uint160(to)), 20)))
        );

        req.add("path", "metadataUrl");
        requestId = sendChainlinkRequest(req, fee);
        requestToTokenId[requestId] = tokenId;
    }

    function fulfill(
        bytes32 _requestId,
        string memory _metadataUri
    ) public virtual recordChainlinkFulfillment(_requestId) {

        uint256 tokenId = requestToTokenId[_requestId];
        emit StableDilutionMetadataReceived(tokenId);
        _setTokenURI(tokenId, _metadataUri);
        emit MetadataUpdate(tokenId);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function setSaleStartTime(uint256 _saleStartTime) public onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function freezeMetadata() public onlyOwner() {
        require(metadataFrozen == false, "Metadata already frozen");
        metadataFrozen = true;
        for (uint256 i = STARTING_INDEX; i <= totalSupply(); ++i) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    function setTokenUri(uint256[] calldata tokenIds, string[] calldata _metadataUris) public onlyOwner {
        require(metadataFrozen == false, "Metadata frozen");
        require(tokenIds.length == _metadataUris.length, "Arrays need to be same size");
        for(uint256 i=0;i<tokenIds.length;i++) {
            _setTokenURI(tokenIds[i], _metadataUris[i]);
            emit MetadataUpdate(tokenIds[i]);
        }
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function _beforeTokenTransfer(address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Royalty, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}