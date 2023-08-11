// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {TOKEN_TYPE_NATIVE, TOKEN_TYPE_ERC20, TOKEN_TYPE_ERC721, TOKEN_TYPE_ERC1155} from "./lib/TokenType.sol";
import {BURN_TYPE_CONTRACT_BURN, BURN_TYPE_SEND_TO_DEAD} from "./lib/BurnType.sol";
import {MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "./lib/MinterStructs.sol";
import {ReentrancyGuard} from "./lib/ReentrancyGuard.sol";
import {ILayerrMinter} from "./interfaces/ILayerrMinter.sol";
import {ILayerr20} from "./interfaces/ILayerr20.sol";
import {ILayerr721} from "./interfaces/ILayerr721.sol";
import {ILayerr721A} from "./interfaces/ILayerr721A.sol";
import {ILayerr1155} from "./interfaces/ILayerr1155.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {IDelegationRegistry} from "./interfaces/IDelegationRegistry.sol";
import {MerkleProof} from "./lib/MerkleProof.sol";
import {SignatureVerification} from "./lib/SignatureVerification.sol";

/**
 * @title LayerrMinter
 * @author 0xth0mas (Layerr)
 * @notice LayerrMinter is an unowned immutable primative for ERC20, ERC721 and ERC1155
 *         token minting on EVM-based blockchains. Token contract owners build and sign
 *         MintParameters which are used by minters to create MintOrders to mint tokens.
 *         MintParameters define what to mint and conditions for minting.
 *         Conditions for minting include requiring tokens be burned, payment amounts,
 *         start time, end time, additional oracle signature, maximum supply, max per 
 *         wallet and max signature use.
 *         Mint tokens can be ERC20, ERC721 or ERC1155
 *         Burn tokens can be ERC20, ERC721 or ERC1155
 *         Payment tokens can be the chain native token or ERC20
 *         Payment tokens can specify a referral BPS to pay a referral fee at time of mint
 *         LayerrMinter has native support for delegate.cash delegation on allowlist mints
 */
contract LayerrMinter is ILayerrMinter, ReentrancyGuard, SignatureVerification {

    /// @dev mapping of signature digests that have been marked as invalid for a token contract
    mapping(address => mapping(bytes32 => bool)) public signatureInvalid;

    /// @dev counter for number of times a signature has been used, only incremented if signatureMaxUses > 0
    mapping(bytes32 => uint256) public signatureUseCount;

    /// @dev mapping of addresses that are allowed signers for token contracts
    mapping(address => mapping(address => bool)) public contractAllowedSigner;

    /// @dev mapping of addresses that are allowed oracle signers for token contracts
    mapping(address => mapping(address => bool)) public contractAllowedOracle;

    /// @dev mapping of nonces for signers, used to invalidate all previously signed MintParameters
    mapping(address => uint256) public signerNonce;

    /// @dev address to send tokens when burn type is SEND_TO_DEAD
    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// @dev delegate.cash registry for users that want to use a hot wallet for minting an allowlist mint
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    /**
     * @inheritdoc ILayerrMinter
     */
    function setContractAllowedSigner(address _signer, bool _allowed) external {
        contractAllowedSigner[msg.sender][_signer] = _allowed;

        emit ContractAllowedSignerUpdate(msg.sender, _signer, _allowed);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function setContractAllowedOracle(address _oracle, bool _allowed) external {
        contractAllowedOracle[msg.sender][_oracle] = _allowed;

        emit ContractOracleUpdated(msg.sender, _oracle, _allowed);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function incrementSignerNonce() external {
        unchecked {
            signerNonce[msg.sender] += uint256(
                keccak256(abi.encodePacked(block.timestamp))
            );
        }

        emit SignerNonceIncremented(msg.sender, signerNonce[msg.sender]);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function incrementNonceFor(address signer, bytes calldata signature) external {
        if(!_validateIncrementNonceSigner(signer, signerNonce[signer], signature)) revert InvalidSignatureToIncrementNonce();
        unchecked {
            signerNonce[signer] += uint256(
                keccak256(abi.encodePacked(block.timestamp))
            );
        }

        emit SignerNonceIncremented(signer, signerNonce[signer]);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function setSignatureValidity(
        bytes32[] calldata signatureDigests,
        bool invalid
    ) external {
        for (uint256 i; i < signatureDigests.length; ) {
            signatureInvalid[msg.sender][signatureDigests[i]] = invalid;
            emit SignatureValidityUpdated(msg.sender, invalid, signatureDigests[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mint(
        MintOrder calldata mintOrder
    ) external payable NonReentrant {
        _processMintOrder(msg.sender, mintOrder, 0);

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintBatch(
        MintOrder[] calldata mintOrders
    ) external payable NonReentrant {
        uint256 suppliedBurnTokenIdIndex = 0;

        for (uint256 orderIndex; orderIndex < mintOrders.length; ) {
            MintOrder calldata mintOrder = mintOrders[orderIndex];

            suppliedBurnTokenIdIndex = _processMintOrder(msg.sender, mintOrder, suppliedBurnTokenIdIndex);

            unchecked {
                ++orderIndex;
            }
        }

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintTo(
        address mintToWallet,
        MintOrder calldata mintOrder,
        uint256 paymentContext
    ) external payable NonReentrant {
        _processMintOrder(mintToWallet, mintOrder, 0);

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintBatchTo(
        address mintToWallet,
        MintOrder[] calldata mintOrders,
        uint256 paymentContext
    ) external payable NonReentrant {
        uint256 suppliedBurnTokenIdIndex = 0;

        for (uint256 orderIndex; orderIndex < mintOrders.length; ) {
            MintOrder calldata mintOrder = mintOrders[orderIndex];

            suppliedBurnTokenIdIndex = _processMintOrder(mintToWallet, mintOrder, suppliedBurnTokenIdIndex);

            unchecked {
                ++orderIndex;
            }
        }

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @notice Validates mint parameters, processes payments and burns, mint tokens
     * @param mintToWallet address that tokens will be minted to
     * @param mintOrder struct containing the mint order details
     * @param suppliedBurnTokenIdIndex the current burn token index before processing the mint order
     * @return suppliedBurnTokenIdIndex the current burn token index after processing the mint order
     */
    function _processMintOrder(
        address mintToWallet, 
        MintOrder calldata mintOrder, 
        uint256 suppliedBurnTokenIdIndex
    ) internal returns (uint256) {
        MintParameters calldata mintParameters = mintOrder.mintParameters;
        bytes calldata mintParametersSignature = mintOrder.mintParametersSignature;
        uint256 quantity = mintOrder.quantity;

        (address mintParametersSigner, bytes32 mintParametersDigest) = _recoverMintParametersSigner(
            mintParameters,
            mintParametersSignature
        );

        (bool useDelegate, address oracleSigner) = _validateMintParameters(mintToWallet, mintOrder, mintParametersSignature, mintParametersSigner, mintParametersDigest);

        _processPayments(
            quantity,
            mintParameters.paymentTokens,
            mintOrder.referrer
        );
        if(mintParameters.burnTokens.length > 0) {
            suppliedBurnTokenIdIndex = _processBurns(
                quantity,
                suppliedBurnTokenIdIndex,
                mintParameters.burnTokens,
                mintOrder.suppliedBurnTokenIds
            );
        }

        address mintCountWallet;
        if(useDelegate) {
            mintCountWallet = mintOrder.vaultWallet;
        } else {
            mintCountWallet = mintToWallet;
        }
        
        _processMints(
            mintParameters.mintTokens,
            mintParametersSigner,
            mintParametersDigest,
            oracleSigner,
            quantity,
            mintCountWallet,
            mintToWallet
        );

        emit MintOrderFulfilled(mintParametersDigest, mintToWallet, quantity);

        return suppliedBurnTokenIdIndex;
    }

    /**
     * @notice Checks the MintParameters for start/end time compliance, signer nonce, allowlist, signature max uses and oracle signature
     * @param mintToWallet address tokens will be minted to
     * @param mintOrder struct containing the mint order details 
     * @param mintParametersSignature EIP712 signature of the MintParameters
     * @param mintParametersSigner recovered signer of the mintParametersSignature
     * @param mintParametersDigest hash digest of the MintParameters
     * @return useDelegate true for allowlist mint that mintToWallet 
     * @return oracleSigner recovered address of the oracle signer if oracle signature is required or address(0) if oracle signature is not required
     */
    function _validateMintParameters(
        address mintToWallet, 
        MintOrder calldata mintOrder, 
        bytes calldata mintParametersSignature, 
        address mintParametersSigner, 
        bytes32 mintParametersDigest
    ) internal returns(bool useDelegate, address oracleSigner) {
        MintParameters calldata mintParameters = mintOrder.mintParameters;
        if (mintParameters.startTime > block.timestamp) {
            revert MintHasNotStarted();
        }
        if (mintParameters.endTime < block.timestamp) {
            revert MintHasEnded();
        }
        if (signerNonce[mintParametersSigner] != mintParameters.nonce) {
            revert SignerNonceInvalid();
        }
        if (mintParameters.merkleRoot != bytes32(0)) {
            if (
                !MerkleProof.verifyCalldata(
                    mintOrder.merkleProof,
                    mintParameters.merkleRoot,
                    keccak256(abi.encodePacked(mintToWallet))
                )
            ) {
                address vaultWallet = mintOrder.vaultWallet;
                if(vaultWallet == address(0)) {
                    revert InvalidMerkleProof();
                } else {
                    // check delegate for all first as it's more likely than delegate for contract, saves 3200 gas
                    if(!delegateCash.checkDelegateForAll(mintToWallet, vaultWallet)) {
                        if(!delegateCash.checkDelegateForContract(mintToWallet, vaultWallet, address(this))) {
                            revert InvalidMerkleProof();
                        }
                    }
                    if (
                        MerkleProof.verifyCalldata(
                            mintOrder.merkleProof,
                            mintParameters.merkleRoot,
                            keccak256(abi.encodePacked(vaultWallet))
                        )
                    ) {
                        useDelegate = true;
                    } else {
                        revert InvalidMerkleProof();
                    }
                }
            }
        }
        
        if (mintParameters.signatureMaxUses != 0) {
            signatureUseCount[mintParametersDigest] += mintOrder.quantity;
            if (signatureUseCount[mintParametersDigest] > mintParameters.signatureMaxUses) {
                revert ExceedsMaxSignatureUsage();
            }
        }

        if(mintParameters.oracleSignatureRequired) {
            oracleSigner = _recoverOracleSigner(mintToWallet, mintParametersSignature, mintOrder.oracleSignature);
            if(oracleSigner == address(0)) {
                revert InvalidOracleSignature();
            }
        }
    }

    /**
     * @notice Iterates over payment tokens and sends payment amounts to recipients. 
     *         If there is a referrer and a payment token has a referralBPS the referral amount is split and sent to the referrer
     *         Payment token types can be native token or ERC20.
     * @param mintOrderQuantity multipier for each payment token
     * @param paymentTokens array of payment tokens for a mint order
     * @param referrer wallet address of user that made the referral for this sale
     */
    function _processPayments(
        uint256 mintOrderQuantity,
        PaymentToken[] calldata paymentTokens,
        address referrer
    ) internal {
        for (uint256 paymentTokenIndex = 0; paymentTokenIndex < paymentTokens.length; ) {
            PaymentToken calldata paymentToken = paymentTokens[paymentTokenIndex];
            uint256 paymentAmount = paymentToken.paymentAmount * mintOrderQuantity;
            uint256 tokenType = paymentToken.tokenType;

            if (tokenType == TOKEN_TYPE_NATIVE) {
                if(referrer == address(0) || paymentToken.referralBPS == 0) {
                    _transferNative(paymentToken.payTo, paymentAmount);
                } else {
                    uint256 referrerPayment = paymentAmount * paymentToken.referralBPS / 10000;
                    _transferNative(referrer, referrerPayment);
                    paymentAmount -= referrerPayment;
                    _transferNative(paymentToken.payTo, paymentAmount);
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                if(referrer == address(0) || paymentToken.referralBPS == 0) {
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        paymentToken.payTo,
                        paymentAmount
                    );
                } else {
                    uint256 referrerPayment = paymentAmount * paymentToken.referralBPS / 10000;
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        referrer,
                        referrerPayment
                    );
                    paymentAmount -= referrerPayment;
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        paymentToken.payTo,
                        paymentAmount
                    );
                }
            } else {
                revert InvalidPaymentTokenType();
            }
            unchecked {
                ++paymentTokenIndex;
            }
        }
    }

    /**
     * @notice Processes burns for a mint order. Burn tokens can be ERC20, ERC721, or ERC1155. Burn types can be
     *         contract burns or send to dead address.
     * @param mintOrderQuantity multiplier for each burn token
     * @param suppliedBurnTokenIdIndex current index for the supplied burn token ids before processing burns
     * @param burnTokens array of burn tokens for a mint order
     * @param suppliedBurnTokenIds array of burn token ids supplied by minter
     * @return suppliedBurnTokenIdIndex current index for the supplied burn token ids after processing burns
     */
    function _processBurns(
        uint256 mintOrderQuantity,
        uint256 suppliedBurnTokenIdIndex,
        BurnToken[] calldata burnTokens,
        uint256[] calldata suppliedBurnTokenIds
    ) internal returns (uint256) {
        for (uint256 burnTokenIndex = 0; burnTokenIndex < burnTokens.length; ) {
            BurnToken calldata burnToken = burnTokens[burnTokenIndex];

            address contractAddress = burnToken.contractAddress;
            uint256 tokenId = burnToken.tokenId;
            bool specificTokenId = burnToken.specificTokenId;
            uint256 burnType = burnToken.burnType;
            uint256 tokenType = burnToken.tokenType;
            uint256 burnAmount = burnToken.burnAmount * mintOrderQuantity;

            if (tokenType == TOKEN_TYPE_ERC1155) {
                uint256 burnTokenEnd = burnTokenIndex;
                for (; burnTokenEnd < burnTokens.length; ) {
                    if (burnTokens[burnTokenEnd].contractAddress != contractAddress) {
                        break;
                    }
                    unchecked {
                        ++burnTokenEnd;
                    }
                }
                unchecked { --burnTokenEnd; }
                if (burnTokenEnd == burnTokenIndex) {
                    if (specificTokenId) {
                        if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                            revert InvalidBurnTokenId();
                        }
                    }
                    if (burnType == BURN_TYPE_CONTRACT_BURN) {
                        ILayerr1155(contractAddress).burnTokenId(
                            msg.sender,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex],
                            burnAmount
                        );
                    } else if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                        IERC1155(contractAddress).safeTransferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex],
                            burnAmount,
                            ""
                        );
                    } else {
                        revert InvalidBurnType();
                    }
                    unchecked {
                        ++suppliedBurnTokenIdIndex;
                    }
                } else {
                    unchecked {
                        ++burnTokenEnd;
                    }
                    uint256[] memory burnTokenIds = new uint256[]((burnTokenEnd - burnTokenIndex));
                    uint256[] memory burnTokenAmounts = new uint256[]((burnTokenEnd - burnTokenIndex));
                    for (uint256 arrayIndex = 0; burnTokenIndex < burnTokenEnd; ) {
                        burnToken = burnTokens[burnTokenIndex];
                        specificTokenId = burnToken.specificTokenId;
                        tokenId = burnToken.tokenId;
                        burnAmount = burnToken.burnAmount * mintOrderQuantity;

                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }

                        burnTokenIds[arrayIndex] = suppliedBurnTokenIds[suppliedBurnTokenIdIndex];
                        burnTokenAmounts[arrayIndex] = burnAmount;
                        unchecked {
                            ++burnTokenIndex;
                            ++arrayIndex;
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                    unchecked {
                        --burnTokenIndex;
                    }
                    if (burnType == BURN_TYPE_CONTRACT_BURN) {
                        ILayerr1155(contractAddress).burnBatchTokenIds(
                            msg.sender,
                            burnTokenIds,
                            burnTokenAmounts
                        );
                    } else if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                        IERC1155(contractAddress).safeBatchTransferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            burnTokenIds,
                            burnTokenAmounts,
                            ""
                        );
                    } else {
                        revert InvalidBurnType();
                    }
                }
            } else if (tokenType == TOKEN_TYPE_ERC721) {
                if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                    if (burnAmount > 1) {
                        if (specificTokenId) {
                            revert CannotBurnMultipleERC721WithSameId();
                        }
                        for (uint256 burnCounter = 0; burnCounter < burnAmount; ) {
                            IERC721(contractAddress).transferFrom(
                                msg.sender,
                                DEAD_ADDRESS,
                                suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                            );
                            unchecked {
                                ++burnCounter;
                                ++suppliedBurnTokenIdIndex;
                            }
                        }
                    } else {
                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }
                        IERC721(contractAddress).transferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                        );
                        unchecked {
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                } else if (burnType == BURN_TYPE_CONTRACT_BURN) {
                    if (burnAmount > 1) {
                        if (specificTokenId) {
                            revert CannotBurnMultipleERC721WithSameId();
                        }
                        uint256[] memory burnTokenIds = new uint256[](burnAmount);
                        for (uint256 arrayIndex = 0; arrayIndex < burnAmount;) {
                            burnTokenIds[arrayIndex] = suppliedBurnTokenIds[suppliedBurnTokenIdIndex];
                            unchecked {
                                ++arrayIndex;
                                ++suppliedBurnTokenIdIndex;
                            }
                        }
                        ILayerr721(contractAddress).burnBatchTokenIds(msg.sender, burnTokenIds);
                    } else {
                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }
                        ILayerr721(contractAddress).burnTokenId(
                            msg.sender,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                        );
                        unchecked {
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                } else {
                    revert InvalidBurnType();
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                    _transferERC20(
                        contractAddress,
                        msg.sender,
                        DEAD_ADDRESS,
                        burnAmount
                    );
                } else if (burnType == BURN_TYPE_CONTRACT_BURN) {
                    ILayerr20(contractAddress).burn(msg.sender, burnAmount);
                } else {
                    revert InvalidBurnType();
                }
            } else {
                revert InvalidBurnTokenType();
            }
            unchecked {
                ++burnTokenIndex;
            }
        }

        return suppliedBurnTokenIdIndex;
    }

    /**
     * @notice Processes mints for a mint order. Token types can be ERC20, ERC721, or ERC1155. 
     * @param mintTokens array of mint tokens from the mint order
     * @param mintParametersSigner recovered address from the mint parameters signature
     * @param mintParametersDigest hash digest of the supplied mint parameters
     * @param oracleSigner recovered address of the oracle signer if oracle signature required was true, address(0) otherwise
     * @param mintOrderQuantity multiplier for each mint token
     * @param mintCountWallet wallet address that will be used for checking max per wallet mint conditions
     * @param mintToWallet wallet address that tokens will be minted to
     */
    function _processMints(
        MintToken[] calldata mintTokens,
        address mintParametersSigner,
        bytes32 mintParametersDigest,
        address oracleSigner,
        uint256 mintOrderQuantity,
        address mintCountWallet,
        address mintToWallet
    ) internal {
        uint256 mintTokenIndex;
        uint256 mintTokensLength = mintTokens.length;
        for ( ; mintTokenIndex < mintTokensLength; ) {
            MintToken calldata mintToken = mintTokens[mintTokenIndex];

            address contractAddress = mintToken.contractAddress;
            _checkContractSigners(contractAddress, mintParametersSigner, mintParametersDigest, oracleSigner);

            uint256 tokenId = mintToken.tokenId;
            uint256 maxSupply = mintToken.maxSupply;
            uint256 maxMintPerWallet = mintToken.maxMintPerWallet;
            bool specificTokenId = mintToken.specificTokenId;
            uint256 mintAmount = mintToken.mintAmount * mintOrderQuantity;
            uint256 tokenType = mintToken.tokenType;

            if (tokenType == TOKEN_TYPE_ERC1155) {
                uint256 mintTokenEnd = mintTokenIndex;
                for (; mintTokenEnd < mintTokensLength; ) {
                    if (mintTokens[mintTokenEnd].contractAddress != contractAddress) {
                        break;
                    }
                    unchecked {
                        ++mintTokenEnd;
                    }
                }
                unchecked { --mintTokenEnd; }
                if (mintTokenEnd == mintTokenIndex) {
                    _checkERC1155MintQuantities(contractAddress, tokenId, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                    ILayerr1155(contractAddress).mintTokenId(
                        mintCountWallet,
                        mintToWallet,
                        tokenId,
                        mintAmount
                    );
                } else {
                    unchecked {
                        ++mintTokenEnd;
                    }
                    uint256[] memory mintTokenIds = new uint256[]((mintTokenEnd - mintTokenIndex));
                    uint256[] memory mintTokenAmounts = new uint256[]((mintTokenEnd - mintTokenIndex));
                    for (uint256 arrayIndex = 0; mintTokenIndex < mintTokenEnd; ) {
                        mintToken = mintTokens[mintTokenIndex];
                        maxSupply = mintToken.maxSupply;
                        maxMintPerWallet = mintToken.maxMintPerWallet;
                        tokenId = mintToken.tokenId;
                        mintAmount = mintToken.mintAmount * mintOrderQuantity;

                        _checkERC1155MintQuantities(contractAddress, tokenId, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                        mintTokenIds[arrayIndex] = tokenId;
                        mintTokenAmounts[arrayIndex] = mintAmount;
                        unchecked {
                            ++mintTokenIndex;
                            ++arrayIndex;
                        }
                    }
                    unchecked {
                        --mintTokenIndex;
                    }
                    ILayerr1155(contractAddress)
                        .mintBatchTokenIds(
                            mintCountWallet,
                            mintToWallet,
                            mintTokenIds,
                            mintTokenAmounts
                        );
                }
            } else if (tokenType == TOKEN_TYPE_ERC721) {
                _checkERC721MintQuantities(contractAddress, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                if (!specificTokenId || mintAmount > 1) {
                    if (specificTokenId) {
                        revert CannotMintMultipleERC721WithSameId();
                    }
                    ILayerr721A(contractAddress).mintSequential(mintCountWallet, mintToWallet, mintAmount);
                } else {
                    ILayerr721(contractAddress).mintTokenId(mintCountWallet, mintToWallet, tokenId);
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                _checkERC20MintQuantities(contractAddress, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);
                ILayerr20(contractAddress).mint(mintCountWallet, mintToWallet, mintAmount);
            } else {
                revert InvalidMintTokenType();
            }
            unchecked {
                ++mintTokenIndex;
            }
        }
    }

    /**
     * @notice Checks the mint parameters and oracle signers to ensure they are authorized for the token contract.
     *         Checks that the mint parameters signature digest has not been marked as invalid.
     * @param contractAddress token contract to check signers for
     * @param mintParametersSigner recovered signer for the mint parameters
     * @param mintParametersDigest hash digest of the supplied mint parameters 
     * @param oracleSigner recovered oracle signer if oracle signature is required by mint parameters
     */
    function _checkContractSigners(address contractAddress, address mintParametersSigner, bytes32 mintParametersDigest, address oracleSigner) internal view {
        if (!contractAllowedSigner[contractAddress][mintParametersSigner]) {
            revert NotAllowedSigner();
        }
        if (signatureInvalid[contractAddress][mintParametersDigest]) {
            revert SignatureInvalid();
        }
        if(oracleSigner != address(0)) {
            if(!contractAllowedOracle[contractAddress][oracleSigner]) {
                revert InvalidOracleSignature();
            }
        }
    }

    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param tokenId id of the token to check
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC1155MintQuantities(address contractAddress, uint256 tokenId, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr1155(contractAddress).totalMintedCollectionAndMinter(mintCountWallet, tokenId);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }


    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC721MintQuantities(address contractAddress, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr721(contractAddress).totalMintedCollectionAndMinter(mintCountWallet);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }


    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC20MintQuantities(address contractAddress, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr20(contractAddress).totalMintedTokenAndMinter(mintCountWallet);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }

    /**
     * @notice Transfers `amount` of native token to `to` address. Reverts if the transfer fails.
     * @param to address to send native token to
     * @param amount amount of native token to send
     */
    function _transferNative(address to, uint256 amount) internal {
        (bool sent, ) = payable(to).call{value: amount}("");
        if (!sent) {
            if(address(this).balance < amount) {
                revert InsufficientPayment();
            } else {
                revert PaymentFailed();
            }
        }
    }

    /**
     * @notice Transfers `amount` of ERC20 token from `from` address to `to` address.
     * @param contractAddress ERC20 token address
     * @param from address to transfer ERC20 tokens from
     * @param to address to send ERC20 tokens to
     * @param amount amount of ERC20 tokens to send
     */
    function _transferERC20(
        address contractAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(contractAddress).transferFrom(from, to, amount);
    }
}