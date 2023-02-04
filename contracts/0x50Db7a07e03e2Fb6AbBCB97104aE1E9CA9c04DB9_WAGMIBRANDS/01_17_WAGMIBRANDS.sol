// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting WAGMI BRANDS tokens.
 */
contract WAGMIBRANDS is
    ERC1155Supply,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981
{
    using ECDSA for bytes32;

    // Used to validate authorized presale mint addresses
    address private presaleSignerAddress =
        0x62f7911A4bF4A1D5540416509198B8e40C816a09;
    // Address of the smart contract used to check if an operator address is from a blocklisted exchange
    address public blocklistContractAddress;
    address public royaltyAddress = 0x4e1E1D4883A4127BC388b26cE9Be1539fCf386DC;
    address[] public payoutAddresses = [
        0x4e1E1D4883A4127BC388b26cE9Be1539fCf386DC
    ];
    // Permanently freezes metadata for all tokens so they can never be changed
    bool public allMetadataFrozen = false;
    // Permanently disable the blocklist so all exchanges are allowed
    bool public blocklistPermanentlyDisabled;
    // If true, payout addresses and basis points are permanently frozen and can never be updated
    bool public payoutAddressesFrozen;
    // The amount of tokens minted by a given address for a given token id
    mapping(address => mapping(uint256 => uint256))
        public tokensMintedByAddress;
    // If true, the exchange represented by a uint256 integer is blocklisted and cannot be used to transfer tokens
    mapping(uint256 => bool) public isExchangeBlocklisted;
    // Permanently freezes metadata for a specific token id so it can never be changed
    mapping(uint256 => bool) public tokenMetadataFrozen;
    // If true, the given token id can never be minted again
    mapping(uint256 => bool) public tokenMintingPermanentlyDisabled;
    mapping(uint256 => bool) public tokenPresaleSaleActive;
    mapping(uint256 => bool) public tokenPublicSaleActive;
    // If true, sale start and end times for the presale will be enforced, else ignored
    mapping(uint256 => bool) public tokenUsePresaleTimes;
    // If true, sale start and end times for the public sale will be enforced, else ignored
    mapping(uint256 => bool) public tokenUsePublicSaleTimes;
    mapping(uint256 => string) public tokenURI;
    // Maximum supply of tokens that can be minted for each token id. If zero, this token is open edition and has no mint limit
    mapping(uint256 => uint256) public tokenMaxSupply;
    // If zero, this token is open edition and has no mint limit
    mapping(uint256 => uint256) public tokenPresaleMaxSupply;
    mapping(uint256 => uint256) public tokenPresaleMintsPerAddress;
    mapping(uint256 => uint256) public tokenPresalePrice;
    mapping(uint256 => uint256) public tokenPresaleSaleEndTime;
    mapping(uint256 => uint256) public tokenPresaleSaleStartTime;
    mapping(uint256 => uint256) public tokenPublicMintsPerAddress;
    mapping(uint256 => uint256) public tokenPublicPrice;
    mapping(uint256 => uint256) public tokenPublicSaleEndTime;
    mapping(uint256 => uint256) public tokenPublicSaleStartTime;
    string public name = "WAGMI BRANDS";
    string public symbol = "BRANDS";
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint256[] public payoutBasisPoints = [10000];
    uint96 public royaltyFee = 400;

    constructor(address _blocklistContractAddress)
        ERC1155(
            "ipfs://bafybeibtcoaw6dlxqxjbtafujkoldhlnyaey6ev3pvlz6kf2uk7ebezgh4/{id}"
        )
    {
        blocklistContractAddress = _blocklistContractAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        tokenMaxSupply[1] = 400;
        tokenPublicPrice[1] = 0.07 ether;
        tokenPublicMintsPerAddress[1] = 400;
        require(
            payoutAddresses.length == payoutBasisPoints.length,
            "PAYOUT_ARRAYS_NOT_SAME_LENGTH"
        );
        uint256 totalPayoutBasisPoints = 0;
        for (uint256 i = 0; i < payoutBasisPoints.length; i++) {
            totalPayoutBasisPoints += payoutBasisPoints[i];
        }
        require(
            totalPayoutBasisPoints == 10000,
            "TOTAL_BASIS_POINTS_MUST_BE_10000"
        );
        isExchangeBlocklisted[2] = true;
        isExchangeBlocklisted[4] = true;
        isExchangeBlocklisted[5] = true;
        isExchangeBlocklisted[7] = true;
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "CANNOT_CALL_FROM_CONTRACT");
        _;
    }

    /**
     * @notice Returns a custom URI for each token id if set
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        if (bytes(tokenURI[_tokenId]).length == 0) {
            return super.uri(_tokenId);
        }
        return tokenURI[_tokenId];
    }

    /**
     * @notice Sets a URI for a specific token id.
     */
    function setURI(uint256 _tokenId, string calldata _newTokenURI)
        external
        onlyOwner
    {
        require(
            !allMetadataFrozen && !tokenMetadataFrozen[_tokenId],
            "METADATA_HAS_BEEN_FROZEN"
        );
        tokenURI[_tokenId] = _newTokenURI;
    }

    /**
     * @notice Update the global default ERC-1155 base URI
     */
    function setGlobalURI(string calldata _newTokenURI) external onlyOwner {
        require(!allMetadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        _setURI(_newTokenURI);
    }

    /**
     * @notice Freeze metadata for a specific token id so it can never be changed again
     */
    function freezeTokenMetadata(uint256 _tokenId) external onlyOwner {
        require(
            !tokenMetadataFrozen[_tokenId],
            "METADATA_HAS_ALREADY_BEEN_FROZEN"
        );
        tokenMetadataFrozen[_tokenId] = true;
    }

    /**
     * @notice Freeze all metadata so it can never be changed again
     */
    function freezeAllMetadata() external onlyOwner {
        require(!allMetadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        allMetadataFrozen = true;
    }

    /**
     * @notice Reduce the max supply of tokens for a given token id
     * @param _newMaxSupply The new maximum supply of tokens available to mint
     * @param _tokenId The token id to reduce the max supply for
     */
    function reduceMaxSupply(uint256 _tokenId, uint256 _newMaxSupply)
        external
        onlyOwner
    {
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                _newMaxSupply < tokenMaxSupply[_tokenId],
            "NEW_MAX_SUPPLY_TOO_HIGH"
        );
        require(
            _newMaxSupply >= totalSupply(_tokenId),
            "SUPPLY_LOWER_THAN_MINTED_TOKENS"
        );
        tokenMaxSupply[_tokenId] = _newMaxSupply;
    }

    /**
     * @notice Lock a token id so that it can never be minted again
     */
    function permanentlyDisableTokenMinting(uint256 _tokenId)
        external
        onlyOwner
    {
        tokenMintingPermanentlyDisabled[_tokenId] = true;
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

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed.
     * This prevents arbitrary 'creation' of new tokens in the collection by anyone.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Allow owner to send tokens without cost to multiple addresses
     */
    function giftTokens(
        uint256 _tokenId,
        address[] calldata _receivers,
        uint256[] calldata _mintNumber
    ) external onlyOwner {
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        uint256 totalMint = 0;
        for (uint256 i = 0; i < _mintNumber.length; i++) {
            totalMint += _mintNumber[i];
        }
        // require either no tokenMaxSupply set or tokenMaxSupply not maxed out
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + totalMint <= tokenMaxSupply[_tokenId],
            "MINT_TOO_LARGE"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            _mint(_receivers[i], _tokenId, _mintNumber[i], "");
        }
    }

    /**
     * @notice To be updated by contract owner to allow public sale minting for a given token
     */
    function setTokenPublicSaleState(uint256 _tokenId, bool _saleActiveState)
        external
        onlyOwner
    {
        require(
            tokenPublicSaleActive[_tokenId] != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenPublicSaleActive[_tokenId] = _saleActiveState;
    }

    /**
     * @notice Update the public mint price for a given token
     */
    function setTokenPublicPrice(uint256 _tokenId, uint256 _publicPrice)
        external
        onlyOwner
    {
        tokenPublicPrice[_tokenId] = _publicPrice;
    }

    /**
     * @notice Set the maximum public mints allowed per a given address for a given token
     */
    function setTokenPublicMintsAllowedPerAddress(
        uint256 _tokenId,
        uint256 _mintsAllowed
    ) external onlyOwner {
        tokenPublicMintsPerAddress[_tokenId] = _mintsAllowed;
    }

    /**
     * @notice Update the start time for public mint for a given token
     */
    function setTokenPublicSaleStartTime(
        uint256 _tokenId,
        uint256 _publicSaleStartTime
    ) external onlyOwner {
        require(_publicSaleStartTime > block.timestamp, "TIME_IN_PAST");
        tokenPublicSaleStartTime[_tokenId] = _publicSaleStartTime;
    }

    /**
     * @notice Update the end time for public mint for a given token
     */
    function setTokenPublicSaleEndTime(
        uint256 _tokenId,
        uint256 _publicSaleEndTime
    ) external onlyOwner {
        require(_publicSaleEndTime > block.timestamp, "TIME_IN_PAST");
        tokenPublicSaleEndTime[_tokenId] = _publicSaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic public sale times for a given token
     */
    function setTokenUsePublicSaleTimes(
        uint256 _tokenId,
        bool _usePublicSaleTimes
    ) external onlyOwner {
        require(
            tokenUsePublicSaleTimes[_tokenId] != _usePublicSaleTimes,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenUsePublicSaleTimes[_tokenId] = _usePublicSaleTimes;
    }

    /**
     * @notice Returns if public sale times are active for a given token
     */
    function tokenPublicSaleTimeIsActive(uint256 _tokenId)
        public
        view
        returns (bool)
    {
        if (tokenUsePublicSaleTimes[_tokenId] == false) {
            return true;
        }
        return
            block.timestamp >= tokenPublicSaleStartTime[_tokenId] &&
            block.timestamp <= tokenPublicSaleEndTime[_tokenId];
    }

    /**
     * @notice Allow for public minting of tokens for a given token
     */
    function mintToken(uint256 _tokenId, uint256 _numTokens)
        external
        payable
        originalUser
        nonReentrant
    {
        require(tokenPublicSaleActive[_tokenId], "PUBLIC_SALE_IS_NOT_ACTIVE");
        require(
            tokenPublicSaleTimeIsActive(_tokenId),
            "PUBLIC_SALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            tokenPublicMintsPerAddress[_tokenId] == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                tokenPublicMintsPerAddress[_tokenId],
            "MAX_MINTS_FOR_ADDRESS_EXCEEDED"
        );
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + _numTokens <= tokenMaxSupply[_tokenId],
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == tokenPublicPrice[_tokenId] * _numTokens,
            "PAYMENT_INCORRECT"
        );
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );

        tokensMintedByAddress[msg.sender][_tokenId] += _numTokens;
        _mint(msg.sender, _tokenId, _numTokens, "");

        if (
            tokenMaxSupply[_tokenId] != 0 &&
            totalSupply(_tokenId) >= tokenMaxSupply[_tokenId]
        ) {
            tokenPublicSaleActive[_tokenId] = false;
        }
    }

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setPresaleSignerAddress(address _presaleSignerAddress)
        external
        onlyOwner
    {
        require(_presaleSignerAddress != address(0));
        presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice To be updated by contract owner to allow presale minting for a given token
     */
    function setTokenPresaleState(uint256 _tokenId, bool _saleActiveState)
        external
        onlyOwner
    {
        require(
            tokenPresaleSaleActive[_tokenId] != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenPresaleSaleActive[_tokenId] = _saleActiveState;
    }

    /**
     * @notice Update the presale mint price for a given token
     */
    function setTokenPresalePrice(uint256 _tokenId, uint256 _presalePrice)
        external
        onlyOwner
    {
        tokenPresalePrice[_tokenId] = _presalePrice;
    }

    /**
     * @notice Set the maximum presale mints allowed per a given address for a given token
     */
    function setTokenPresaleMintsAllowedPerAddress(
        uint256 _tokenId,
        uint256 _mintsAllowed
    ) external onlyOwner {
        tokenPresaleMintsPerAddress[_tokenId] = _mintsAllowed;
    }

    /**
     * @notice Reduce the presale max supply of tokens for a given token id
     * @param _newPresaleMaxSupply The new maximum supply of tokens available to mint
     * @param _tokenId The token id to reduce the max supply for
     */
    function reducePresaleMaxSupply(
        uint256 _tokenId,
        uint256 _newPresaleMaxSupply
    ) external onlyOwner {
        require(
            tokenPresaleMaxSupply[_tokenId] == 0 ||
                _newPresaleMaxSupply < tokenPresaleMaxSupply[_tokenId],
            "NEW_MAX_SUPPLY_TOO_HIGH"
        );
        tokenPresaleMaxSupply[_tokenId] = _newPresaleMaxSupply;
    }

    /**
     * @notice Update the start time for presale mint for a given token
     */
    function setTokenPresaleStartTime(
        uint256 _tokenId,
        uint256 _presaleStartTime
    ) external onlyOwner {
        require(_presaleStartTime > block.timestamp, "TIME_IN_PAST");
        tokenPresaleSaleStartTime[_tokenId] = _presaleStartTime;
    }

    /**
     * @notice Update the end time for presale mint for a given token
     */
    function setTokenPresaleEndTime(uint256 _tokenId, uint256 _presaleEndTime)
        external
        onlyOwner
    {
        require(_presaleEndTime > block.timestamp, "TIME_IN_PAST");
        tokenPresaleSaleEndTime[_tokenId] = _presaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic presale times for a given token
     */
    function setTokenUsePresaleTimes(uint256 _tokenId, bool _usePresaleTimes)
        external
        onlyOwner
    {
        require(
            tokenUsePresaleTimes[_tokenId] != _usePresaleTimes,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenUsePresaleTimes[_tokenId] = _usePresaleTimes;
    }

    /**
     * @notice Returns if presale times are active for a given token
     */
    function tokenPresaleTimeIsActive(uint256 _tokenId)
        public
        view
        returns (bool)
    {
        if (tokenUsePresaleTimes[_tokenId] == false) {
            return true;
        }
        return
            block.timestamp >= tokenPresaleSaleStartTime[_tokenId] &&
            block.timestamp <= tokenPresaleSaleEndTime[_tokenId];
    }

    /**
     * @notice Verify that a signed message is validly signed by the presaleSignerAddress
     */
    function verifySignerAddress(
        bytes32 _messageHash,
        bytes calldata _signature
    ) private view returns (bool) {
        return
            presaleSignerAddress ==
            _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Allow for allowlist minting of tokens
     */
    function presaleMint(
        bytes32 _messageHash,
        bytes calldata _signature,
        uint256 _tokenId,
        uint256 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable originalUser nonReentrant {
        require(tokenPresaleSaleActive[_tokenId], "PRESALE_IS_NOT_ACTIVE");
        require(
            tokenPresaleTimeIsActive(_tokenId),
            "PRESALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        require(
            tokenPresaleMintsPerAddress[_tokenId] == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                tokenPresaleMintsPerAddress[_tokenId],
            "MAX_MINTS_PER_ADDRESS_EXCEEDED"
        );
        require(
            _maximumAllowedMints == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                _maximumAllowedMints,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            tokenPresaleMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + _numTokens <=
                tokenPresaleMaxSupply[_tokenId],
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == tokenPresalePrice[_tokenId] * _numTokens,
            "PAYMENT_INCORRECT"
        );
        require(
            keccak256(abi.encode(msg.sender, _maximumAllowedMints, _tokenId)) ==
                _messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(_messageHash, _signature),
            "SIGNATURE_VALIDATION_FAILED"
        );

        tokensMintedByAddress[msg.sender][_tokenId] += _numTokens;
        _mint(msg.sender, _tokenId, _numTokens, "");

        if (
            tokenPresaleMaxSupply[_tokenId] != 0 &&
            totalSupply(_tokenId) >= tokenPresaleMaxSupply[_tokenId]
        ) {
            tokenPresaleSaleActive[_tokenId] = false;
        }
    }

    /**
     * @notice Freeze all payout addresses and percentages so they can never be changed again
     */
    function freezePayoutAddresses() external onlyOwner {
        require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_ALREADY_FROZEN");
        payoutAddressesFrozen = true;
    }

    /**
     * @notice Update payout addresses and basis points for each addresses' respective share of contract funds
     */
    function updatePayoutAddressesAndBasisPoints(
        address[] calldata _payoutAddresses,
        uint256[] calldata _payoutBasisPoints
    ) external onlyOwner {
        require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_FROZEN");
        require(
            _payoutAddresses.length == _payoutBasisPoints.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < _payoutBasisPoints.length; i++) {
            totalBasisPoints += _payoutBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "TOTAL_BASIS_POINTS_MUST_BE_10000");
        payoutAddresses = _payoutAddresses;
        payoutBasisPoints = _payoutBasisPoints;
    }

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 amount = (balance * payoutBasisPoints[i]) / 10000;
            (bool success, ) = payoutAddresses[i].call{value: amount}("");
            require(success, "Transfer failed.");
        }
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
     * @notice Override default ERC-1155 setApprovalForAll to require that the operator is not from a blocklisted exchange
     * @param operator Address to add to the set of authorized operators
     * @param approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
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
        uint256[] calldata _exchanges,
        bool[] calldata _blocklisted
    ) external onlyOwner {
        require(
            _exchanges.length == _blocklisted.length,
            "ARRAYS_MUST_BE_SAME_LENGTH"
        );
        for (uint256 i = 0; i < _exchanges.length; i++) {
            isExchangeBlocklisted[_exchanges[i]] = _blocklisted[i];
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        uint256 operatorExchangeId = IExchangeOperatorAddressList(
            blocklistContractAddress
        ).operatorAddressToExchange(operator);
        require(
            blocklistPermanentlyDisabled ||
                !isExchangeBlocklisted[operatorExchangeId],
            "BLOCKLISTED_EXCHANGE"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

interface IExchangeOperatorAddressList {
    function operatorAddressToExchange(address operatorAddress)
        external
        view
        returns (uint256);
}