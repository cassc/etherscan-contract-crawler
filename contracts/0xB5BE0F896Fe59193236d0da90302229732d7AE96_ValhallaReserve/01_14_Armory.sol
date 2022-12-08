// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./token/ERC1155/ERC1155.sol";
import "./utils/ERC2981.sol";
import "./utils/IERC165.sol";
import "./utils/Ownable.sol";
import "./utils/ECDSA.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    ██╗░░░██╗░█████╗░██╗░░░░░██╗░░██╗░█████╗░██╗░░░░░██╗░░░░░░█████╗░    //
//    ██║░░░██║██╔══██╗██║░░░░░██║░░██║██╔══██╗██║░░░░░██║░░░░░██╔══██╗    //
//    ╚██╗░██╔╝███████║██║░░░░░███████║███████║██║░░░░░██║░░░░░███████║    //
//    ░╚████╔╝░██╔══██║██║░░░░░██╔══██║██╔══██║██║░░░░░██║░░░░░██╔══██║    //
//    ░░╚██╔╝░░██║░░██║███████╗██║░░██║██║░░██║███████╗███████╗██║░░██║    //
//    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * Subset of the IOperatorFilterRegistry with only the methods that the main minting contract will call.
 * The owner of the collection is able to manage the registry subscription on the contract's behalf
 */
interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external returns (bool);
}

contract ValhallaReserve is ERC1155, Ownable, ERC2981 {
    using ECDSA for bytes32;

    // =============================================================
    //                            STRUCTS
    // =============================================================

    // Compiler will pack this into a 256bit word.
    struct SaleData {
        // unitPrice for each token for the general sale
        uint96 price;
        // Optional value to prevent a transaction from buying too much supply
        uint64 txLimit;
        // startTime for the sale of the tokens
        uint48 startTimestamp;
        // endTime for the sale of the tokens
        uint48 endTimestamp;
    }

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Address that houses the implemention to check if operators are allowed or not
    address public operatorFilterRegistryAddress;
    // Address this contract verifies with the registryAddress for allowed operators.
    address public filterRegistrant;

    // Address used for the mintSignature method
    address public signer;
    // Used to quickly invalidate batches of signatures if needed.
    uint256 public signatureVersion;
    // Mapping that shows if a tier is active or not
    mapping(uint256 => mapping(string => bool)) public isTierActive;
    mapping(bytes32 => bool) public signatureUsed;
    
    // For tokens that are open to a general sale.
    mapping(uint256 => SaleData) public generalSaleData;

    // Mapping of owner-approved contracts that can burn the user's tokens during a transaction
    mapping(address => mapping(uint256 => bool)) public approvedBurners;

    // =============================================================
    //                            Events
    // =============================================================

    event MintOpen(
        uint256 indexed tokenId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 price,
        uint256 txLimit
    );
    event MintClosed(uint256 indexed tokenId);

    // =============================================================
    //                          Constructor
    // =============================================================

    constructor () {
        _setName("ValhallaReserve");
        _setSymbol("RSRV");
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Allows the owner to set a new name for the collection.
     */
    function setName(string memory name) external onlyOwner {
        _setName(name);
    }

    /**
     * @dev Allows the owner to set a new symbol for the collection.
     */
    function setSymbol(string memory symbol) external onlyOwner {
        _setSymbol(symbol);
    }

    /**
     * @dev Allows the owner to add a new tokenId if it does not already exist.
     * 
     * @param tokenId TokenId that will get created
     * @param tokenMintLimit Token Supply for the tokenId. If 0, the supply is capped at uint64 max.
     * @param uri link pointing to the token metadata
     */
    function addTokenId(uint256 tokenId, uint64 tokenMintLimit, string calldata uri) external onlyOwner {
        _addTokenId(tokenId, tokenMintLimit, uri);
    }

    /**
     * @dev Allows the owner to set a new token URI for a single tokenId.
     * 
     * This tokenId must have already been added by `addTokenId`
     */
    function updateTokenURI(uint256 tokenId, string calldata uri) external onlyOwner {
        _updateMetadata(tokenId, uri);
    }

    /**
     * @dev Token supply can be set, but can ONLY BE LOWERED. It also cannot be lower than the current supply.
     *
     * This logic is gauranteed by the {_setTokenMintLimit} method
     */
    function setTokenMintLimit(uint256 tokenId, uint64 tokenMintLimit) external onlyOwner {
        _setTokenMintLimit(tokenId, tokenMintLimit);
    }
 
    // =============================================================
    //                 Operator Filter Registry
    // =============================================================

    /**
     * @dev Stops operators from being added as an approved address to transfer.
     * @param operator the address a wallet is trying to grant approval to.
     */
    function _beforeApproval(address operator) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, operator)
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeApproval(operator);
    }

    /**
     * @dev Stops operators that are not approved from doing transfers.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, msg.sender)
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice Allows the owner to set a new registrant contract.
     */
    function setOperatorFilterRegistryAddress(
        address registryAddress
    ) external onlyOwner {
        operatorFilterRegistryAddress = registryAddress;
    }

    /**
     * @notice Allows the owner to set a new registrant address.
     */
    function setFilterRegistrant(address newRegistrant) external onlyOwner {
        filterRegistrant = newRegistrant;
    }

    // =============================================================
    //                        Token Minting
    // =============================================================

    /**
     * @dev This function does a best effort to Owner mint. If a given tokenId is
     * over the token supply amount, it will mint as many are available and stop at the limit.
     * This is necessary so that a given transaction does not fail if another public mint
     * transaction happens to take place just before this one that would cause the amount of
     * minted tokens to go over a token limit.
     */
    function mintDev(
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyOwner {
        if (
            receivers.length != tokenIds.length ||
            receivers.length != amounts.length
        ) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < receivers.length; ) {
            uint256 buyLimit = _remainingSupply(tokenIds[i]);

            if (buyLimit != 0) {
                if (amounts[i] > buyLimit) {
                    _mint(receivers[i], tokenIds[i], buyLimit, "");
                } else {
                    _mint(receivers[i], tokenIds[i], amounts[i], "");
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows the owner to change the active version of their signatures, this also
     * allows a simple invalidation of all signatures they have created on old versions.
     */
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /**
     * @notice Allows the owner to change the active version of their signatures, this also
     * allows a simple invalidation of all signatures they have created on old versions.
     */
    function setSignatureVersion(uint256 version) external onlyOwner {
        signatureVersion = version;
    }

    /**
     * @notice Allows owner to sets if a certain tier is active or not.
     */
    function setIsTierActive(
        uint256 tokenId,
        string memory tier,
        bool active
    ) external onlyOwner {
        isTierActive[tokenId][tier] = active;
    }
    
    /**
     * @dev With the correct hash signed by the owner, a wallet can mint at
     * a unit price up to the quantity specified.
     */
    function mintSignature(
        string memory tier,
        uint256 tokenId,
        uint256 unitPrice,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256 buyAmount,
        bytes memory sig
    ) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);
        if (!isTierActive[tokenId][tier]) revert TierNotActive();
        if (buyAmount > amount || buyAmount == 0) revert InvalidSignatureBuyAmount();
        if (version != signatureVersion) revert InvalidSignatureVersion();
        uint256 totalPrice = unitPrice * buyAmount;
        if (msg.value != totalPrice) revert IncorrectMsgValue();

        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encode(
                    tier,
                    address(this),
                    tokenId,
                    unitPrice,
                    version,
                    nonce,
                    amount,
                    msg.sender
                )
            )
        );

        if (signatureUsed[hash]) revert SignatureAlreadyUsed();
        signatureUsed[hash] = true;
        if (hash.recover(sig) != signer) revert InvalidSignature();

        _mint(_msgSender(), tokenId, buyAmount, "");
    }

    /**
     * @dev Allows the owner to open the {mint} method for a certain tokenId
     * this method is to allow buyers to save gas on minting by not requiring a signature.
     */
    function openMint(
        uint256 tokenId,
        uint96 price,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint64 txLimit
    ) external onlyOwner {
        if(!exists(tokenId)) revert NonExistentToken();
        generalSaleData[tokenId].price = price;
        generalSaleData[tokenId].startTimestamp = startTimestamp;
        generalSaleData[tokenId].endTimestamp = endTimestamp;
        generalSaleData[tokenId].txLimit = txLimit;

        emit MintOpen(
            tokenId,
            startTimestamp,
            endTimestamp,
            price,
            txLimit
        );
    }

    /**
     * @dev Allows the owner to close the {generalMint} method to the public for a certain tokenId.
     */
    function closeMint(uint256 tokenId) external onlyOwner {
        delete generalSaleData[tokenId];
        emit MintClosed(tokenId);
    }

    /**
     * @dev Allows any user to buy a certain tokenId. This buy transaction is still limited by the
     * wallet mint limit, token supply limit, and transaction limit set for the tokenId. These are
     * all considered primary sales and will be split according to the withdrawal splits defined in the contract.
     */
    function mint(uint256 tokenId, uint256 buyAmount) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);
        if (block.timestamp < generalSaleData[tokenId].startTimestamp) revert MintNotActive();
        if (block.timestamp > generalSaleData[tokenId].endTimestamp) revert MintNotActive();
        if (
            generalSaleData[tokenId].txLimit != 0 &&
            buyAmount > generalSaleData[tokenId].txLimit
        ) {
            revert OverTransactionLimit();
        }

        if (msg.value != generalSaleData[tokenId].price * buyAmount) revert IncorrectMsgValue();
        _mint(_msgSender(), tokenId, buyAmount, "");
    }

    // =============================================================
    //                        Token Burning
    // =============================================================

    /**
     * @dev Owner can allow or pause holders from burning tokens of a certain
     * tokenId on without an intermediary contract.
     */
    function setBurnable(uint256 tokenId, bool burnable) external onlyOwner {
        _setBurnable(tokenId, burnable);
    }

    /**
     * @dev Allows token owners to burn tokens if self-burn is enabled for that token.
     */
    function burn(uint256 tokenId, uint256 amount) external {
        if(!_isSelfBurnable(tokenId)) revert NotSelfBurnable();
        _burn(msg.sender, tokenId, amount);
    }

    /**
     * @dev Owner can allow for certain contract addresses to burn tokens for users.
     * 
     * If this is an EOA, the approvedBurn transaction will revert.
     */
    function setApprovedBurner(
        address burner, 
        uint256 tokenId, 
        bool approved
    ) external onlyOwner {
        approvedBurners[burner][tokenId] = approved;
    }

    /**
     * @dev Allows token owners to burn their tokens through owner-approved burner contracts.
     */
    function approvedBurn(address spender, uint256 tokenId, uint256 amount) external {
        if (!approvedBurners[msg.sender][tokenId]) revert SenderNotApprovedBurner();
        if (tx.origin == msg.sender) revert NotContractAccount();
        _burn(spender, tokenId, amount);
    }

    // =============================================================
    //                        Miscellaneous
    // =============================================================

    /**
     * @notice Allows owner to withdraw a specified amount of ETH to a specified address.
     */
    function withdraw(
        address withdrawAddress,
        uint256 amount
    ) external onlyOwner {
        unchecked {
            if (amount > address(this).balance) {
                amount = address(this).balance;
            }
        }

        if (!_transferETH(withdrawAddress, amount)) revert WithdrawFailed();
    }

    /**
     * @notice Internal function to transfer ETH to a specified address.
     */
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30000 }(new bytes(0));
        return success;
    }
    
    error IncorrectMsgValue();
    error InvalidSignature();
    error InvalidSignatureBuyAmount();
    error InvalidSignatureVersion();
    error MintNotActive();
    error NotContractAccount();
    error NotSelfBurnable();
    error OperatorNotAllowed();
    error OverTransactionLimit();
    error SenderNotApprovedBurner();
    error SignatureAlreadyUsed();
    error TierNotActive();
    error WithdrawFailed();
}