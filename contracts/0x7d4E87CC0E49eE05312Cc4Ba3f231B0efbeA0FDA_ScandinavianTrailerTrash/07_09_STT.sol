// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
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

contract ScandinavianTrailerTrash is ERC721A, Ownable, IERC2981 {
    using Strings for uint256;

    uint16 public constant maxTrashSupply = 10000;
    uint16 public reserveTrash = 512; // tokens reserve for the owner

    uint16 private _totalTrashSupplyPublic; // number of tokens minted from public supply
    uint16 private publicTrashSupply = maxTrashSupply - reserveTrash; // tokens avaiable for public to mint
    uint16 private trashTax = 690; // royalties 6.9% in bps

    uint256 public spawnPrice = 0.069 ether; // mint price per token
    uint16 public spawnLimit = 1; // initially, only 1 tokens per address are allowd to mint.
    address public trashTaxCollector; // EOA for as royalties receiver for collection

    bool public isSpawning;
    string public baseURI;

    /***************************************************/
    /******************** MODIFIERS ********************/
    /***************************************************/

    modifier spawnRequirements(uint16 volume) {
        require(volume > 0, "Tokens gt 0");

        require(msg.value >= (spawnPrice * volume), "Low price!");

        uint16 newTotalTrashSupplyPublic = _totalTrashSupplyPublic + volume;
        require(
            newTotalTrashSupplyPublic <= publicTrashSupply,
            "Max supply exceeded!"
        );

        uint256 _newBalanceOf = balanceOf(_msgSender()) + volume;
        require(_newBalanceOf <= spawnLimit, "Spawn limit exceeded!");

        _totalTrashSupplyPublic = newTotalTrashSupplyPublic;
        _;
    }

    /**
     * @dev  It will mint from tokens allocated for public
     * @param volume is the quantity of tokens to be minted
     */
    function spawn(uint16 volume) external payable spawnRequirements(volume) {
        require(isSpawning, "Spawning has not yet started!");
        __mint(_msgSender(), volume);
    }

    /**
     * @dev mint function only callable by the Contract owner. It will mint from reserve tokens for owner
     * @param to is the address to which the tokens will be minted
     * @param volume is the quantity of tokens to be minted
     */
    function spawnFromReserve(address to, uint16 volume) external onlyOwner {
        require(volume <= reserveTrash, "Trash reserve exceeded!");

        reserveTrash -= volume;
        __mint(to, volume);
    }

    /**
     * @dev private function to mint given amount of tokens
     * @param to is the address to which the tokens will be minted
     * @param volume is the quantity of tokens to be minted
     */
    function __mint(address to, uint16 volume) private {
        _safeMint(to, volume);
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*********************************************************/
    /******************** ADMIN FUNCTIONS ********************/
    /*********************************************************/

    /**
     * @dev it is only callable by Contract owner. it will toggle public minting status
     */
    function toggleSpawningStatus() external onlyOwner {
        isSpawning = !isSpawning;
    }

    /**
     * @dev it will update mint price
     * @param _spawnPrice is new value for mint
     */
    function setSpawnPrice(uint256 _spawnPrice) external onlyOwner {
        spawnPrice = _spawnPrice;
    }

    /**
     * @dev it will update the mint limit aka amount of nfts a wallet can hold
     * @param _spawnLimit is new value for the limit
     */
    function setSpawnLimit(uint16 _spawnLimit) external onlyOwner {
        spawnLimit = _spawnLimit;
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
    function setTrashTaxReceiver(address _trashTaxCollector)
        external
        onlyOwner
    {
        require(_trashTaxCollector != address(0));
        trashTaxCollector = _trashTaxCollector;
    }

    /**
     * @dev it will update the royalties for token
     * @param _trashTax is new percentage of royalties. it should be more than 0 and least 90
     */
    function setTrashTax(uint16 _trashTax) external onlyOwner {
        require(_trashTax > 0, "should be > 0");

        trashTax = (_trashTax * 100); // convert percentage into bps
    }

    /**
     * @dev it is only callable by Contract owner. it will withdraw balace of contract
     */
    function withdraw() external onlyOwner {
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "Transfer failed!");
    }

    /********************************************************/
    /******************** VIEW FUNCTIONS ********************/
    /********************************************************/

    /**
     * @dev it will return tokenURI for given tokenIdToOwner
     * @param _tokenId is valid token id mint in this contract
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
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
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     *  @dev it retruns the amount of royalty the owner will receive for given tokenId
     *  @param _tokenId is valid token number
     *  @param _salePrice is amount for which token will be traded
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(
            _exists(_tokenId),
            "ERC2981RoyaltyStandard: Royalty info for nonexistent token"
        );
        return (trashTaxCollector, (_salePrice * trashTax) / 10000);
    }

    constructor(string memory _uri)
        ERC721A("Scandinavian Trailer Trash", "Trash")
    {
        baseURI = _uri;
        trashTaxCollector = msg.sender;
    }
}