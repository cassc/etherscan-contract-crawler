//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract NeverFearTruthTrackOne is ERC1155, IERC2981, Ownable {
    address public royaltyRECEIVER;
    uint256 public royaltyPERCENTAGE;
    bool public locked = false;

    constructor(
        address _royaltyReceiver,
        uint256 _royaltyPercentage,
        string memory _bURI
    ) ERC1155(_bURI) {
        royaltyRECEIVER = _royaltyReceiver;
        royaltyPERCENTAGE = _royaltyPercentage;
    }

    function reserve(address[] calldata to) external onlyOwner {
        require(!locked, "Contract locked");
        for (uint256 i = 0; i < to.length; i++) {
            address receiver = to[i];
            _mint(receiver, 0, 1, "");
        }
    }

    /**
     * @dev -  Set Royalties
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

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setURI(newBaseURI);
    }

    function setLocked() external onlyOwner {
        locked = true;
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, IERC165)
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
}