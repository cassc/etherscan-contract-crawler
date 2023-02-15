// SPDX-License-Identifier: MIT
/*
                 
                   ///////////////////      //////////////////,
                   ///////////////////      //////////////////,
                   ///////////////////      //////////////////,
             ######///////////////////////////////      /////////////
             #####(///////////////////////////////      /////////////
             #####(///////////////////////////////            ,//////
             #####(///////////////////////////////            ,//////
             #####(///////////////////////////////            ,//////
             ############(///////////////////////////////////////////
             ############(///////////////////////////////////////////
                   #############//////////////////////////////,
                   #############//////////////////////////////,
                   (#####(#####(//////////////////////////////,
                         *############//////////////////
                         *############//////////////////
                                ############//////
                                ############//////
                                #####(######//////
                                      ######
                                      ######
*/

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
error LovelistSoldOut();
error SoldOut();
error WrongPrice();
error WrongSaleState();
error WrongLimit();
error WrongSignature();
error ProvenanceNotSet();
error RandomStartingIndexExisted();
error NotFound();
error NotOwner();
error TouchNotAllowed();
error NotExist();
error MustTenMultiplied();
error StillAvailable();
error NotOpenYet();
error NotAllowed();

abstract contract SecretContract {
    function doSomethingSecret(address to_, uint256[] memory tokenIds_) public virtual;
}

contract Aishiteru is ERC721A, ERC2981, Ownable, VRFV2WrapperConsumerBase, DefaultOperatorFilterer {
    /* TOUCH */
    uint256 public touchPrice = 0 ether;
    uint256 public goldenTouchPrice = 0.0001 ether;

    /* STATUS */
    mapping(uint256 => uint256) public loveScore;
    mapping(uint256 => uint256) public loveAvailableUntil;
    mapping(uint256 => bool) public transferStatus;
    mapping(uint256 => bool) public testLocked; // Only testing purposes

    /* SIGNATURE */
    using ECDSA for bytes32;
    address public signerAddress;

    /* COLLECTION */
    uint256 public maxSupply = 5000;

    uint256 public lovelistFreeLimit = 2; // Change to 1 Free after 1 hour of Phase 1 Lovelist Mint
    uint256 public lovelistSupply = 4900;
    uint256 public lovelistLimit = 5;
    uint256 public lovelistMintPrice = 0.0069 ether;

    uint256 public publicLimit = 10;
    uint256 public publicMintPrice = 0.0069 ether;

    bool public allowedFreePublic = false;
    uint256 public publicFreeLimit = 1;

    uint256 public reserved = 100;

    string private baseTokenURI;
    string private baseLockedTokenURI;

    string private baseDynamicTokenURI;
    bool public dynamicTokenEnabled = false; // Soon...

    string private contractMetadataURI;
    string public provenance;
    uint256 public randomStartingIndex;
    address payable public withdrawAddress;

    uint256 public launchedTimestamp;
    uint256 public checkpointLevel = 50; // Must multiply of 10
    enum SaleState {
        Closed,
        Lovelist,
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
        string memory unrevealTokenURI_
    )
        ERC721A("Aishiteru", unicode"❤️")
        VRFV2WrapperConsumerBase(linkAddress_, wrapperAddress_)
    {
        setSignerAddress(signerAddress_);
        setWithdrawAddress(mainAddress_);
        setRoyaltyInfo(1000);
        setBaseTokenURI(unrevealTokenURI_);

        launchedTimestamp = block.timestamp;
        linkAddress = linkAddress_;

        _mintERC2309(mainAddress_, 1);
    }

    /* MINT */
    function lovelistMint(uint256 quantity_, bytes calldata signature_) external payable isSaleState(SaleState.Lovelist) {
        if (!verifySignature(signature_, "Lovelist")) revert WrongSignature();
        if (_totalMinted() + quantity_ > lovelistSupply) revert LovelistSoldOut();
        if (quantity_ > lovelistLimit) revert Exceeded();
        if (_numberMinted(msg.sender) + quantity_ > lovelistLimit) revert LimitExceed();
        if (_numberMinted(msg.sender) >= lovelistFreeLimit) {
            if (msg.value != quantity_ * lovelistMintPrice) revert WrongPrice();
        } else {
            if (lovelistFreeLimit >= _numberMinted(msg.sender) + quantity_) {
                if (msg.value != 0) revert WrongPrice();
            } else {
                if (msg.value != ((_numberMinted(msg.sender) + quantity_) - lovelistFreeLimit) * lovelistMintPrice) revert WrongPrice();
            }
        }

        _mint(msg.sender, quantity_);
    }

    function publicMint(uint256 quantity_) external payable isSaleState(SaleState.Public) {
        if (_totalMinted() + quantity_ > (maxSupply - reserved)) revert SoldOut();
        if (quantity_ > publicLimit) revert Exceeded();
        if (_numberMinted(msg.sender) + quantity_ > publicLimit) revert LimitExceed();

        if (allowedFreePublic) {
            if (_numberMinted(msg.sender) >= publicFreeLimit) {
                if (msg.value != quantity_ * publicMintPrice) revert WrongPrice();
            } else {
                if (publicFreeLimit >= _numberMinted(msg.sender) + quantity_) {
                    if (msg.value != 0) revert WrongPrice();
                } else {
                    if (msg.value != ((_numberMinted(msg.sender) + quantity_) - publicFreeLimit) * publicMintPrice) revert WrongPrice();
                }
            }
        } else {
            if (msg.value != quantity_ * publicMintPrice) revert WrongPrice();
        }

        _mint(msg.sender, quantity_);
    }

    function reserve(address receiver_, uint256 quantity_) external onlyOwner {
        if (_totalMinted() + quantity_ > maxSupply) revert Exceeded();

        _mint(receiver_, quantity_);
    }

    /* TOUCH */
    function commonTouch(uint256[] memory tokenIds_) external payable {
        // Validate touch price
        if (msg.value != touchPrice * tokenIds_.length) revert TouchNotAllowed();

        // Multiple txn
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 _tokenId = tokenIds_[i];
            refreshAppearance(_tokenId, 1); // only 1 score...
        }
    }

    function goldenTouch(uint256[] memory tokenIds_) external payable {
        // Validate touch price
        if (msg.value != goldenTouchPrice * tokenIds_.length) revert TouchNotAllowed();

        // Multiple txn
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 _tokenId = tokenIds_[i];
            refreshAppearance(_tokenId, checkpointLevel / 10); // GOLDEN SCORE!
        }
    }

    function refreshAppearance(uint256 tokenId_, uint256 addScore_) public {
        // Validate owner
        if (ownerOf(tokenId_) != msg.sender) revert NotOwner();
        if (block.timestamp <= availableUntil(tokenId_))
            revert StillAvailable();

        // Love unlocked
        uint256 _epochAdd = epochAdd(tokenId_, addScore_);
        loveAvailableUntil[tokenId_] = block.timestamp + _epochAdd;

        // Add 1 loveScore
        loveScore[tokenId_] += addScore_;
    }

    function epochAdd(
        uint256 tokenId_,
        uint256 addScore_
    ) public view returns (uint256) {
        // Optimize get love score
        uint256 _loveScore = loveScore[tokenId_];

        // Love unlocked
        uint256 _daysAdd = ((_loveScore + addScore_) * 10) / checkpointLevel;
        return 604800 + (_daysAdd * 86400);
    }

    function availableUntil(uint256 tokenId) public view returns (uint256) {
        if (testLocked[tokenId]) return 0; // Only for testing purposes

        uint256 _loveScore = loveScore[tokenId];
        if (_loveScore == 0 && !transferStatus[tokenId]) {
            return launchedTimestamp + 604800; // 7 * 24 * 60 * 60
        } else {
            return loveAvailableUntil[tokenId];
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NotExist();

        if (block.timestamp > availableUntil(tokenId)) {
            return
                bytes(baseLockedTokenURI).length != 0
                    ? string(
                        abi.encodePacked(baseLockedTokenURI, _toString(tokenId))
                    )
                    : "";
        }

        if (dynamicTokenEnabled) {
            uint256 _loveScore = loveScore[tokenId];
            return
                bytes(baseDynamicTokenURI).length != 0
                    ? string(
                        abi.encodePacked(
                            baseDynamicTokenURI,
                            _loveScore,
                            "/",
                            _toString(tokenId)
                        )
                    )
                    : "";
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    /* Love Transfer */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
        resetAvailability(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
        resetAvailability(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
        resetAvailability(tokenId);
    }

    function resetAvailability(uint256 tokenId_) public {
        if (!transferStatus[tokenId_]) {
            transferStatus[tokenId_] = true;
            uint256 _epochAdd = epochAdd(tokenId_, 0);
            loveAvailableUntil[tokenId_] = block.timestamp + _epochAdd;
        }
    }

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

    /* VALIDATOR */
    function verifySignature(
        bytes memory signature_,
        string memory saleStateName_
    ) internal view returns (bool) {
        return
            signerAddress ==
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

    /* OWNER */
    function setSignerAddress(address signerAddress_) public onlyOwner {
        if (signerAddress_ == address(0)) revert ZeroAddress();
        signerAddress = signerAddress_;
    }

    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function setBaseDynamicTokenURI(
        string memory baseDynamicTokenURI_
    ) public onlyOwner {
        baseDynamicTokenURI = baseDynamicTokenURI_;
    }

    function setDynamicTokenEnabled(bool enabled_) public onlyOwner {
        dynamicTokenEnabled = enabled_;
    }

    function setCheckpointLevel(uint256 checkpointLevel_) public onlyOwner {
        if (checkpointLevel_ / 10 <= 0) revert MustTenMultiplied();
        checkpointLevel = checkpointLevel_;
    }

    function setBaseLockedTokenURI(
        string memory baseLockedTokenURI_
    ) public onlyOwner {
        baseLockedTokenURI = baseLockedTokenURI_;
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

    function setGoldenTouchPrice(uint256 goldenTouchPrice_) public onlyOwner {
        goldenTouchPrice = goldenTouchPrice_;
    }

    function setTouchPrice(uint256 touchPrice_) public onlyOwner {
        touchPrice = touchPrice_;
    }

    function setProvenanceHash(string memory provenance_) external onlyOwner {
        provenance = provenance_;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function setReserved(uint256 reserved_) public onlyOwner {
        reserved = reserved_;
    }

    function setAllowedFreePublic(bool allowed_) public onlyOwner {
        allowedFreePublic = allowed_;
    }

    function setLovelistSupply(uint256 lovelistSupply_) public onlyOwner {
        lovelistSupply = lovelistSupply_;
    }

    function setLovelistFreeLimit(uint256 lovelistFreeLimit_) public onlyOwner {
        lovelistFreeLimit = lovelistFreeLimit_;
    }

    function setLovelistMintPrice(uint256 lovelistMintPrice_) public onlyOwner {
        lovelistMintPrice = lovelistMintPrice_;
    }

    function setPublicMintPrice(uint256 publicMintPrice_) public onlyOwner {
        publicMintPrice = publicMintPrice_;
    }

    function setPublicLimit(uint256 publicLimit_) public onlyOwner {
        publicLimit = publicLimit_;
    }

    function setPublicFreeLimit(uint256 publicFreeLimit_) public onlyOwner {
        publicFreeLimit = publicFreeLimit_;
    }

    function setLovelistLimit(uint256 lovelistLimit_) public onlyOwner {
        lovelistLimit = lovelistLimit_;
    }

    /* TESTING PURPOSES ONLY - will not be used in Production */
    function setLockedAsTesting(
        bool locked_,
        uint256 tokenId_
    ) public onlyOwner {
        testLocked[tokenId_] = locked_;
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
            randomStartingIndex = 14;
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

    /* LAST SECRET */
    bool public secretOpen = false;
    address public secretAddress;
    uint256 public minimumLoveScore;

    function secretMint(uint256[] memory tokenIds_) public payable {
        if (!secretOpen) revert NotOpenYet();

        // BURN
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (loveScore[tokenIds_[i]] < minimumLoveScore) revert NotAllowed();
            _burn(tokenIds_[i]);
        }

        // to MINT
        SecretContract secretContract = SecretContract(secretAddress);
        secretContract.doSomethingSecret(msg.sender, tokenIds_);
    }

    function setMinimumLoveScore(uint256 minimumLoveScore_) public onlyOwner {
        minimumLoveScore = minimumLoveScore_;
    }

    function setSecretAddress(address address_) public onlyOwner {
        secretAddress = address_;
    }

    function setSecretOpen(bool open_) public onlyOwner {
        secretOpen = open_;
    }
}