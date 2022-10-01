// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "./DAOHAUSAccessControl.sol";
import "./DAOHAUSRoleVerifier.sol";

contract DAOHAUSMinter is
    DAOHAUSAccessControl,
    DAOHAUSRoleVerifier,
    ERC721ABurnable,
    ReentrancyGuard
{
    // ====== INTERNAL TYPES ======

    uint256 internal constant ROLE_COUNT = 4;
    struct DAOHAUSMinterState {
        bool isMintOpen;
        uint256 maxMintSupply;
        DAOHAUSRole minimumRoleRequired;
        uint256[ROLE_COUNT] mintPriceForRole;
        uint256[ROLE_COUNT] mintLimitForRole;
    }

    // ====== STATE VARIABLES ======

    DAOHAUSMinterState internal _state;
    mapping(address => uint256) public totalClaimedForAddress;

    // ====== CONSTRUCTOR ======

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxMintSupply
    ) ERC721A(tokenName, tokenSymbol) {
        _state.isMintOpen = false;
        _state.maxMintSupply = maxMintSupply;
        _state.minimumRoleRequired = DAOHAUSRole.TEAM;

        _state.mintPriceForRole[uint256(DAOHAUSRole.PUBLIC)] = 0.00 ether;
        _state.mintPriceForRole[uint256(DAOHAUSRole.DAOLIST)] = 0.00 ether;
        _state.mintPriceForRole[uint256(DAOHAUSRole.CREATOR)] = 0.00 ether;
        _state.mintPriceForRole[uint256(DAOHAUSRole.TEAM)] = 0.00 ether;

        _state.mintLimitForRole[uint256(DAOHAUSRole.PUBLIC)] = 2;
        _state.mintLimitForRole[uint256(DAOHAUSRole.DAOLIST)] = 2;
        _state.mintLimitForRole[uint256(DAOHAUSRole.CREATOR)] = 2;
        _state.mintLimitForRole[uint256(DAOHAUSRole.TEAM)] = 3;
    }

    // ====== MODIFIERS ======

    /**
     * @dev Determines if the mint is currently open to the given `role`.
     */
    modifier isMintOpenToRole(DAOHAUSRole role) {
        require(_state.isMintOpen, "DH_MINT_NOT_OPEN");
        require(role >= _state.minimumRoleRequired, "DH_MINT_NOT_OPEN_TO_ROLE");
        _;
    }

    /**
     * @dev Determines if there is enough supply available to mint `amount` more
     * tokens.
     */
    modifier isSupplyAvailable(uint256 amount) {
        require(
            (_totalMinted() + amount) <= _state.maxMintSupply,
            "DH_SUPPLY_EXHAUSTED"
        );
        _;
    }

    /**
     * @dev Determines if the caller has provided sufficient funds to mint
     * `amount` number of tokens with the given `role`.
     *
     * If a caller with a role higher than `PUBLIC` decides to mint after their
     * designated time to mint, they will only be charged the discounted price
     * originally set for their role.
     */
    modifier isCorrectPaymentForRole(DAOHAUSRole role, uint256 amount) {
        require(
            msg.value >= _state.mintPriceForRole[uint256(role)] * amount,
            "DH_INSUFFICIENT_FUNDS"
        );
        _;
    }

    /**
     * @dev Determines if the caller has not minted the maximum allowed for
     * the given `role`.
     */
    modifier hasNotReachedMintLimitForRole(DAOHAUSRole role, uint256 amount) {
        uint256 mintLimit = _state.mintLimitForRole[uint256(role)];
        require(
            totalClaimedForAddress[msg.sender] + amount <= mintLimit,
            "DH_MINT_LIMIT_EXCEEDED"
        );
        _;
    }

    // ====== MINTING FUNCTIONS ======

    /**
     * @dev Mints `amount` number of DAOHAUSes with the given `role`, verified
     * with the provided `merkleProof`.
     *
     * This function requires several prerequisites to be met for `msg.sender`
     * to successfully mint a DAOHAUS token:
     *
     *   - The mint is currently open to the given `role`;
     *   - There is enough supply available to mint `amount` extra tokens;
     *   - Sufficient amount of ETH has been provided to purchase `amount`
     *     number of tokens;
     *   - The caller has not minted (or will not mint) over the maximum
     *     number of tokens they are allowed to mint; and
     *   - It can be verified that `msg.sender` is a member of `role` using the
     *     provided `merkleProof`. If `role` is `PUBLIC`, this check will be
     *     skipped.
     *
     * If any of the above prerequisites are not met, this function will reject
     * the mint and throw an error.
     */
    function mint(
        DAOHAUSRole role,
        uint256 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        isMintOpenToRole(role)
        isSupplyAvailable(amount)
        isCorrectPaymentForRole(role, amount)
        hasNotReachedMintLimitForRole(role, amount)
        isValidMerkleProofForRole(role, merkleProof)
    {
        _mintToAddress(msg.sender, amount);
    }

    /**
     * @dev Mints `amount` number of DAOHAUSes directly to `receiver`.
     *
     * This function does not validate the DAOHAUS role of the receiver.
     * However, it will ensure that there is enough supply available to mint the
     * given amount of DAOHAUSes.
     *
     * Note that this function will not check if gifting the token will exceed
     * the mint limit imposed on the receiver, simply because we don't know
     * which role this receiver belongs to without complicating the function.
      However, it will still increment `_totalClaimedForAddress`, so any
     * subsequent calls to `mint` from the receiver will fail with the expected
     * `"DH_MINT_LIMIT_EXCEEDED"` error.
     */
    function mintUnchecked(address receiver, uint256 amount)
        external
        onlyOperator
        isSupplyAvailable(amount)
    {
        _mintToAddress(receiver, amount);
    }

    /**
     * @dev Internal function that mints `amount` number of DAOHAUSes to
     * `receiver`.
     */
    function _mintToAddress(address receiver, uint256 amount) internal {
        // Record the total amount of tokens minted by the minter.
        totalClaimedForAddress[receiver] += amount;

        // The second argument of `_safeMint` in AZUKI's `ERC721A` contract
        // expects the amount to mint, not a token ID.
        _safeMint(receiver, amount);
    }

    // ====== EXTERNAL/PUBLIC FUNCTIONS ======

    /**
     * @dev Returns a convenient struct reporting the current state of the
     * DAOHAUS mint orchestrator.
     *
     * The JavaScript ABI does not expose the array fields `mintPriceForRole`
     * and `mintLimitForRole` if we make the `_state` property public, which is
     * why we resorted to return it from a function here.
     */
    function currentState() external view returns (DAOHAUSMinterState memory) {
        return _state;
    }

    /**
     * @dev Returns the current minting price for the given `role`.
     */
    function mintPriceForRole(DAOHAUSRole role)
        external
        view
        returns (uint256)
    {
        return _state.mintPriceForRole[uint256(role)];
    }

    // ====== ONLY-OPERATOR FUNCTIONS ======

    /**
     * @dev Opens the mint to all minters who have at least the given minimum
     * role. Anyone with roles that are higher than the given role would also be
     * able to mint (if they weren't able to before) at the price that was
     * originally set for them.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function openMint(DAOHAUSRole minimumRoleRequired) external onlyOperator {
        if (!_state.isMintOpen) _state.isMintOpen = true;
        _state.minimumRoleRequired = minimumRoleRequired;
    }

    /**
     * @dev Closes the mint to ALL potential minters of ANY role.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function closeMint() external onlyOperator {
        if (_state.isMintOpen) _state.isMintOpen = false;
        _state.minimumRoleRequired = DAOHAUSRole.TEAM;
    }

    /**
     * @dev Updates the maximum number of tokens that can be minted.
     *
     * This function will ensure that `newTotal` is greater than or equal to
     * the current number of tokens minted.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function setMaxMintSupply(uint256 newTotal) external onlyOperator {
        require(newTotal >= _totalMinted(), "DH_NEW_SUPPLY_TOO_SMALL");
        _state.maxMintSupply = newTotal;
    }

    /**
     * @dev Updates the maximum number of tokens allowed to be minted for a
     * caller with the given `role`.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function setMintLimitForRole(DAOHAUSRole role, uint256 newLimit)
        external
        onlyOperator
    {
        _state.mintLimitForRole[uint256(role)] = newLimit;
    }

    /**
     * @dev Updates the price of each token for a caller with the given `role`.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function setMintPriceForRole(DAOHAUSRole role, uint256 newPrice)
        external
        onlyOperator
    {
        _state.mintPriceForRole[uint256(role)] = newPrice;
    }

    // ====== MISCELLANEOUS ======

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721A, IERC721A)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }
}