// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/// @title Centaurify Intermediate Storage - IntermediateStorage.sol
/// @author @dadogg80 - Viken Blockchain Solutions.

/// @notice This is the Centaurify Intermediate Collection smart contract used for the Artist Collections.
/// @dev Supports ERC2981 Royalty Standard.
/// @dev Supports OpenSea's - Royalty Standard { https://docs.opensea.io/docs/contract-level-metadata }.

/** 
 * @notice Intermediate Collection Features:
 *          - Premint whitelists w/MerkleProof validation.  
 *          - Public mint phase.  
 */


abstract contract IntermediateStorage is ERC721, ERC721Enumerable, AccessControl, Ownable, ERC2981 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    enum Status {
        Initiate,
        Phase1,
        Public
    }

    Status public status;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice recipient is the receiver of the withdraw method.
    address payable public recipient;

    /// @notice CentaurifyPrimintedNFTs is the receiver of the
    address internal _CentaurifyPrimintedNFTs =
        payable(0x7e5c63372C8C382Fc3fFC1700F54B5acE3b93c93);

    /// @notice The current mint phase values.
    uint256 public mintPrice;
    uint256 public maxItemsPerTx;

    /// @notice Timestamps to keep track of the start and end time of each phase.
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    /// @notice The merkleRoot of the current running phase.
    bytes32 public merkleRoot = "";

    /// @dev Minting restrictions.
    uint256 internal MAX_ITEMS;

    /// @notice URIs used in this contract.
    string internal _baseTokenURI;
    string internal _contractURI;

    string constant _ReceivefunctionError = "Not a payable receive function!";
    string constant _MaxItemsError = "Sold out";
    string constant _TransactionError = "Failed tx";

    /// @dev Maps user address to their remaining mints if they have minted some but not all of their allocation
    mapping(address => uint256) public whitelistPhase1Remaining;
    mapping(address => uint256) public publicMintRemaining;

    /// @dev Maps user address to bool, true if user has minted
    mapping(address => bool) public whitelistPhase1Used;
    mapping(address => bool) public publicMintUsed;

    /// @notice error codes can be located in the documentation
    /// { https://centaurifyorg.github.io/Centaurify_Docs/Collections}

    /// @dev Wrong status.
    error Code_1(Status Current, Status Required);

    /// @dev Wrong timestamp.
    error Code_2(uint256 Timestamp);

    /// @dev Returns an error message.
    error Code_3(string Message);

    /// @dev Zero value not allowed.
    error NoZeroValues();

    /// @dev Wrong amount.
    error WrongValue(uint256 Value);

    /// @notice Modifier checks that the {msg.value} is correct.
    modifier costs(uint256 amount) {
        uint256 value = (mintPrice * amount);
        if (msg.value != value) revert WrongValue(msg.value);
        _;
    }

    /// @notice Modifier checks if the premint Phase1 has started.
    modifier phaseOneIsOpen() {
        uint256 currentTime = block.timestamp;
        if (status != Status.Phase1) revert Code_1(status, Status.Phase1);
        if (currentTime <= startTimestamp) revert Code_2(startTimestamp);
        if (startTimestamp == 0) revert Code_2(startTimestamp);
        _;
    }

    /// @notice Modifier checks if the public minting has started.
    modifier publicMintingIsOpen() {
        uint256 currentTime = block.timestamp;
        if (status != Status.Public) revert Code_1(status, Status.Public);
        if (currentTime <= startTimestamp) revert Code_2(startTimestamp);
        if (startTimestamp == 0) revert Code_2(startTimestamp);
        _;
    }

    event Initiated();

    /// @notice Event is emitted when the status is changed.
    /// @param status Indexed -The current mint phase status.
    /// @param startTimestamp The start timestamp of this current mint phase.
    /// @param endTimestamp The end timestamp of this current mint phase.
    event StatusChange(
        Status indexed status,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /// @notice Event is emitted when a new token has been minted.
    /// @param owner Indexed -The owner of the newly minted tokens.
    /// @param tokenId The Id of the minted token.
    event Minted(
        address indexed owner,
        uint256 tokenId
    );

    /// @notice Event is emitted when the Withdraw method has been executed successfull.
    /// @param receiver Indexed - The receiving address of the smart contract funds.
    event Withdraw(address indexed receiver);



    /* ------------------------------------------------------------  ADMIN FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Adjust the merkleroot of the current phase.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _merkleRoot The new merkleRoot hash.
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
    }

    /// @notice Adjust the current max items per transaction.
    /// @dev Only use during the public mint to adjust the max amount of mints.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _maxItemsPerTx The new max items per transaction.
    function setMaxItemsPerTx(uint256 _maxItemsPerTx) external onlyRole(ADMIN_ROLE) {
        maxItemsPerTx = _maxItemsPerTx;
    }

    /// @notice Adjust the recipient address.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _recipient The receiver address is a smart contract that will split the withdraw payouts to preset accounts.
    function setRecipient(address payable _recipient) external onlyRole(ADMIN_ROLE) {
        recipient = _recipient;
    }

    /// @notice Adjust the mintPrice.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _mintPrice The new price for this currnet mint phase.
    function setMintPrice(uint256 _mintPrice) external onlyRole(ADMIN_ROLE) {
        mintPrice = _mintPrice;
    }


    /// @notice Removes stuck erc20 tokens from contract.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _token The contract address of the token to remove.
    /// @param _to The to account.
    function removeStuckTokens(
        address _token,
        address _to
    ) external onlyRole(ADMIN_ROLE) {
        uint256 _amount = balanceOf(address(_token));
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice Function to adjust the BaseTokenURI.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param __baseTokenURI The new baseTokenURI.
    function setBaseTokenURI(string memory __baseTokenURI) external onlyRole(ADMIN_ROLE) {
        _baseTokenURI = __baseTokenURI;
    }

    /// @notice Function to adjust the ContractURI.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param __contractURI The new contractURI.
    function setContractURI(string memory __contractURI) external onlyRole(ADMIN_ROLE) {
        _contractURI = __contractURI;
    }


    /// @notice Withdraw the contract balance to the recipient's address.
    function withdraw() external {
        if (recipient == address(0x0)) revert Code_3("Set recipient first");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        if (!success) revert Code_3(_TransactionError);
        emit Withdraw(recipient);
    }

    /* ------------------------------------------------------------  ADMIN ROYALTY FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Adjust the current default royalty data.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _royaltyAddress The account to receive the royalty amount.
    /// @param feeNumerator The royalty amount in BIPS. example: 750 is 7,5%.
    function setDefaultRoyalty(address payable _royaltyAddress, uint96 feeNumerator) external onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(_royaltyAddress, feeNumerator);
    }

    /* ------------------------------------------------------------  ADMIN (SET PREMINT & PUBLICMINT) FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Used to initiate the Artist variables for this collection.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _royalty The _royalty address is the adderss that will receive all the royalty from secondary sales.
    /// @param _recipient The _recipient address is the adderss that will receive all the funds from the collection sales.
    /// @param _feeNumerator The royalty amount in BIPS. example: 750 is 7,5%.
    /// @param __contractURI Read { https://docs.opensea.io/docs/contract-level-metadata } for more information.
    function InitiateArtistCollection(
        address payable _royalty,
        address payable _recipient,
        string memory __contractURI,
        string memory __baseTokenURI,
        uint96 _feeNumerator
    ) external onlyRole(ADMIN_ROLE) {
        recipient = _recipient;
        _contractURI = __contractURI;
        _baseTokenURI = __baseTokenURI;
        _setDefaultRoyalty(_royalty, _feeNumerator);
        status = Status(1);

        emit Initiated();
    }

    /// @notice Used to set the Status to Premint Phase 1.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param  _pricePhaseOne The mint price for Premint Phase 1.
    /// @param  _maxItemsPerTx The max Items Per Tx for Premint Phase 1.
    /// @param  _startTimestamp The timestamp to start the Premint Phase 1.
    /// @param  _endTimestamp The timestamp to end the Premint Phase 1.
    /// @param  _merkleRoot The MerkleRoot of the Phase1 whitelist to mint from.
    function setPhaseOneMintValues(
        uint256 _pricePhaseOne,
        uint256 _maxItemsPerTx,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _merkleRoot
    ) external onlyRole(ADMIN_ROLE) {
        if (status != Status(1)) revert Code_1(status, Status(1));

        merkleRoot = _merkleRoot;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        mintPrice = _pricePhaseOne;
        maxItemsPerTx = _maxItemsPerTx;

        emit StatusChange(status, startTimestamp, endTimestamp);
    }

    /// @notice Used to set the Status to Public mint.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param  _pricePublicPhase The mint price for Public Mint Phase.
    /// @param  _maxItemsPerTx The max Items Per Tx for Public Mint Phase.
    /// @param  _startTimestamp The timestamp to start the Public minting.
    /// @param  _endTimestamp The timestamp to end the Public minting.
    function setPublicMintValues(
        uint256 _pricePublicPhase,
        uint256 _maxItemsPerTx,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external onlyRole(ADMIN_ROLE) {
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        merkleRoot = "";
        status = Status.Public;
        mintPrice = _pricePublicPhase;
        maxItemsPerTx = _maxItemsPerTx;

        emit StatusChange(status, startTimestamp, endTimestamp);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC2981, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }



}