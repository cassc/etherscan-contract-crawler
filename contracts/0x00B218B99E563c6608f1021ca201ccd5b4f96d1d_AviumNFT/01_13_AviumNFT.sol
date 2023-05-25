// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721AURIStorage.sol";

contract AviumNFT is Ownable, ERC721AURIStorage {
    address public controller;
    uint256 immutable totalMint;

    constructor(uint256 _totalMint) ERC721AURIStorage("Avium Founders' Pass", "AFP") {
        totalMint = _totalMint;
    }

    /**
     * @dev Set the baseURI
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Set the controller
     * @param _newController the new controller
     */
    function setController(address _newController) public onlyOwner {
        controller = _newController;
    }

    /**
     * @dev Get the total mint
     */
    function getTotalMint() public view returns (uint256) {
        return totalMint;
    }

    /**
     * @dev Get the current index
     */
    function getCurrentIndex() public view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Get the current index
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Mint NFTs
     * @param _to the receiver
     * @param _quantity the mint quantity
     * @param _data the arbitrary data
     */
    function mint(
        address _to,
        uint256 _quantity,
        bytes memory _data
    ) public {
        require(
            _msgSender() == controller || _msgSender() == owner(),
            "AviumNFT: only owner or controller are allowed"
        );
        require(
            _currentIndex + _quantity <= totalMint + 1,
            "AviumNFT: the total mint has been exeeded"
        );
        _safeMint(_to, _quantity, _data);
    }

    /**
     * @dev Burn NFT
     * @param _tokenId the token id
     */
    function burn(uint256 _tokenId) public {
        _burn(_tokenId, true);
    }
}