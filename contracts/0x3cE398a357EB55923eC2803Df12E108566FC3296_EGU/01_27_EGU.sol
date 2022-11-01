// SPDX-License-Identifier: MIT
// ,------.                       ,--.  ,--.                     ,----.             ,--.
// |  .---' ,---.,--. ,--.,---. ,-'  '-.`--' ,--,--.,--,--,     '  .-./    ,---.  ,-|  |,-----.
// |  `--, | .-. |\  '  /| .-. |'-.  .-',--.' ,-.  ||      \    |  | .---.| .-. |' .-. |`-.  /
// |  `---.' '-' ' \   ' | '-' '  |  |  |  |\ '-'  ||  ||  |    '  '--'  |' '-' '\ `-' | /  `-.
// `------'.`-  /.-'  /  |  |-'   `--'  `--' `--`--'`--''--'     `------'  `---'  `---' `-----'
//         `---' `---'   `--'                      ,---.
//                                          ,---. /  .-'
//                                         | .-. ||  `-,
//                                         ' '-' '|  .-'
//                                          `---' `--'
//   ,--.  ,--.                ,--. ,--.           ,--.                                       ,--.   ,--.
// ,-'  '-.|  ,---.  ,---.     |  | |  |,--,--,  ,-|  | ,---. ,--.--.,--.   ,--. ,---. ,--.--.|  | ,-|  |
// '-.  .-'|  .-.  || .-. :    |  | |  ||      \' .-. || .-. :|  .--'|  |.'.|  || .-. ||  .--'|  |' .-. |
//   |  |  |  | |  |\   --.    '  '-'  '|  ||  |\ `-' |\   --.|  |   |   .'.   |' '-' '|  |   |  |\ `-' |
//   `--'  `--' `--' `----'     `-----' `--''--' `---'  `----'`--'   '--'   '--' `---' `--'   `--' `---'
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract EGU is ERC721, ERC721Enumerable, ERC721Burnable, AccessControlEnumerable, EIP712, ERC721Votes {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseURI;

    constructor(string memory name_, string memory symbol_, string memory baseURI_)
        ERC721(name_, symbol_)
        EIP712(name_, "1")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        baseURI = baseURI_;
    }

    // ---------- tokenURI ----------
    function setBaseURI(string memory baseURI_) external onlyRole(MANAGER_ROLE) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // ---------- mint ----------
    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    function batchMint(address to, uint256[] memory tokenId) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tokenId.length; i++) {
            _safeMint(to, tokenId[i]);
        }
    }

    // ---------- override ----------
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        require(from == address(0) || to == address(0), "SBT: you can only mint or burn");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}