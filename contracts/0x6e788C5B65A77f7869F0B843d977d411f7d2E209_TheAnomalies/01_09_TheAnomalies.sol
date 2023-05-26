// SPDX-License-Identifier: MIT
// Creator: P4SD Labs

pragma solidity 0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error NonExistentToken();
error CallerIsNotOwner();
error CannotSetZeroAddress();
error CannotSetBlankURI();

contract TheAnomalies is ERC721A, ERC2981, Ownable {
    address public treasuryAddress;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) public isPossessed;

    constructor(
        address defaultTreasury
    ) ERC721A("The Anomalies", "ANOMALY") {
        setTreasuryAddress(payable(defaultTreasury));
        setRoyaltyInfo(500);
    }

    function mint(address tokenOwner, string memory baseTokenURI) external onlyOwner {
        _mint(tokenOwner, 1);
        setTokenURI(_nextTokenId()-1, baseTokenURI);
    }

    function setTokenURI(uint256 tokenID, string memory baseTokenURI) public onlyOwner {
        if (!_exists(tokenID)) revert NonExistentToken();
        if (bytes(baseTokenURI).length == 0) revert CannotSetBlankURI();
        _tokenURIs[tokenID] = baseTokenURI;
    }

    /**
     * @dev Set the metadata to Possessed or Blessed State
     */
    function setIsPossessed(uint256 tokenID, bool isPssssd) external {
        if (!_exists(tokenID)) revert NonExistentToken();
        if (ownerOf(tokenID) != msg.sender) revert CallerIsNotOwner();
        isPossessed[tokenID] = isPssssd;
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

    // OVERRIDES ---------

    /**
    * @dev Variation of {ERC721Metadata-tokenURI}.
    * Returns different token uri depending on blessed or possessed.
    */
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        if (!_exists(tokenID)) revert NonExistentToken();
        string memory postfix = isPossessed[tokenID] ? "possessed" : "blessed";
        return string(abi.encodePacked(_tokenURIs[tokenID], postfix, ".json"));
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
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

}