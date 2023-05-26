// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice ERC721
import "./launchpad/ERC721A.sol";

/// @notice libraries
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice Payment Splitter
import "./launchpad/PaymentSplitter.sol";

/**
 * @title OasisXNFT721
 * @notice Base 721 contract
 * @author OasisX Protocol | cryptoware.eth
 **/
contract OasisXNFT721 is ERC721A, Pausable, PaymentSplitter {
    /// @notice using Strings for uints conversion (tokenId)
    using Strings for uint256;

    /// @notice using Address for addresses extended functionality
    using Address for address;

    /// @notice using MerkleProof Library to verify Merkle proofs
    using MerkleProof for bytes32[];

    /// @notice Enum representing minting phases
    enum Phase {
        Presale,
        Public
    }

    /// @notice EIP721-required Base URI
    string private _baseTokenURI;

    /// @notice URI to hide NFTS during minting
    string public _notRevealedUri;

    /// @notice the current phase of the minting
    Phase private _phase;

    /// @notice root of the Merkle tree
    bytes32 private _merkleRoot;

    /// @notice The rate of minting per phase
    mapping(Phase => uint256) public mintPrice;

    /// @notice Address of protocol fee wallet;
    address payable public protocolAddress;

    /// @notice protocol fees from every drop
    uint256 private protocolFee;

    /// @notice The rate of mints per user
    mapping(Phase => mapping(address => uint256)) public _mintsPerUser;

    /// @notice Max number of NFTs to be minted
    uint256 private _maxTokenId;

    /// @notice max amount of nfts that can be minted per wallet address
    uint64 public _mintsPerAddressLimit;

    /// @notice public metadata locked flag
    bool public locked = false;

    /// @notice public revealed state
    bool public revealed;

    /// @notice defining whether contract is Base or not
    bool public isBase;

    /// @notice address owner
    address public owner;

    /// @notice Minting events definition
    event AdminMinted(
        address indexed to,
        uint256 indexed startTokenId,
        uint256 quantity
    );
    event Minted(
        address indexed to,
        uint256 indexed startTokenId,
        uint256 quantity
    );

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
        require(!locked, "OasisXNFT721: Metadata URIs are locked");
        _;
    }

    /// @notice Art not revealed modifier
    modifier notRevealed() {
        require(!revealed, "OasisXNFT721: Art is already revealed");
        _;
    }

    /// @notice Art revealed modifier
    modifier Revealed() {
        require(revealed, "OasisXNFT721: Art is not revealed");
        _;
    }

    /// @notice only Owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "OasisXNFT721: only owner");
        _;
    }

    /**
     * @notice constructor
     * @param name the name of the EIP721 Contract
     * @param symbol the token symbol
     **/
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {
        isBase = true;
    }

    /**
     * @notice initializing the cloned contract
     * @param data data for 721Proxy clone encoded
     * @param owner_ address of 721Proxy owner
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
            "OasisXNFT721: this is the base contract,cannot initialize"
        );

        require(
            owner == address(0),
            "OasisXNFT721: contract already initialized"
        );

        require
        (
            owner_ != address (0),
            "OasisXNFT721: Owner address cannot be 0"
        );

        require
        (
            protocolAddress_ != address(0),
            "OasisXNFT721 : Protocol address cannot be 0"
        );

        (
            string memory name_,
            string memory symbol_,
            string memory baseTokenURI,
            string memory notRevealedUri,
            bytes32 root,
            address[] memory payees_,
            uint256[] memory shares_,
            uint256 maxTokenId,
            uint256 mintPrice_,
            uint64 mintsPerAddressLimit,
            bool revealed_
        ) = abi.decode(
                data,
                (
                    string,
                    string,
                    string,
                    string,
                    bytes32,
                    address[],
                    uint256[],
                    uint256,
                    uint256,
                    uint64,
                    bool
                )
            );

        initialize721A(name_, symbol_);

        initializePaymentSplitter(payees_, shares_);

        protocolFee = protocolFee_;

        protocolAddress = payable(protocolAddress_);

        owner = owner_;

        revealed = revealed_;

        _mintsPerAddressLimit = mintsPerAddressLimit;

        _maxTokenId = maxTokenId;

        _merkleRoot = root;

        _phase = root == bytes32(0) ? Phase(1) : Phase(0);

        mintPrice[_phase] = mintPrice_;

        _baseTokenURI = baseTokenURI;

        _notRevealedUri = notRevealedUri;
    }

    /// @notice setting starting token id to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice receive fallback should revert
    receive() external payable override {
        revert("OasisXNFT721: Please use Mint or Admin calls");
    }

    /// @notice default fallback should revert
    fallback() external payable {
        revert("OasisXNFT721: Please use Mint or Admin calls");
    }

    /// @notice returns the base URI for the contract
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            revealed
                ? string(abi.encodePacked(super.tokenURI(tokenId), ".json"))
                : _notRevealedUri;
    }

    /**
     * @notice a function for admins to mint cost-free
     * @param to the address to send the minted token to
     * @param quantity quantity of tokens to mint
     **/
    function adminMint(address to, uint256 quantity)
        external
        whenNotPaused
        onlyOwner
    {
        require(to != address(0), "OasisXNFT721: Address cannot be 0");

        limitNotExceeded(quantity);

        uint256 startToken = _currentIndex;

        _safeMint(to, quantity);

        emit AdminMinted(to, startToken, quantity);
    }

    /**
     * @notice the public/presale minting function -- requires 1 ether sent
     * @param to the address to send the minted token to
     * @param quantity quantity of tokens to mint
     * @param proof_ verify if msg.sender is whitelisted whenever presale
     **/
    function mint(
        address to,
        uint256 quantity,
        bytes32[] memory proof_
    ) external payable whenNotPaused {
        uint256 received = msg.value;

        require(to != address(0), "OasisXNFT721: Address cannot be 0");
        require(
            received == mintPrice[_phase]*(quantity),
            "OasisXNFT721: Ether sent mismatch with mint price"
        );

        limitNotExceeded(quantity);

        _merkleRoot > bytes32(0) && isAllowedToMint(proof_);

        require(
            _checkLimit(to, quantity),
            "OasisXNFT721: max NFT mints per address exceeded"
        );

        uint256 startToken = _currentIndex;

        _mintsPerUser[_phase][to] += quantity;

        _safeMint(to, quantity);

        _forwardFunds(received);

        emit Minted(to, startToken, quantity);
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
        require(success, "OasisXLaunch721: Failed to forward funds");
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
        require(mintCost > 0, "OasisXNFT721: rate is 0");

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
            "OasisXNFT721: mint Cost cannot be same as previous"
        );
        mintPrice[_phase] = mintCost;
    }

    /**
     * @notice changes the Base URI
     * @param newBaseURI the new Base URI
     **/
    function changeBaseURI(string memory newBaseURI)
        external
        onlyOwner
        notLocked
    {
        require(
            (keccak256(abi.encodePacked((_baseTokenURI))) !=
                keccak256(abi.encodePacked((newBaseURI)))),
            "OasisXNFT721: Base URI cannot be same as previous"
        );
        _baseTokenURI = newBaseURI;
    }

    /**
     * @notice changes the minting cost
     * @param newNotRevealedUri the new notRevealed URI
     **/
    function changeNotRevealedURI(string memory newNotRevealedUri)
        external
        onlyOwner
        notRevealed
    {
        require(
            (keccak256(abi.encodePacked((newNotRevealedUri))) !=
                keccak256(abi.encodePacked((_notRevealedUri)))),
            "OasisXNFT721: Base URI cannot be same as previous"
        );
        _notRevealedUri = newNotRevealedUri;
    }

    /**
     * @notice reveal NFTs
     **/
    function reveal() external onlyOwner notRevealed {
        revealed = true;
    }

    /**
     * @notice lock metadata forever
     **/
    function lockMetadata() external onlyOwner notLocked Revealed {
        locked = true;
    }

    /**
     * @notice changes merkleRoot in case whitelist list updated
     * @param merkleRoot root of the Merkle tree
     **/
    function changeMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        require(
            merkleRoot != _merkleRoot,
            "OasisXNFT721: Merkle root cannot be same as previous"
        );
        _merkleRoot = merkleRoot;
    }

    /// @notice the public function for checking if more tokens can be minted
    function limitNotExceeded(uint256 quantity) public view returns (bool) {
        require(
            (_currentIndex+(quantity))-(1) <= _maxTokenId,
            "OasisXNFT721: max NFT limit exceeded"
        );
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
                "OasisXNFT721: Caller is not whitelisted for Presale"
            );
        }
        return true;
    }

    /**
     * @notice checks if an address reached limit per wallet
     * @param minter address user minting nft
     * @param quantity amount of tokens being minted
     **/
    function _checkLimit(address minter, uint256 quantity)
        public
        view
        returns (bool)
    {
        return
            _mintsPerUser[_phase][minter]+(quantity) <=
            _mintsPerAddressLimit;
    }

    /**
     * @notice before transfer hook function
     * @param from the address to send the token from
     * @param to the address to send the token to
     * @param startTokenId the start token id
     * @param quantity the quantity transfered
     **/
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "OasisXNFT721: token transfer while paused");
    }
}