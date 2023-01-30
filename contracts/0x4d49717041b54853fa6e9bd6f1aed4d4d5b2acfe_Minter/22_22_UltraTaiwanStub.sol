// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UltraTaiwanStub is ERC721Enumerable, ERC721Royalty, Ownable {
    using Counters for Counters.Counter;

    address public minter;
    uint256 public transferableTimestamp;

    string private baseURI_;

    constructor() ERC721("UltraTaiwan", "ULTRATW") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function setTransferableTimestamp(uint256 _transferableTimestamp) external onlyOwner {
        transferableTimestamp = _transferableTimestamp;
    }

    function setURI(string memory uri) external onlyOwner {
        baseURI_ = uri;
    }

    function setRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == minter, "Not minter");
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override (ERC721, ERC721Enumerable)
    {
        if (from != address(0)) {
            require(block.timestamp >= transferableTimestamp, "untransferable");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}