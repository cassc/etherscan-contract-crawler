// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract FlickDropNFT is
    ERC721AQueryable,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    string public m_baseURI;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(
        string memory name,
        string memory symbol,
        address feeReceiver,
        uint96 feeBasis
    ) ERC721A(name, symbol) ERC2981() {
        _setDefaultRoyalty(feeReceiver, feeBasis);
    }

    function setDefaultRoyalty(
        address feeReceiver,
        uint96 feeBasis
    ) external onlyOwner {
        _setDefaultRoyalty(feeReceiver, feeBasis);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        m_baseURI = newBaseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        (address receiver, ) = royaltyInfo(0, 0);
        payable(receiver).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return m_baseURI;
    }

    function bulkMint(address[] memory _to) public onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], 1);
        }
    }

    /**
     * @dev implements operator-filter-registry blocklist filtering because https://opensea.io/blog/announcements/on-creator-fees/
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev implements operator-filter-registry blocklist filtering because https://opensea.io/blog/announcements/on-creator-fees/
     */
    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev implements operator-filter-registry blocklist filtering because https://opensea.io/blog/announcements/on-creator-fees/
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev implements operator-filter-registry blocklist filtering because https://opensea.io/blog/announcements/on-creator-fees/
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev implements operator-filter-registry blocklist filtering because https://opensea.io/blog/announcements/on-creator-fees/
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            interfaceID == type(IERC721AQueryable).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    receive() external payable {
        // transfer all funds to contract
    }

    /**
     * @dev allow onlyOwner to call arbitary calldata as contract, as a safety valve for stuck coins
     */
    function callContract(
        address _contract,
        bytes memory _data
    ) external onlyOwner {
        (bool success, ) = _contract.call(_data);
        require(success, "callContract failed");
    }
}