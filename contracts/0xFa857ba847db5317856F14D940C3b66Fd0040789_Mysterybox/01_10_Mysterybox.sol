// SPDX-License-Identifier: MIT
// Creator: Serozense

pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

//                     ▄▄████
//                 ▄▄█▀▀ ▄██▀
//              ▄██▀    ▄██▀                                     ▄
//           ▄██▀      ███                                   ▄▄███▌
//         ▄█▀        ███                              ▄   ▄█▀ ███
//        ▀█▄▄▄     ▄███         ▄▄       ▄▄  ▄▄▄▄▄▄▄ ▐█ ▄█▀  ███
//                 ▄██▀ ▄▄▀▀▀▀▀▀███▀▀▀▀▀▀███▀▀        ██ ▀   ▐██    ▄
//                ███▌▄▄▄▄█▀▀   ██       ██          ██ ▄▄   ██▌ ▄▄▄█▀
//               ████▌     ▄██ ▐█▌  ▄▄█ ▐█▌▄███▌ ██ ▄██▐█▌  ████▀
//             ▄██▀███  ▀█▀▀██ ▐█ ▄█▀██ ██ ██▄█▌██████ ██  ▐████▄      ▄▄▄▄
//            ▄██▀  ███ ▀ ▀███ ██▄▀████ █▌ ▀▀▀▀ ▀  ▀▀▀ █   ██  ███         ▀▀█▄
//           ███     ▀██▄      █▌   ▀▀  █   ▄▄▄▄▄▀▀▀▀▀    ██    ▀██▄           ▀█▄
//          ███        ▀██▄             ▀                 █▌      ▀██▄          ▐██
//         ██▀            ▀██▄▄▄▀                                    ▀██▄       ██▀
//        ██                              MYSTERY BOX                    ▀▀███▀▀▀


    error SoldOut();
    error CannotSetZeroAddress();

contract Mysterybox is ERC721A, ERC2981, Ownable {

    using Address for address;

    uint256 public collectionSize = 2500;
    string public baseURI;
    string public preRevealBaseURI;

    // Sets Treasury Address for withdraw() and ERC2981 royaltyInfo
    address public treasuryAddress;

    constructor(
        address defaultTreasury,
        uint256 toTreasury,
        string memory defaultPreRevealBaseURI
    ) ERC721A("Kreators Box", "BOXES") {
        setTreasuryAddress(payable(defaultTreasury));
        setRoyaltyInfo(500);
        setPreRevealBaseURI(defaultPreRevealBaseURI);
        _mintERC2309(msg.sender, toTreasury);
    }

    function airdrop(address to, uint256 quantity) external onlyOwner {
        if(totalSupply() + quantity > collectionSize) revert SoldOut();
        _mint(to, quantity);
    }

    // OWNER FUNCTIONS ---------
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @dev Just in case there is a bug and we need to update the uri
     */
    function setPreRevealBaseURI(string memory newBaseURI) public onlyOwner {
        preRevealBaseURI = newBaseURI;
    }

    /**
     * @dev Update the royalty percentage (500 = 5%)
     */
    function setRoyaltyInfo(uint96 newRoyaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
    }

    /**
     * @dev Update the royalty wallet address
     */
    function setTreasuryAddress(address payable newAddress) public onlyOwner {
        if (newAddress == address(0)) revert CannotSetZeroAddress();
        treasuryAddress = newAddress;
    }

    /**
     * @dev Withdraw funds to treasuryAddress
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    // OVERRIDES ---------

    /**
     * @dev Change starting tokenId to 1 (from erc721A)
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Variation of {ERC721Metadata-tokenURI}.
     * Returns different token uri depending on blessed or possessed.
     */
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenID), ".json")) : string(abi.encodePacked(preRevealBaseURI, _toString(tokenID), ".json"));
    }

    /**
     * @dev {ERC165-supportsInterface} Adding IERC2981
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, ERC2981)
    returns (bool)
    {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
        interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981.
        super.supportsInterface(interfaceId);
    }

}