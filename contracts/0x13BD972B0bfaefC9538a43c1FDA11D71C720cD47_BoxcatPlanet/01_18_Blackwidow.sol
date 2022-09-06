// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721psi/contracts/ERC721Psi.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error AddressNotAllowlistVerified();
error CallerNotOwner();
error CallerIsContract();
error AllowlistMintIsOff();
error PublicMintIsOff();
error MintMoreThanAllowed();
error ReachMaxSupply();
error NeedSendMoreETH();
error TokenNotExistent();
error NotCurrentRound();
error MintlistNumberOff();
error OwnerOnlyTransfer();
error NotOwnerOrApproval();
error BoxingIsNotOpen();
error IsNotBoxing();
error IsBoxing();

/**
 @author Catchon Labs
 @title Blackwidow NFT
 */
contract BoxcatPlanet is ERC721Psi, VRFConsumerBaseV2, Ownable {
    using Strings for uint256;

    struct TierConfig {
        uint8 maxTotalMint;
        uint256 listPrice;
        address verificationAddr;
    }

    struct VRFConfig {
        uint64 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    struct MintConfig {
        uint32 allowlistMintStartTime;
        uint32 publicMintStartTime;
        uint256 publicPrice;
        uint256 publicMaxMint;
        string baseTokenURI;
    }

    bool public randomseedRequested = false;

    mapping(address => uint256) public _numberMinted;
    bool public boxingOpen = false;

    uint256 public immutable collectionSize;
    uint256 public currentRound;
    MintConfig public config;
    TierConfig[2] public tierConfigs;

    uint256[] public s_randomWords;

    VRFCoordinatorV2Interface COORDINATOR;
    VRFConfig private vRFConfig;
    uint256 private s_requestId;
    uint256 private offset;

    mapping(uint256 => uint256) private boxingStarted;
    mapping(uint256 => uint256) private boxingTotal;

    enum TransferStatus {
        DISALLOWED,
        ALLOWED
    }

    TransferStatus private boxingTransferStatus = TransferStatus.DISALLOWED;

    modifier callerIsUser() {
        if (tx.origin != msg.sender) {
            revert CallerIsContract();
        }
        _;
    }

    constructor(uint256 collectionSize_, address vrfCoordinator)
        ERC721Psi("BoxcatPlanet", "BCP")
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        collectionSize = collectionSize_;
    }

    /**
     Check if allowlist mint is ON.
     @return the status of allowlist mint, true for ON and false for OFF
     */
    function isAllowlistMintOn() public view returns (bool) {
        return
            tierConfigs[0].verificationAddr != address(0) &&
            tierConfigs[1].verificationAddr != address(0) &&
            config.allowlistMintStartTime != 0 &&
            block.timestamp >= config.allowlistMintStartTime;
    }

    /**
     Check if public mint is ON.
     @return the status of public mint, true for ON and false for OFF
     */
    function isPublicSaleOn() public view returns (bool) {
        return
            config.publicMintStartTime != 0 &&
            config.publicPrice != 0 &&
            block.timestamp >= config.allowlistMintStartTime &&
            block.timestamp >= config.publicMintStartTime;
    }

    /**
     API for addresses in allowlist to mint.
     @param quantity the amount of tokens to mint
     @param signature a signature to identify the sender 
     */
    function allowlistMint(uint256 quantity, bytes memory signature)
        public
        payable
        callerIsUser
    {
        uint256 idx = getAllowlistTier(msg.sender, signature);

        // Allowlist Mint should start
        if (!isAllowlistMintOn()) {
            revert AllowlistMintIsOff();
        }

        if (idx != currentRound) {
            revert NotCurrentRound();
        }

        if (
            (idx == 0) && (quantity != uint256(tierConfigs[idx].maxTotalMint))
        ) {
            revert MintlistNumberOff();
        }

        if (
            numberMinted(msg.sender) + quantity > tierConfigs[idx].maxTotalMint
        ) // Check allowlist mint size
        {
            revert MintMoreThanAllowed();
        }

        // For security purpose to prevent overmint
        if (totalSupply() + quantity > collectionSize) {
            revert ReachMaxSupply();
        }

        if (msg.value < tierConfigs[idx].listPrice * quantity) {
            revert NeedSendMoreETH();
        }

        _numberMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function configAllowlist(
        address veriAddr,
        uint8 maxNum,
        uint256 price,
        uint256 idx
    ) external onlyOwner {
        tierConfigs[idx].verificationAddr = veriAddr;
        tierConfigs[idx].maxTotalMint = maxNum;
        tierConfigs[idx].listPrice = price;
    }

    /**
     API for public to mint.
     @param quantity the amount of tokens to mint
     */
    function publicMint(uint256 quantity) external payable callerIsUser {
        if (!isPublicSaleOn()) {
            revert PublicMintIsOff();
        }

        if (totalSupply() + quantity > collectionSize) {
            revert ReachMaxSupply();
        }

        if (numberMinted(msg.sender) + quantity > config.publicMaxMint) {
            revert MintMoreThanAllowed();
        }

        if (msg.value < config.publicPrice * quantity) {
            revert NeedSendMoreETH();
        }

        _numberMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function safeTransferWhileBoxing(address to, uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert OwnerOnlyTransfer();
        }
        boxingTransferStatus = TransferStatus.ALLOWED;
        safeTransferFrom(msg.sender, to, tokenId);
        boxingTransferStatus = TransferStatus.DISALLOWED;
    }

    function toggleBoxing(uint256 tokenId) internal {
        if (
            _msgSender() != ownerOf(tokenId) &&
            !isApprovedForAll(ownerOf(tokenId), _msgSender())
        ) {
            revert NotOwnerOrApproval();
        }
        uint256 start = boxingStarted[tokenId];
        if (start == 0) {
            if (!boxingOpen) {
                revert BoxingIsNotOpen();
            }
            boxingStarted[tokenId] = block.timestamp;
        } else {
            boxingTotal[tokenId] += block.timestamp - start;
            boxingStarted[tokenId] = 0;
        }
    }

    function toggleBoxing(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleBoxing(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a Moonbird from the nest.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has boxing and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting boxcat to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because boxing would then be all-or-nothing for all of a particular owner's
    BoxCatPlanet.
     */
    function expelFromBox(uint256 tokenId) external onlyOwner {
        if (boxingStarted[tokenId] == 0) {
            revert IsNotBoxing();
        }
        boxingTotal[tokenId] += block.timestamp - boxingStarted[tokenId];
        boxingStarted[tokenId] = 0;
    }

    function devMint(uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > collectionSize) {
            revert ReachMaxSupply();
        }
        _safeMint(msg.sender, quantity);
    }

    /**
     Get the number of token minted by minter.
     @param minter the minter address to be queried for
     @return the number of tokens minted by this minter
     */
    function numberMinted(address minter) public view returns (uint256) {
        return _numberMinted[minter];
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        config.baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setConfig(
        uint32 allowlistMintStartTime,
        uint256 publicPriceWei,
        uint32 publicMintStartTime,
        string memory baseTokenURI,
        uint256 publicMaxMint
    ) external onlyOwner {
        config.allowlistMintStartTime = allowlistMintStartTime;
        config.publicPrice = publicPriceWei;
        config.publicMintStartTime = publicMintStartTime;
        config.baseTokenURI = baseTokenURI;
        config.publicMaxMint = publicMaxMint;
    }

    function setVRFConfig(
        uint64 subscriptionId,
        bytes32 keyHash_,
        uint32 callbackGasLimit_,
        uint16 requestConfirmations_
    ) external onlyOwner {
        vRFConfig.subscriptionId = subscriptionId;
        vRFConfig.keyHash = keyHash_;
        vRFConfig.numWords = 1;
        vRFConfig.callbackGasLimit = callbackGasLimit_;
        vRFConfig.requestConfirmations = requestConfirmations_;
    }

    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            vRFConfig.keyHash,
            vRFConfig.subscriptionId,
            vRFConfig.requestConfirmations,
            vRFConfig.callbackGasLimit,
            vRFConfig.numWords
        );
    }

    function setCurrentRound(uint256 _current) external onlyOwner {
        currentRound = _current;
    }

    function setBoxingStatus(bool status) external onlyOwner {
        boxingOpen = status;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomseedRequested = true;
        s_randomWords = randomWords;
        uint256 seed = uint256(keccak256(abi.encode(s_randomWords[0])));
        if (seed < collectionSize) {
            seed += collectionSize;
        }
        offset = seed % collectionSize;
    }

    function getAllowlistTier(address addr, bytes memory signature)
        internal
        view
        returns (uint256 idx)
    {
        address tempAddr = ECDSA.recover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n40", this, addr)
            ),
            signature
        );
        if (tempAddr == tierConfigs[0].verificationAddr) {
            return 0;
        } else if (tempAddr == tierConfigs[1].verificationAddr) {
            return 1;
        } else {
            revert AddressNotAllowlistVerified();
        }
    }

    function boxingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool boxing,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = boxingStarted[tokenId];
        if (start != 0) {
            boxing = true;
            current = block.timestamp - start;
        }
        total = current + boxingTotal[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Psi)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert TokenNotExistent();
        }

        return
            randomseedRequested
                ? string(
                    abi.encodePacked(
                        _baseURI(),
                        _toString(getMetadata(tokenId))
                    )
                )
                : string(abi.encodePacked(_baseURI(), _toString(tokenId)));
    }

    function getMetadata(uint256 tokenId) public view returns (uint256) {
        if (tokenId >= totalSupply()) {
            revert TokenNotExistent();
        }

        if (!randomseedRequested) return tokenId;

        return (offset + tokenId) % collectionSize;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return config.baseTokenURI;
    }

    /**
    @dev Block transfers while nesting.
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            if (
                boxingStarted[tokenId] != 0 &&
                boxingTransferStatus == TransferStatus.DISALLOWED
            ) {
                revert IsBoxing();
            }
        }
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}