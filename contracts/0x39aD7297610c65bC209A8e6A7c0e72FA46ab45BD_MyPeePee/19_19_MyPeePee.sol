// SPDX-License-Identifier: MIT
//
//
//=*  M
//        Y
//
//              P
//                 E
//                    E
//
//                      P
//                       E
//                       E

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error NotUser();
error ZeroAddress();
error LimitExceed();
error Exceeded();
error WhitelistSoldOut();
error SoldOut();
error WrongPrice();
error WrongSaleState();
error WrongLimit();
error WrongSignature();
error ProvenanceNotSet();
error RandomStartingIndexExisted();
error NotFound();

contract MyPeePee is
    ERC721A,
    Ownable,
    ERC2981,
    VRFV2WrapperConsumerBase,
    DefaultOperatorFilterer
{
    /* SIGNATURE */
    using ECDSA for bytes32;
    address public signerAddress;

    /* COLLECTION */
    uint256 public maxSupply = 6969;
    uint256 public whitelistSupply = 1800;
    uint256 public whitelistMintPrice = 0.0069 ether;
    uint256 public whitelistLimit = 3;
    uint256 public publicMintPrice = 0.0069 ether;
    uint256 public publicLimit = 10;
    uint256 public constant RESERVED = 169;

    string private baseTokenURI;
    string private contractMetadataURI;
    string public provenance;
    uint256 public randomStartingIndex;
    address payable public withdrawAddress;

    /* SALE STATE */
    enum SaleState {
        Closed,
        Whitelist,
        Public
    }
    SaleState public saleState;

    /* EVENT */
    event Minted(address indexed receiver, uint256 quantity);
    event SaleStateChanged(SaleState saleState);

    constructor(
        address signerAddress_,
        address payable mainAddress_,
        address linkAddress_,
        address wrapperAddress_,
        string memory unrevealTokenURI,
        string memory contractURI_
    )
        ERC721A("My Pee Pee", "MyPeePee")
        VRFV2WrapperConsumerBase(linkAddress_, wrapperAddress_)
    {
        setSignerAddress(signerAddress_);
        setWithdrawAddress(mainAddress_);
        setRoyaltyInfo(690);
        setBaseTokenURI(unrevealTokenURI);
        setContractMetadataURI(contractURI_);

        linkAddress = linkAddress_;

        _mintERC2309(mainAddress_, 1);
    }

    /* MINT */
    function whitelistMint(
        uint256 quantity_,
        bytes calldata signature_
    ) external payable isSaleState(SaleState.Whitelist) {
        if (!verifySignature(signature_, "Whitelist")) revert WrongSignature();
        if (_totalMinted() + quantity_ > whitelistSupply) revert WhitelistSoldOut();
        if (quantity_ > whitelistLimit) revert Exceeded();
        if (_numberMinted(msg.sender) + quantity_ > whitelistLimit) revert LimitExceed();
        if (_numberMinted(msg.sender) >= 1) {
            if (msg.value != quantity_ * whitelistMintPrice) revert WrongPrice();
        } else {
            if (msg.value != (quantity_ - 1) * whitelistMintPrice) revert WrongPrice();
        }

        _mint(msg.sender, quantity_);
        emit Minted(msg.sender, quantity_);
    }

    function publicMint(
        uint256 quantity_
    ) external payable isSaleState(SaleState.Public) {
        if (_totalMinted() + quantity_ > (maxSupply - whitelistSupply - RESERVED)) revert SoldOut();
        if (quantity_ > publicLimit) revert Exceeded();
        if (_numberMinted(msg.sender) + quantity_ > publicLimit) revert LimitExceed();
        if (msg.value != quantity_ * publicMintPrice) revert WrongPrice();

        _mint(msg.sender, quantity_);
        emit Minted(msg.sender, quantity_);
    }

    function reserve(address receiver_, uint256 quantity_) external onlyOwner {
        if (_totalMinted() + quantity_ > maxSupply) revert Exceeded();

        _mint(receiver_, quantity_);
        emit Minted(receiver_, quantity_);
    }

    function verifySignature(
        bytes memory signature_,
        string memory saleStateName_
    ) internal view returns (bool) {
        return
            signerAddress == keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(abi.encodePacked(msg.sender, saleStateName_))
            )).recover(signature_);
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /* CHAINLINK */
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint256 requestForBodyIndex;
    address public linkAddress;

    function requestRandomStartingIndex()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        if (bytes(provenance).length <= 0) revert ProvenanceNotSet();
        if (randomStartingIndex > 0) revert RandomStartingIndexExisted();

        // Start request
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;

        randomStartingIndex = _randomWords[0] % maxSupply;
        if (randomStartingIndex == 0 || randomStartingIndex == 1) {
            randomStartingIndex = 69;
        }

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /* OWNER */
    function setSignerAddress(address signerAddress_) public onlyOwner {
        if (signerAddress_ == address(0)) revert ZeroAddress();
        signerAddress = signerAddress_;
    }

    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function setContractMetadataURI(
        string memory contractMetadataURI_
    ) public onlyOwner {
        contractMetadataURI = contractMetadataURI_;
    }

    function setWithdrawAddress(
        address payable withdrawAddress_
    ) public onlyOwner {
        if (withdrawAddress_ == address(0)) revert ZeroAddress();
        withdrawAddress = withdrawAddress_;
    }

    function setWithdrawLinkAddress(
        address payable linkAddress_
    ) public onlyOwner {
        if (linkAddress_ == address(0)) revert ZeroAddress();
        linkAddress = linkAddress_;
    }

    function setRoyaltyInfo(uint96 royaltyPercentage_) public onlyOwner {
        if (withdrawAddress == address(0)) revert ZeroAddress();
        _setDefaultRoyalty(withdrawAddress, royaltyPercentage_);
    }

    function setSaleState(uint256 saleState_) external onlyOwner {
        saleState = SaleState(saleState_);
        emit SaleStateChanged(saleState);
    }

    modifier isSaleState(SaleState saleState_) {
        if (msg.sender != tx.origin) revert NotUser();
        if (saleState != saleState_) revert WrongSaleState();
        _;
    }

    function setProvenanceHash(string memory provenance_) external onlyOwner {
        provenance = provenance_;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function setwhitelistSupply(uint256 whitelistSupply_) public onlyOwner {
        whitelistSupply = whitelistSupply_;
    }

    function setWhitelistMintPrice(uint256 whitelistMintPrice_) public onlyOwner {
        whitelistMintPrice = whitelistMintPrice_;
    }

    function setPublicMintPrice(uint256 publicMintPrice_) public onlyOwner {
        publicMintPrice = publicMintPrice_;
    }

    function setPublicLimit(uint256 publicLimit_) public onlyOwner {
        publicLimit = publicLimit_;
    }

    function setWhitelistLimit(uint256 whitelistLimit_) public onlyOwner {
        whitelistLimit = whitelistLimit_;
    }

    /* WITHDRAW */
    function withdraw() external onlyOwner {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /* OpenSea OPERATOR FILTERER */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}