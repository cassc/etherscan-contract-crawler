// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//   ██████  ▄████▄   ▄▄▄       ███▄    █ ▓█████▄  ██▓ ███▄    █  ▄▄▄    ██▒   █▓ ██▓ ▄▄▄       ███▄    █
// ▒██    ▒ ▒██▀ ▀█  ▒████▄     ██ ▀█   █ ▒██▀ ██▌▓██▒ ██ ▀█   █ ▒████▄ ▓██░   █▒▓██▒▒████▄     ██ ▀█   █
// ░ ▓██▄   ▒▓█    ▄ ▒██  ▀█▄  ▓██  ▀█ ██▒░██   █▌▒██▒▓██  ▀█ ██▒▒██  ▀█▄▓██  █▒░▒██▒▒██  ▀█▄  ▓██  ▀█ ██▒
//   ▒   ██▒▒▓▓▄ ▄██▒░██▄▄▄▄██ ▓██▒  ▐▌██▒░▓█▄   ▌░██░▓██▒  ▐▌██▒░██▄▄▄▄██▒██ █░░░██░░██▄▄▄▄██ ▓██▒  ▐▌██▒
// ▒██████▒▒▒ ▓███▀ ░ ▓█   ▓██▒▒██░   ▓██░░▒████▓ ░██░▒██░   ▓██░ ▓█   ▓██▒▒▀█░  ░██░ ▓█   ▓██▒▒██░   ▓██░
// ▒ ▒▓▒ ▒ ░░ ░▒ ▒  ░ ▒▒   ▓▒█░░ ▒░   ▒ ▒  ▒▒▓  ▒ ░▓  ░ ▒░   ▒ ▒  ▒▒   ▓▒█░░ ▐░  ░▓   ▒▒   ▓▒█░░ ▒░   ▒ ▒
// ░ ░▒  ░ ░  ░  ▒     ▒   ▒▒ ░░ ░░   ░ ▒░ ░ ▒  ▒  ▒ ░░ ░░   ░ ▒░  ▒   ▒▒ ░░ ░░   ▒ ░  ▒   ▒▒ ░░ ░░   ░ ▒░
// ░  ░  ░  ░          ░   ▒      ░   ░ ░  ░ ░  ░  ▒ ░   ░   ░ ░   ░   ▒     ░░   ▒ ░  ░   ▒      ░   ░ ░
//       ░  ░ ░            ░  ░         ░    ░     ░           ░       ░  ░   ░   ░        ░  ░         ░
//          ░                              ░                                 ░
// ▄▄▄█████▓ ██▀███   ▄▄▄       ██▓ ██▓    ▓█████  ██▀███     ▄▄▄█████▓ ██▀███   ▄▄▄        ██████  ██░ ██
// ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄    ▓██▒▓██▒    ▓█   ▀ ▓██ ▒ ██▒   ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄    ▒██    ▒ ▓██░ ██▒
// ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄  ▒██▒▒██░    ▒███   ▓██ ░▄█ ▒   ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄  ░ ▓██▄   ▒██▀▀██░
// ░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██ ░██░▒██░    ▒▓█  ▄ ▒██▀▀█▄     ░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██   ▒   ██▒░▓█ ░██
//   ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒░██░░██████▒░▒████▒░██▓ ▒██▒     ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒▒██████▒▒░▓█▒░██▓
//   ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▓  ░ ▒░▓  ░░░ ▒░ ░░ ▒▓ ░▒▓░     ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒
//     ░      ░▒ ░ ▒░  ▒   ▒▒ ░ ▒ ░░ ░ ▒  ░ ░ ░  ░  ░▒ ░ ▒░       ░      ░▒ ░ ▒░  ▒   ▒▒ ░░ ░▒  ░ ░ ▒ ░▒░ ░
//   ░        ░░   ░   ░   ▒    ▒ ░  ░ ░      ░     ░░   ░      ░        ░░   ░   ░   ▒   ░  ░  ░   ░  ░░ ░
//             ░           ░  ░ ░      ░  ░   ░  ░   ░                    ░           ░  ░      ░   ░  ░  ░

// =============================================================
//                       ERRORS
// =============================================================

/// When public spawning has not yet started
error SpawningIsPaused();

/// Zero NFTs spawn. Wallet can spawn at least one NFT.
error ZeroTokensSpawn();

/// For price check. msg.value should be greater than or equal to spawn price
error LowPrice();

/// Max supply limit exceed error
error TrashExceeded();

/// Whitelist and public spawn limit exceed error
error SpawnLimitExceeded();

/// Reserved limit exceed error
error ReservedTrashExceeded();

// =============================================================
//       Scandinavian Trailer Trash ERC721A Contract
// =============================================================

contract ScandinavianTrailerTrash is ERC721A, Ownable, IERC2981 {
    using Strings for uint256;

    uint16 public constant maxTrashSupply = 10000; //  _publicTrashSupply + reserveTrash = maxTrashSupply
    uint16 private constant _publicTrashSupply = 9488; // tokens avaiable for public to spawn
    uint16 public reserveTrash = 512; // tokens reserve for the owner
    uint16 private _totalPublicTrash; // number of tokens spawn from public supply
    uint16 private _trashTax = 690; // royalties 6.9% in bps

    // public spwan price
    uint256 public spawnPrice = 0.004 ether; // spawn price per token
    uint16 public spawnLimit = 10; // tokens per address are allowd to spawn.
    uint16 public freeSpawnLimit = 1; // free tokens per address
    bool public isSpawning;

    address public trashTaxCollector; // EOA for as royalties receiver for collection
    string public baseURI; // token base uri

    mapping(address => uint16) public freeSpawnOf; // to check if wallet has spawn free NFTs

    // =============================================================
    //                       MODIFIERS
    // =============================================================

    modifier spawnRequirements(uint16 volume) {
        if (!isSpawning) revert SpawningIsPaused();
        if (volume == 0) revert ZeroTokensSpawn();

        uint16 freeSpawnOf_ = freeSpawnLimit - freeSpawnOf[_msgSender()];

        freeSpawnOf[_msgSender()] += freeSpawnOf_;

        if (msg.value < (spawnPrice * (volume - freeSpawnOf_)))
            revert LowPrice();

        uint256 totalSpawns = balanceOf(_msgSender()) + volume;
        if (totalSpawns > spawnLimit) revert SpawnLimitExceeded();

        _;
    }

    // =============================================================
    //                       FUNCTIONS
    // =============================================================

    /**
     * @dev  It will spawn from tokens allocated for public
     * @param volume is the quantity of tokens to be spawn
     */
    function spawn(uint16 volume) external payable spawnRequirements(volume) {
        _maxSupplyCheck(volume);
        _safeMint(_msgSender(), volume);
    }

    /**
     * @dev spawn function only callable by the Contract owner. It will spawn from reserve tokens for owner
     * @param to is the address to which the tokens will be spawn
     * @param volume is the quantity of tokens to be spawn
     */
    function spawnFromReserve(address to, uint16 volume) external onlyOwner {
        if (volume > reserveTrash) revert ReservedTrashExceeded();
        reserveTrash -= volume;
        _safeMint(to, volume);
    }

    /**
     * @dev private function to compute max supply limit
     */
    function _maxSupplyCheck(uint16 volume) private {
        uint16 totalTrash = _totalPublicTrash + volume;
        if (totalTrash > _publicTrashSupply) revert TrashExceeded();
        _totalPublicTrash = totalTrash;
    }

    // =============================================================
    //                      ADMIN FUNCTIONS
    // =============================================================

    /**
     * @dev it is only callable by Contract owner. it will toggle spawn status
     */
    function toggleSpawningStatus() external onlyOwner {
        isSpawning = !isSpawning;
    }

    /**
     * @dev it will update spawn price
     * @param _spawnPrice is new value for spawn
     */
    function setSpawnPrice(uint256 _spawnPrice) external onlyOwner {
        spawnPrice = _spawnPrice;
    }

    /**
     * @dev it will update the spawn limit aka amount of nfts a wallet can hold
     * @param _spawnLimit is new value for the limit
     */
    function setSpawnLimit(uint16 _spawnLimit) external onlyOwner {
        spawnLimit = _spawnLimit;
    }

    /**
     * @dev it will update the spawn limit aka amount of nfts a wallet can hold
     * @param _spawnLimit is new value for the limit
     */
    function setFreeSpawnLimit(uint16 _spawnLimit) external onlyOwner {
        freeSpawnLimit = _spawnLimit;
    }

    /**
     * @dev it will update baseURI for tokens
     * @param _uri is new URI for tokens
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev it will update the address for royalties receiver
     * @param _trashTaxCollector is new royalty receiver
     */
    function setTrashTaxReceiver(
        address _trashTaxCollector
    ) external onlyOwner {
        require(_trashTaxCollector != address(0));
        trashTaxCollector = _trashTaxCollector;
    }

    /**
     * @dev it will update the royalties for token
     * @param trashTax_ is new percentage of royalties. it should be  in bps (1% = 1 *100 = 100). 6.9% => 6.9 * 100 = 690
     */
    function setTrashTax(uint16 trashTax_) external onlyOwner {
        require(trashTax_ > 0, "should be > 0");
        _trashTax = trashTax_;
    }

    /**
     * @dev it is only callable by Contract owner. it will withdraw balace of contract
     */
    function withdraw() external onlyOwner {
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "Transfer failed!");
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev it will return tokenURI for given tokenIdToOwner
     * @param _tokenId is valid token id mint in this contract
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     *  @dev it retruns the amount of royalty the owner will receive for given tokenId
     *  @param _tokenId is valid token number
     *  @param _salePrice is amount for which token will be traded
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        require(
            _exists(_tokenId),
            "ERC2981RoyaltyStandard: Royalty info for nonexistent token"
        );
        return (trashTaxCollector, (_salePrice * _trashTax) / 10000);
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // =============================================================
    //                      CONSTRUCTOR
    // =============================================================

    constructor(string memory _uri) ERC721A("Scandinaviantt", "Trash") {
        baseURI = _uri;
        trashTaxCollector = msg.sender;
    }
}