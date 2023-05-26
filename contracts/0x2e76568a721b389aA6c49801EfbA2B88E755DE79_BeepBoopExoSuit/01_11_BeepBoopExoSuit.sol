// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {Pausable} from "@oz/security/Pausable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ERC721A, IERC721A, ERC721AQueryable} from "@erc721a/extensions/ERC721AQueryable.sol";
import {IBeepBoop} from "./interfaces/IBeepBoop.sol";
import {IBattleZone} from "./interfaces/IBattleZone.sol";

contract BeepBoopExoSuit is ERC721AQueryable, Pausable, Ownable {
    /// @notice Maximum supply
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_INGAME_MINTS = 5;

    /// @notice Base URI for the NFT collection
    string private baseURI;

    /// @notice $BeepBoop
    IBeepBoop public beepBoop;

    /// @notice BattleZone contract
    IBattleZone public immutable battleZone;

    /// @notice Wallet limit
    mapping(address => uint256) addressMinted;

    /// @notice Token recipient
    address public tokenRecipient;

    /// @notice Suit Price (game)
    uint256 public gameMintPrice = 100000e18;

    /// @notice Suit Price (erc20)
    uint256 public tokenMintPrice = 10000e18;

    /// @notice Ingame mintable
    bool public gameMintable;

    constructor(
        string memory baseURI_,
        address tokenRecipient_,
        address beepBoop_,
        address battleZone_
    ) ERC721A("Beep Boop Exo Suit", "BB9000") {
        baseURI = baseURI_;
        tokenRecipient = tokenRecipient_;
        beepBoop = IBeepBoop(beepBoop_);
        battleZone = IBattleZone(battleZone_);
        _pause();
        gameMintable = false;
    }

    /**
     * @notice Purchase a suit (max 5 using in-game)
     */
    function mintIngame(uint256 quantity) public whileNotSoldOut(quantity) {
        require(gameMintable, "Game mint not open");
        require(
            addressMinted[msg.sender] + quantity <= MAX_INGAME_MINTS,
            "Hit max mint"
        );
        uint256 cost = quantity * gameMintPrice;
        addressMinted[msg.sender] += quantity;
        IBeepBoop(beepBoop).spendBeepBoop(msg.sender, cost);
        _mint(msg.sender, quantity);
    }

    /**
     * @notice Purchase a suit (no limit)
     */
    function mint(uint256 quantity)
        public
        whenNotPaused
        whileNotSoldOut(quantity)
    {
        uint256 cost = quantity * tokenMintPrice;
        IERC20(address(beepBoop)).transferFrom(msg.sender, tokenRecipient, cost);
        _mint(msg.sender, quantity);
    }

    modifier whileNotSoldOut(uint256 quantity) {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Hit max supply");
        _;
    }

    /**
     * @notice Admin mint specific address
     * @param recipient Receiver of the pass
     * @param quantity Quantity to mint
     */
    function adminMint(address recipient, uint256 quantity) public onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Hit Max Supply");
        _mint(recipient, quantity);
    }

    /**
     * @notice Set the base URI of the token
     * @param baseURI_ The base URI of the collection
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Return the base uri of the ERC721
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    /**
     * @notice Pre-approve the battlezone contract to save users fees
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (bool)
    {
        if (operator == address(battleZone)) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Change the suit contract
     */
    function changeBeepBoopContract(address contract_) public onlyOwner {
        beepBoop = IBeepBoop(contract_);
    }

    /**
     * @notice Modify suit price
     */
    function setTokenMintPrice(uint256 price) public onlyOwner {
        tokenMintPrice = price;
    }

    /**
     * @notice Modify suit price
     */
    function setGameMintPrice(uint256 price) public onlyOwner {
        gameMintPrice = price;
    }

    /**
     * @notice Set token recipient
     */
    function setTokenRecipient(address address_) public onlyOwner {
        tokenRecipient = address_;
    }

    /**
     * @notice Toggle the sale
     */
    function toggleSale() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @notice Toggle game sale
     */
    function toggleGameMintable() public onlyOwner {
        gameMintable = !gameMintable;
    }
}