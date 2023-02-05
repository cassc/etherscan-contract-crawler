// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting Pixies World tokens.
 */
contract PixiesWorld is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981
{
    event Stake(uint256 indexed tokenId);
    event Unstake(uint256 indexed tokenId);

    // Address where burnt tokens are sent
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    // Address of the smart contract used to check if an operator address is from a blocklisted exchange
    address public blocklistContractAddress;
    address public burnToMintContractAddress =
        0xD6b788c38e36554fD51dC55635D76BC336834a01;
    address public royaltyAddress = 0xb24229d45907d8110aF867520FB79791990e478a;
    // Permanently disable the blocklist so all exchanges are allowed
    bool public blocklistPermanentlyDisabled;
    // If true tokens can be burned in order to mint
    bool public burnClaimActive;
    // When false, tokens cannot be staked but can still be unstaked
    bool public isStakingActive = true;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen;
    bool public stakingTransferActive;
    // If true, the exchange represented by a uint256 integer is blocklisted and cannot be used to transfer tokens
    mapping(uint256 => bool) public isExchangeBlocklisted;
    // Returns the UNIX timestamp at which a token began staking if currently staked
    mapping(uint256 => uint256) public currentTimeStaked;
    // Returns the total time a token has been staked in seconds, not counting the current staking time if any
    mapping(uint256 => uint256) public totalTimeStaked;
    string public baseTokenURI = "https://wowpixies.com/dust/";
    // Maximum supply of tokens that can be minted
    uint256 public MAX_SUPPLY = 8888;
    uint256 public mintsPerBurn = 1;
    uint96 public royaltyFee = 600;

    constructor(address _blocklistContractAddress)
        ERC721A("Pixies World", "PXWRLD")
    {
        blocklistContractAddress = _blocklistContractAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        isExchangeBlocklisted[5] = true;
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "CANNOT_CALL_FROM_CONTRACT");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Wraps and exposes publicly _numberMinted() from ERC721A
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Reduce the max supply of tokens
     * @param _newMaxSupply The new maximum supply of tokens available to mint
     */
    function reduceMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(_newMaxSupply < MAX_SUPPLY, "NEW_MAX_SUPPLY_TOO_HIGH");
        require(
            _newMaxSupply >= totalSupply(),
            "SUPPLY_LOWER_THAN_MINTED_TOKENS"
        );
        MAX_SUPPLY = _newMaxSupply;
    }

    /**
     * @notice Freeze metadata so it can never be changed again
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        metadataFrozen = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, ERC4907A)
        returns (bool)
    {
        // Supports the following interfaceIds:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - IERC4907: 0xad092b5c
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC4907A.supportsInterface(interfaceId);
    }

    /**
     * @notice Allow owner to send 'mintNumber' tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256[] calldata mintNumber)
        external
        onlyOwner
    {
        require(
            receivers.length == mintNumber.length,
            "ARRAYS_MUST_BE_SAME_LENGTH"
        );
        uint256 totalMint = 0;
        for (uint256 i = 0; i < mintNumber.length; i++) {
            totalMint += mintNumber[i];
        }
        require(totalSupply() + totalMint <= MAX_SUPPLY, "MINT_TOO_LARGE");
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber[i]);
        }
    }

    /**
     * @notice Turn staking on or off
     */
    function setStakingState(bool _stakingState) external onlyOwner {
        require(
            isStakingActive != _stakingState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isStakingActive = _stakingState;
    }

    /**
     * @notice Stake an arbitrary number of tokens
     */
    function stakeTokens(uint256[] calldata tokenIds) external {
        require(isStakingActive, "STAKING_IS_NOT_ACTIVE");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "TOKEN_NOT_OWNED");
            if (currentTimeStaked[tokenId] == 0) {
                currentTimeStaked[tokenId] = block.timestamp;
                emit Stake(tokenId);
            }
        }
    }

    /**
     * @notice Unstake an arbitrary number of tokens
     */
    function unstakeTokens(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "TOKEN_NOT_OWNED");
            if (currentTimeStaked[tokenId] != 0) {
                totalTimeStaked[tokenId] +=
                    block.timestamp -
                    currentTimeStaked[tokenId];
                currentTimeStaked[tokenId] = 0;
                emit Unstake(tokenId);
            }
        }
    }

    /**
     * @notice Allows for transfers (not sales) while staking
     */
    function stakingTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == msg.sender, "TOKEN_NOT_OWNED");
        stakingTransferActive = true;
        safeTransferFrom(from, to, tokenId);
        stakingTransferActive = false;
    }

    /**
     * @notice Allow contract owner to forcibly unstake a token if needed
     */
    function adminUnstake(uint256 tokenId) external onlyOwner {
        require(currentTimeStaked[tokenId] != 0, "TOKEN_NOT_STAKED");
        totalTimeStaked[tokenId] +=
            block.timestamp -
            currentTimeStaked[tokenId];
        currentTimeStaked[tokenId] = 0;
        emit Unstake(tokenId);
    }

    /**
     * @notice Return the total amount of time a token has been staked
     */
    function totalTokenStakeTime(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        uint256 currentStakeStartTime = currentTimeStaked[tokenId];
        if (currentStakeStartTime != 0) {
            return
                (block.timestamp - currentStakeStartTime) +
                totalTimeStaked[tokenId];
        }
        return totalTimeStaked[tokenId];
    }

    /**
     * @notice Return the amount of time a token has been currently staked
     */
    function currentTokenStakeTime(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        uint256 currentStakeStartTime = currentTimeStaked[tokenId];
        if (currentStakeStartTime != 0) {
            return block.timestamp - currentStakeStartTime;
        }
        return 0;
    }

    /**
     * @notice To be updated by contract owner to allow burning to claim a token
     */
    function setBurnClaimState(bool _burnClaimActive) external onlyOwner {
        require(
            burnClaimActive != _burnClaimActive,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        burnClaimActive = _burnClaimActive;
    }

    /**
     * @notice Update the number of free mints claimable per token burned
     */
    function updateMintsPerBurn(uint256 _mintsPerBurn) external onlyOwner {
        mintsPerBurn = _mintsPerBurn;
    }

    function burnERC721ToMint(uint256[] calldata _tokenIds)
        external
        nonReentrant
        originalUser
    {
        require(burnClaimActive, "BURN_CLAIM_IS_NOT_ACTIVE");
        uint256 numberOfTokens = _tokenIds.length;
        require(numberOfTokens > 0, "NO_TOKEN_IDS_PROVIDED");
        require(
            totalSupply() + (numberOfTokens * mintsPerBurn) <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        ERC721A ExternalERC721BurnContract = ERC721A(burnToMintContractAddress);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            require(
                ExternalERC721BurnContract.ownerOf(_tokenIds[i]) == msg.sender,
                "DOES_NOT_OWN_TOKEN_ID"
            );
            ExternalERC721BurnContract.transferFrom(
                msg.sender,
                burnAddress,
                _tokenIds[i]
            );
        }
        _safeMint(msg.sender, numberOfTokens * mintsPerBurn);
    }

    /**
     * @dev Require that the address being approved is not from a blocklisted exchange
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        uint256 operatorExchangeId = IExchangeOperatorAddressList(
            blocklistContractAddress
        ).operatorAddressToExchange(operator);
        require(
            blocklistPermanentlyDisabled ||
                !isExchangeBlocklisted[operatorExchangeId],
            "BLOCKLISTED_EXCHANGE"
        );
        _;
    }

    /**
     * @notice Update blocklist contract address to a custom contract address if desired for custom functionality
     */
    function updateBlocklistContractAddress(address _blocklistContractAddress)
        external
        onlyOwner
    {
        blocklistContractAddress = _blocklistContractAddress;
    }

    /**
     * @notice Permanently disable the blocklist so all exchanges are allowed forever
     */
    function permanentlyDisableBlocklist() external onlyOwner {
        require(!blocklistPermanentlyDisabled, "BLOCKLIST_ALREADY_DISABLED");
        blocklistPermanentlyDisabled = true;
    }

    /**
     * @notice Set or unset an exchange contract address as blocklisted
     */
    function updateBlocklistedExchanges(
        uint256[] calldata exchanges,
        bool[] calldata blocklisted
    ) external onlyOwner {
        require(
            exchanges.length == blocklisted.length,
            "ARRAYS_MUST_BE_SAME_LENGTH"
        );
        for (uint256 i = 0; i < exchanges.length; i++) {
            isExchangeBlocklisted[exchanges[i]] = blocklisted[i];
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(to)
    {
        super.approve(to, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override(ERC721A) whenNotPaused {
        require(
            currentTimeStaked[tokenId] == 0 || stakingTransferActive,
            "TOKEN_IS_STAKED"
        );
        uint256 operatorExchangeId = IExchangeOperatorAddressList(
            blocklistContractAddress
        ).operatorAddressToExchange(msg.sender);
        require(
            blocklistPermanentlyDisabled ||
                !isExchangeBlocklisted[operatorExchangeId],
            "BLOCKLISTED_EXCHANGE"
        );
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }
}

interface IExchangeOperatorAddressList {
    function operatorAddressToExchange(address operatorAddress)
        external
        view
        returns (uint256);
}