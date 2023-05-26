//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/**
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OOkxxddddddxxkOO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkdoodddooddxxkkkkkkxxddoodddooxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdooooxOKNWMMMMMMMMMMMMMMMMMMMMWNKOxoooodkKWMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMNOooookKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkooookNMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMXkoloxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkolokXMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMNOoloONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOoloONMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMXxllkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxllxXMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMXxcl0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ocdXMMMMMMMMMMMMMM
 * MMMMMMMMMMMWNxco0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo:xNMMMMMMMMMMMM
 * MMMMMMMMMMWOcc0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ccOWMMMMMMMMMM
 * MMMMMMMMMXd:xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:dXWMMMMMMMM
 * MMMMMMMM0clKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKk0WMMMMMMMKlc0MMMMMMMM
 * MMMMMMWO:dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;. .xWMMMMMMMNd:OWMMMMMM
 * MMMMMWk;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'      .dNMMMMMMMWx;kWMMMMM
 * MMMMWx;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.          .oXMMMMMMMWx;xWMMMM
 * MMMWO;dWMMMMMMMMMMWkc:::::::::::::::::::::::::::::::::::::::::::::'                cXMMMMMMMWd;OMMMM
 * MWMK:lNMMMMMMMMMMNo.                                                                :XMMMMMMMNl:KMMM
 * MMNl:XMMMMMMMMMMXc                                                               .;lONMMMMMMMMK:lNMM
 * MMk;xMMMMMMMMMMK:                                                             'cxKWMMMMMMMMMMMMx;kMM
 * MNccNMMMMMMMMM0,                                                          .;oONMMMMMMMMMMMMMMMMNccNM
 * MO;dMMMMMMMMMMK;                                                       'cxKWMMMMMMMMMMMMMMMMMMMMx;OM
 * Md;0MMMMMMMMMMMK:            ':::::::::augminted labs, llc:::::::::oolONMMMMMMMMMMMMMMMMMMMMMMMM0;dM
 * Wl:NMMMMMMMMMMMMXc          .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMX:lW
 * N:lWMMMMMMMMMMMMMNo.        cNMWk:::::::::::::::ckXNMMXd:::::::::::::cOWMMMMMMMMMMMMMMMMMMMMMMMMWc:N
 * X:lWMMMMMMMMMMMMMMNd.      .OMM0'               :KMMWK;             .lXMMMMMMMMMMMMMMMMMMMMMMMMMWl:X
 * X:lWMMMMMMMMMMMMMMMWx.     lWMNl              .oNMMWk'             .xNMMMMMMMMMMMMMMMMMMMMMMMMMMWl:N
 * NccNMMMMMMMMMMMMMMMMWO'   ,0MMk.             'kWMNXd.             ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMNccN
 * Mo;KMMMMMMMMMMMMMMMMMM0, .dWMX:             ;0WMKc.              :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:oM
 * Mx;kMMMMMMMMMMMMMMMMMMMK:cXMWk.           .lXMW0,              .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk;xM
 * MK:oWMMMMMMMMMMMMMMMMMMMNNMMWXOdoc;'.    .xNWWx.              .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo:KM
 * MWd:0MMMMMMMMMMMMMMMMMMMMMN00XNMMMWNX0kdo0WMXo.              ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;oWM
 * MMK:lWMMMMMMMMMMMMMMMMMMMMNx'.';coxO0XWMMMMK:               cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo:KMM
 * MMWx;kMMMMMMMMMMMMMMMMMMMMMWk.      ..,:coo'              .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk;xMMM
 * MMMNo:KMMMMMMMMMMMMMMMMMMMMMWO'                          'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:oWMMM
 * MMMMXccKMMMMMMMMMMMMMMMMMMMMMW0,                        :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKccXMMMM
 * MMMMMXccKMMMMMMMMMMMMMMMMMMMMMMK:                     .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXccXMMMMM
 * MMMMMMXccKMMMMMMMMMMMMMMMMMMMMMMXc                   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKclXMMMMMM
 * MMMMMMMNo:OWMMMMMMMMMMMMMMMMMMMMMNo.                ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:oNMMMMMMM
 * MMMMMMMMWk:dNMMMMMMMMMMMMMMMMMMMMMWd.             .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd:kWMMMMMMMM
 * MMMMMMMMMMKlcOWMMMMMMMMMMMMMMMMMMMMWx'          .dXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOclKMMMMMMMMMM
 * MMMMMMMMMMMWkcl0WMMMMMMMMMMMMMMMMMMMWKOOOOOOOOOOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0lckWMMMMMMMMMMM
 * MMMMMMMMMMMMMNxco0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ocxXMMMMMMMMMMMMM
 * MMMMMMMMMMMMMWMXxclONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOlcxXMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMNklldKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdlokNMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMWKdlld0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdlldKWMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMW0doookKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkoood0WMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMWXkdoooxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxooodkXWMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxooooddkO0KXNWWWMMMMMWWNXK0OxdoddooxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkxdooddddddddddddddoodxkOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXXXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * @title Base contract for standard ERC721A token drops
 * @author Augminted Labs, LLC
 * @notice Contract has been optimized for fairness and security
 */
contract ERC721ABase is ERC721AQueryable, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using ECDSA for bytes32;

    VRFCoordinatorV2Interface internal immutable COORDINATOR;
    uint256 internal _tokenOffset;
    string internal _provenanceHash;

    struct VrfRequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }
    VrfRequestConfig public vrfRequestConfig;

    struct Metadata {
        string baseURI;
        string collectionURI;
        string placeholderURI;
    }
    Metadata public metadata;

    uint256 public immutable MAX_SUPPLY;
    uint256 public mintPrice;
    uint256 public maxPerAddress;
    address public signer;
    bool public revealed;
    bool public saleActive;
    mapping(address => uint256) public addressMinted;
    mapping(bytes4 => bool) public functionLocked;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        address vrfCoordinator
    )
        ERC721A(name, symbol)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        MAX_SUPPLY = maxSupply;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        require(!functionLocked[msg.sig], "Function is locked");
        _;
    }

    /**
     * @notice Return token metadata
     * @param tokenId To return metadata for
     * @return Token URI for the specified token
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return revealed ? ERC721A.tokenURI(tokenId) : metadata.placeholderURI;
    }

    /**
     * @notice Override ERC721 _baseURI function to use base URI pattern
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return metadata.baseURI;
    }

    /**
     * @notice Token offset is added to the token ID (wrapped on overflow) to get metadata asset index
     */
    function tokenOffset() public view returns (uint256) {
        require(_tokenOffset != 0, "Offset is not set");

        return _tokenOffset;
    }

    /**
     * @notice Provenance hash is used as proof that token metadata has not been modified
     */
    function provenanceHash() public view returns (string memory) {
        require(bytes(_provenanceHash).length != 0, "Provenance hash is not set");

        return _provenanceHash;
    }

    /**
     * @notice Lock individual functions that are no longer needed. WARNING: THIS CANNOT BE UNDONE
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyOwner {
        functionLocked[id] = true;
    }

    /**
     * @notice Set token offset using Chainlink VRF
     * @dev Provenance hash must already be set
     */
    function setTokenOffset() public onlyOwner {
        require(_tokenOffset == 0, "Offset is already set");
        provenanceHash(); // require provenance hash is set

        COORDINATOR.requestRandomWords(
            vrfRequestConfig.keyHash,
            vrfRequestConfig.subId,
            vrfRequestConfig.requestConfirmations,
            vrfRequestConfig.callbackGasLimit,
            1 // number of random words
        );
    }

    /**
     * @notice Callback function for Chainlink VRF request randomness call
     * @dev Maximum offset value is the maximum token ID (MAX_SUPPLY - 1)
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _tokenOffset = randomWords[0] % MAX_SUPPLY;
    }

    /**
     * @notice Set provenance hash
     * @dev Can only be set before the token offset is generated
     * @param hash Metadata proof string
     */
    function setProvenanceHash(string memory hash) public onlyOwner {
        require(_tokenOffset == 0, "Cannot set provenance hash after token offset is set");

        _provenanceHash = hash;
    }

    /**
     * @notice Set configuration data for Chainlink VRF
     * @param _vrfRequestConfig Struct with updated configuration values
     */
    function setVrfRequestConfig(VrfRequestConfig memory _vrfRequestConfig) public onlyOwner {
        vrfRequestConfig = _vrfRequestConfig;
    }

    /**
     * @notice Set metadata information
     * @param _metadata Struct with updated metadata values
     */
    function setMetadata(Metadata calldata _metadata) public lockable onlyOwner {
        metadata = _metadata;
    }

    /**
     * @notice Set mint price
     * @param _mintPrice Amount to pay for a single token
     */
    function setMintPrice(uint256 _mintPrice) public lockable onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @notice Set maximum number of tokens per address
     * @param _maxPerAddress Maximum number of tokens a single address can mint
     */
    function setMaxPerAddress(uint256 _maxPerAddress) public lockable onlyOwner {
        require(_maxPerAddress > 0, "Max per address must be greater than zero");

        maxPerAddress = _maxPerAddress;
    }

    /**
     * @notice Set signature signing address
     * @param _signer Address of account used to create mint signatures
     */
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    /**
     * @notice Flip token metadata to revealed
     * @dev Can only be revealed after token offset has been set
     */
    function flipRevealed() public lockable onlyOwner {
        require(_tokenOffset != 0, "Offset is not set");

        revealed = !revealed;
    }

    /**
     * @notice Flip state of the token sale
     */
    function flipSaleActive() public lockable onlyOwner {
        saleActive = !saleActive;
    }

    /**
     * @notice Mint the specified number of token using a signature
     * @param amount Of tokens to mint
     * @param signature Ethereum signed message of transaction sender's address, created by signer
     */
    function mint(uint256 amount, bytes memory signature) public virtual payable nonReentrant {
        require(saleActive, "Sale is not active");
        require(_totalMinted() + amount <= MAX_SUPPLY, "Insufficient supply");
        require(msg.value == mintPrice * amount, "Invalid Ether amount sent");
        require(addressMinted[_msgSender()] + amount <= maxPerAddress, "Insufficient mints available");

        require(signer == ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender()))),
            signature
        ), "Invalid signature");

        _safeMint(_msgSender(), amount);
        addressMinted[_msgSender()] += amount;
    }

    /**
     * @notice Permanently commit the state of the mint configuration. WARNING: THIS CANNOT BE UNDONE
     */
    function commitMintConfig() external {
        lockFunction(this.setMintPrice.selector);
        lockFunction(this.setMaxPerAddress.selector);
    }

    /**
     * @notice Permanently commit the state of the metadata information. WARNING: THIS CANNOT BE UNDONE
     * @dev Metadata should be migrated to a decentralized and, ideally, permanent storage solution
     */
    function commitMetadata() external {
        require(revealed, "Metadata must be revealed");

        lockFunction(this.setMetadata.selector);
        lockFunction(this.flipRevealed.selector);
    }

    /**
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }
}