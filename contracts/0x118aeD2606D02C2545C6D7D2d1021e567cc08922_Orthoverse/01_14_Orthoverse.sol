// SPDX-License-Identifier: MIT
/*
 *   Orthoverse V2 - How to mint an insane number of NFTs in one go!
 *
 *  Brought to you by:
 *
 *       Keir Finlow-Bates - https://www.linkedin.com/in/keirf/
 *                      &
 *       Richard Piacentini - https://www.linkedin.com/in/richardpiacentini/
 *
 */

pragma solidity 0.8.13;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./IERC2981.sol";

contract Orthoverse is ERC1155, Ownable, ERC1155Supply, IERC2981 {
    constructor(
        string memory uri_,
        address W0_,
        address W1_
    ) ERC1155(uri_, W0_, W1_) {}

    function name() external pure returns (string memory) {
        return "Orthoverse";
    }

    function symbol() external pure returns (string memory) {
        return "ORTH";
    }

    function setURI(string memory newURI_) external onlyOwner {
        _setURI(newURI_);
    }

    function setVoidURI(string memory newVoidURI_) external onlyOwner {
        _setVoidURI(newVoidURI_);
    }

    function castleLevel(uint256 tokenId_) external view returns (uint256) {
        return tokenCastleLevel[tokenId_];
    }

    function castlePrice(uint256 tokenId_) public view returns (uint256) {
        return (CASTLE_BASE_PRICE * (2**(tokenCastleLevel[tokenId_] % 8)));
    }

    function upgradeCastleLevel(address account_) external payable {
        require(account_ != address(0), "No zero address");
        uint256 tokenId = uint256(uint160(account_));

        require(
            tokenCastleLevel[tokenId] != 7 && tokenCastleLevel[tokenId] != 15,
            "At max level"
        );

        if (msg.sender != W0 && msg.sender != W1) {
            require(msg.value >= castlePrice(tokenId), "Not enough ETH");
        }
        tokenCastleLevel[tokenId]++;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");

        uint256 half = (balance * 5) / 10;
        Address.sendValue(payable(W0), half);
        Address.sendValue(payable(W1), half);
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * 250) / 10000);
    }

    // Required after "Panic at the Orthoverse V1"
    function migrator(
        address[] calldata from_,
        address[] calldata to_,
        uint256[] calldata tokenId_,
        uint256[] calldata level_
    ) external onlyOwner {
        _migrator(from_, to_, tokenId_, level_);
    }

    // Never go back...
    function killMigrator() external onlyOwner {
        _killMigrator();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}