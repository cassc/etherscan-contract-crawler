// SPDX-License-Identifier: MIT

/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@&#BG5G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@&BG555GYB#P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@#[email protected]&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@&B5YPBG5BB&#[email protected]@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G!?JYBGY5P55GGPPGGPPGYBG#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@P~5PYY555PPPPP5YBYY#@GBB&&5#&#BB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G!YJY55YY5YPYY#PBP5#&555##GGBPPJ5#@@@@#&#B&G#########&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G7JYJY55YYJGP5BYYGGGGPGPGGGGGGG55YB###B##BBB&&&##@@@#PGB&&###&&&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G7?J5Y55P5JYPPPPPGGGGGPGBBBB#BBP5BG#####B###BB##P&@@&GGP&@@@&YG####&@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@?!JYY5YYPPPPGGGPG#BBGBB#BGY?J5#G55###&BGB&#B##[email protected]###@@P#####GG#@BBG##&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@Y?JYJ55PPGPBBG5GBPP7^J#PY!:.:5#G#5G5J5#B#Y!~7P#BG##&#@&G#G5G#@BG&[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G?Y555PPP5GP5J^PP5J..5#G5^.::G#B&&7.^~Y#Y!J?^^[email protected]#&[email protected]&###GB#BGPP&@@@@@@@@@@@@@
@@@@@@@@@@@@@&JJJYYY5Y57P5P7:BBPJ..YBG5^::^PPP#&P~GB5GY&@@G^P#B&Y#!.!PB^?GB5G#G#&##BGY&@@@@@@@@@@@@@
@@@@@@@@@@@@@#7?JY55PPP75PP?~55P5JY55PBGGBBPPP#####BGGYPGBPPPBB&B#7^7GB.!G5^YP!555PPG5#@@@@@@@@@@@@@
@@@@@@@@@@@@@@[email protected]@@G&@@@@@@@&P#:!BP:5G7PY55YJ7#@@@@@@@@@@@@@
@@@@@@@@@@@@@@J?JY5G5PGGPPGGGGPGGGBGGGBBBB#BGG####B#GGP5###G#&#&&&&&#P#GBBBPGB5GPPP557#@@@@@@@@@@@@@
@@@@@@@@@@@@@#?5PPPPPPPGPGBGGGG#BPPBB##G5JPBB&&PJ?JGB#B5GGB&#G##GB&BPP###B###B#[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@YJYY55P55YGPPJ~GB5Y^:J#G57..^Y#BY:...!5#PJ::^?BBP^:^5BBG&7J##?G#[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@5JYY5YP557P55~:GG5J.:Y#P5^:::G#BJ:::.~B#B#?.::Y#J.:.?GBGG.!BP:[email protected]@@@@@@@@@@@@
@@@@@@@@&&&&&&YJY55PGPP7PPP!:BBPJ::5#GP~:::B#BJ:::.~##B&@!.:5#Y.::JGB#P.!BP:5G7PY555YJB&&&&&@@@@@@@@
@@@@@@@@&&&&&&BPPP5P55P?55P!:GGPJ..Y#GP^..:B#BJ....~##B&@#~:5#J...?GGB#!?GP?PG5GGBBB##&&&&&@@@@@@@@@
@@@@@@@@@@@@&&&&&&&&####BBBBGGGGPYYPPPPJ???PPPY777!?GPGB##PJPGP555GBBBB####&&&&&&&&&&&&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&####&&&#################&###&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@ */

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";
import "./IERC721A.sol";

contract ColiseumVested is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    // Custom errors
    error NotAController();
    error NoContracts();
    error AlreadyMinted();
    error InvalidAmount();
    error NotQualified();
    error WouldExceedMax();
    error NotActive();

    // State variables
    string private _baseTokenURI =
        "https://nftstorage.link/ipfs/bafybeicksu2nga5i2kwuc5wu2ovbsouwsaisgdyp2rhtrkfu7augoen76y/";

    bool public lockActive = true;
    bool public mintActive = true;

    uint256 public price = 0.5 ether;
    uint256 public maxVestedSupply = 60;

    bytes32 private qualifiedMerkleRoot;

    // Mappings
    mapping(address => bool) private _controller;

    // Constructor
    constructor() ERC721A("Coliseum Vested Tokens", "Coliseum Vested") {
        _mint(msg.sender, 1);
    }

    // Modifiers
    modifier onlyController() {
        if (_controller[msg.sender] == false) revert NotAController();
        _;
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    // Functions

    /**
     * @dev Set the maximum vested supply.
     * @param _maxVestedSupply The new maximum vested supply.
     */
    function setVestedSupply(uint256 _maxVestedSupply) external onlyOwner {
        maxVestedSupply = _maxVestedSupply;
    }

    /**
     * @dev Set the qualified Merkle root.
     * @param _qualifiedMerkleRoot The new qualified Merkle root.
     */
    function setQualifiedMerkleRoot(
        bytes32 _qualifiedMerkleRoot
    ) external onlyOwner {
        qualifiedMerkleRoot = _qualifiedMerkleRoot;
    }

    /**
     * @dev Check if a user is valid according to the Merkle root.
     * @param _user The user address to check.
     * @param _proof The proof required to validate the user.
     * @return bool True if the user is valid, false otherwise.
     */
    function isValid(
        address _user,
        bytes32[] calldata _proof
    ) external view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                qualifiedMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    /**
     * @dev Set the price for minting.
     * @param _price The new price.
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @dev Toggle the mint on or off.
     */
    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    /**
     * @dev Mint a token, only if the caller is qualified. Token is vested and can not be transferred by holder.
     * @param _proof The proof required to validate the user.
     */
    function mint(bytes32[] calldata _proof) external payable callerIsUser {
        if (!mintActive) revert NotActive();
        if (msg.value != price) revert InvalidAmount();
        if (
            !MerkleProof.verify(
                _proof,
                qualifiedMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotQualified();
        if (totalSupply() + 1 > maxVestedSupply) revert WouldExceedMax();
        if (_numberMinted(msg.sender) + 1 > 1) revert AlreadyMinted();

        _mint(msg.sender, 1);
    }

    /**
     * @dev Mints tokens and assigns them to multiple addresses in one function call.
     * @param targets An array of addresses to receive the minted tokens.
     */
    function airDrop(address[] calldata targets) external {
        require(
            (_controller[msg.sender] == true) || (owner() == _msgSender()),
            "Caller is not authorized"
        );
        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], 1);
        }
    }

    /**
     * @notice Allows the controller to transfer a token on behalf of the owner
     * @dev This function can only be called by the controller
     * @param from The address of the current owner of the token
     * @param to The address to receive the token
     * @param tokenId The ID of the token to be transferred
     */
    function controllerTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external onlyController {
        require(to != address(0), "Invalid recipient address");

        safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Burns multiple tokens at once.
     * @param tokenIds An array of token IDs to burn.
     */
    function burn(uint256[] calldata tokenIds) external onlyController {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    /**
     * @dev Returns the base URI for a given token.
     * @return The base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets the base URI for the token metadata.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Toggles the lock state of Soulbound tokens.
     */
    function toggleLock() external onlyOwner {
        lockActive = !lockActive;
    }

    /**
     * @dev Adds multiple addresses as controllers in the contract.
     * @param _addresses An array of addresses to be added as controllers.
     */
    function addControllers(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _controller[_addresses[i]] = true;
        }
    }

    /**
     * @dev Removes multiple addresses from being controllers in the contract.
     * @param _addresses An array of addresses to be removed as controllers.
     */
    function removeControllers(
        address[] calldata _addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _controller[_addresses[i]] = false;
        }
    }

    /**
     * @dev Checks if a given address is a controller.
     * @param _address The address to be checked.
     * @return bool True if the address is a controller, false otherwise.
     */
    function isController(address _address) external view returns (bool) {
        return _controller[_address];
    }

    /**
     * @dev Withdraw the balance of the contract to the owner.
     * Can only be called by the owner and is protected by the nonReentrant modifier.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Hooks into the token transfer process and enforces restrictions.
     * @param from The address sending the tokens.
     * @param to The address receiving the tokens.
     * @param startTokenId The ID of the first token being transferred.
     * @param quantity The number of tokens being transferred.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!lockActive || _controller[msg.sender], "Transfers are locked");
    }
}