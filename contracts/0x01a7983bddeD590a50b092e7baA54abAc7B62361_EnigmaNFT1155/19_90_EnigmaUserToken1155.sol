// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT1155.sol";

/// @title EnigmaUserToken1155
///
/// @dev This contract extends from BaseEnigmaNFT1155
contract EnigmaUserToken1155 is BaseEnigmaNFT1155 {
    address public operator;
    bool public autoId;
    address public bundledItemsRecipient;

    event OperatorChanged(address indexed newOperator);
    event BundledItemsRecipientChanged(address indexed newBundledItemsrecipient);
    event ItemsBundled(uint256 indexed newTokenId, uint256[] ids, uint256[] amounts);

    struct MintItem {
        uint256 tokenId;
        address recipient;
        uint256 amount;
        uint256 fee;
        string uri;
    }

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Not owner nor operator");
        _;
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice Initialize NFT1155 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the token base uri
     * @param operator_ that will be able to mint tokens on behalf the owner
     * @param transferGatekeeperBeacon_ TransferGatekeeper beacon
     * @param autoId_ True if token id will be automatically assigned when minting
     * @param bundledItemsRecipient_ Adress that will receive the tokens to be bundled. This ideally should lock them.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_,
        address operator_,
        address transferGatekeeperBeacon_,
        bool autoId_,
        address bundledItemsRecipient_
    ) external initializer {
        super._initialize(name_, symbol_, tokenURIPrefix_);
        operator = operator_;
        transferGatekeeperBeacon = IBeacon(transferGatekeeperBeacon_);
        autoId = autoId_;
        bundledItemsRecipient = bundledItemsRecipient_;
    }

    function batchMint(MintItem[] calldata toMint) external onlyOwnerOrOperator {
        uint256 length = toMint.length;

        for (uint256 index = 0; index < length; index++) {
            _mintItem(toMint[index]);
        }
    }

    /**
     * @notice This function bundles (exchanges) some tokens in exchange for a new one. All the tokens
     *         must belong to the same collection (this one)
     * @dev This operation can only be performed by the owner or the operator.
     *
     * @param tokensOwner The one the tokens are going to be taken from
     * @param ids TokenIds to be locked in exchange for the new one
     * @param amounts For each token to be exchanged
     * @param toMint new token to be generated and minted to the owner
     */
    function bundle(
        address tokensOwner,
        uint256[] memory ids,
        uint256[] memory amounts,
        MintItem calldata toMint
    ) external onlyOwnerOrOperator {
        super.safeBatchTransferFrom(tokensOwner, bundledItemsRecipient, ids, amounts, "");
        _mintItem(toMint);
        emit ItemsBundled(toMint.tokenId, ids, amounts);
    }

    /**
     * @dev Mints a new NFT if it doesn't exist otherwise uses the existing one
     */
    function _mintItem(MintItem calldata item) internal {
        if (!super._exists(item.tokenId)) {
            super._mintNew(item.recipient, autoId ? _increaseNextId() : item.tokenId, item.amount, item.uri, item.fee);
        } else {
            super._mint(item.recipient, item.tokenId, item.amount, "");
        }
    }

    /**
     * @notice For compatibility reasons this method is kept although it always returns the contract owner
     */
    function getCreator(uint256) external view virtual override returns (address) {
        return owner();
    }

    /**
     * @notice Let's the owner to update the operator
     * @param newOperator to set
     */
    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit OperatorChanged(newOperator);
    }

    /**
     * @notice Allows changing the bundled NFTs recipient to another address
     * @param bundledItemsRecipient_ New recipient. Cannot be 0x0 address otherwise will fail when transfering
     */
    function setBundledItemsRecipient(address bundledItemsRecipient_) external onlyOwnerOrOperator {
        require(bundledItemsRecipient_ != address(0x0), "Cannot be 0x0 address");
        bundledItemsRecipient = bundledItemsRecipient_;
        emit BundledItemsRecipientChanged(bundledItemsRecipient);
    }
}