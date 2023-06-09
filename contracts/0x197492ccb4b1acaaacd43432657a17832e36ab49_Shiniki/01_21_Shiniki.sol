// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IShiniki.sol";
import "./interfaces/ISignatureVerifier.sol";
import "./ShinikiTransfer.sol";
import "./ERC721A.sol";
import "./access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Shiniki is
    Ownable,
    IShiniki,
    ERC721A,
    ReentrancyGuard,
    Pausable,
    ERC2981,
    ShinikiTransfer
{
    // Info config
    struct SaleConfig {
        uint128 preSaleStartTime;
        uint128 preSaleDuration;
        uint128 publicSaleStartTime;
        uint128 publicSaleDuration;
        uint256 publicSalePrice;
    }

    // Info interface address signature
    ISignatureVerifier public SIGNATURE_VERIFIER;

    // Info config mint
    SaleConfig public saleConfig;

    // Check transfer when tokenId is locked
    mapping(uint256 => bool) public stakingTransfer;

    // Info number minted public
    mapping(address => uint256) public numberPublicMinted;

    // Info number minted pre
    mapping(address => uint256) public numberPreMinted;

    // Info locked
    mapping(uint256 => bool) public locked;

    event Lock(address locker, uint256 tokenId, uint64 startTimestampLock);
    event UnLock(address unlocker, uint256 tokenId);

    constructor(
        address signatureVerifier,
        uint256 collectionSize_,
        uint256 maxBatchSize_,
        uint256 amountMintDev_,
        string memory defaultURI_
    ) ERC721A("Shiniki - Land of Gods", "SHINIKI", collectionSize_, maxBatchSize_) {
        SIGNATURE_VERIFIER = ISignatureVerifier(signatureVerifier);
        currentIndex[TYPE_1] = 0;
        currentIndex[TYPE_2] = collectionSize_ / 2;
        startIndex[TYPE_1] = 0;
        startIndex[TYPE_2] = collectionSize_ / 2;
        revealed = false;
        defaultURI = defaultURI_;
        privateMint(msg.sender, amountMintDev_ / 2, amountMintDev_ / 2);
    }

    /**
     * @notice Validate caller
     */
    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Shiniki: The caller is another contract"
        );
        _;
    }

    /**
     * @notice mint pre sale
     * @param receiver 'address' receiver for nft
     * @param typeMints array 'bytes32' type mint
     * @param quantities array 'uint256' quantity for each type
     * @param amountAllowce 'uint256' maximum quanity of user in whitelist
     * @param nonce 'uint256' a number random
     * @param signature 'bytes' a signature to verify data when mint nft
     */
    function preSaleMint(
        address receiver,
        bytes32[] memory typeMints,
        uint256[] memory quantities,
        uint256 amountAllowce,
        uint256 nonce,
        bytes memory signature
    ) external override nonReentrant callerIsUser whenNotPaused {
        require(receiver == msg.sender, "Shiniki: caller is not receiver");
        require(
            SIGNATURE_VERIFIER.verifyPreSaleMint(
                receiver,
                typeMints,
                quantities,
                amountAllowce,
                nonce,
                signature
            ),
            "Shiniki: signature claim is invalid"
        );
        uint256 totalMint = caculatorQuantity(typeMints, quantities);
        require(
            totalMint <= maxBatchSize,
            "Shiniki: quantity to mint is less than maxBatchSize"
        );
        require(isPreSaleOn(), "Shiniki: pre sale has not begun yet");
        require(
            totalSupply() + totalMint <= collectionSize,
            "Shiniki: reached max supply"
        );
        require(
            numberPreMinted[msg.sender] + totalMint <= amountAllowce,
            "Shiniki: can not mint greater than whiteList"
        );

        numberPreMinted[msg.sender] += totalMint;

        for (uint8 i = 0; i < typeMints.length; i++) {
            _safeMint(msg.sender, quantities[i], typeMints[i]);
        }
    }

    /**
     * @notice mint public sale
     * @param typeMints array 'bytes32' type mint
     * @param quantities array 'uint256' quantity for each type
     */
    function publicSaleMint(
        bytes32[] memory typeMints,
        uint256[] memory quantities
    ) external payable override nonReentrant callerIsUser whenNotPaused {
        uint256 totalMint = caculatorQuantity(typeMints, quantities);
        require(
            totalMint <= maxBatchSize,
            "Shiniki: quantity to mint is less than maxBatchSize"
        );
        require(isPublicSaleOn(), "Shiniki: public sale has not begun yet");
        require(
            totalSupply() + totalMint <= collectionSize,
            "Shiniki: reached max supply"
        );
        numberPublicMinted[msg.sender] += totalMint;
        uint256 totalPrice = saleConfig.publicSalePrice * totalMint;

        require(msg.value >= totalPrice, "Shiniki: insufficient balance");
        if (msg.value > totalPrice) {
            transferETH(msg.sender, msg.value - totalPrice);
        }
        for (uint8 i = 0; i < typeMints.length; i++) {
            _safeMint(msg.sender, quantities[i], typeMints[i]);
        }
    }

    /**
     * @notice mint private
     * @param receiver 'address' receiver when mint nft
     * @param quantityType1 'uint256' quantity when mint nft by Type1
     * @param quantityType2 'uint256' quantity when mint nft by Type2
     */
    function privateMint(
        address receiver,
        uint256 quantityType1,
        uint256 quantityType2
    ) public override onlyOwner whenNotPaused {
        require(
            totalSupply() + quantityType1 + quantityType2 <= collectionSize,
            "Shiniki: reached max supply"
        );

        //mint with type 1
        if (quantityType1 != 0) {
            require(
                totalSupply(TYPE_1) + quantityType1 <= collectionSize / 2,
                "Shiniki: type1 input is reached max supply"
            );
            _safeMint(receiver, quantityType1, TYPE_1);
        }

        //mint with type 2
        if (quantityType2 != 0) {
            require(
                totalSupply(TYPE_2) + quantityType2 <=
                    (collectionSize - (collectionSize / 2)),
                "Shiniki: type2 input is reached max supply"
            );
            _safeMint(receiver, quantityType2, TYPE_2);
        }
    }

    /**
     * @notice caculate total quantity
     * @param typeMints array 'bytes32' type mint
     * @param quantities array 'uint256' quantity for each type
     * @return 'uint256' total quantity user want to mint
     */
    function caculatorQuantity(
        bytes32[] memory typeMints,
        uint256[] memory quantities
    ) internal view returns (uint256) {
        uint256 totalQuantity = 0;
        require(
            (typeMints.length == quantities.length),
            "Shiniki: input is invalid"
        );
        for (uint8 i = 0; i < typeMints.length; i++) {
            require(
                (typeMints[i] == TYPE_1 || typeMints[i] == TYPE_2),
                "Shiniki: type input is invalid"
            );
            if (typeMints[i] == TYPE_1) {
                require(
                    totalSupply(typeMints[i]) + quantities[i] <=
                        collectionSize / 2,
                    "Shiniki: type1 input is reached max supply"
                );
            } else {
                require(
                    quantities[i] + totalSupply(typeMints[i]) <=
                        (collectionSize - (collectionSize / 2)),
                    "Shiniki: type2 input is reached max supply"
                );
            }
            totalQuantity += quantities[i];
        }
        return totalQuantity;
    }

    /**
     * @notice lock nft for staking
     * @param tokenIds array 'uint256' tokenIds
     */
    function lock(uint256[] memory tokenIds) public override {
        require(tokenIds.length != 0, "Shiniki: tokenIds is not zero");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenOwnership memory ownership = ownershipOf(tokenIds[i]);
            require(
                msg.sender == ownership.addr,
                "Shiniki: You are not owner of tokenId"
            );
            require(!locked[tokenIds[i]], "Shiniki: tokenId is locked");

            uint64 timeStampNow = uint64(block.timestamp);
            _ownerships[tokenIds[i]] = TokenOwnership(
                ownership.addr,
                ownership.startTimestamp,
                timeStampNow
            );
            locked[tokenIds[i]] = true;
            stakingTransfer[tokenIds[i]] = true;

            emit Lock(msg.sender, tokenIds[i], timeStampNow);
        }
    }

    /**
     * @notice unlock nft for un-staking
     * @param tokenIds array 'uint256' tokenIds
     */
    function unlock(uint256[] memory tokenIds) public override {
        require(tokenIds.length != 0, "Shiniki: tokenIds is not zero");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenOwnership memory ownership = ownershipOf(tokenIds[i]);
            require(
                msg.sender == ownership.addr,
                "Shiniki: You are not owner of tokenId"
            );
            require(locked[tokenIds[i]], "Shiniki: tokenId is not locked");

            _ownerships[tokenIds[i]] = TokenOwnership(
                ownership.addr,
                ownership.startTimestamp,
                0
            );
            locked[tokenIds[i]] = false;
            stakingTransfer[tokenIds[i]] = false;

            emit UnLock(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @notice set base uri
     * @param _typeMint array 'bytes32' type mint
     * @param _baseURI array 'string' base uri
     */
    function setBaseURI(bytes32[] memory _typeMint, string[] memory _baseURI)
        external
        onlyOwner
    {
        require(
            _typeMint.length == _baseURI.length,
            "Shiniki: input data is invalid"
        );
        for (uint256 i = 0; i < _typeMint.length; i++) {
            require(
                (_typeMint[i] == TYPE_1 || _typeMint[i] == TYPE_2),
                "Shiniki: type input is invalid"
            );
            _baseTokenURI[_typeMint[i]] = _baseURI[i];
        }
    }

    /**
     * @notice set default uri
     * @param _defaultURI 'string' default uri
     */
    function setDefaultURI(string memory _defaultURI) external onlyOwner {
        defaultURI = _defaultURI;
    }

    /**
     * @notice set max batch size
     * @param _maxBatchSize 'uint256' number new maxBatchSize
     */
    function setMaxBatchSize(uint256 _maxBatchSize) external onlyOwner {
        maxBatchSize = _maxBatchSize;
    }

    /**
    @notice Setting new address signature
     * @param _signatureVerifier 'address' signature 
     */
    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        SIGNATURE_VERIFIER = ISignatureVerifier(_signatureVerifier);
    }

    /**
     * @notice check pre sale
     * @return 'bool' status pre sale
     */
    function isPreSaleOn() public view returns (bool) {
        return
            block.timestamp >= saleConfig.preSaleStartTime &&
            block.timestamp <=
            saleConfig.preSaleStartTime + saleConfig.preSaleDuration;
    }

    /**
     * @notice check public sale
     * @return 'bool' status public sale
     */
    function isPublicSaleOn() public view returns (bool) {
        return
            saleConfig.publicSalePrice != 0 &&
            block.timestamp >= saleConfig.publicSaleStartTime &&
            block.timestamp <=
            saleConfig.publicSaleStartTime + saleConfig.publicSaleDuration;
    }

    /**
     * @notice set pre sale config
     * @param _preSaleStartTime 'uint128' start time pre sale
     * @param _preSaleDuration 'uint128' duration time of pre sale
     */
    function setPreSaleConfig(
        uint128 _preSaleStartTime,
        uint128 _preSaleDuration
    ) external onlyOwner {
        saleConfig.preSaleStartTime = _preSaleStartTime;
        saleConfig.preSaleDuration = _preSaleDuration;
    }

    /**
     * @notice set public sale config
     * @param _publicSaleStartTime 'uint128' start time public sale
     * @param _publicSaleDuration 'uint128' duration time of public sale
     * @param _publicSalePrice 'uint256' price of public sale for each nft
     */
    function setPublicSaleConfig(
        uint128 _publicSaleStartTime,
        uint128 _publicSaleDuration,
        uint256 _publicSalePrice
    ) external onlyOwner {
        saleConfig.publicSaleStartTime = _publicSaleStartTime;
        saleConfig.publicSaleDuration = _publicSaleDuration;
        saleConfig.publicSalePrice = _publicSalePrice;
    }

    /**
     * @notice set revealed
     * @param _revealed 'bool' status revealed
     */
    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    /**
     * @notice withdraw asset
     * @param receiver 'address' receiver asset
     * @param amount 'uint256' number asset to withdraw
     */
    function withdraw(address receiver, uint256 amount)
        external
        override
        onlyOwner
        nonReentrant
    {
        transferETH(receiver, amount);
    }

    /**
     * @notice withdraw all asset
     * @param receiver 'address' receiver asset
     */
    function withdrawAll(address receiver)
        external
        override
        onlyOwner
        nonReentrant
    {
        transferETH(receiver, address(this).balance);
    }

    /**
     * @notice number minted
     * @param owner 'address' user
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice get ownership data of a nft
     * @param tokenId 'uint256' id of nft
     * @return 'TokenOwnership' detail a nft
     */
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    /**
    @notice Transfer a token between addresses while the Shiniki is staking
     * @param from 'address' sender
     * @param to 'address' receiver
     * @param tokenId 'uint256' id of nft
     */
    function safeTransferWhileStaking(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        require(ownerOf(tokenId) == _msgSender(), "Shiniki: Only owner");
        if (stakingTransfer[tokenId]) {
            stakingTransfer[tokenId] = false;
            safeTransferFrom(from, to, tokenId);
            stakingTransfer[tokenId] = true;
        } else {
            safeTransferFrom(from, to, tokenId);
        }
    }

    /**
    @dev Pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    @dev Unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    @dev Block transfers while staking.
     */
    function _beforeTokenTransfers(
        address from,
        address,
        uint256 tokenId,
        uint256
    ) internal view override {
        if (from != address(0)) {
            require(!stakingTransfer[tokenId], "Shiniki: staking");
        }
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner, uint256 nonce, bytes memory signature) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(
            SIGNATURE_VERIFIER.verifyTransferOwner(newOwner, nonce, signature),
            "Shiniki: signature transfer owner is invalid"
        );
        _transferOwnership(newOwner);
    }
}