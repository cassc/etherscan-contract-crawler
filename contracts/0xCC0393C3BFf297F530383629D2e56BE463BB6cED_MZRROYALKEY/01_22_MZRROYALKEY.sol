// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract MZRROYALKEY is ERC721, ERC721Enumerable, DefaultOperatorFilterer, Ownable {
    using SafeERC20 for ERC20;
    address private wallet = 0x74916bD3F92b7197aC66ff2761B1D20FDd8d549f;
    address private usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint private priceInUsdt = 90000000;
    uint16[200] private ids;
    uint16 private index;

    constructor() ERC721("MZRROYALKEY", "MZRROYAL") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeieyi6ewaju2lmsbsj2ygufngf5klxvaby6rw4revjt3sck3d4e3lu/";
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseURI();
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(index, msg.sender, block.difficulty, block.timestamp, blockhash(block.number-1))));
    }

    function setUsdtPrice(uint price) public onlyOwner {
        priceInUsdt = price;
    }

    function _pickRandomUniqueId() private returns (uint256 id) {
        uint randomUint = random();
        uint len = ids.length - index++;
        require(len > 0, 'All nft minted');
        uint randomIndex = randomUint % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }

    function mint() external {
        ERC20(usdtAddress).safeTransferFrom(msg.sender, wallet, priceInUsdt);
        uint tokenId = _pickRandomUniqueId();
        _safeMint(_msgSender(), tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}