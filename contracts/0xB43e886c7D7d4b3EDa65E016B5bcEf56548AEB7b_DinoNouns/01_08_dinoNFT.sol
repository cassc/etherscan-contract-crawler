// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;

/*************************************************************
**           _               -x-++--+-x                     **
**     _____|_|_ __   ___   __  __ ___  _  ___  __   ___    **
**    / __  | | '_ \ / _ \ /  \/ / _ \| |__|  | '_ \/ __|   **
**   / /_/ /|_|_| |_| (_) /_/\__/ (_) |\__,_|_| | | \__ \   **
**  /_____/          \___/       \___/        |_| |_|___/   **
**                                                          **
*************************************************************/   

// Project  : DinoNouns
// Buidler  : Nero One
// Note     : Interactive on-chain DinoNouns - Main NFT -

import "./LilOwnable.sol";
import "solmate/src/tokens/ERC721.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

error NoTokensLeft();
error NotEnoughETH();
error NoQuantitiesAndRecipients();
error NonExistentTokenURI();
error TooManyPerTx();
error NotDinoOwner();
error SaleNotYetStarted();

contract DinoNouns is LilOwnable, ERC721, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 420;
    uint256 public totalSupply;
    uint256 public maxPerTx = 10;
    uint256 public cost = 0 ether;
    uint256 public costDinoName = 0 ether;
    uint256 public costCustomCSS = 0 ether;

    bool public publicSale = false;

    address public dinoUtility;

    mapping(uint256 => string) public dinoName;
    mapping(uint256 => string) public customCSS;

    constructor(string memory name_, string memory symbol_)
        payable
        ERC721(name_, symbol_)
    {}

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    function setCost(uint256 _cost) external nonReentrant onlyOwner {
        cost = _cost;
    }

    function setCostDinoName(uint256 _cost) external nonReentrant onlyOwner {
        costDinoName = _cost;
    }

    function setCostCustomCSS(uint256 _cost) external nonReentrant onlyOwner {
        costCustomCSS = _cost;
    }

    function setMaxPerTx(uint256 _num) external nonReentrant onlyOwner {
        maxPerTx = _num;
    }

    function setMaxSupply(uint256 _num) external nonReentrant onlyOwner {
        maxSupply = _num;
    }

    function setDinoUtilityAddress(address _address) external onlyOwner {
        dinoUtility = _address;
    }

    function setPublicSale(bool _bool) external onlyOwner {
        publicSale = _bool;
    }

    function setDinoName(string calldata _name, uint256 _id) external payable {
        if (msg.value < costDinoName) revert NotEnoughETH();
        if (ownerOf(_id) != msg.sender) revert NotDinoOwner();

        dinoName[_id] = _name;
    }

    function setCustomCSS(string calldata _css, uint256 _id) external payable {
        if (msg.value < costCustomCSS) revert NotEnoughETH();
        if (ownerOf(_id) != msg.sender) revert NotDinoOwner();

        customCSS[_id] = _css;
    }

    function getCustomCSS(uint256 _id) external view returns (string memory) {
        return customCSS[_id];
    }

    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf(_id) == address(0)) revert NonExistentTokenURI();

        string memory _name = dinoName[_id];

        return IDinoUtility(dinoUtility).getMetadata(_name, _id);
    }

    function bulkMintDino(address addr, uint256 qty)
        external
        nonReentrant
        onlyOwner
    {
        uint256 s = totalSupply;
        if (s + qty > maxSupply) revert NoTokensLeft();
        for (uint256 j = 0; j < qty; ) {
            dinoName[s] = string(abi.encodePacked("DinoNouns-", s.toString()));
            _safeMint(addr, s++);
            totalSupply++;
            unchecked {
                ++j;
            }
        }
        delete s;
    }

    function mintDino(address addr, uint256 qty) external payable nonReentrant {
        if (!publicSale) revert SaleNotYetStarted();
        if (qty > maxPerTx) revert TooManyPerTx();
        if (msg.value < cost * qty) revert NotEnoughETH();
        uint256 s = totalSupply;
        if (s + qty > maxSupply) revert NoTokensLeft();
        for (uint256 j = 0; j < qty; ) {
            dinoName[s] = string(abi.encodePacked("DinoNouns-", s.toString()));
            _safeMint(addr, s++);
            totalSupply++;
            unchecked {
                ++j;
            }
        }
        delete s;
    }

    function bulkTransfer(uint256[] calldata _id, address[] calldata _to)
        external
    {
        if (_id.length != _to.length) revert NoQuantitiesAndRecipients();

        uint256 length = _to.length;
        for (uint256 i; i < length; ) {
            if (ownerOf(_id[i]) != msg.sender) revert NotDinoOwner();
            safeTransferFrom(msg.sender, _to[i], _id[i]);
            unchecked {
                ++i;
            }
        }
        delete length;
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(LilOwnable, ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }
}

interface IDinoUtility {
    function getMetadata(string calldata _name, uint256 _id)
        external
        view
        returns (string memory);
}