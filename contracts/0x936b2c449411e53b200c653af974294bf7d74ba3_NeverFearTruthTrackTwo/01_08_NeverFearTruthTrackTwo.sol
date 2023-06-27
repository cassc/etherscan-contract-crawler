//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract NeverFearTruthTrackTwo is ERC721A, IERC2981, Ownable {
    address public royaltyRECEIVER;
    uint256 public royaltyPERCENTAGE;
    bool public locked = false;

    string public baseURI;

    constructor(
        address _royaltyReceiver,
        uint256 _royaltyPercentage,
        string memory _bURI
    ) ERC721A("Never Fear Truth Track Two", "NFTT2") {
        royaltyRECEIVER = _royaltyReceiver;
        royaltyPERCENTAGE = _royaltyPercentage;
        baseURI = _bURI;
    }

    function reserve(address[] calldata to, uint256[] calldata amount) external onlyOwner {
        require(!locked, "Contract locked");
        require(to.length == amount.length, "Amount + Address length needs to be the same");
        for (uint256 i = 0; i < to.length; i++) {
            address receiver = to[i];
            uint256 myAmount = amount[i];
            _mint(receiver, myAmount);
        }
    }

    /**
     * @dev - Set Royalties
     * @param _royaltyReceiver - Receiver of royalties
     * @param _royaltyPercentage - Percentage amount in ratio to 1000. e.g. 50 = 5%
     */
    function setRoyaltyInfo(
        address _royaltyReceiver,
        uint256 _royaltyPercentage
    ) public onlyOwner {
        royaltyRECEIVER = _royaltyReceiver;
        royaltyPERCENTAGE = _royaltyPercentage;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setLocked() external onlyOwner {
        locked = true;
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // IERC2981

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice / 1000) * royaltyPERCENTAGE;
        return (royaltyRECEIVER, royaltyAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}