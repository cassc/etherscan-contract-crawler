// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {Pausable} from "@oz/security/Pausable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ERC721A, IERC721A, ERC721AQueryable} from "@erc721a/extensions/ERC721AQueryable.sol";
import {DefaultOperatorFilterer} from "@os/DefaultOperatorFilterer.sol";
import {Address} from "@oz/utils/Address.sol";

import {IBeepBoop} from "./interfaces/IBeepBoop.sol";
import {IBattleZone} from "./interfaces/IBattleZone.sol";
import {IBeepBoopExtensionCord} from "./interfaces/IBeepBoopExtensionCord.sol";

contract BeepBoopChargerS2 is
    ERC721AQueryable,
    DefaultOperatorFilterer,
    Pausable,
    Ownable
{
    /// @notice Maximum supply
    uint256 public maxSupply = 10000;

    /// @notice Base URI for the NFT collection
    string private baseURI;

    /// @notice $BeepBoop
    IBeepBoop public beepBoop;

    /// @notice BattleZone contract
    IBattleZone public battleZone;

    /// @notice Mint price
    uint256 public mintPrice;

    /// @notice Game mint price
    uint256 public gameMintPrice = 500000e18;

    /// @notice Pause transfers
    bool public pauseTransfers;

    /// @notice Extension Cord
    IBeepBoopExtensionCord public immutable extensionCord;

    constructor(
        string memory baseURI_,
        address battleZone_,
        address beepBoop_,
        address extensionCord_
    ) ERC721A("Beep Boop Charger Season 2", "BBCS2") {
        baseURI = baseURI_;
        battleZone = IBattleZone(battleZone_);
        extensionCord = IBeepBoopExtensionCord(extensionCord_);
        beepBoop = IBeepBoop(beepBoop_);
        _pause();
    }

    /**
     * @notice Purchase a charger
     */
    function mint(uint256 quantity)
        public
        payable
        whenNotPaused
        whileNotSoldOut(quantity)
    {
        require(mintPrice != 0, "Not available");
        require(msg.value >= mintPrice * quantity, "Not enough ETH");
        _mint(msg.sender, quantity);
    }

    modifier whileNotSoldOut(uint256 quantity) {
        require(_totalMinted() + quantity <= maxSupply, "Hit max supply");
        _;
    }

    /**
     * @notice Claim chargers
     */
    function claim(uint256[] memory tokenIds) public whenNotPaused {
        uint256 numTokens = tokenIds.length;
        for (uint256 i; i < numTokens; ++i) {
            require(
                extensionCord.ownerOf(tokenIds[i]) == msg.sender,
                "Extension Cord Non-Owner"
            );
        }
        IBeepBoop(beepBoop).spendBeepBoop(
            msg.sender,
            numTokens * gameMintPrice
        );
        extensionCord.burnMany(tokenIds);
        _mint(msg.sender, numTokens);
    }

    /**
     * @notice Contract withdrawal
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(
            payable(0xEE547a830A9a54653de3D40A67bd2BC050DAeD81),
            (balance * 80) / 100
        );
        Address.sendValue(
            payable(0x2b6b97A1ec523e3F97FB749D5a6a8173B589834A),
            (balance * 20) / 100
        );
    }

    /**
     * @notice Admin mint specific address
     * @param recipient Receiver of the pass
     * @param quantity Quantity to mint
     */
    function adminMint(address recipient, uint256 quantity)
        public
        whileNotSoldOut(quantity)
        onlyOwner
    {
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
        if (pauseTransfers) {
            revert("Unapproved");
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
     * @notice Modify price
     */
    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    /**
     * @notice Modify game price
     */
    function setGameMintPrice(uint256 price) public onlyOwner {
        gameMintPrice = price;
    }

    /**
     * @notice Modify max supply
     */
    function setMaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
    }

    /**
     * @notice Change battlezone contract
     */
    function changeBattleZoneContract(address battleZone_) public onlyOwner {
        battleZone = IBattleZone(battleZone_);
    }

    /**
     * @notice Modify transferability
     */
    function toggleTransfers() public onlyOwner {
        pauseTransfers = !pauseTransfers;
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
     * @notice See {IERC721A}.transferFrom
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice See {IERC721A}.safeTransferFrom
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice See {IERC721A}.safeTransferFrom
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Prevent transfer
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        if (
            to != address(0) &&
            from != address(0) &&
            to != address(battleZone) &&
            from != address(battleZone) &&
            pauseTransfers
        ) {
            revert("Untransferable");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev Allow contract to receive ether
    receive() external payable {}
}