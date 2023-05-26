// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC721A } from "@thirdweb-dev/contracts/eip/ERC721AVirtualApprove.sol";

import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/extension/Royalty.sol";
import "@thirdweb-dev/contracts/extension/BatchMintMetadata.sol";
import "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import "@thirdweb-dev/contracts/extension/Drop.sol";
import "@thirdweb-dev/contracts/extension/LazyMint.sol";
import "@thirdweb-dev/contracts/extension/DelayedReveal.sol";
import "@thirdweb-dev/contracts/extension/DefaultOperatorFilterer.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

import "@thirdweb-dev/contracts/lib/TWStrings.sol";

contract MintbossDrop is
    ERC721A,
    ContractMetadata,
    Multicall,
    Ownable,
    PermissionsEnumerable,
    Royalty,
    BatchMintMetadata,
    PrimarySale,
    LazyMint,
    DefaultOperatorFilterer,
    Drop
{
    using TWStrings for uint256;

    /// @dev The amount to be sent to the passed address per token claimed
    uint256 public commissionPerToken;
    uint256 public discountPerToken;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint128 public maxSupply;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient,
        uint256 _commissionPerToken,
        uint256 _discountPerToken,
        uint128 _maxSupply
    ) ERC721A(_name, _symbol) {
        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_primarySaleRecipient);
        _setOperatorRestriction(true);
        commissionPerToken = _commissionPerToken;
        discountPerToken = _discountPerToken;
        maxSupply = _maxSupply;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /// @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }

    /*///////////////////////////////////////////////////////////////
                    Overriden ERC 721 logic
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                    Overriden lazy minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice                  Lets an authorized address lazy mint a given amount of NFTs.
     *
     *  @param _amount           The number of NFTs to lazy mint.
     *  @param _baseURIForTokens The placeholder base URI for the 'n' number of NFTs being lazy minted, where the
     *                           metadata for each of those NFTs is `${baseURIForTokens}/${tokenId}`.
     *  @param _data             The encrypted base URI + provenance hash for the batch of NFTs being lazy minted.
     *  @return batchId          A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public virtual override returns (uint256 batchId) {
        // chek that we are not minting more than the max supply
        require(_amount + nextTokenIdToLazyMint <= maxSupply, "Minting more than max supply");

        return LazyMint.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /// @notice The tokenId assigned to the next new NFT to be claimed.
    function nextTokenIdToClaim() public view virtual returns (uint256) {
        return _currentIndex;
    }

    /*///////////////////////////////////////////////////////////////
                        Overridden Claim logic
    //////////////////////////////////////////////////////////////*/

    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) public payable override {
        _beforeClaim(_receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);

        uint256 activeConditionId = getActiveClaimConditionId();

        verifyClaim(activeConditionId, _dropMsgSender(), _quantity, _currency, _pricePerToken, _allowlistProof);

        // Update contract state.
        claimCondition.conditions[activeConditionId].supplyClaimed += _quantity;
        claimCondition.supplyClaimedByWallet[activeConditionId][_dropMsgSender()] += _quantity;

        // Prepare variables for value transfers
        uint256 valueForMintboss;
        address payable receiver;
        uint256 remainingValue;
        address originalSaleRecipient = address(0);

        if (_isMintboss(bytes20(_data))) {
            valueForMintboss = commissionPerToken * _quantity;
            require(msg.value >= valueForMintboss, "Insufficient ETH");

            // Send 0.005 ETH to the passed address
            receiver = payable(address(bytes20(_data)));

            // Send the remaining value to the original sale recipient
            remainingValue = msg.value - valueForMintboss;
        } else {
            // If no address is passed, send the full value to the original sale recipient
            remainingValue = msg.value;
        }

        // Mint the relevant tokens to claimer.
        uint256 startTokenId = _transferTokensOnClaim(_receiver, _quantity);
        if (valueForMintboss > 0) {
            _transferToken(receiver, valueForMintboss);
        }
        _transferToken(originalSaleRecipient, remainingValue);

        emit TokensClaimed(activeConditionId, _dropMsgSender(), _receiver, startTokenId, _quantity);

        _afterClaim(_receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /*//////////////////////////////////////////////////////////////
                        Minting/burning logic
    //////////////////////////////////////////////////////////////*/

    function airdrop(
        address _receiver,
        uint256 _quantity
    ) public virtual onlyRole(MINTER_ROLE) {
        if (_currentIndex + _quantity > nextTokenIdToLazyMint) {
            revert("Not enough minted tokens");
        }
        // Mint the relevant tokens to claimer.
        uint256 startTokenId = _transferTokensOnClaim(_receiver, _quantity);
        emit TokensClaimed(0, _dropMsgSender(), _receiver, startTokenId, _quantity);
    }

    /**
     *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
     *  @dev            ERC721A's `_burn(uint256,bool)` internally checks for token approvals.
     *
     *  @param _tokenId The tokenId of the NFT to burn.
     */
    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC-721 overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev See {ERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {ERC721-approve}.
    function approve(address operator, uint256 tokenId)
        public
        virtual
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /// @dev See {ERC721-_transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        address,
        uint256 _quantity,
        address,
        uint256 _pricePerToken,
        AllowlistProof calldata,
        bytes memory _data
    ) internal view virtual override {
        // check if the correct value is sent
        if (_isMintboss(bytes20(_data))) {
            require(msg.value == _quantity * (_pricePerToken - discountPerToken), "Incorrect value sent");
        } else {
            require(msg.value == _quantity * _pricePerToken, "Incorrect value sent");
        }

        if (_currentIndex + _quantity > nextTokenIdToLazyMint) {
            revert("Not enough minted tokens");
        }
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override {}

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _transferToken(
        address _primarySaleRecipient,
        uint256 _totalValueToTransfer
    ) internal {
        require(_totalValueToTransfer > 0, "No value to transfer");
        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;
        // transfer the value to the sale recipient
        payable(saleRecipient).transfer(_totalValueToTransfer);
    }

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        virtual
        override
        returns (uint256 startTokenId)
    {
        startTokenId = _currentIndex;
        _safeMint(_to, _quantityBeingClaimed);
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether NFTs can be revealed in the given execution context.
    function _canReveal() internal view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns whether operator restriction can be set in the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _dropMsgSender() internal view virtual override returns (address) {
        return msg.sender;
    }

    function _isMintboss(
        bytes20 _data
    ) internal pure virtual returns (bool) {
        // Check if _data parameter contains an Ethereum address
        address recipient = address(_data);
        if (recipient != address(0)) {
            return true;
        }
        return false;
    }

    function setDiscountPerToken(uint256 _discountPerToken) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        discountPerToken = _discountPerToken;
    }

    function setCommission(uint256 _commission) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        commissionPerToken = _commission;
    }
}