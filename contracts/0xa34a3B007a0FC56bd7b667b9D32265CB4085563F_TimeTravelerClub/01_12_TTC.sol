// contracts/Fantasy3K.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";


contract TimeTravelerClub is ERC721A, Pausable, Ownable {

    event BaseURIChanged(string newBaseURI);
    event Mint(address minter, uint256 count);
    event IsBurnEnabledChanged(bool newIsBurnEnabled);

    bool public isBurnEnabled = false;
    string public baseURI;

    constructor() ERC721A("TimeTravelerClub", "TTC") {

    }

    function mintTokens(address to, uint256 count) public onlyAdmin {

        require(count > 0, "TTC: invalid count");

        _safeMint(to, count);
        emit Mint(to, count);
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit IsBurnEnabledChanged(_isBurnEnabled);
    }

    function setBaseURI(string calldata newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
        emit BaseURIChanged(newbaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "burn is not enabled");
        _burn(tokenId, true);
    }


    function mintTeam(address _team1, address _team2) external onlyOwner{
        _safeMint(_team1, 556);
        _safeMint(_team2, 556);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        super._beforeTokenTransfers(from, to, tokenId, 1);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}