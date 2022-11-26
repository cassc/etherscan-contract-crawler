// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./AllowedAddresses.sol";

pragma solidity ^0.8.7;

error VerdomiGenerals__NotEnoughMinted();
error VerdomiGenerals__ExceedsMaxSupply();
error VerdomiGenerals__MaxStage();
error VerdomiGenerals__BaseUriIsFrozen();
error VerdomiGenerals__NotAtMaxStage();
error VerdomiGenerals__AllNotRevealed();

contract VerdomiGenerals is ERC721A, AllowedAddresses {
    string constant NAME = "Verdomi Generals";
    string constant SYMBOL = "VGEN";

    uint256 private s_stage = 1;
    string private s_baseUri = "";
    string private s_unrevealedUri = "";
    bool private isUriFrozen = false;
    uint256 private s_revealedUntil = 0;

    constructor() ERC721A(NAME, SYMBOL) {}

    // =============================================================
    //                       FUNCTIONS
    // =============================================================

    function mintGeneral(address to, uint256 quantity) public onlyAllowedAddresses {
        if (_nextTokenId() + quantity > maxSupply()) {
            revert VerdomiGenerals__ExceedsMaxSupply();
        }
        _mint(to, quantity);
    }

    function nextStage() external onlyOwner {
        if (s_stage < 5) {
            unchecked {
                ++s_stage;
            }
        } else {
            revert VerdomiGenerals__MaxStage();
        }
    }

    function setBaseURI(string memory uri, uint256 reavealedUntil) external onlyOwner {
        if (isUriFrozen) {
            revert VerdomiGenerals__BaseUriIsFrozen();
        }
        s_revealedUntil = reavealedUntil;
        s_baseUri = uri;
    }

    function setUnrevealedURI(string memory uri) external onlyOwner {
        s_unrevealedUri = uri;
    }

    function freezeBaseURI() external onlyOwner {
        if (s_stage < 5) {
            revert VerdomiGenerals__NotAtMaxStage();
        }
        if (s_revealedUntil < maxSupply()) {
            revert VerdomiGenerals__AllNotRevealed();
        }
        isUriFrozen = true;
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        // If token is not revealed yet.
        if (tokenId > s_revealedUntil) {
            return s_unrevealedUri;

            // If it is revealed
        } else {
            string memory baseURI = _baseURI();

            return
                bytes(baseURI).length != 0
                    ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                    : "";
        }
    }

    function maxSupply() public view returns (uint256) {
        return s_stage * 2000;
    }

    function _baseURI() internal view override returns (string memory) {
        return s_baseUri;
    }

    function unrevealedURI() external view returns (string memory) {
        return s_unrevealedUri;
    }

    function revealedUntil() external view returns (uint256) {
        return s_revealedUntil;
    }

    function uriFrozen() public view returns (bool) {
        return isUriFrozen;
    }
}