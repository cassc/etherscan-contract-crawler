// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16 <0.9.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC721A, ERC721ACommon} from "ethier/contracts/erc721/ERC721ACommon.sol";
import {BaseTokenURI} from "ethier/contracts/erc721/BaseTokenURI.sol";
import {PremintReady} from "premint-connect/PremintReady.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/DefaultOperatorFilterer.sol";

contract Cockpunch is
    ERC721ACommon,
    BaseTokenURI,
    PremintReady,
    DefaultOperatorFilterer
{
    using Address for address payable;

    // =========================================================================
    //                           Errors
    // =========================================================================

    error DisallowedByCurrentStage(Stage got, Stage want);
    error TooManyMintsRequested();
    error BurnDisabled();
    error IncorrectPayment(uint256 got, uint256 want);
    error IllegalOperator();
    error StageLocked();
    error CannotCommitAgain();
    error InvalidCommitment();

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice The different stages of the contract.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     */
    enum Stage {
        Closed,
        Premint
    }

    /**
     * @notice Specifies the receiver of owner mints.
     */
    struct OwnerMintReceiver {
        address to;
        uint16 num;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice Maximum total supply.
     */
    uint256 public constant NUM_MAX = 5555;

    /**
     * @notice Maximum owner mints (treasury + collaborators)
     */
    uint16 internal constant _MAX_OWNER_MINTS = 555 + 160;

    /**
     * @notice The maximum number of mints per address.
     * @dev Will be enforced by the premint contrac.
     */
    uint16 internal constant _MAX_MINTS_PER_ADDRESS = 1;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The signer approving the premint allowance signer.
     */
    address internal _premintSigner;

    /**
     * @notice The current stage of the contract.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     */
    Stage public stage;

    /**
     * @notice Flag the locks the current minting stage of the contract.
     */
    bool public stageLocked;

    /**
     * @notice Flag to enable token burning.
     */
    bool public burnEnabled;

    /**
     * @notice Number of tokens that can still be minted free-of-charge by the
     * contract owner.
     * @dev See also `ownerMint`
     */
    uint16 public ownerMintsRemaining;

    /**
     * @notice The receiver of minting revenues.
     */
    address payable public primaryReceiver;

    /**
     * @notice The block number used to derive the shuffling entropy.
     */
    uint256 private _entropyBlock;

    /**
     * @notice The commitment to a random salt used to derive the shuffling
     * entropy.
     */
    bytes32 private _saltHashCommitment;

    /**
     * @notice The entropy used for shuffling the tokens upon reveal.
     */
    bytes32 public entropy;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        address payable primaryReceiver_,
        address payable royaltiesReceiver,
        string memory baseTokenURI_
    )
        ERC721ACommon(
            "COCKPUNCH by Tim Ferriss",
            "COCKPUNCH",
            royaltiesReceiver,
            690
        )
        BaseTokenURI(baseTokenURI_)
    {
        _premintSigner = owner();
        primaryReceiver = primaryReceiver_;

        ownerMintsRemaining = _MAX_OWNER_MINTS;
    }

    // =========================================================================
    //                           Premint
    // =========================================================================

    /**
     * @notice Handles mints via the premint interface.
     * @dev This can only be called if the premint verification has been
     * successful and we can mint `amount` tokens to `to`.
     */
    function _premint(address to, uint256 amount)
        internal
        override
        onlyDuring(Stage.Premint)
    {
        _processMint(to, amount);
    }

    /**
     * @notice Returns the address that is allowed to configure premint.
     */
    function premintSigner() public view virtual override returns (address) {
        return _premintSigner;
    }

    /**
     * @notice Returns max number of tokens that can be minted through premint.
     */
    function premintMax() public view virtual override returns (uint256) {
        return _MAX_MINTS_PER_ADDRESS;
    }

    // =========================================================================
    //                           Minting
    // =========================================================================

    /**
     * @notice Free-of-charge minting interface for the contract owner.
     */
    function ownerMint(OwnerMintReceiver[] calldata receivers)
        external
        onlyOwner
    {
        uint16 ownerMintsRemaining_ = ownerMintsRemaining;
        for (uint256 idx; idx < receivers.length; ++idx) {
            if (receivers[idx].num > ownerMintsRemaining_) {
                revert TooManyMintsRequested();
            }

            ownerMintsRemaining_ -= receivers[idx].num;
        }
        ownerMintsRemaining = ownerMintsRemaining_;

        for (uint256 idx; idx < receivers.length; ++idx) {
            _processMint(receivers[idx].to, receivers[idx].num);
        }
    }

    /**
     * @notice Does the actual minting and routes the generated revenues.
     */
    function _processMint(address to, uint256 amount) internal {
        if (_totalMinted() + amount > NUM_MAX) {
            revert TooManyMintsRequested();
        }

        _mint(to, amount);
        if (msg.value > 0) {
            primaryReceiver.sendValue(msg.value);
        }
    }

    // =========================================================================
    //                           Burning
    // =========================================================================

    /**
     * @notice Burns an existing token.
     * @dev Can only be called by the token owner or approved addresses.
     */
    function burn(uint256 tokenId) external {
        if (!burnEnabled) {
            revert BurnDisabled();
        }
        _burn(tokenId, true);
    }

    // =========================================================================
    //                           Shuffling Entropy
    // =========================================================================

    /**
     * @notice Commits to an IPFS URL and some random salt to derive ungameable
     * entropy for shuffling.
     * @param attributesURL the IPFS URL to a JSON file containing all
     * attributes of the unshuffled tokens.
     * @param saltHash the hash of a 256bit random salt
     * @dev Commitments are blocked for 256 blocks after a commitment, and
     * indefinitely after revealing the entropy.
     */
    // solhint-disable-next-line no-unused-vars
    function commit(string calldata attributesURL, bytes32 saltHash)
        public
        onlyOwner
    {
        if (block.number - _entropyBlock < 256 || uint256(entropy) != 0) {
            revert CannotCommitAgain();
        }
        _entropyBlock = block.number;
        _saltHashCommitment = saltHash;
    }

    /**
     * @notice Reveals the entropy that will be used to shuffle token content
     * for the token reveal.
     * @param salt The random salt used for the commitment.
     * @dev The commitment must have been made within the last 256 blocks.
     * @dev This form of entropy derivation can only be gamed in two ways: 1) if
     * we as the drivers would directly collude with many validators to only
     * include our commit transaction in blocks with favourable hashes (which
     * is very difficult in practice and outweighs any potential gain); or 2)
     * if we repeatedly fail to reveal the entropy and recommit, waiting for a
     * favourable blockhash to appear. The second approach can, however, be
     * easily detected from on-chain data, and we only keep the possibility for
     * recommitting as a last resort should we miss the reveal window for any
     * unforeseen reasons.
     */
    function revealEntropy(bytes32 salt) public onlyOwner {
        bytes32 bhash = blockhash(_entropyBlock);
        bytes32 saltHash = keccak256(abi.encodePacked(salt));

        if (uint256(bhash) == 0 || saltHash != _saltHashCommitment) {
            revert InvalidCommitment();
        }

        entropy = keccak256(abi.encodePacked(bhash, saltHash));
        delete _entropyBlock;
        delete _saltHashCommitment;
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Changes the address allowed to do the premint configuration.
     * @dev Changing this address invalidates all existing allowances, if
     * the premint validator has not been signed yet.
     * @dev Can only be called by the contract owner.
     */
    function setPremintSigner(address signer) public onlyOwner {
        _premintSigner = signer;
    }

    /**
     * @notice Advances the stage of the contract.
     * @dev Can only be advanced after the treasury reserve has been minted to
     * ensure the genesis tokens are minted.
     */
    function setStage(Stage stage_) external onlyOwner {
        if (stageLocked) {
            revert StageLocked();
        }

        stage = stage_;
    }

    /**
     * @notice Locks the minting stage of the contract.
     */
    function lockStage() external onlyOwner {
        stageLocked = true;
    }

    /**
     * @notice Ensures that the contract is in a given stage.
     */
    modifier onlyDuring(Stage stage_) {
        if (stage_ != stage) {
            revert DisallowedByCurrentStage(stage, stage_);
        }
        _;
    }

    /**
     * @notice Sets the receiver of the minting proceeds.
     */
    function setPrimaryReciever(address payable primaryReceiver_)
        external
        onlyOwner
    {
        primaryReceiver = primaryReceiver_;
    }

    /**
     * @notice Reduces the number of tokens that can be minted free-of-charge
     * by the contract owner.
     */
    function reduceOwnerMintAllocation(uint16 amount) external onlyOwner {
        ownerMintsRemaining -= amount;
    }

    /**
     * @notice Toggles if tokens can be burned by users.
     */
    function toggleBurn(bool enabled) external onlyOwner {
        burnEnabled = enabled;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @dev Inheritance resolution.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}