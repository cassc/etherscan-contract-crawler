// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {Pausable} from "@oz/security/Pausable.sol";
import {ERC721A, IERC721A, ERC721AQueryable} from "@erc721a/extensions/ERC721AQueryable.sol";
import {IBeepBoop} from "./interfaces/IBeepBoop.sol";
import {IBattleZone} from "./interfaces/IBattleZone.sol";

contract BeepBoopToolbox is ERC721AQueryable, Pausable, Ownable {
    /// @notice Maximum supply of the mint passes
    uint256 public constant MAX_SUPPLY = 30000;

    /// @notice Base URI for the NFT collection
    string private baseURI;

    /// @notice $BeepBoop
    IBeepBoop public beepBoop;

    /// @notice BattleZone contract
    IBattleZone public immutable battleZone;

    /// @notice Toolbox Price
    uint256 public mintPrice = 4000e18;

    constructor(
        string memory baseURI_,
        address beepBoop_,
        address battleZone_
    ) ERC721A("Beep Boop Toolbox", "BBT") {
        baseURI = baseURI_;
        beepBoop = IBeepBoop(beepBoop_);
        battleZone = IBattleZone(battleZone_);
        _pause();
    }

    /**
     * @notice Purchase a toolbox
     */
    function mint(uint256 quantity) public whenNotPaused {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Hit Max Supply");
        uint256 cost = quantity * mintPrice;
        IBeepBoop(beepBoop).spendBeepBoop(msg.sender, cost);
        _mint(msg.sender, quantity);
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
     * @notice Change the toolbox contract
     */
    function changeBeepBoopContract(address contract_) public onlyOwner {
        beepBoop = IBeepBoop(contract_);
    }

    /**
     * @notice Modify toolbox price
     */
    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
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
}