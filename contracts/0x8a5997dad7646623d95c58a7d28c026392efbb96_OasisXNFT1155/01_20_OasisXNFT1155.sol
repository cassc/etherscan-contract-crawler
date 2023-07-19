// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice tokens
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice libraries
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Payment Splitter
import "./launchpad/PaymentSplitter.sol";

/**
 * @title OasisXNFT1155
 * @notice Base 1155 contract
 * @author OasisX Protocol | cryptoware.eth
 **/
/**
 * @title OasisXNFT1155
 * @notice Base 1155 contract
 * @author OasisX Protocol | cryptoware.eth
 **/
contract OasisXNFT1155 is
    ERC1155,
    ERC1155Supply,
    ERC1155Burnable,
    Pausable,
    Initializable,
    PaymentSplitter,
    ReentrancyGuard
{
    /// @notice using Strings for uints conversion (tokenId)
    using Strings for uint256;

    /// @notice using Address for addresses extended functionality
    using Address for address;

    /// @notice using MerkleProof Library to verify Merkle proofs
    using MerkleProof for bytes32[];

    /// @notice using a counter to increment next Id to be minted
    using Counters for Counters.Counter;

    /// @notice Enum representing minting phases
    enum Phase {
        Presale,
        Public
    }

    /// @notice Mapping minted tokens by address
    mapping(Phase => mapping(address => uint256)) public _minted;

    /// @notice the current phase of the minting
    Phase private _phase;

    /// @notice root of the Merkle tree
    bytes32 private _merkleRoot;

    /// @notice tokenIds to supply mapping
    mapping(uint256 => uint256) public tokenMaxSupplies;

    /// @notice The rate of minting per phase
    mapping(Phase => uint256) public mintPrice;

    /// @notice max amount of nfts that can be minted per wallet address
    uint64 public _mintsPerAddressLimit;

    /// @notice Splitter Contract that will collect mint fees
    address payable private _mintingBeneficiary;

    /// @notice token id to be minted next
    Counters.Counter private _tokenIdTracker;

    /// @notice Address of protocol fee wallet;
    address payable public protocolAddress;

    /// @notice protocol fees from every drop
    uint256 private protocolFee;

    /// @notice max tokenId that can be minted
    uint256 public maxTokenId;

    /// @notice public metadata locked flag
    bool public locked = false;

    /// @notice defining whether contract is Base or not
    bool public isBase;

    /// @notice address owner
    address public owner;

    /// @notice Token name
    string private _name;

    /// @notice Token symbol
    string private _symbol;

    /// @notice Minting events definition
    event AdminMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event Minted(address indexed to, uint256 indexed tokenId, uint256 quantity);

    /**
     * @notice Event published when a phase is triggered
     * @param phase next minting phase
     * @param mintCost minting cost in next phase
     * @param mintPerAddressLimit minting limit per wallet address
     **/
    event PhaseTriggered(
        Phase indexed phase,
        uint256 indexed mintCost,
        uint64 mintPerAddressLimit
    );

    /// @notice metadata not locked modifier
    modifier notLocked() {
        require(!locked, "OasisXNFT1155: Metadata URIs are locked");
        _;
    }

    /// @notice only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "OasisXNFT1155: only owner");
        _;
    }

    /**
     * @notice constructor
     * @param name_ the name of the EIP721 Contract
     * @param symbol_ the token symbol
     * @param uri_ token metadata base uri
     **/
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC1155(uri_) {
        isBase = true;
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @notice initializing the cloned contract
     * @param data data for 1155Proxy clone encoded
     * @param owner_ address of 1155Proxy owner
     * @param protocolFee_ protocolFee from mint
     * @param protocolAddress_ protocol address to collect protocolFee from mint
     **/
    function initialize(
        bytes memory data,
        address owner_,
        uint256 protocolFee_,
        address protocolAddress_
    ) external initializer {
        require(
            isBase == false,
            "OasisXNFT1155: this is the base contract,cannot initialize"
        );

        require(
            owner == address(0),
            "OasisXNFT1155: contract already initialized"
        );

        (
            string memory name_,
            string memory symbol_,
            string memory uri_,
            bytes32 root,
            address[] memory payees_,
            uint256[] memory shares_,
            uint256[] memory tokenIds,
            uint256[] memory tokenSupplies,
            uint256 maxTokenId_,
            uint256 mintPrice_,
            uint64 mintsPerAddressLimit
        ) = abi.decode(
                data,
                (
                    string,
                    string,
                    string,
                    bytes32,
                    address[],
                    uint256[],
                    uint256[],
                    uint256[],
                    uint256,
                    uint256,
                    uint64
                )
            );
        _name = name_;
        _symbol = symbol_;

        initializePaymentSplitter(payees_, shares_);

        protocolFee = protocolFee_;

        protocolAddress = payable(protocolAddress_);

        owner = owner_;

        _mintsPerAddressLimit = mintsPerAddressLimit;

        _merkleRoot = root;

        _phase = root == bytes32(0) ? Phase(1) : Phase(0);

        maxTokenId = maxTokenId_;

        mintPrice[_phase] = mintPrice_;

        _tokenIdTracker.increment();

        _setURI(uri_);

        _initialAddTokens(tokenIds, tokenSupplies);
    }

    /// @notice setting starting token id to 0
    function _startTokenId() internal pure virtual returns (uint256) {
        return 0;
    }

    ///@notice returns name of token
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /// @notice returns symbol of token
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @notice changes the minting beneficiary payable address
     * @param beneficiary the contract Splitter that will receive minting funds
     **/
    function changeMintBeneficiary(address beneficiary) external onlyOwner {
        require(
            beneficiary != address(0),
            "OasisXNFT1155: Minting beneficiary cannot be address 0"
        );
        require(
            beneficiary != _mintingBeneficiary,
            "OasisXNFT1155: beneficiary cannot be same as previous"
        );
        _mintingBeneficiary = payable(beneficiary);
    }

    /**
     * @notice Updates the phase and minting cost
     * @param phase the phase ID to set next
     * @param mintCost the cost of minting next phase
     * @param mintsPerAddressLimit set limit per wallet address
     **/
    function setPhase(
        Phase phase,
        uint256 mintCost,
        uint64 mintsPerAddressLimit
    ) external onlyOwner {
        require(mintCost > 0, "OasisXNFT1155: rate is 0");

        /// @notice set phase
        _phase = phase;

        _mintsPerAddressLimit = mintsPerAddressLimit;

        /// @notice set phase cost
        changeMintCost(mintCost);

        emit PhaseTriggered(_phase, mintCost, mintsPerAddressLimit);
    }

    /// @notice gets the current phase of minting and if whitelisting is required or not
    function getPhase() external view returns (Phase) {
        return _phase;
    }

    /**
     * @notice changes the minting cost
     * @param mintCost new minting cost
     **/
    function changeMintCost(uint256 mintCost) public onlyOwner {
        require(
            mintCost != mintPrice[_phase],
            "OasisXNFT1155: mint Cost cannot be same as previous"
        );
        mintPrice[_phase] = mintCost;
    }

    /**
     * @notice setting token URI
     * @param uri_ new URI
     */
    function setURI(string memory uri_) external onlyOwner {
        require(
            keccak256(abi.encodePacked(super.uri(0))) !=
                keccak256(abi.encodePacked(uri_)),
            "ERROR: URI same as previous"
        );
        _setURI(uri_);
    }

    /**
     * @notice return existing URI
     * @param id id of the token
     */
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(exists(id), "OasisXNFT1155: Nonexistent token");
        return string(abi.encodePacked(super.uri(0), id.toString(), ".json"));
    }

    /**
     * @notice nextId to mint
     **/
    function nextId() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /// @notice pausing the contract minting and token transfer
    function pause() external virtual onlyOwner {
        _pause();
    }

    /// @notice unpausing the contract minting and token transfer
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @notice a function for admins to mint cost-free
     * @param to the address to send the minted token to
     * @param tokenId the id of the token to mint
     * @param amount amount of tokens to mint
     **/
    function adminMint(address to, uint256 tokenId, uint256 amount)
        external
        whenNotPaused
        onlyOwner
    {
        require(to != address(0), "OasisXNFT1155: Address cannot be 0");

        limitNotExceeded(tokenId, amount);


       _mint(to, tokenId, amount, "");

        emit AdminMinted(to, tokenId, amount);
    }


    /**
     * @notice the public/presale minting function
     * @param to the address to send the minted token to
     * @param id id of the token to mint
     * @param amount quantity of tokens to mint
     * @param proof_ verify if msg.sender is whitelisted whenever presale
     **/
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes32[] memory proof_
    ) external payable nonReentrant{
        uint256 received = msg.value;

        require(to != address(0), "OasisXNFT1155: Address cannot be 0");
        require(
            received == mintPrice[_phase]*(amount),
            "OasisXNFT1155: Ether sent mismatch with mint price"
        );

        _merkleRoot > bytes32(0) && isAllowedToMint(proof_);

        limitNotExceeded(id, amount);

        require(
            _checkLimit(_msgSender(), amount),
            "OasisXNFT1155: max NFT mints per address exceeded"
        );

        _minted[_phase][to] = amount;

        _mint(to, id, amount, "");

        _forwardFunds(received);

        emit Minted(to, id, amount);
    }

    /**
     * @notice the public minting function -- requires 1 ether sent
     * @param to the address to send the minted token to
     * @param ids ids of the minted tokens
     * @param amounts quantity of tokens to mint
     * @param proof_ verify if msg.sender is whitelisted whenever presale
     **/
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes32[] memory proof_
    ) external payable nonReentrant{
        uint256 received = msg.value;
        uint256 amount = 0;

        require(to != address(0), "OasisXNFT1155: Address cannot be 0");

        for (uint256 i = 0; i < amounts.length; i++) {
            limitNotExceeded(ids[i], amounts[i]);
            amount += amounts[i];
        }

        require(
            received == mintPrice[_phase]*(amount),
            "OasisXNFT1155: Ether sent mismatch with mint price"
        );

        _merkleRoot > bytes32(0) && isAllowedToMint(proof_);

        require(
            _checkLimit(_msgSender(), amount),
            "OasisXNFT1155: max NFT mints per address exceeded"
        );

        _mintBatch(to, ids, amounts, "");

        _forwardFunds(received);

        for (uint256 i = 0; i < amounts.length; i++) {
            _tokenIdTracker.increment();
            _minted[_phase][to] = amount;
            emit Minted(to, ids[i], amounts[i]);
        }
    }

    /**
     * @notice Determines how ETH is stored/forwarded on purchases.
     * @param received amount to forward
     **/
    function _forwardFunds(uint256 received) internal {
        /// @notice forward fund to receiver wallet using CALL to avoid 2300 stipend limit
        (bool success, ) = protocolAddress.call{
            value: (received*(protocolFee))/(10000)
        }("");
        require(success, "OasisXLaunch1155: Failed to forward funds");
    }

    /**
     * @notice transfer batch of tokens
     * @param from address to transfer from
     * @param to address to transfer to
     * @param ids ids of the token transfered
     * @param amounts amount of token to transfer
     * @param data data to pass while transfer
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice transfer token
     * @param from address to transfer from
     * @param to address to transfer to
     * @param id id of the token transfered
     * @param amount amount of token to transfer
     * @param data data to pass while transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice changes merkleRoot in case whitelist list updated
     * @param merkleRoot root of the Merkle tree
     **/
    function changeMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        require(
            merkleRoot != _merkleRoot,
            "OasisXNFT1155: Merkle root cannot be same as previous"
        );
        _merkleRoot = merkleRoot;
    }

    /**
     * @notice the public function for checking if more tokens can be minted
     * @param id id of the token
     * @param amount amount of tokens being minted
     **/
    function limitNotExceeded(uint256 id, uint256 amount)
        public
        view
        returns (bool)
    {
        if (tokenMaxSupplies[id] > 0) {
            require(
                totalSupply(id)+(amount) <= tokenMaxSupplies[id],
                "OasisXNFT1155: ID supply exceeded"
            );
        } else {
            require(!exists(id), "");
            require(
                amount == 1 && nextId() <= maxTokenId,
                "OasisXNFT1155: NFT supply exceeded"
            );
        }
        return true;
    }

    /**
     * @notice the public function validating addresses to presale phase
     * @param proof_ hashes validating that a leaf exists inside merkle tree aka _merkleRoot
     **/
    function isAllowedToMint(bytes32[] memory proof_)
        internal
        view
        returns (bool)
    {
        if (_phase == Phase.Presale) {
            require(
                MerkleProof.verify(
                    proof_,
                    _merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "OasisXNFT1155: Caller is not whitelisted for Presale"
            );
        }
        return true;
    }

    /**
     * @notice checks if an address reached limit per wallet
     * @param minter address user minting nft
     * @param amount amount of tokens being minted
     **/
    function _checkLimit(address minter, uint256 amount)
        public
        view
        returns (bool)
    {
        return _minted[_phase][minter]+(amount) <= _mintsPerAddressLimit;
    }

    /**
     * @notice add initial token ids with their respective supplies
     * @param tokenIds_ list of token ids to be added
     * @param tokenSupplies_ supply of token id
     **/
    function _initialAddTokens(
        uint256[] memory tokenIds_,
        uint256[] memory tokenSupplies_
    ) private {
        require(
            tokenIds_.length == tokenSupplies_.length,
            "OasisXNFT1155: IDs/Supply arity mismatch"
        );
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            tokenMaxSupplies[tokenIds_[i]] = tokenSupplies_[i];
        }
    }

    /**
     * @notice add new token id with its respective supply
     * @param tokenIds_ list of token ids to be added
     * @param tokenSupplies_ supply of token id
     **/
    function addTokensAndChangeMaxSupply(
        uint256[] memory tokenIds_,
        uint256[] memory tokenSupplies_,
        uint256 maxTokenId_
    ) external onlyOwner {
        require(
            tokenIds_.length == tokenSupplies_.length,
            "OasisXNFT1155: IDs/Supply arity mismatch"
        );
        require(
            maxTokenId + tokenIds_.length <= maxTokenId_,
            "OasisXNFT1155: tokens added mismatch maxSupply"
        );
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(
                !exists(tokenIds_[i]),
                "OasisXNFT1155: token ID already exists"
            );
            tokenMaxSupplies[tokenIds_[i]] = tokenSupplies_[i];
        }
        maxTokenId = maxTokenId_;
    }

    /**
     * @notice before token transfer hook override
     * @param operator address of the operator
     * @param from address to send tokens from
     * @param to address to send tokens to
     * @param ids ids of the tokens to send
     * @param amounts amount of each token
     * @param data data to pass while sending
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(!paused(), "OasisXNFT1155: token transfer while paused");
    }
}