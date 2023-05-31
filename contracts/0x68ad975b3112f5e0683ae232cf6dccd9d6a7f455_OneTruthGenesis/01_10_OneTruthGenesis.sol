// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721APreApproval.sol";

/// @title OneTruthGenesis
/// @author Anthony Graignic (@agraignic)
/// @notice Genesis NFT by the artist duo One Truth (Pase & Dr.Drax)
/// We understand that the contract creation, the minting and the first transactions have a climate impact and decided to contribute to ClimeWorks to counterbalance it for many years.
contract OneTruthGenesis is ERC721APreApproval, Ownable {
    uint256 public constant LIMIT_PER_ADDRESS = 1;
    uint256 public limitPerPublicMint = 2; // 1+1
    uint256 public constant PRESALE_PRICE = 0.2 ether;
    uint256 public constant PUBLIC_PRICE = 0.25 ether;
    /// @notice Revenues & Royalties recipient
    address public beneficiary;

    uint256 public constant MAX_SUPPLY = 501; // 500+1
    uint256 public constant INTERNAL_SUPPLY = 28; // 27+1
    uint256 public constant ALLOWLIST_SUPPLY = 473;

    /// @dev Root hash of addresses for allow list
    bytes32 public allowlistMerkleRoot;

    /// @dev Root hash of addresses for wait list
    bytes32 public waitlistMerkleRoot;

    /// @notice 256-bitmap for claimed allow list
    mapping(uint256 => uint256) private claimedAllowlist;
    /// @notice 256-bitmap for claimed wait list
    mapping(uint256 => uint256) private claimedWaitlist;

    ///@notice Provenance hash of images
    uint256 public immutable provenanceHash;
    ///@notice Starting index, pseudo randomly set
    uint16 public startingIndex;

    /// @notice IPFS base URI for metadata
    string private baseURI;
    /// @dev Contract URI used by OpenSea to get contract details (owner, royalties...)
    string public contractURI;

    /// @notice Timestamp after which some functions will be frozen
    uint256 public freezeAt;

    /// @notice Mint steps
    /// CLOSED sale closed or sold out
    /// ALLOWLIST Allow list sale
    /// WAITLIST Wait list list sale
    /// PUBLIC Public sale
    enum MintStep {
        CLOSED,
        ALLOWLIST,
        WAITLIST,
        PUBLIC
    }
    MintStep public step;

    event MintStepUpdated(MintStep step);
    event AllowlistUpdated();
    event WaitlistUpdated();

    constructor(
        string memory initContractURI,
        string memory initBaseURI,
        address _owner,
        address _beneficiary,
        bytes32 _merkleRoot,
        uint256 _provenanceHash
    ) ERC721A("One Truth Genesis", "OTG") {
        contractURI = initContractURI;
        baseURI = initBaseURI;
        if (_owner != address(0)) {
            _transferOwnership(_owner);
        }
        if (_beneficiary != address(0)) {
            beneficiary = _beneficiary;
        }
        allowlistMerkleRoot = _merkleRoot;
        waitlistMerkleRoot = _merkleRoot;

        provenanceHash = _provenanceHash;

        freezeAt = block.timestamp + 8 weeks;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier rightPresalePrice(uint256 _quantity) {
        require(msg.value == PRESALE_PRICE * _quantity, "incorrect price");
        _;
    }

    modifier rightPublicPrice(uint256 _quantity) {
        require(msg.value == PUBLIC_PRICE * _quantity, "incorrect price");
        _;
    }

    modifier belowMaxAllowed(uint256 _quantity, uint8 _max) {
        require(_quantity <= _max, "quantity above max");
        _;
    }

    modifier belowTotalSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity < MAX_SUPPLY,
            "total supply exceeded"
        );
        _;
    }

    modifier frozen() {
        require(block.timestamp < freezeAt, "frozen function");
        _;
    }

    /// @notice Mint your NFT(s) (public sale)
    /// @param _quantity number of NFT to mint
    /// no gift allowed nor minting from other smartcontracts
    function mint(uint256 _quantity)
        external
        payable
        callerIsUser
        rightPublicPrice(_quantity)
        belowTotalSupply(_quantity)
    {
        require(step == MintStep.PUBLIC, "no public mint yet");
        require(_quantity < limitPerPublicMint, "quantity too high");

        _mint(msg.sender, _quantity);
    }

    /// @notice Mint NFT(s) during allowlist sale
    /// Can only be done once.
    /// @param _quantity number of NFT to mint
    /// @param _max Max number of token allowed to mint
    /// @param _proof Merkle Proof leaf for the sender address
    /// @param _index address index in allowlist
    function allowlistMint(
        uint256 _quantity,
        uint8 _max,
        uint256 _index,
        bytes32[] calldata _proof
    )
        external
        payable
        rightPresalePrice(_quantity)
        belowMaxAllowed(_quantity, _max)
    {
        require(step == MintStep.ALLOWLIST, "no allowlist sale");
        require(
            totalSupply() + _quantity < ALLOWLIST_SUPPLY + INTERNAL_SUPPLY,
            "allowlist supply exceeded"
        );
        require(!hasClaimedAllowlist(_index), "already claimed");
        require(
            isInAllowList(msg.sender, _max, _index, _proof),
            "invalid merkle proof"
        );

        _setClaimedAllowlist(_index);
        _mint(msg.sender, _quantity);
    }

    /// @notice Mint NFT(s) during waitlist sale
    /// Can only be done once.
    /// @param _quantity number of NFT to mint
    /// @param _proof Merkle Proof leaf for the sender address
    /// @param _max Max number of token allowed to mint
    /// @param _index address index in waitlist
    function waitlistMint(
        uint256 _quantity,
        uint8 _max,
        uint256 _index,
        bytes32[] calldata _proof
    )
        external
        payable
        rightPresalePrice(_quantity)
        belowTotalSupply(_quantity)
        belowMaxAllowed(_quantity, _max)
    {
        require(step == MintStep.WAITLIST, "no waitlist sale");
        require(!hasClaimedWaitlist(_index), "already claimed");
        require(
            isInWaitList(msg.sender, _max, _index, _proof),
            "invalid merkle proof"
        );

        _setClaimedWaitlist(_index);
        _mint(msg.sender, _quantity);
    }

    /// @notice Check if an address is in the allowlist with the correct data
    /// @dev Use OpenZeppelin MerkleProof code to compute leaf & verify itS
    /// @param _account address to verify
    /// @param _max max quantity to mint
    /// @param _index address index in waitlist
    /// @param _proof merkle proof to verify
    /// @return true if in allowlist merkle root, false otherwise
    function isInAllowList(
        address _account,
        uint8 _max,
        uint256 _index,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account, _max, _index));
        return MerkleProof.verify(_proof, allowlistMerkleRoot, leaf);
    }

    /// @notice Check if an address is in the waitlist with the correct data
    /// @dev Use OpenZeppelin MerkleProof code to compute leaf & verify itS
    /// @param _account address to verify
    /// @param _max max quantity to mint
    /// @param _index address index in waitlist
    /// @param _proof merkle proof to verify
    /// @return true if in waitlist merkle root, false otherwise
    function isInWaitList(
        address _account,
        uint8 _max,
        uint256 _index,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account, _max, _index));
        return MerkleProof.verify(_proof, waitlistMerkleRoot, leaf);
    }

    /// @inheritdoc ERC721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    ///@dev Setting starting index only once
    function _setStartingIndex() internal {
        if (startingIndex == 0) {
            uint256 predictableRandom = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.difficulty,
                        totalSupply()
                    )
                )
            );
            startingIndex = uint16(predictableRandom % (MAX_SUPPLY - 1));
        }
    }

    /// @notice Check if an index (corresponding to an address) has claimed its allowlist spot
    /// @param index address index in allowlist
    /// @return true if already claimed, false otherwise
    function hasClaimedAllowlist(uint256 index) public view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 mask = (1 << bitIndex);

        return claimedAllowlist[wordIndex] & mask == mask;
    }

    /// @notice Set an index to claimed
    /// @param index address index in allowlist
    function _setClaimedAllowlist(uint256 index) private {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        claimedAllowlist[wordIndex] =
            claimedAllowlist[wordIndex] |
            (1 << bitIndex);
    }

    /// @notice Check if an index (corresponding to an address) has claimed its waitlist spot
    /// @param index address index in waitlist
    /// @return true if already claimed, false otherwise
    function hasClaimedWaitlist(uint256 index) public view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 mask = (1 << bitIndex);

        return claimedWaitlist[wordIndex] & mask == mask;
    }

    /// @notice Set an index to claimed
    /// @param index address index in waitlist
    function _setClaimedWaitlist(uint256 index) private {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        claimedWaitlist[wordIndex] =
            claimedWaitlist[wordIndex] |
            (1 << bitIndex);
    }

    /// @inheritdoc ERC721A
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////
    ///// Royalties                                   //
    ////////////////////////////////////////////////////

    /// @dev Royalties are the same for every token that's why we don't use OZ's impl.
    function royaltyInfo(uint256, uint256 amount)
        public
        view
        returns (address, uint256)
    {
        address recipient = beneficiary;
        if (recipient == address(0)) {
            recipient = owner();
        }

        // (royaltiesRecipient || owner), 7.5%
        return (recipient, (amount * 750) / 10000);
    }

    ////////////////////////////////////////////////////
    ///// Only Owner                                  //
    ////////////////////////////////////////////////////

    /// @notice Gift a NFT to someone i.e. a team member, only done by owner
    /// @param _to recipient address
    /// @param _quantity number of NFT to mint and gift
    function gift(address _to, uint256 _quantity) external onlyOwner {
        require(
            totalSupply() + _quantity < INTERNAL_SUPPLY,
            "internal supply exceeded"
        );
        _mint(_to, _quantity);
    }

    /// @notice Allow the owner to change the baseURI
    /// @param newBaseURI the new uri
    function setBaseURI(string calldata newBaseURI) external onlyOwner frozen {
        baseURI = newBaseURI;
    }

    /// @notice Allow owner to set the royalties recipient
    /// @param newBeneficiary the new contract uri
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    /// @notice Allow owner to set contract URI
    /// @param newContractURI the new contract URI
    function setContractURI(string calldata newContractURI)
        external
        onlyOwner
        frozen
    {
        contractURI = newContractURI;
    }

    /// @notice Allow owner to change minting step
    /// @param newStep the new step
    function setStep(MintStep newStep) external onlyOwner frozen {
        step = newStep;
        // Set starting index after people minted
        if (newStep == MintStep.ALLOWLIST) {
            _setStartingIndex();
        }
        emit MintStepUpdated(newStep);
    }

    /// @notice Allow owner to update the allowlist merkle root
    /// @param newAllowlistMerkleRoot the new merkle root for the allowlist
    function setAllowlistMerkleRoot(bytes32 newAllowlistMerkleRoot)
        external
        onlyOwner
        frozen
    {
        allowlistMerkleRoot = newAllowlistMerkleRoot;
        emit AllowlistUpdated();
    }

    /// @notice Allow owner to update the waitlist merkle root
    /// @param newWaitlistMerkleRoot the new merkle root for the waitlist
    function setWaitlistMerkleRoot(bytes32 newWaitlistMerkleRoot)
        external
        onlyOwner
        frozen
    {
        waitlistMerkleRoot = newWaitlistMerkleRoot;
        emit WaitlistUpdated();
    }

    /// @notice Allow owner to update the limit per wallet for public mint
    /// @param newLimit the new limit e.g. 7 for public mint per wallet
    function setLimitPerPublicMint(uint256 newLimit) external onlyOwner frozen {
        limitPerPublicMint = newLimit;
    }

    /// @notice Allow everyone to withdraw contract balance and send it to owner
    function withdraw() external {
        payable(beneficiary).transfer(address(this).balance);
    }

    /// @notice Allow everyone to withdraw contract ERC20 balance and send it to owner
    function withdrawERC20(IERC20 _erc20Token) external {
        _erc20Token.transfer(beneficiary, _erc20Token.balanceOf(address(this)));
    }
}