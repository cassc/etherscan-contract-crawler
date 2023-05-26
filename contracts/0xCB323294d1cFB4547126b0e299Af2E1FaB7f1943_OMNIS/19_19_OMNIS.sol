// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error IncorrectPrice();
error NotUser();
error InvalidSaleState();
error ZeroAddress();
error LimitPerTxnExceeded();
error WhitelistSoldOut();
error SoldOut();
error InvalidSignature();
error ProvenanceBodyNotSet();
error ProvenanceEquipmentOnBodyNotSet();
error StartingIndexExisted();
error LimitPerWalletExceeded();
error ReservedExceeded();
error DifferentCount();
error NotFound();

contract OMNIS is
    ERC721A,
    Ownable,
    ERC2981,
    VRFV2WrapperConsumerBase,
    DefaultOperatorFilterer
{
    /* DETAILS */
    uint256 public mintPrice = 0.005 ether;
    uint256 public publicMintPrice = 0.005 ether;

    uint256 public maxSupply = 10000; // min. tokens for public : 100
    uint256 public whitelistTokens = 9600;
    uint256 public constant RESERVED_TEAM = 300;
    uint256 public reservedCount = 1;

    uint256 public whitelistLimitPerTxn = 3;
    uint256 public publicLimitPerTxn = 3;
    uint256 public limitPerWallet = 3;

    string private baseTokenURI;
    string private contractMetadataURI;

    /* PROVENANCE RECORD */
    string public provenanceBody;
    mapping(uint256 => string) public provenanceEquipmentOnBody;

    uint256 public startingIndexBody;
    mapping(uint256 => uint256) public startingIndexEquipmentOnBody;
    mapping(uint256 => uint256) public bodyCount;
    mapping(uint256 => string) public bodyName;
    uint256 public provedBodyCount;

    string public baseBodyURI;
    mapping(uint256 => string) public baseEquipmentURI;

    /* SIGNATURE */
    using ECDSA for bytes32;
    address public signerAddress;

    /* STAGE REVEAL */
    enum DiskType {
        None,
        Body,
        Equipment
    }
    DiskType public diskType;

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
        address signer_,
        address payable deployerAddress_,
        address linkAddress_,
        address wrapperAddress_,
        string memory firstStageURI_,
        string memory contractURI_
    )
        ERC721A("OMNIS", "OMNIS")
        VRFV2WrapperConsumerBase(linkAddress_, wrapperAddress_)
    {
        setSignerAddress(signer_);
        setWithdrawAddress(deployerAddress_);
        setRoyaltyInfo(500); // Royalty of 5%
        setBaseTokenURI(firstStageURI_);
        setContractMetadataURI(contractURI_);

        linkAddress = linkAddress_;

        _mintERC2309(deployerAddress_, 1);
    }

    /* MINT */
    function whitelistMint(
        uint256 quantity_,
        bytes calldata signature_
    ) external payable isSaleState(SaleState.Whitelist) {
        if (!verifySignature(signature_, "Whitelist")) revert InvalidSignature();
        if (_totalMinted() + quantity_ > whitelistTokens) revert WhitelistSoldOut();
        if (_numberMinted(msg.sender) + quantity_ > limitPerWallet) revert LimitPerWalletExceeded();
        if (msg.value != quantity_ * mintPrice) revert IncorrectPrice();
        if (quantity_ > whitelistLimitPerTxn) revert LimitPerTxnExceeded();

        _mint(msg.sender, quantity_);
        emit Minted(msg.sender, quantity_);
    }

    function publicMint(
        uint256 quantity_,
        bytes calldata signature_
    ) external payable isSaleState(SaleState.Public) {
        if (!verifySignature(signature_, "Public")) revert InvalidSignature();
        if (_totalMinted() + quantity_ > (maxSupply - RESERVED_TEAM)) revert SoldOut();
        if (_numberMinted(msg.sender) + quantity_ > limitPerWallet) revert LimitPerWalletExceeded();
        if (msg.value != quantity_ * publicMintPrice) revert IncorrectPrice();
        if (quantity_ > publicLimitPerTxn) revert LimitPerTxnExceeded();
        
        _mint(msg.sender, quantity_);
        emit Minted(msg.sender, quantity_);
    }

    function reserve(address receiver_, uint256 quantity_) external onlyOwner {
        if (reservedCount + quantity_ > RESERVED_TEAM) revert ReservedExceeded();
        if (_totalMinted() + quantity_ > maxSupply) revert ReservedExceeded();

        _mint(receiver_, quantity_);
        reservedCount += quantity_;
        emit Minted(receiver_, quantity_);
    }

    function verifySignature(bytes memory signature_, string memory saleStateName_) internal view returns (bool) {
        return signerAddress ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(abi.encodePacked(msg.sender, saleStateName_))
                )
            ).recover(signature_);
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

    /* CHAINLINK VRF FOR RANDOM ON REVEAL */

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

    function requestRandomStartingIndex(DiskType diskType_, uint256 requestForBodyIndex_)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        if (diskType_ == DiskType.Body){
            if (bytes(provenanceBody).length <= 0) revert ProvenanceBodyNotSet();
            if (startingIndexBody > 0) revert StartingIndexExisted();

            if (requestForBodyIndex > 0) {
                requestForBodyIndex = 0;
            }
        }
        else if (diskType_ == DiskType.Equipment){
            if (bytes(provenanceEquipmentOnBody[requestForBodyIndex_]).length <= 0) revert ProvenanceEquipmentOnBodyNotSet();
            if (startingIndexEquipmentOnBody[requestForBodyIndex_] > 0) revert StartingIndexExisted();

            requestForBodyIndex = requestForBodyIndex_;
        }
        else {
            revert NotFound();
        }

        // Set current
        diskType = DiskType(diskType_);

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

        // Set random match with the type
        if (diskType == DiskType.Body){
            uint256 startingIndex = _randomWords[0] % maxSupply;
            // Prevent default sequence
            if (startingIndex == 0 || startingIndex == 1) {
                startingIndex = 2;
            }

            // Set starting index body
            startingIndexBody = startingIndex;
        }
        else if (diskType == DiskType.Equipment){
            uint256 startingIndex = _randomWords[0] % bodyCount[requestForBodyIndex];
            // Prevent default sequence
            if (startingIndex == 0 || startingIndex == 1) {
                startingIndex = 2;
            }
            
            // Set starting index equipment on specific body
            startingIndexEquipmentOnBody[requestForBodyIndex] = startingIndex;
        }

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /* OWNER */

    function setSaleState(uint256 saleState_) external onlyOwner {
        saleState = SaleState(saleState_);
        emit SaleStateChanged(saleState);
    }

    modifier isSaleState(SaleState saleState_) {
        if (msg.sender != tx.origin) revert NotUser();
        if (saleState != saleState_) revert InvalidSaleState();
        _;
    }
    
    function setProvenanceBody(string memory provenanceBody_) external onlyOwner {
        provenanceBody = provenanceBody_;
    }

    function setProvenanceEquipmentOnBody(
        string[] memory provenanceEquipmentOnBody_,
        uint256[] memory bodyCount_,
        string[] memory bodyName_
    ) external onlyOwner {
        if (provenanceEquipmentOnBody_.length != bodyCount_.length || provenanceEquipmentOnBody_.length != bodyName_.length) revert DifferentCount();

        for (uint256 i = 0; i < provenanceEquipmentOnBody_.length; i++) {
            provenanceEquipmentOnBody[i] = provenanceEquipmentOnBody_[i];
            bodyCount[i] = bodyCount_[i];
            bodyName[i] = bodyName_[i];
        }
        provedBodyCount = provenanceEquipmentOnBody_.length;
    }

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

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function setWhitelistTokens(uint256 whitelistTokens_) public onlyOwner {
        whitelistTokens = whitelistTokens_;
    }

    function setMintPrice(uint256 mintPrice_) public onlyOwner {
        mintPrice = mintPrice_;
    }

    function setPublicMintPrice(uint256 publicMintPrice_) public onlyOwner {
        publicMintPrice = publicMintPrice_;
    }

    function setPublicLimitPerTxn(uint256 publicLimitPerTxn_) public onlyOwner {
        publicLimitPerTxn = publicLimitPerTxn_;
    }

    function setWhitelistLimitPerTxn(uint256 whitelistLimitPerTxn_) public onlyOwner {
        whitelistLimitPerTxn = whitelistLimitPerTxn_;
    }

    function setLimitPerWallet(uint256 limitPerWallet_) public onlyOwner {
        limitPerWallet = limitPerWallet_;
    }

    function setBaseBodyURI(string memory baseBodyURI_) public onlyOwner {
        baseBodyURI = baseBodyURI_;
    }

    function setBaseEquipmentURI(string memory baseEquipmentURI_, uint256 bodyIndex_) public onlyOwner {
        baseEquipmentURI[bodyIndex_] = baseEquipmentURI_;
    }

    function bodyURI(uint256 tokenId) public view virtual returns (string memory) {
        return bytes(baseBodyURI).length > 0 ? string(abi.encodePacked(baseBodyURI, _toString(tokenId))) : "";
    }
    function equipmentURI(uint256 tokenId, uint256 bodyIndex_) public view virtual returns (string memory) {
        return bytes(baseEquipmentURI[bodyIndex_]).length > 0 ? string(abi.encodePacked(baseEquipmentURI[bodyIndex_], _toString(tokenId))) : "";
    }

    /* WITHDRAW */
    
    address payable public withdrawAddress;
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

    /* OPERATOR FILTERER */

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}