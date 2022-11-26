//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MetroGradStaked is ERC721, Ownable {
    error NotAuthorized();

    string private _baseTokenURI =
        "ipfs://QmX7LbjRfj82u8e7MPgcgcxzfX6PaRE6Tg28DjvEXZoY8A/";

    mapping(address => bool) controllers;

    constructor() ERC721("Staked MetroGrad Gen.1", "Staked Survivor") {}

    function mint(address to, uint256 tokenId) public callerIsController {
        _safeMint(to, tokenId);
    }

    modifier callerIsController() {
        if (!controllers[msg.sender]) revert NotAuthorized();
        _;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function batchMint(address to, uint256[] memory tokenIds)
        external
        callerIsController
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mint(to, tokenIds[i]);
        }
    }

    function burn(uint256 tokenId) public callerIsController {
        _burn(tokenId);
    }

    function batchBurn(uint256[] memory tokenIds) external callerIsController {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }

    // VIEW FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // ADMIN FUNCTIONS
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            controllers[msg.sender],
            "Staked Survivor can not be transferred!"
        );
    }
}