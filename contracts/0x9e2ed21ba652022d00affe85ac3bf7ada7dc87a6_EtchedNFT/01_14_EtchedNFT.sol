//         .,,,,,,,,,,,,,,,,,,,,,.....................,,,,,,,,,,,,,,,,,,,,,.
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//  ,,,,,,,,,,,,,,,.,,,,,,,.                       .,,,,,,,,,,,,,,,.,,,,,,,,,,,,,,,
//  ,,,,,,,,,,,,,,,,,,.                                 ,,,,,,,,,,,.,,,,,,,,,,,,,,,
// ,,,,,,,,,,,,,,,,                                         ,,,,,,,.,,,,,,,,,,,,,,,
// ,,,,,,,,,,,,,                                               ,,,,.,,,,,,,,,,,,,,,
// ,,,,,,,,,,,                                                   ,,.,,,,,,,,,,,,,,,
// ,,,,,,,,,                                                       .,,,,,,,,,,,,,,,
// ,,,,.,,                   &*********,*,,,,&                      ,,,.,,,.,,,.,,,
// ,,,,,,                &/************,*,,,,,,,#                     ,,,,,,,,,,,,,
// ,,,,,               &///************,*....                          ,,,,,,,,,,,,
// ,,,,               *////********.........&&&&(* &                   ,,,,,,,,,,,,
// .,,,              &/////*********.........  .     *                  ,,,.,,,,,,,
// .,,.              &/////*********.....*&&&&&& ( %%                   ,,,,,,,,,,,
// .,,               &*////*********...../%,/ & % .*  /                 ,,,,,,,,,,,
// .,,                &*///****&&&%*.........    % #/   #               ,,,,,,,,,,,
// .,.,                &**/***.%.,&.,........          %                ,.,.,.,.,.,
// .,,,                  &***&&,(,&..........      /,,,.&               ,,,,,,,,,,,
// .,,,,                    *&**(&,..&.......        ,,.%              ,,,,,,,,,,,,
// .,,,,                         &,..........         .               ,,,,,,,,,,,,,
// ,,,,,,                         %......%&&.         .              ,,,,,,.,,,,,,,
// ,,,,,,,,                        ..........&&                     ,,,,,,,,,,,,,,,
// ,,,,,,,,,                      ..........&                     ,.,,,,,,,,,,,,,,,
// ,,,,,,,,,,,                /&&**,****@..%                    .,,.,,,,,,,,,,,,,,,
// ,,,,.,,,.,,,.,           #%%%/##/*********                 ,.,,,.,,,.,,,.,,,.,,,
// ,,,,,,,,,,,,,,,,,     #&&%%(%&*%#(******&               ,,,,,,,,.,,,,,,,,,,,,,,,
// ,,,,,,,,,,,,,,,,.,,@&&&&#%%*,%###((&***,            ,,,,,,,,,,,,.,,,,,,,,,,,,,,,
// ,,,,,,,,,,,,,,,,,@&&&@&&%,&%%#&#*((///@@      .,,,,,,,,,,,,,,,,,.,,,,,,,,,,,,,,,
//  ,,,,,,,,,,,,,,,&&&&&&&&%%%&%@%#(((//***&,,,,,,,.,,,,,,,.,,,,,,,.,,,,,,,,,,,,,,,
//   ,,,,,,,,,,,,,@#&&&#&&&%%@%%###(((//@,@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//     ,,,,,,,,,,&#&&&##&&&%%%(%//(((///***&,,,,,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,

pragma solidity 0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "contracts/interfaces/IERC2981.sol";

contract EtchedNFT is ERC721A, Ownable, ReentrancyGuard, IERC2981 {
    // --------------------------------------------------------------
    // STORAGE
    // --------------------------------------------------------------

    string public uriExtension;
    uint256 public constant SCALE = 1e18;

    uint256 public publicPrice;
    uint256 private immutable MAX_PER_ADDRESS_PHASE_TWO;
    uint256 private immutable MAX_PER_ADDRESS_PUBLIC;
    uint256 private immutable MAX_TOKEN_SUPPLY;
    string private baseURI;
    string private presaleURI;
    uint256 public roundOneNum;
    REVEALROUND public revealRound = REVEALROUND.ONE;

    uint256 public royaltyCut = 1e17; // default = 10%
    address public royaltyRecipient;

    bytes32 private phaseOneMerkleRoot;
    bytes32 private phaseTwoMerkleRoot;
    bool public phaseOneFlag;
    bool public phaseTwoFlag;
    bool public publicFlag;
    mapping(address => uint256) public mintedTokens; // how many an account has minted
    mapping(address => uint256) public mintedTokensPhaseTwo;
    mapping(address => bool) public phaseOneClaimed;

    // --------------------------------------------------------------
    // EVENTS
    // --------------------------------------------------------------

    event TokenURISet(uint256 tokenID);
    event TokensMinted(address indexed to, uint256 quantity);
    event BaseURIUpdated(string uri);
    event PhaseOneMerkleRootUpdated(bytes32 root);
    event PhaseTwoMerkleRootUpdated(bytes32 root);
    event TokenURIExtentionSet(string extention);
    event NewRoyaltyRecipientSet(address newRecipient);
    event NewRoyaltyCutSet(uint256 newRoyaltyCut);
    event NewPublicMintPriceSet(uint256 newPrice);
    event PresaleURIUpdated(string uri);
    event FlagSwitched(bool value);
    event RevealRoundSet(REVEALROUND phase);
    event RoundOneRevealNumberUpdated(uint256 quantity);

    enum REVEALROUND {
        ONE,
        TWO
    }

    // --------------------------------------------------------------
    // CUSTOM ERRORS
    // --------------------------------------------------------------

    error RoyaltyCutTooHigh();
    error FounderMintNotActive();
    error PhaseTwoMintNotActive();
    error PublicMintNotActive();
    error TokensAlreadyMinted();
    error InsufficientEth();
    error AmountExceedsMax();
    error MintExceedsMaxPerAddress();
    error NftIDOutOfRange();
    error MerkleProofNotValid();
    error MintExceedsMaxSupply();
    error WithdrawEthFailed();
    error NoRoundOneRevealNumber();

    // --------------------------------------------------------------
    // CONSTRUCTOR
    // --------------------------------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _publicPrice,
        uint256 _maxPerAddressforSale,
        uint256 _maxPerAddressforPreSale,
        uint256 _maxTokenSupply
    ) ERC721A(_name, _symbol) {
        MAX_PER_ADDRESS_PHASE_TWO = _maxPerAddressforPreSale;
        MAX_PER_ADDRESS_PUBLIC = _maxPerAddressforSale;
        MAX_TOKEN_SUPPLY = _maxTokenSupply;
        publicPrice = _publicPrice;
    }

    // --------------------------------------------------------------
    // STATE-MODIFYING FUNCTIONS
    // --------------------------------------------------------------

    /// @notice Starts the Mintings with Tokenid at a count of one
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice first phase pre-sale mint for whitelisted accounts, free minting
    /// @param quantity amount an address can mint
    /// @param _merkleProof for whitelist verification
    function phaseOneMint(uint256 quantity, bytes32[] calldata _merkleProof) public {
        if (phaseOneFlag != true) revert FounderMintNotActive();

        if (phaseOneClaimed[msg.sender]) revert TokensAlreadyMinted();

        if (totalSupply() + quantity > MAX_TOKEN_SUPPLY) revert MintExceedsMaxSupply();

        // Merkle proof verification
        bool proofIsValid = MerkleProof.verify(
            _merkleProof,
            phaseOneMerkleRoot,
            keccak256(abi.encodePacked(msg.sender, quantity))
        );
        if (!proofIsValid) revert MerkleProofNotValid();

        phaseOneClaimed[msg.sender] = true;

        _safeMint(msg.sender, quantity);
    }

    /// @notice second phase pre-sale mint for whitelisted accounts, specified price
    /// @param quantity amount an address can mint
    /// @param _merkleProof for whitelist verification
    function phaseTwoMint(uint256 quantity, bytes32[] calldata _merkleProof) public payable {
        if (phaseTwoFlag != true) revert PhaseTwoMintNotActive();

        if (msg.value < publicPrice * quantity) revert InsufficientEth();

        if (quantity + mintedTokensPhaseTwo[msg.sender] > MAX_PER_ADDRESS_PHASE_TWO) revert AmountExceedsMax();

        if (totalSupply() + quantity > MAX_TOKEN_SUPPLY) revert MintExceedsMaxSupply();

        // Merkle proof verification
        bool proofIsValid = MerkleProof.verify(
            _merkleProof,
            phaseTwoMerkleRoot,
            keccak256(abi.encodePacked(msg.sender))
        );
        if (!proofIsValid) revert MerkleProofNotValid();

        mintedTokensPhaseTwo[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    /// @notice public mint for non-whitelisted addresses
    /// @param quantity amount an address can mint
    function mint(uint256 quantity) public payable {
        if (publicFlag != true) revert PublicMintNotActive();

        if (msg.value < publicPrice * quantity) revert InsufficientEth();

        if (quantity + mintedTokens[msg.sender] > MAX_PER_ADDRESS_PUBLIC) revert MintExceedsMaxPerAddress();

        if (totalSupply() + quantity > MAX_TOKEN_SUPPLY) revert MintExceedsMaxSupply();

        mintedTokens[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    // --------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    // --------------------------------------------------------------

    function setRevealRound(REVEALROUND _phase) public onlyOwner {
        revealRound = _phase;
        emit RevealRoundSet(_phase);
    }

    function switchPhaseOneFlag(bool state) public onlyOwner {
        string memory boolString = state == true ? "true" : "false";
        require(phaseOneFlag != state, string(abi.encodePacked("Phase Status already ", boolString)));
        phaseOneFlag = state;
        emit FlagSwitched(state);
    }

    function switchPhaseTwoFlag(bool state) public onlyOwner {
        string memory boolString = state == true ? "true" : "false";
        require(phaseTwoFlag != state, string(abi.encodePacked("Phase Status already ", boolString)));
        phaseTwoFlag = state;
        emit FlagSwitched(state);
    }

    function switchPublicFlag(bool state) public onlyOwner {
        string memory boolString = state == true ? "true" : "false";
        require(publicFlag != state, string(abi.encodePacked("Phase Status already ", boolString)));
        publicFlag = state;
        emit FlagSwitched(state);
    }

    function setPublicMintPrice(uint256 _price) public onlyOwner {
        publicPrice = _price;
        emit NewPublicMintPriceSet(_price);
    }

    function setPresaleURI(string memory uri) external onlyOwner {
        presaleURI = uri;
        emit PresaleURIUpdated(uri);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    function setURIExtention(string memory _extention) public onlyOwner {
        uriExtension = _extention;
        emit TokenURIExtentionSet(_extention);
    }

    function setPhaseOneMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        phaseOneMerkleRoot = _merkleRoot;
        emit PhaseOneMerkleRootUpdated(_merkleRoot);
    }

    function setRoundOneRevealNumber(uint256 quantity) public onlyOwner {
        roundOneNum = quantity;
        emit RoundOneRevealNumberUpdated(quantity);
    }

    function setPhaseTwoMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        phaseTwoMerkleRoot = _merkleRoot;
        emit PhaseTwoMerkleRootUpdated(_merkleRoot);
    }

    function setRoyaltyRecipient(address _newRecipient) public onlyOwner {
        royaltyRecipient = _newRecipient;
        emit NewRoyaltyRecipientSet(_newRecipient);
    }

    function setRoyaltyCut(uint256 _newCut) public onlyOwner {
        if (_newCut > SCALE) revert RoyaltyCutTooHigh();
        royaltyCut = _newCut;
        emit NewRoyaltyCutSet(_newCut);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        if (!os) revert WithdrawEthFailed();
    }

    // --------------------------------------------------------------
    // VIEW FUNCTIONS
    // --------------------------------------------------------------

    function tokenURI(uint256 _tokenID) public view override returns (string memory) {
        if (_tokenID > totalSupply()) revert NftIDOutOfRange();

        if (bytes(baseURI).length == 0) {
            return presaleURI;
        } else {
            if (revealRound == REVEALROUND.ONE) {
                if (roundOneNum == 0) revert NoRoundOneRevealNumber();

                if (_tokenID <= roundOneNum) {
                    return string(abi.encodePacked(baseURI, toString(_tokenID), uriExtension));
                } else {
                    return presaleURI;
                }
            } else {
                return string(abi.encodePacked(baseURI, toString(_tokenID), uriExtension));
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

    function royaltyInfo(uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice * royaltyCut) / SCALE;
        return (royaltyRecipient, royaltyAmount);
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Stolen from OpenZeppelin lol
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}