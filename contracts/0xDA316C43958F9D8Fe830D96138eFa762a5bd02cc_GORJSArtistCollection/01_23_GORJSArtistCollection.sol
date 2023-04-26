//SPDX-License-Identifier: UNLICENSED
// AUDIT: LCL-06 | UNLOCKED COMPILER VERSION
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "../interfaces/IGorjsToken.sol";
import "../roles/AccessRoleUpgradeable.sol";

/**
 * @title GORJSArtistCollection
 * @author Ben.
 * @dev Implementation of Artist NFT based on ERC721
 */
// AUDIT: LCL-01 | CENTRALIZED CONTROL OF CONTRACT UPGRADE Category
/// @dev we transfer ownership of proxyAmdin to multi-sig public wallet
// AUDIT: LCL-05 | MISSING INHERITANCE
contract GORJSArtistCollection is
    Initializable,
    OwnableUpgradeable,
    AccessRoleUpgradeable,
    ERC721Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /// @notice ERC20 based yielding token.
    IGorjsToken private _daoToken;

    /// @dev base uri
    string private _baseURIString;

    // @dev controller contract
    address public controllerContract;

    // total supply
    uint256 public TOTAL_SUPPLY_LIMIT;

    /** mapping owner => UintSet to store all users stake info*/
    mapping(address => EnumerableSetUpgradeable.UintSet) private userStakeInfo;

    /** Events */

    event Lock(address indexed owner, uint256[] ids);
    event Unlock(address indexed owner, uint256[] ids);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer for upgradeable smart contract.
     * @param _name The name of collection
     * @param _symbol The symbol of collection
     * @param _uri The base URL for metadata
     */
    // AUDIT: LCL-07 | FUNCTION SHOULD BE DECLARED EXTERNAL
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address adminWallet,
        uint256 _totalSupplyLimit
    ) external initializer {
        __Context_init();
        __Ownable_init();
        __AccessRole_init(adminWallet);
        __ERC721_init(_name, _symbol);

        _baseURIString = _uri;
        TOTAL_SUPPLY_LIMIT = _totalSupplyLimit;
    }

    /** Modifiers */

    modifier onlyControllerContract() {
        require(
            msg.sender == controllerContract,
            "Should be a controller contract"
        );
        _;
    }

    /** View functions */

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURIString;
    }

    /** Admin functions */

    /**
     * @dev Base URI can only be set by an owner.
     * @param baseURIString_ New sales status to be set.
     */
    function setBaseURI(string calldata baseURIString_) external onlyAdmin {
        _baseURIString = baseURIString_;
    }

    /**
     * @dev The contract address can only be set by Owner.
     * @param daoToken_ The address of yielding token.
     */
    function setDaoToken(address daoToken_) external onlyAdmin {
        require(daoToken_ != address(0), "invalid token");
        _daoToken = IGorjsToken(daoToken_);
    }

    /**
     * @dev The controller contract address can only be set by Owner.
     * @param _controllerContract The address of conroller contract.
     */
    function setControllerContract(address _controllerContract)
        external
        onlyAdmin
    {
        require(_controllerContract != address(0), "invalid address");
        controllerContract = _controllerContract;
    }

    /** Mutative functions */

    /**
     * @notice Mint can be called by only controller contract
     *
     * @param to The recipient address
     * @param id The token id
     */
    function mint(address to, uint256 id) external onlyControllerContract {
        require(id < TOTAL_SUPPLY_LIMIT, "Invalid token id");
        // Update rewards
        _daoToken.updateRewardsOnMint(to, 1);

        _mint(to, id);
    }

    /**
     * @notice Claim rewards by holding tokens.
     */
    function claimRewards() external {
        require(address(_daoToken) != address(0), "Yielding Token is not set.");

        _daoToken.claimRewards(msg.sender);
    }

    /** Internal functions */

    /**
     * @notice Split the payment payout for the creator and fee recipient.
     *
     */
    function _splitPayout() internal {}

    /** Soft staking functions */

    /**
     * @dev lock nfts
     * @param _ids NFT Ids to lock
     */
    function lock(uint256[] memory _ids) external {
        require(_ids.length > 0, "Invalid NFT amount");

        /** lock nfts */
        for (uint256 i; i < _ids.length; ) {
            require(
                !EnumerableSetUpgradeable.contains(
                    userStakeInfo[msg.sender],
                    _ids[i]
                ),
                "Already locked"
            );
            require(ownerOf(_ids[i]) == msg.sender, "Not an owner");

            EnumerableSetUpgradeable.add(userStakeInfo[msg.sender], _ids[i]);

            unchecked {
                ++i;
            }
        }

        emit Lock(msg.sender, _ids);
    }

    /**
     * @dev unlock NFTs from the contract
     * @param _ids NFT ids to unlock
     */
    function unlock(uint256[] memory _ids) external {
        require(_ids.length > 0, "Invalid NFT amount");

        /** transfer nfts from staking cotract to the owner*/
        for (uint256 i; i < _ids.length; ) {
            require(
                EnumerableSetUpgradeable.contains(
                    userStakeInfo[msg.sender],
                    _ids[i]
                ),
                "Not able to unlock"
            );

            EnumerableSetUpgradeable.remove(userStakeInfo[msg.sender], _ids[i]);

            unchecked {
                ++i;
            }
        }

        emit Unlock(msg.sender, _ids);
    }

    /**
     * @dev return the balance of staked nfts
     * @param _owner the owner address
     */
    function stakeBalanceOf(address _owner) external view returns (uint256) {
        return userStakeInfo[_owner].length();
    }

    /**
     * @dev return the token ids of staked nfts
     * @param _owner the owner address
     */
    function stakedTokens(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return EnumerableSetUpgradeable.values(userStakeInfo[_owner]);
    }

    /** Overriden functions */

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        require(
            !EnumerableSetUpgradeable.contains(
                userStakeInfo[msg.sender],
                tokenId
            ),
            "Not able to approve locked NFT"
        );
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev
     * @param from Account to transfer token from
     * @param to Account to transfer token to
     * @param id Token ID to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, id);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(address(_daoToken) != address(0), "Yielding Token is not set.");
        require(
            !EnumerableSetUpgradeable.contains(
                userStakeInfo[msg.sender],
                tokenId
            ),
            "Not able to transfer locked NFT"
        );

        _daoToken.updateRewardsOnTransfer(from, to);

        super._transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}