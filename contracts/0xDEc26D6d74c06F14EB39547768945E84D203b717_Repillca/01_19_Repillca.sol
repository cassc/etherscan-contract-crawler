// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableOperatorFilterer.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting Repillca tokens.
 */
contract Repillca is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981,
    RevokableOperatorFilterer
{
    struct BurnToken {
        address contractAddress;
        uint8 tokenType;
        uint8 tokensPerBurn;
        uint16 tokenId;
    }

    // Array of tokens required to be burned for burnToMint
    BurnToken[] public burnTokens;
    // Address where burnt tokens are sent
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    // Default address to subscribe to for determining blocklisted exchanges
    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    // Address where HeyMint fees are sent
    address public heymintPayoutAddress =
        0xE1FaC470dE8dE91c66778eaa155C64c7ceEFc851;
    address public royaltyAddress = 0x2d62B7B4aB2aeA16f53f78aF3544088300040126;
    address[] public payoutAddresses = [
        0x2d62B7B4aB2aeA16f53f78aF3544088300040126
    ];
    // If true tokens can be burned in order to mint
    bool public burnClaimActive;
    bool public isPublicSaleActive;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen;
    // If true, payout addresses and basis points are permanently frozen and can never be updated
    bool public payoutAddressesFrozen;
    string public baseTokenURI =
        "ipfs://bafybeibhgndldgb7cvfcaftm4t243cepmh4i7rapfpmntl63klr4un2jq4/";
    // Maximum supply of tokens that can be minted
    uint256 public MAX_SUPPLY = 200;
    // Fee paid to HeyMint per NFT minted
    uint256 public heymintFeePerToken;
    uint256 public mintsPerBurn = 1;
    uint256 public publicMintsAllowedPerAddress = 1;
    uint256 public publicMintsAllowedPerTransaction = 200;
    uint256 public publicPrice = 0 ether;
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint256[] public payoutBasisPoints = [10000];
    uint96 public royaltyFee = 1200;

    constructor(uint256 _heymintFeePerToken)
        ERC721A("Repillca", "RPLCA")
        RevokableOperatorFilterer(
            0x000000000000AAeB6D7670E522A718067333cd4E,
            DEFAULT_SUBSCRIPTION,
            true
        )
    {
        heymintFeePerToken = _heymintFeePerToken;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
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
        burnTokens.push(
            BurnToken(0x3Cb83A3d0956F06cC42C8Fe197C4911309e1cC63, 2, 10, 1)
        );
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
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
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
     * @notice To be updated by contract owner to allow public sale minting
     */
    function setPublicSaleState(bool _saleActiveState) external onlyOwner {
        require(
            isPublicSaleActive != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isPublicSaleActive = _saleActiveState;
    }

    /**
     * @notice Update the public mint price
     */
    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the public sale
     */
    function setPublicMintsAllowedPerAddress(uint256 _mintsAllowed)
        external
        onlyOwner
    {
        publicMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum public mints allowed per a given transaction
     */
    function setPublicMintsAllowedPerTransaction(uint256 _mintsAllowed)
        external
        onlyOwner
    {
        publicMintsAllowedPerTransaction = _mintsAllowed;
    }

    /**
     * @notice Allow for public minting of tokens
     */
    function mint(uint256 numTokens)
        external
        payable
        nonReentrant
        originalUser
    {
        require(isPublicSaleActive, "PUBLIC_SALE_IS_NOT_ACTIVE");

        require(
            numTokens <= publicMintsAllowedPerTransaction,
            "MAX_MINTS_PER_TX_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <=
                publicMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        require(totalSupply() + numTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        uint256 heymintFee = numTokens * heymintFeePerToken;
        require(
            msg.value == publicPrice * numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );

        (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
        require(success, "Transfer failed.");
        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= MAX_SUPPLY) {
            isPublicSaleActive = false;
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
    function withdraw() external nonReentrant onlyOwner {
        require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 amount = (balance * payoutBasisPoints[i]) / 10000;
            (bool success, ) = payoutAddresses[i].call{value: amount}("");
            require(success, "Transfer failed.");
        }
    }

    /**
     * @notice To be updated by contract owner to allow burning to claim a token
     * @param _burnClaimActive If true tokens can be burned in order to mint
     */
    function setBurnClaimState(bool _burnClaimActive) external onlyOwner {
        require(
            burnClaimActive != _burnClaimActive,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        burnClaimActive = _burnClaimActive;
    }

    /**
     * @notice Update the number of tokens that can be minted per burn transaction
     * @param _mintsPerBurn The new number of tokens that can be minted per burn transaction
     */
    function updateMintsPerBurn(uint256 _mintsPerBurn) external onlyOwner {
        mintsPerBurn = _mintsPerBurn;
    }

    /**
     * @notice Set the contract address[es] of the NFT[s] to be burned in order to mint
     * @param _burnTokens An array of all tokens required for burning
     */
    function updateBurnTokens(BurnToken[] calldata _burnTokens)
        external
        onlyOwner
    {
        uint256 newBurnTokensLength = _burnTokens.length;
        uint256 oldBurnTokensLength = burnTokens.length;
        if (newBurnTokensLength < oldBurnTokensLength) {
            for (
                uint256 i = 0;
                i < oldBurnTokensLength - newBurnTokensLength;
                i++
            ) {
                burnTokens.pop();
            }
            for (uint256 i = 0; i < newBurnTokensLength; i++) {
                burnTokens[i] = _burnTokens[i];
            }
        } else {
            for (uint256 i = 0; i < oldBurnTokensLength; i++) {
                burnTokens[i] = _burnTokens[i];
            }
            for (
                uint256 i = oldBurnTokensLength;
                i < newBurnTokensLength;
                i++
            ) {
                burnTokens.push(_burnTokens[i]);
            }
        }
    }

    /**
     * @notice Burn tokens from other contracts in order to mint tokens on this contract
     * @dev This contract must be approved by the caller to transfer the tokens being burned
     * @param _contracts The contracts of the tokens to burn in the same order as the array burnTokens
     * @param _tokenIds Nested array of token ids to burn for 721 and amounts to burn for 1155 corresponding to _contracts
     *                  (for 1155, just pass in a single value array with the total amount to burn)
     * @param _tokensToMint The number of tokens to mint
     */
    function burnToMint(
        address[] calldata _contracts,
        uint256[][] calldata _tokenIds,
        uint256 _tokensToMint
    ) external payable nonReentrant originalUser {
        require(burnClaimActive, "NOT_ACTIVE");
        uint256 contractsLength = _contracts.length;
        uint256 burnTokenLength = burnTokens.length;
        require(
            contractsLength == _tokenIds.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        require(contractsLength == burnTokenLength, "ARRAY_LENGTHS_MUST_MATCH");
        require(burnTokenLength > 0, "NO_BURN_TOKENS_SET");
        require(
            totalSupply() + _tokensToMint <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 heymintFee = heymintFeePerToken * _tokensToMint;
        require(msg.value == heymintFee, "PAYMENT_INCORRECT");
        (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
        require(success, "Transfer failed.");
        for (uint256 i = 0; i < burnTokenLength; i++) {
            BurnToken memory burnToken = burnTokens[i];
            require(
                burnToken.contractAddress == _contracts[i],
                "INCORRECT_CONTRACT"
            );
            if (burnToken.tokenType == 1) {
                uint256 _tokenIdsLength = _tokenIds[i].length;
                require(
                    (_tokenIdsLength / burnToken.tokensPerBurn) *
                        mintsPerBurn ==
                        _tokensToMint,
                    "INCORRECT_NO_OF_TOKENS_TO_BURN"
                );
                for (uint256 j = 0; j < _tokenIdsLength; j++) {
                    ERC721A burnContract = ERC721A(_contracts[i]);
                    uint256 tokenId = _tokenIds[i][j];
                    require(
                        burnContract.ownerOf(tokenId) == msg.sender,
                        "MUST_OWN_TOKEN"
                    );
                    burnContract.transferFrom(msg.sender, burnAddress, tokenId);
                }
            } else if (burnToken.tokenType == 2) {
                uint256 amountToBurn = _tokenIds[i][0];
                require(
                    (amountToBurn / burnToken.tokensPerBurn) * mintsPerBurn ==
                        _tokensToMint,
                    "INCORRECT_NO_OF_TOKENS_TO_BURN"
                );
                IERC1155 burnContract = IERC1155(_contracts[i]);
                require(
                    burnContract.balanceOf(msg.sender, burnToken.tokenId) >=
                        amountToBurn,
                    "MUST_OWN_TOKEN"
                );
                burnContract.safeTransferFrom(
                    msg.sender,
                    burnAddress,
                    burnToken.tokenId,
                    amountToBurn,
                    ""
                );
            }
        }

        _safeMint(msg.sender, _tokensToMint);
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
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }
}