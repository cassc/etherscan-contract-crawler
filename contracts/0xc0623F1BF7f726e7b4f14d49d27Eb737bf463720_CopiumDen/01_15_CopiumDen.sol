// SPDX-License-Identifier: UNLICENSE
// Creator: 0xYeety; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet; 1 cope = 1 cope
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721Storage.sol";
import "./ENSResolver.sol";
import "./RoyaltyReceiver.sol";

////--------------------------------------------------------------------||||
////--------------------------------------------------------------------||||
////    ________    ____  __    __    ____     ____     _____   _____   ||||
////   ||  ||  ||  ||  ||  \\  //    //   \   //  \\   ||   \\ ||       ||||
////   ||  ||  ||  ||__||   \\//    //       //    \\  ||___// ||___    ||||
////   ||  ||  ||  ||  ||   //\\    \\       \\    //  ||      ||       ||||
////   ||      ||  ||  || _//  \\_   \\___/   \\__//   ||      ||____   ||||
////____________________________________________________________________||||
////____________________________________________________________________||||

contract CopiumDen is Ownable, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    string public PROVENANCE;
    bool provenanceSet;

    string private contractURI_;

    uint256 public mintPrice;
    uint256 public maxPossibleSupply;
    uint256 public maxAllowedMints;

    uint256 royaltyBasisPoints;

    address public immutable currency;
    address public immutable wrappedNativeCoinAddress;

    RoyaltyReceiver royaltyReceiver;
    ENSResolver resolver;
    ERC721Storage storageLayer;

    address private signerAddress;

    bool public _metadataFrozen = false;

    mapping(address => bool) public agreements;
    uint256 numAgreements = 0;

    enum MintStatus {
        NotStarted,
        Public,
        Finished
    }

    MintStatus public mintStatus = MintStatus.NotStarted;

    uint256 numPayees;
    mapping(uint256 => address) private indexer;
    mapping(address => uint256) public earningsSplit;
    mapping(address => uint256) public balances;

    //////////

    mapping(uint256 => mapping(address => uint256)) public listings;

    struct OfferData {
        string openBrk;
        address addr;
        uint256 offer;
        uint256 pos;
        string closeBrk;
    }
    mapping(uint256 => mapping(address => uint256)) public offers;
    mapping(uint256 => mapping(uint256 => address)) public offerAddressPositions;
    mapping(uint256 => uint256) public offerCounts;

    event Sale(address _from, address _to, uint256 _price);


    /**
     * @dev Throws if called by any account other than a royalty receiver/payee.
     */
    modifier onlyPayee() {
        _isPayee();
        _;
    }

    /**
     * @dev Throws if the sender is not on the royalty receiver/payee list.
     */
    function _isPayee() internal view virtual {
        require(earningsSplit[_msgSender()] > 0, "not a royalty payee");
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxPossibleSupply,
        uint256 _mintPrice,
        uint256 _royaltyBasisPoints,
        uint256 _maxAllowedMints,
        address _currency,
        address _wrappedNativeCoinAddress,
        address _royaltyReceiverAddress,
        address[] memory payees,
        uint256[] memory percentages
    ) {
        require(payees.length == percentages.length, "length mismatch");
        numPayees = payees.length;
        for (uint i = 0; i < numPayees; i++) {
            indexer[i] = payees[i];
            earningsSplit[payees[i]] = percentages[i];
        }
        maxPossibleSupply = _maxPossibleSupply;
        mintPrice = _mintPrice;
        royaltyBasisPoints = _royaltyBasisPoints;
        maxAllowedMints = _maxAllowedMints;
        currency = _currency;
        wrappedNativeCoinAddress = _wrappedNativeCoinAddress;

        resolver = new ENSResolver();

        storageLayer = new ERC721Storage(
            _name,
            _symbol,
            _maxAllowedMints,
            _mintPrice,
            _maxPossibleSupply,
            _currency,
            _wrappedNativeCoinAddress
        );

        royaltyReceiver = RoyaltyReceiver(payable(_royaltyReceiverAddress));
    }

    function _ENSResolverAddress() public view returns (address) {
        return address(resolver);
    }

    function _ERC721StorageAddress() public view returns (address) {
        return address(storageLayer);
    }

    function _RoyaltyReceiverAddress() public view returns (address) {
        return address(royaltyReceiver);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI_ = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    function freezeMetadata() public onlyOwner {
        _metadataFrozen = true;
    }

    function metadataFrozen() public view returns (bool) {
        return _metadataFrozen;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!_metadataFrozen, "mf");
        storageLayer._setBaseURI(baseURI);
    }

    function revealMetadata() public onlyOwner {
        storageLayer._revealMetadata();
    }

    function changeMintStatus(MintStatus _status) external onlyOwner {
        require(_status != MintStatus.NotStarted && mintStatus != MintStatus.NotStarted);
        mintStatus = _status;
    }

    function agreeToMint() external onlyPayee {
        require(!(agreements[msg.sender]), "already agreed");
        agreements[msg.sender] = true;
        numAgreements += 1;
        if (numAgreements == numPayees) {
            mintStatus = MintStatus.Public;
        }
    }

    function giftMint(uint amount, address to) public payable {
        _mint(amount, address(msg.sender), to);
    }

    function giftMintENS(uint amount, string memory ENSAddr) public payable {
        address to = resolver.resolve(ENSAddr);
        _mint(amount, address(msg.sender), to);
    }

    function mintPublic(uint amount) public payable {
        _mint(amount, address(0), address(msg.sender));
    }

    function _mint(uint _amount, address _from, address _to) internal {
        require(mintStatus == MintStatus.Public, "s");

        storageLayer.mintFn(msg.sender, _amount, _from, _to, msg.value);

        uint256 value = msg.value;
        uint256 split = value/100;
        for (uint256 i = 0; i < numPayees; i++) {
            uint256 allocation = split*(earningsSplit[indexer[i]]);
            balances[indexer[i]] += allocation;
            value -= allocation;
        }
        balances[indexer[0]] += value;

        if (totalSupply() == maxPossibleSupply) {
            mintStatus = MintStatus.Finished;
        }
    }

    // Marketplace functionality ====================
    function MKT_list(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "mbo");
        require(price > 0, "zp");
        listings[tokenId][msg.sender] = price;
    }

    function MKT_deList(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender && listings[tokenId][msg.sender] > 0, "mbo;nl");
        listings[tokenId][msg.sender] = 0;
    }

    function MKT_buy(uint256 tokenId) public payable {
        address tokenOwner = ownerOf(tokenId);
        require(listings[tokenId][tokenOwner] > 0 && tokenOwner != msg.sender, "nl;io");
        require(listings[tokenId][tokenOwner] == msg.value, "wp");
        listings[tokenId][tokenOwner] = 0;
        payForSale(msg.value, tokenOwner);
        storageLayer.transferBySale(tokenOwner, msg.sender, tokenId);
        emit Sale(tokenOwner, msg.sender, msg.value);
    }

    function MKT_isListed(uint256 tokenId) public view returns (bool) {
        return (listings[tokenId][ownerOf(tokenId)] > 0);
    }

    function MKT_getPrice(uint256 tokenId) public view returns (uint256) {
        require(listings[tokenId][ownerOf(tokenId)] > 0, "nl");
        return listings[tokenId][ownerOf(tokenId)];
    }

    //////////

    function MKT_makeOffer(uint256 tokenId, uint256 price) public payable {
        require(ownerOf(tokenId) != msg.sender, "io");

        // Check if there is already an offer
        uint256 currentOffer = offers[tokenId][msg.sender];

        // Check that the supplied funds are sufficient to update the price
        require(currentOffer + msg.value == price, "ifa");

        if (currentOffer == 0) {
            offerAddressPositions[tokenId][offerCounts[tokenId]] = msg.sender;
            offerCounts[tokenId] += 1;
        }

        offers[tokenId][msg.sender] = price;
    }

    function mkt_deleteOfferInternal(uint256 tokenId, address offerer, uint256 position) private {
        offers[tokenId][offerer] = 0;

        uint256 lastIndex = offerCounts[tokenId] - 1;
        offerAddressPositions[tokenId][position] = offerAddressPositions[tokenId][lastIndex];
        offerAddressPositions[tokenId][lastIndex] = address(0);
        offerCounts[tokenId] -= 1;
    }

    function MKT_cancelOffer(uint256 tokenId, uint256 position) public {
        uint256 currentOffer = offers[tokenId][msg.sender];
        require(offerAddressPositions[tokenId][position] == msg.sender && currentOffer != 0, "no/odne");

        mkt_deleteOfferInternal(tokenId, msg.sender, position);
        (bool success, ) = payable(msg.sender).call{value: currentOffer}("");
        require(success, "tf");
    }

    function MKT_acceptOffer(uint256 tokenId, address offerer, uint256 price, uint256 position) public {
        uint256 currentOffer = offers[tokenId][offerer];
        if (msg.sender == offerer && offerer == ownerOf(tokenId)) {
            mkt_deleteOfferInternal(tokenId, msg.sender, position);
            (bool success, ) = payable(msg.sender).call{value: currentOffer}("");
            require(success, "tf");
        }
        else {
            require(ownerOf(tokenId) == msg.sender && currentOffer != 0
            && currentOffer == price && offerer == offerAddressPositions[tokenId][position], "mbo/odne/wp1/wp2");

            mkt_deleteOfferInternal(tokenId, offerer, position);
            payForSale(currentOffer, msg.sender);

            listings[tokenId][msg.sender] = 0;
            storageLayer.transferBySale(msg.sender, offerer, tokenId);
            emit Sale(msg.sender, offerer, currentOffer);
        }
    }

    function MKT_getOffers(uint256 tokenId) public view returns (OfferData[] memory) {
        OfferData[] memory offerList = new OfferData[](offerCounts[tokenId]);

        for (uint i = 0; i < offerCounts[tokenId]; i++) {
            address addr_i = offerAddressPositions[tokenId][i];
            OfferData memory od = OfferData({openBrk: "[", addr: addr_i, offer: offers[tokenId][addr_i], pos: i, closeBrk: "]"});
            offerList[i] = od;
        }

        return offerList;
    }

    function MKT_getHighestOffer(uint256 tokenId) public view returns (OfferData memory) {
        uint256 highestOffer = 0;
        address highestOfferAddress = address(0);
        uint256 highestPos = 0;

        for (uint i = 0; i < offerCounts[tokenId]; i++) {
            address addr_i = offerAddressPositions[tokenId][i];
            if (offers[tokenId][addr_i] > highestOffer) {
                highestOffer = offers[tokenId][addr_i];
                highestOfferAddress = addr_i;
                highestPos = i;
            }
        }

        return OfferData({openBrk: "[", addr: highestOfferAddress, offer: highestOffer, pos: highestPos, closeBrk: "]"});
    }

    ////////////////////////////////////////


    function payForSale(uint256 paymentValue, address paymentReceiver) private {
        uint256 royaltyPayment = ((paymentValue/100)*royaltyBasisPoints)/100;
        (bool success1, ) = payable(address(royaltyReceiver)).call{value: royaltyPayment}("");
        require(success1, "t1f");
        (bool success2, ) = payable(paymentReceiver).call{value: paymentValue - royaltyPayment}("");
        require(success2, "t2f");
    }

    receive() external payable {
        mintPublic(msg.value / mintPrice);
    }

    function withdraw() external onlyPayee() {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value:amount}("");
        require(success, "tf");
    }

    function withdrawTokens(address tokenAddress) external onlyOwner() {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    ////////////////////////////////////////

    // ERC721 Required Functionality

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return storageLayer.balanceOf(owner);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        storageLayer.safeTransferFrom(msg.sender, from, to, tokenId, _data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        storageLayer.safeTransferFrom(msg.sender, from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        storageLayer.transferFrom(msg.sender, from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public override {
        storageLayer.approve(msg.sender, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        storageLayer.setApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return storageLayer.getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return storageLayer.isApprovedForAll(owner, operator);
    }

    //////////

    // Extra 721A Functionality

    function totalSupply() public view virtual override returns (uint256) {
        return storageLayer.totalSupply();
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return storageLayer.ownerOf(tokenId);
    }

    function name() external view override returns (string memory) {
        return storageLayer.name();
    }

    function symbol() external view override returns (string memory) {
        return storageLayer.symbol();
    }

    function tokenByIndex(uint256 index) external view override returns (uint256) {
        return storageLayer.tokenByIndex(index);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        return storageLayer.tokenOfOwnerByIndex(owner, index);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return storageLayer.tokenURI(tokenId);
    }

    ////////////////////////////////////////

    function emitTransfer(address _from, address _to, uint256 _tokenId) public {
        emit Transfer(_from, _to, _tokenId);
    }

    function emitApproval(address _owner, address _approved, uint256 _tokenId) public {
        emit Approval(_owner, _approved, _tokenId);
    }

    function emitApprovalForAll(address _owner, address _operator, bool _approved) public {
        emit ApprovalForAll(_owner, _operator, _approved);
    }
}