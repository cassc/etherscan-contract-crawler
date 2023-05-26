// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";


/// @title Centaurify Collection AAA - GenesisStorage.sol
/// @author @dadogg80 - Viken Blockchain Solutions.

/// @notice This is one of the Centaurify Collection AAA smart contracts used for the GenesisMint - Golden Ticket.
/// @notice This smart contract Contains the state variables and admin methods for the GenesisMint.sol


abstract contract GenesisStorage is AccessControl, Ownable, ERC721A, ERC721AQueryable, ERC2981 {
    using SafeERC20 for IERC20;

    enum Status {
        Phase1,
        Phase2,
        Phase3,
        Public,
        EarlyReveal,
        Revealed
    }

    Status public status;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    /// @notice recipient is the receiver of the withdraw method.
    address payable public recipient;

    /// @notice royalty is the address to receive the royalty payouts.
    address payable public royalty;
    
    /// @notice The current mint phase values.
    uint public mintPrice;
    uint public maxItemsPerTx;

    /// @notice Timestamps to keep track of the start and end time of each phase.
    uint public startTimestamp;
    uint public endTimestamp;

    /// @notice The merkleRoot of the current running phase.
    bytes32 public merkleRoot = "";

    /// @dev Minting restrictions.
    uint internal constant MAX_ITEMS = 5000;

    uint internal constant PHASE1_PRICE = 0.05 ether;
    uint internal constant PHASE2_PRICE = 0.055 ether;
    uint internal constant PHASE3_PRICE = 0.075 ether;
    uint internal constant PUBLIC_MINT_PRICE = 0.1 ether;

    uint internal constant PHASE1_MAX_MINT = 5;
    uint internal constant PHASE2_MAX_MINT = 3;
    uint internal constant PHASE3_MAX_MINT = 1;
    uint internal constant PUBLIC_MAX_MINT = 1;

    /// @notice URIs used in this contract.
    string internal _baseTokenURI;
    string internal _contractURI;
    string internal _uriSuffix;

    string internal _RemainingAllocationError = "Can't mint more than remaining allocation";
    string internal _MerkleLeafMatchError = "Don't match Merkle leaf";
    string internal _MerkleLeafValidationError = "Not a valid Merkle Leaf";
    string internal _ReceivefunctionError = "Not a payable receive function!";
    string internal _MaxItemsError = "Sold out";
    string internal _TransactionError = "Failed tx";


    /// @dev Maps user address to their remaining mints if they have minted some but not all of their allocation
    mapping(address => uint) internal whitelistPhase1Remaining;
    mapping(address => uint) internal whitelistPhase2Remaining;
    mapping(address => uint) internal whitelistPhase3Remaining;
    mapping(address => uint) internal publicMintRemaining;

    /// @dev Maps user address to bool, true if user has minted
    mapping(address => bool) internal whitelistPhase1Used;
    mapping(address => bool) internal whitelistPhase2Used;
    mapping(address => bool) internal whitelistPhase3Used;
    mapping(address => bool) internal publicMintUsed;

    /// @notice error codes can be located in the documentation
    /// { https://centaurifyorg.github.io/Centaurify_Docs/GenesisMint/ReadTheDocs_Genesis_Mint.html#read-the-docs---genesis-mint }

    /// @dev Wrong status.
    error Code_1(Status Current, Status Required);

    /// @dev Wrong timestamp.
    error Code_2(uint Timestamp);

    /// @dev Returns an error message.
    error Code_3(string Message);

    /// @dev Returns the endTimestamp.
    error MintPhaseEnded(uint EndTimestamp);

    /// @dev Zero value not allowed.
    error NoZeroValues();

    /// @dev Wrong amount.
    error WrongValue(uint Value);

    /// @notice Modifier checks that the {msg.value} is correct.
    modifier costs(uint amount) {
        uint value = (mintPrice * amount);
        if (msg.value != value) revert WrongValue(msg.value);
        _;
    }

    /// @notice Modifier checks if the premint Phase1 has started.
    modifier phaseOneIsOpen() {
        uint currentTime = block.timestamp;
        if (status != Status.Phase1) revert Code_1(status, Status.Phase1);
        if (currentTime <= startTimestamp) revert Code_2(startTimestamp);
        if (startTimestamp == 0) revert Code_2(startTimestamp);
        _;
    }

    /// @notice Modifier checks if the premint Phase2 has started.
    modifier phaseTwoIsOpen() {
        uint currentTime = block.timestamp;
        if (status != Status.Phase2) revert Code_1(status, Status.Phase2);
        if (currentTime <= startTimestamp) revert Code_2(startTimestamp);
        if (startTimestamp == 0) revert Code_2(startTimestamp);
        _;
    }

    /// @notice Modifier checks if the premint Phase3 has started.
    modifier phaseThreeIsOpen() {
        uint currentTime = block.timestamp;
        if (status != Status.Phase3) revert Code_1(status, Status.Phase3);
        if (currentTime <= startTimestamp) revert Code_2(startTimestamp);
        if (startTimestamp == 0) revert Code_2(startTimestamp);
        _;
    }

    /// @notice Modifier checks if the public minting has started.
    modifier publicMintingIsOpen() {
        uint currentTime = block.timestamp;
        if (status != Status.Public) revert Code_1(status, Status.Public);
        if (currentTime <= startTimestamp) revert Code_2(startTimestamp);
        if (startTimestamp == 0) revert Code_2(startTimestamp);
        _;
    }

    /// @notice Modifier checks if the early reveal period has started.
    modifier earlyRevealIsOpen() {
        uint currentTime = block.timestamp;
        if (status != Status.EarlyReveal) revert Code_1(status, Status.EarlyReveal);
        if (currentTime <= startTimestamp) revert Code_2(startTimestamp);
        if (startTimestamp == 0) revert Code_2(startTimestamp);
        _;
    }

    /// @notice Event is emitted when the status is changed.
    /// @param status Indexed -The current mint phase status.
    /// @param startTimestamp The start timestamp of this current mint phase.
    /// @param endTimestamp The end timestamp of this current mint phase.
    event StatusChange(
        Status indexed status,
        uint startTimestamp,
        uint endTimestamp
    );

    /// @notice Event is emitted when a new token has been minted.
    /// @param owner Indexed -The owner of the newly minted tokens.
    /// @param amount The amount of tokens minted.
    /// @param lastTokenId Indexed - The id of the last token minted in this batch.
    /// @param mintPhase Indexed - The mint phase it was minted in.
    event Minted(
        address indexed owner,
        uint amount,
        uint indexed lastTokenId,
        Status indexed mintPhase
    );

    /// @notice Event is emitted when the Withdraw method has been executed successfull.
    /// @param amount The amount withdrawn from the contract.
    /// @param receiver Indexed - The receiving address of the smart contract funds.
    event Withdraw(
        uint amount,
        address indexed receiver
    );

    /// @notice Event is emitted when tokens has been saved by the ADMIN_ROLE.
    /// @param ContractAddress Indexed - The contract address of the ERC20 token. 
    /// @param To Indexed - The address of the receiver. 
    /// @param Amount Indexed - The transacted amount. 
    event SavedStuckTokens(
        address indexed ContractAddress,
        address indexed To,
        uint indexed Amount
    );

    /// @notice Event is emitted when the MerkleRoot has been adjusted by the ADMIN_ROLE.
    /// @dev Execute public method to read the new parameter. 
    event NewMerkleRoot();

    /// @notice Event is emitted when the maxItemPerTx has been adjusted by the ADMIN_ROLE..
    /// @dev Execute public method to read the new parameter. 
    event NewMaxItemPerTx();

    /// @notice Event is emitted when the recipient is adjusted by the ADMIN_ROLE.
    /// @dev Execute public method to read the new parameter. 
    event NewRecipient();

    /// @notice Event is emitted when the royalty receiver has been adjusted by the ADMIN_ROLE.
    /// @dev Execute public method to read the new parameter. 
    event NewRoyaltyReceiver();

    /// @notice Event is emitted when the contractURI has been adjusted by the ADMIN_ROLE.
    /// @dev Execute public method to read the new parameter. 
    event NewContractUri();

    /// @notice Event is emitted when the baseURI has been adjusted by the ADMIN_ROLE. 
    /// @dev The new BaseURI is internal and should not be revealed before the REVEAL phase. 
    event NewBaseUriSet();

    /// @notice Event is emitted when the uriSuffix has been set by the ADMIN_ROLE. 
    /// @param Suffix The uriSuffix. 
    event InitUriSuffix(string Suffix);

/* ------------------------------------------------------------  ADMIN FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Adjust the merkleroot of the current phase.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _merkleRoot The new merkleRoot hash.
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
        emit NewMerkleRoot();
    }

    /// @notice Adjust the current max items per transaction.
    /// @dev Only use during the public mint to adjust the max amount of mints.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _maxItemsPerTx The new max items per transaction.
    function setMaxItemsPerTx(uint _maxItemsPerTx) external onlyRole(ADMIN_ROLE) publicMintingIsOpen {
        if (_maxItemsPerTx > 5) revert Code_3("Cannot set to mint more than five tokens per tx.");
        maxItemsPerTx = _maxItemsPerTx;
        emit NewMaxItemPerTx();
    }

    /// @notice Adjust the recipient address.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _recipient The receiver address is a smart contract that will split the withdraw payouts to preset accounts.
    function setRecipient(address payable _recipient) external onlyRole(ADMIN_ROLE) {
        recipient = _recipient;
        emit NewRecipient();
    }

    /// @notice Adjust the royalty address.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @dev This royalty address will be a payment splitter smart contract.
    /// @param _royalty The royalty amount to receive the royalty payouts.
    function setRoyaltyReceiver(address payable _royalty) external onlyRole(ADMIN_ROLE) {
        royalty = _royalty;
        emit NewRoyaltyReceiver();
    }

    /// @notice Removes stuck erc20 tokens from contract.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _token The contract address of the token to remove.
    /// @param _to The to account.
    function removeStuckTokens(address _token, address _to) external onlyRole(ADMIN_ROLE) {
        uint _amount = balanceOf(address(_token));
        IERC20(_token).safeTransfer(_to, _amount);
        emit SavedStuckTokens(_token, _to, _amount);
    }

    /// @notice Function to adjust the BaseTokenURI.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param __baseTokenURI The new baseTokenURI.
    function setBaseTokenURI(string memory __baseTokenURI) external onlyRole(ADMIN_ROLE) {
        _baseTokenURI = __baseTokenURI;
        emit NewBaseUriSet();
    }

    /// @notice Function to adjust the ContractURI.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param __contractURI The new contractURI.
    function setContractURI(string memory __contractURI) external onlyRole(ADMIN_ROLE) {
        _contractURI = __contractURI;
        emit NewContractUri();
    }

    /// @notice Function to se the uriSuffix of the tokenURI.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _suffix The new _uriSuffix.
    function setURISuffix(string memory _suffix) external onlyRole(ADMIN_ROLE) {
        _uriSuffix = _suffix;
        emit InitUriSuffix(_uriSuffix);
    }

    /// @notice Withdraw the contract balance to the recipient's address.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    function withdraw() external onlyRole(ADMIN_ROLE) {
        if (recipient == address(0x0)) revert Code_3("Set recipient first");
        uint amount = address(this).balance;
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert Code_3(_TransactionError);
        emit Withdraw(amount, recipient);
    }

    /// @notice Used to check if spesific interfaceID is supported.
    /// @dev Supports the following `interfaceId`s:
    /// @dev - IERC165: 0x01ffc9a7
    /// @dev - IERC721: 0x80ac58cd
    /// @dev - IERC721Metadata: 0x5b5e139f
    /// @dev - IERC2981: 0x2a55205a
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC2981, ERC721A, IERC721A) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
    
    /* ------------------------------------------------------------  ADMIN ROYALTY FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Adjust the royalty data of a given token id {will override default royalty for this contact}.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param tokenId The id of the token.
    /// @param _royaltyAddress The account to receive the royalty amount.
    /// @param feeNumerator The royalty amount in BIPS. example: 750 is 7,5%.
    function setTokenRoyalty(uint tokenId, address payable _royaltyAddress, uint96 feeNumerator) 
        external
        onlyRole(ADMIN_ROLE) 
    {
        _setTokenRoyalty(tokenId, _royaltyAddress, feeNumerator);
    }

    /// @notice Adjust the current default royalty data.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _royaltyAddress The account to receive the royalty amount.
    /// @param feeNumerator The royalty amount in BIPS. example: 750 is 7,5%.
    function setDefaultRoyalty(address payable _royaltyAddress, uint96 feeNumerator)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setDefaultRoyalty(_royaltyAddress, feeNumerator);
    }

    /* ------------------------------------------------------------  ADMIN (SET PREMINT & PUBLICMINT) FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Used to set the Status to Premint Phase 1.
    /// @dev Restricted to onlyRole(OPERATOR_ROLE).
    /// @param  _startTimestamp The timestamp to start the Premint Phase 1.
    /// @param  _endTimestamp The timestamp to end the Premint Phase 1.
    /// @param  _merkleRoot The MerkleRoot of the Phase1 whitelist to mint from.
    function setPhaseOneMintValues(uint _startTimestamp, uint _endTimestamp, bytes32 _merkleRoot)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (status != Status(0)) revert Code_1(status, Status(0));
        
        merkleRoot = _merkleRoot;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        status = Status.Phase1;
        mintPrice = PHASE1_PRICE;
        maxItemsPerTx = PHASE1_MAX_MINT;

        emit StatusChange(status, startTimestamp, endTimestamp);
    }

    /// @notice Used to set the Status to Premint Phase 2.
    /// @dev Restricted to onlyRole(OPERATOR_ROLE).
    /// @param  _startTimestamp The timestamp to start the Premint Phase 2.
    /// @param  _endTimestamp The timestamp to end the Premint Phase 2.
    /// @param  _merkleRoot The MerkleRoot of the Phase2 whitelist to mint from.
    function setPhaseTwoMintValues(uint _startTimestamp, uint _endTimestamp, bytes32 _merkleRoot)
        external
        onlyRole(OPERATOR_ROLE)
        phaseOneIsOpen
    {
        merkleRoot = _merkleRoot;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        status = Status.Phase2;
        mintPrice = PHASE2_PRICE;
        maxItemsPerTx = PHASE2_MAX_MINT;

        emit StatusChange(status, startTimestamp, endTimestamp);
    }

    /// @notice Used to set the Status to Premint Phase 3.
    /// @dev Restricted to onlyRole(OPERATOR_ROLE).
    /// @param  _startTimestamp The timestamp to start the Premint Phase 3.
    /// @param  _endTimestamp The timestamp to end the Premint Phase 3.
    /// @param  _merkleRoot The MerkleRoot of the Phase3 whitelist to mint from.
    function setPhaseThreeMintValues(uint _startTimestamp, uint _endTimestamp, bytes32 _merkleRoot)
        external
        onlyRole(OPERATOR_ROLE)
        phaseTwoIsOpen
    {
        merkleRoot = _merkleRoot;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        status = Status.Phase3;
        mintPrice = PHASE3_PRICE;
        maxItemsPerTx = PHASE3_MAX_MINT;

        emit StatusChange(status, startTimestamp, endTimestamp);
    }

    /// @notice Used to set the Status to Public mint.
    /// @dev Restricted to onlyRole(OPERATOR_ROLE).
    /// @param  _startTimestamp The timestamp to start the Public minting.
    /// @param  _endTimestamp The timestamp to end the Public minting.
    function setPublicMintValues(uint _startTimestamp, uint _endTimestamp)
        external
        onlyRole(OPERATOR_ROLE)
        phaseThreeIsOpen
    {
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        merkleRoot = "";
        status = Status.Public;
        mintPrice = PUBLIC_MINT_PRICE;
        maxItemsPerTx = PUBLIC_MAX_MINT;

        emit StatusChange(status, startTimestamp, endTimestamp);
    }

    /// @notice Used to set the Status to EarlyReveal.
    /// @dev Restricted to onlyRole(OPERATOR_ROLE).
    /// @param  _earlyRevealTimestamp The timestamp when earlyReveal is allowed.
    function setEarlyRevealValues(uint _earlyRevealTimestamp)
        external
        onlyRole(OPERATOR_ROLE)
        publicMintingIsOpen
    {
        startTimestamp = _earlyRevealTimestamp;
        endTimestamp = 0;
        status = Status.EarlyReveal;

        emit StatusChange(status, startTimestamp, endTimestamp);
    }

    /// @notice Function to set the status to Revealed.
    /// @dev Restricted to onlyRole(OPERATOR_ROLE).
    function setRevealValues() external onlyRole(OPERATOR_ROLE) earlyRevealIsOpen {
        startTimestamp = 0;
        status = Status.Revealed;

        emit StatusChange(status, startTimestamp, endTimestamp);
    }

}