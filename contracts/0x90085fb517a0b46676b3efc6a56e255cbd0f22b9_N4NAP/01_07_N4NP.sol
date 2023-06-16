/*
𝚃𝚑𝚒𝚜 𝚒𝚜 𝚗𝚘𝚝 𝚏𝚘𝚛 𝚗𝚎𝚠𝚋𝚜 𝚊𝚗𝚍 𝚙𝚕𝚎𝚋𝚜.

𝙵𝚛𝚎𝚎 𝙼𝚒𝚗𝚝. 𝚃𝚠𝚒𝚝𝚝𝚎𝚛 𝚊𝚗𝚍 𝙲𝚘𝚗𝚝𝚛𝚊𝚌𝚝 𝙾𝚗𝚕𝚢. 𝙽𝚘 𝚆𝚎𝚋𝚜𝚒𝚝𝚎. 𝙽𝚘 𝙳𝚒𝚜𝚌𝚘𝚛𝚍. 𝙲𝙲𝙾.

𝙶𝚊𝚝𝚑𝚎𝚛 𝚢𝚘𝚞𝚛 𝚙𝚊𝚛𝚝𝚢. 𝙵𝚒𝚗𝚍 𝚝𝚑𝚎 𝚙𝚘𝚛𝚝𝚊𝚕. 

𝙽𝟺𝙽𝙰𝙿.
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract N4NAP is ERC721A, Ownable {
    using Strings for uint256;

    //three URI for three MD sets
    string private wizardURI;
    string private paladinURI;
    string private assassinURI;

    uint256 public assassinCounter;
    uint256 public paladinCounter;
    uint256 public wizardCounter;

    uint256 public constant MAX_PER_TYPE = 2222;

    bool public isPublicSaleActive;

    mapping(uint256 => uint8) public tokenType;
    mapping(uint256 => uint256) public tokenMapping;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "You must wait to recruit your team");
        _;
    }

    constructor() ERC721A("N4NAP", "N4NAP") {}

    // ---  PUBLIC MINTING FUNCTIONS ---

    // mint allows for regular minting while the supply does not exceed maxTunes.

    function mintAssassin() public publicSaleActive {
        require(assassinCounter < 2222, "all assassins have been recruited");
        require(_numberMinted(msg.sender) < 3, "your party is full");
        assassinCounter++;
        tokenType[_currentIndex] = 1;
        tokenMapping[_currentIndex] = assassinCounter;
        _mint(msg.sender, 1);
    }

    function mintPaladin() public publicSaleActive {
        require(paladinCounter < 2222, "all paladins have been recruited");
        require(_numberMinted(msg.sender) < 3, "your party is full");
        paladinCounter++;
        tokenType[_currentIndex] = 2;
        tokenMapping[_currentIndex] = paladinCounter;
        _mint(msg.sender, 1);
    }

    function mintWizard() public publicSaleActive {
        require(wizardCounter < 2222, "all wizards have been recruited");
        require(_numberMinted(msg.sender) < 3, "your party is full");
        wizardCounter++;
        tokenMapping[_currentIndex] = wizardCounter;
        _mint(msg.sender, 1);
    }

    // --- READ-ONLY FUNCTIONS ---

    // getBaseURI returns the baseURI hash for collection metadata.
    function getBaseURI(uint256 _type) external view returns (string memory) {
        if (_type == 0) return wizardURI;
        if (_type == 1) return assassinURI;
        if (_type == 2) return paladinURI;
        else revert();
    }

    // -- ADMIN FUNCTIONS --

    // setBaseURI sets the base URI for token metadata.
    function setBaseURI(uint256 _type, string memory _uri) external onlyOwner {
        if (_type == 0) assassinURI = _uri;
        else if (_type == 1) paladinURI = _uri;
        else wizardURI = _uri;
    }

    // setIsPublicSaleActive toggles the functionality of the public minting function.
    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    // withdraw allows for the withdraw of all ETH to the owner wallet.
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        if (tokenType[tokenId] == 1)
            return
                string(
                    abi.encodePacked(
                        assassinURI,
                        "/",
                        tokenMapping[tokenId].toString(),
                        ".json"
                    )
                );
        if (tokenType[tokenId] == 2)
            return
                string(
                    abi.encodePacked(
                        paladinURI,
                        "/",
                        tokenMapping[tokenId].toString(),
                        ".json"
                    )
                );
        if (tokenType[tokenId] == 0)
            return
                string(
                    abi.encodePacked(
                        wizardURI,
                        "/",
                        tokenMapping[tokenId].toString(),
                        ".json"
                    )
                );
        else revert();
    }
}