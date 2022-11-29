//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721ARedeemable} from "./ERC721ARedeemable.sol";
import {IERC721A} from "chiru-labs/IERC721A.sol";
import {Ownable2Step} from "OpenZeppelin/access/Ownable2Step.sol";
import {ECDSA} from "OpenZeppelin/utils/cryptography/ECDSA.sol";
import {OperatorFilterer} from "vectorized/OperatorFilterer.sol";

//              @@@@&
//              @@@@&
//    @@@@@@    @@@@&   %@@@@@
//      @@@@@@& @@@@& @@@@@@.
//        [email protected]@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@
//          @@@@@@@@@@@@#                                 @@@@@
//       /@@@@@@@@@@@@@@@@@                               @@@@@
//     @@@@@@*  @@@@&  @@@@@@(                            @@@@@
//     *@@@     @@@@&    *@@@                             @@@@@
//              @@@@&                                     @@@@@
//                                                        @@@@@
//                                                        @@@@@
//              .....                                     @@@@@
//              @@@@&                                     @@@@@
//              @@@@&                                     @@@@@
//              @@@@&                                     @@@@@
//              @@@@&                                     @@@@@
//              @@@@&                                     @@@@@
//              @@@@&                                     @@@@@
//              @@@@&                                     @@@@@
//              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

/**
 * @title   AmericanaVault
 *
 * @notice  ERC721A has been modified for this contract to permanently store the timestamp
 *          each token was minted at within what was its `lastTimestamp` bits of packedOwnership.
 *          Those bits are now referred to as `mintTimestamp`.
 *
 *          The `extraData` bits of packed ownership data within ERC721A are used to store
 *          number of days a token is non-redeemable from the time it was minted.
 *
 * @dev     Implementation of ERC721A with the above adaptations meant to faciliate nft minting,
 *          redemption, and bundling for Americana.
 */

contract AmericanaVault is ERC721ARedeemable("Americana", "VAULT"), Ownable2Step, OperatorFilterer {
    using ECDSA for bytes32;

    event BundleCreated(
        address indexed auxTokenAddress, uint48 auxTokenId, uint48 indexed americanaTokenId, address indexed redeemer
    );

    event BundleUnwrapped(
        address auxTokenAddress,
        uint48 auxTokenId,
        uint48 indexed physicalTokenId,
        address indexed redeemer,
        uint256 indexed bundleTokenId
    );
    event SigCancelled(
        address indexed _bundler, address indexed _auxTokenAddress, uint48 indexed _auxTokenId, uint48 _americanaTokenId
    );
    event FailedAuthWithdrawal();
    event TokenRedeemed(address indexed redeemer, uint256 indexed tokenId);
    event AuthChange(address indexed authAddress, bool indexed authStatus);
    event TokenLockupTimeUpdated(uint256 indexed tokenId, uint256 indexed newLockupFromMintInDays);
    event PauseStateFlipped(bool indexed newStatus);
    event TokenWithdrawn(address indexed _tokenAddress, uint48 indexed _tokenId);
    event BaseUriUpdate(string indexed newUri);
    event WrapperBurnt(uint256 indexed _tokenId);

    error UnwrapByNonOwner();
    error InvalidSig();
    error Unauthorized();
    error TokenNotRedeemable();
    error ContractPaused();
    error CannotUpdateLockTimeOfBundleToken();
    error InvalidAuxToken();
    error InvalidBundleToken();
    error InvalidSignerAddress();
    error SignatureUsedOrCancelled();
    error SignatureExpired();
    error CannotBurnToken();
    error BundleAlreadyUnwrapped();
    error RedeemByNonOwner();
    error CannotBundleAnAlreadyBundledToken();

    /**
     * @dev     Mapping used within onlyAuth modifier for access control
     */
    mapping(address => bool) public isAuthorized;

    /**
     * @dev     Mapping used to invalidate bundle digests
     */
    mapping(bytes32 => bool) public isInvalidated;

    /**
     * @dev     Mapping used to track active bundle token data
     */
    mapping(uint256 => BundleData) public bundleDataByTokenId;

    /**
     * @dev     Packed data struct for storing bundle data.
     *
     *          `auxTokenAddress` the contract address of the token being wrapped with an Americana Vault token
     *          `auxTokenId` the tokenId of the token being wrapped with an Americana Vault token
     *          `americanaTokenId` the tokenId of the Americana Vault token being wrapped to the Aux token
     */
    struct BundleData {
        address auxTokenAddress;
        uint48 auxTokenId;
        uint48 americanaTokenId;
    }

    bool public isPaused;

    bool public operatorFilteringEnabled;

    string private _baseTokenURI;

    /**
     * @dev     Modifier for access control
     */
    modifier onlyAuth() {
        if (!isAuthorized[msg.sender] && msg.sender != owner()) revert Unauthorized();
        _;
    }

    /**
     * @dev     Modifier for contract pausing in case of emergency
     */
    modifier active() {
        if (isPaused) revert ContractPaused();
        _;
    }

    constructor() {
        isAuthorized[msg.sender] = true;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        isPaused = false;
    }

    // =============================================================
    //                     Main Functionality
    // =============================================================

    /**
     * @dev     Mints `_amount` tokens to `_to` address. Sets ERC721A packedOwnerships extra data
     *          to `_lockupInDays`, the number of days that token is to be non-redeemable after mintTimestamp.
     *
     *          Requirements:
     *
     *          - msg.sender is authorized address
     *          - contract is not paused
     */

    function mint(address _to, uint256 _amount, uint24 _lockupInDays) external onlyAuth active {
        uint256 startTokenId = _nextTokenId();
        _mint(_to, _amount);
        _setExtraDataAt(startTokenId, _lockupInDays);
        for (uint256 i = 1; i < _amount;) {
            // Initializes ownership upon mint to remove inheritance of _lockupInDays from the startTokenId
            // Without intitialization, if I mint 5 then update the lockup time for the first token. That will incorrectly update lockup times for all the minted tokens.
            _initializeOwnershipAt(startTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev     Facilitate redemption of non-bundle tokens for their physical counterpart.
     *
     *          Requirements:
     *
     *          - Number of days stored in tokens packed ownership extraData slot have passed since the token was originally minted.
     *          - Msg.sender is ownerOf(_tokenId)
     *          - Contract is not paused
     */
    function redeem(uint256 _tokenId) external active {
        if (ownerOf(_tokenId) != msg.sender) revert RedeemByNonOwner();

        // Check redemption time has passed
        if (!isRedeemable(_tokenId)) {
            revert TokenNotRedeemable();
        }
        _burn(_tokenId, false);
        emit TokenRedeemed(msg.sender, _tokenId);
    }

    /**
     * @dev     Bundles token `_auxTokenId` from the `_auxTokenAddress` contract with the `_americanaTokenId`
     *          specified.
     *
     *          Requirements:
     *
     *          - The `_sig` recovers to an authorized address when compared against the hash of the other encoded *            params.
     *          - Msg.sender has approved Americana contract to transfer their aux token
     *          - block.timestamp must be less than _sigExpirationDate
     *          - The`_auxTokenAddress` cannot be address(0) or address(this)
     *          - Sig digest must not be used or cancelled via isInvalidated mapping
     *          - `_americanaTokenId` must not be a bundle token
     */
    function bundle(
        uint256 _sigExpirationDate,
        address _auxTokenAddress,
        uint48 _auxTokenId,
        uint48 _americanaTokenId,
        uint256 _salt,
        bytes calldata _sig
    ) external active {
        if (_auxTokenAddress == address(this) || _auxTokenAddress == address(0)) {
            revert InvalidAuxToken();
        }
        // Generate sig digest for verification.
        bytes32 digest = keccak256(
            abi.encode(
                msg.sender, _sigExpirationDate, _auxTokenAddress, _auxTokenId, _americanaTokenId, block.chainid, _salt
            )
        );
        if (bundleDataByTokenId[_americanaTokenId].auxTokenAddress != address(0)) {
            revert CannotBundleAnAlreadyBundledToken();
        }
        if (!isAuthorized[(digest.toEthSignedMessageHash().recover(_sig))]) revert InvalidSignerAddress();
        if (isInvalidated[digest]) revert SignatureUsedOrCancelled();
        if (_sigExpirationDate < block.timestamp) revert SignatureExpired();

        isInvalidated[digest] = true;

        // Transfer Americana token to this contract.
        transferFrom(msg.sender, address(this), _americanaTokenId);

        // Transfer aux token to this contract.
        IERC721A(_auxTokenAddress).transferFrom(msg.sender, address(this), _auxTokenId);

        uint256 startTokenId = _nextTokenId();

        // Store bundle data struct in `bundleDataByTokenId` mapping.
        bundleDataByTokenId[startTokenId] = BundleData(_auxTokenAddress, _auxTokenId, _americanaTokenId);

        _mint(msg.sender, 1);

        //Set bundle nft redeemable timestamp to type(uint16).max as bundle nft's are not redeemable.
        _setExtraDataAt(startTokenId, type(uint16).max);

        emit BundleCreated(_auxTokenAddress, _auxTokenId, _americanaTokenId, msg.sender);
    }

    /**
     * @dev     Unwraps the bundle specified by the `_tokenId`. Transfers underlying tokens to msg.sender.
     *
     *          Requirements:
     *
     *          - Msg.sender is ownerOf(_tokenId)
     */
    function unwrap(uint256 _tokenId) external active {
        if (ownerOf(_tokenId) != msg.sender) revert UnwrapByNonOwner();

        // Burn bundle token
        _burn(_tokenId, false);

        BundleData memory _bundle = bundleDataByTokenId[_tokenId];

        // Transfer Americana token to msg.sender
        this.transferFrom(address(this), msg.sender, _bundle.americanaTokenId);

        // Transfer aux token to msg.sender.
        // Note, a check that `_tokenId` is a bundle is not necessary because if it is not, this transfer call to address(0) will revert.
        IERC721A(_bundle.auxTokenAddress).transferFrom(address(this), msg.sender, _bundle.auxTokenId);

        delete bundleDataByTokenId[_tokenId];

        emit BundleUnwrapped(
            _bundle.auxTokenAddress, _bundle.auxTokenId, _bundle.americanaTokenId, msg.sender, _tokenId
            );
    }

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    // =============================================================
    //                          Auth Functions
    // =============================================================

    /**
     * @dev     Allows auth address to force transfer out a bundles tokens in the case of emergency.
     *
     */
    function authUnwrap(uint256 _tokenId) external onlyOwner {
        BundleData memory _bundle = bundleDataByTokenId[_tokenId];

        if (_bundle.auxTokenAddress == address(0)) revert BundleAlreadyUnwrapped();

        try this.transferFrom(address(this), msg.sender, _bundle.americanaTokenId) {}
        catch {
            emit FailedAuthWithdrawal();
        }

        try IERC721A(_bundle.auxTokenAddress).transferFrom(address(this), msg.sender, _bundle.auxTokenId) {}
        catch {
            emit FailedAuthWithdrawal();
        }
    }

    /**
     * @dev     Used after an auth unwrap to burn the unwrapped bundle token
     *
     */
    function burnWrapperToken(uint256 _tokenId) external onlyOwner {
        BundleData memory _bundle = bundleDataByTokenId[_tokenId];
        if (_bundle.auxTokenAddress == address(0)) revert InvalidBundleToken();

        if (
            ownerOf(_bundle.americanaTokenId) != address(this)
                && IERC721A(_bundle.auxTokenAddress).ownerOf(_bundle.auxTokenId) != address(this)
        ) {
            _burn(_tokenId, false);
            delete bundleDataByTokenId[_tokenId];
            emit WrapperBurnt(_tokenId);
        } else {
            revert CannotBurnToken();
        }
    }

    function updateAuth(address authAddress, bool newAuthStatus) external onlyOwner {
        isAuthorized[authAddress] = newAuthStatus;

        emit AuthChange(authAddress, newAuthStatus);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;

        emit BaseUriUpdate(baseURI);
    }

    function updatePausedState(bool _newPauseState) external onlyOwner {
        isPaused = _newPauseState;

        emit PauseStateFlipped(_newPauseState);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    /**
     * @dev     Cancels the digest of a bundle signature. This cancellation is checked upon bundling.
     */
    function cancelBundleDigest(
        address _bundler,
        uint256 _sigExpirationDate,
        address _auxTokenAddress,
        uint48 _auxTokenId,
        uint48 _americanaTokenId,
        uint256 _salt
    ) external onlyAuth {
        bytes32 digest = keccak256(
            abi.encode(
                _bundler, _sigExpirationDate, _auxTokenAddress, _auxTokenId, _americanaTokenId, block.chainid, _salt
            )
        );
        isInvalidated[digest] = true;

        emit SigCancelled(_bundler, _auxTokenAddress, _auxTokenId, _americanaTokenId);
    }
    /**
     * @dev     Updates the number of days a token is locked post mint
     *
     *          Requirements:
     *
     *          - `tokenId` is not a bundle token
     */

    function updateLockupTime(uint256 tokenId, uint24 newLockupFromMintInDays) external onlyAuth {
        if (bundleDataByTokenId[tokenId].auxTokenAddress != address(0)) revert CannotUpdateLockTimeOfBundleToken();
        _setExtraDataAt(tokenId, newLockupFromMintInDays);

        emit TokenLockupTimeUpdated(tokenId, newLockupFromMintInDays);
    }

    // =============================================================
    //                       ERC721A Overrides
    // =============================================================

    /**
     * @dev Transfer overrides to appeal to OpenSea's Mandatory Operator Filterer.
     * See: https://github.com/ProjectOpenSea/operator-filter-registry
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev ERC721A override to always initialize ownership of a token upon minting so we can set the extraData slot.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual override {
        _initializeOwnershipAt(index);
        super._setExtraDataAt(index, extraData);
    }

    function _extraData(address, address, uint24 previousExtraData) internal pure override returns (uint24) {
        return previousExtraData;
    }

    // =============================================================
    //                      View Only Functions
    // =============================================================

    /**
     * @dev Returns whether or not a tokens lockup time has passed since mint.
     */
    function isRedeemable(uint256 tokenId) internal view returns (bool redeemable) {
        uint256 redeemTimestamp =
            uint256(_ownershipOf(tokenId).mintTimestamp) + uint256(_ownershipOf(tokenId).extraData) * 1 days;

        redeemable = block.timestamp > redeemTimestamp;
    }

    /**
     * @dev Returns time left until lockup expires. Returns 0 for unlocked tokens
     */
    function timeUntilUnlock(uint256 tokenId) external view returns (uint256 secondsUntilUnlock) {
        if (isRedeemable(tokenId)) {
            secondsUntilUnlock = 0;
        } else {
            uint256 mintTimestamp = _ownershipOf(tokenId).mintTimestamp;
            uint256 daysLocked = _ownershipOf(tokenId).extraData;

            secondsUntilUnlock = (mintTimestamp + daysLocked * 1 days) - block.timestamp;
        }
    }

    function ownershipOf(uint256 tokenId) public view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function nextToken() external view returns (uint256) {
        return _nextTokenId();
    }
}