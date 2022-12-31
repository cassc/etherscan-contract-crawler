// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import {REAL_ID_MULTIPLIER, EDITION_SIZE, EDITION_RELEASE_SCHEDULE} from "./Constants.sol";
import {IMetadata} from "./IMetadata.sol";

/**
 * @author Sam King (samkingstudio.eth)
 * @title  Sam King Studio ECR721
 * @notice Uses solmate ERC721 and includes royalties, operator filtering, withdrawing
 * and an upgradeable metadata contract.
 */
contract SKS721 is ERC721, OperatorFilterer, Owned {
    /// @notice The public address of the artist, Sam King
    address public artist;

    /// @notice The next original token id
    uint256 public nextId = 1;

    /// @notice The total count of burned tokens
    uint256 public burned;

    /// @notice Mapping of burned token ids
    mapping(uint256 => bool) public tokenBurned;

    struct RoyaltyInfo {
        address receiver;
        uint96 amount;
    }

    /// @dev Store info about token royalties
    RoyaltyInfo internal _royaltyInfo;

    /// @notice If operator filtering is enabled for royalties
    bool public operatorFilteringEnabled;

    /// @dev Metadata rendering contract
    IMetadata internal _metadata;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error ZeroBalance();
    error WithdrawFailed();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the contract is initialized
     */
    event Initialized();

    /**
     * @notice When the royalty information is updated
     * @param receiver The new receiver of royalties
     * @param amount The new royalty amount with two decimals (10,000 = 100)
     */
    event RoyaltiesUpdated(address indexed receiver, uint256 indexed amount);

    /**
     * @notice When the metadata rendering contract is updated
     * @param prevMetadata The current metadata address
     * @param metadata The new metadata address
     */
    event MetadataUpdated(address indexed prevMetadata, address indexed metadata);

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(
        address owner,
        string memory name,
        string memory symbol,
        address metadata
    ) ERC721(name, symbol) Owned(owner) {
        artist = owner;
        _royaltyInfo = RoyaltyInfo(owner, uint96(5_00));
        _metadata = IMetadata(metadata);

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        emit Initialized();
        emit RoyaltiesUpdated(owner, 5_00);
        emit MetadataUpdated(address(0), metadata);
    }

    /* ------------------------------------------------------------------------
       M E T A D A T A
    ------------------------------------------------------------------------ */

    /**
     * @notice {ERC721.tokenURI} that calls to an external contract to render metadata
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "INVALID_ID");
        return _metadata.tokenURI(tokenId);
    }

    /** ADMIN -------------------------------------------------------------- */

    /**
     * @notice Admin function to set the metadata rendering contract address
     * @param metadata The new metadata contract address
     */
    function setMetadata(address metadata) public onlyOwner {
        emit MetadataUpdated(address(_metadata), metadata);
        _metadata = IMetadata(metadata);
    }

    /* ------------------------------------------------------------------------
       R O Y A L T I E S
    ------------------------------------------------------------------------ */

    /**
     * @notice EIP-2981 royalty standard for on-chain royalties
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyInfo.receiver;
        royaltyAmount = (salePrice * _royaltyInfo.amount) / 10_000;
    }

    /**
     * @dev Extend `supportsInterface` to support EIP-2981
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // EIP-2981 = bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /** ADMIN -------------------------------------------------------------- */

    /**
     * @notice Admin function to update royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10000 = 100)
     */
    function setRoyaltyInfo(address receiver, uint96 amount) external onlyOwner {
        emit RoyaltiesUpdated(receiver, amount);
        _royaltyInfo = RoyaltyInfo(receiver, uint96(amount));
    }

    /**
     * @notice Admin function to enable OpenSea operator filtering
     * @param enabled If operator filtering should be enabled
     */
    function setOperatorFilteringEnabled(bool enabled) external onlyOwner {
        operatorFilteringEnabled = enabled;
    }

    /** INTERNAL ----------------------------------------------------------- */

    /**
     * @notice Internal override for {OperatorFilterer} to determine if filtering is enabled
     */
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    /**
     * @notice Internal override for {OperatorFilterer} to determine if operator checks
     * should be skipped for a particular operator to save on gas
     */
    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw all ETH from the contract to the owner
     */
    function withdrawETH() external onlyOwner {
        if (address(this).balance == 0) revert ZeroBalance();
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    /**
     * @notice Admin function to withdraw all ERC20 tokens from the contract to the owner
     * @param token The ERC20 token contract address to withdraw
     */
    function withdrawERC20(address token) external onlyOwner {
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }

    /* ------------------------------------------------------------------------
       U T I L S
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Internal function to convert an id and edition number into an _actual_ artwork id
     *
     * @param id The original artwork id e.g. 1, 2, 3
     * @param edition The edition number
     * @return tokenId The real id which is a combination of the original id and edition number
     */
    function _getRealTokenId(uint256 id, uint256 edition) internal pure returns (uint256) {
        return id * REAL_ID_MULTIPLIER + edition;
    }

    /**
     * @notice
     * Internal function to get the original artwork id from the _actual_ artwork id
     *
     * @param realId The artwork id including the edition number
     * @return id The original artwork id e.g. 1, 2, 3
     */
    function _getIdFromRealTokenId(uint256 realId) internal pure returns (uint256) {
        return realId / REAL_ID_MULTIPLIER;
    }

    /**
     * @notice
     * Internal function to get the edition number from the _actual_ artwork id
     *
     * @param realId The artwork id including the edition number
     * @return edition The edition number
     */
    function _getEditionFromRealTokenId(uint256 realId) internal pure returns (uint256) {
        return realId % REAL_ID_MULTIPLIER;
    }

    /* ------------------------------------------------------------------------
       E R C - 7 2 1
    ------------------------------------------------------------------------ */

    /**
     * @notice Overrides {ERC721.ownerOf} to return the artist for minted and unsold editions
     * @param id The real artwork id including the edition number
     */
    function ownerOf(uint256 id) public view override returns (address owner) {
        owner = _ownerOf[id];
        if (owner == address(0)) {
            uint256 originalId = _getIdFromRealTokenId(id);
            require(originalId > 0 && originalId < nextId, "NOT_MINTED");
            require(tokenBurned[id] == false, "BURNED");
            owner = artist;
        }
    }

    /**
     * @notice Burns an NFT
     * @param id The real artwork id including the edition number
     */
    function burn(uint256 id) external {
        require(_ownerOf[id] == msg.sender, "NOT_OWNER");
        _burn(id);
        tokenBurned[id] = true;
        ++burned;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function totalSupply() external view returns (uint256) {
        return ((nextId - 1) * EDITION_SIZE) - burned;
    }
}