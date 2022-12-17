// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

contract CreepyDucks is ERC721, DefaultOperatorFilterer, Ownable, PullPayment {
    mapping(address => bool) private minters;
    string public baseTokenURI;
    uint256 public constant TOTAL_SUPPLY = 333;
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    
    constructor() ERC721("Creepy Little Ducks", "CLD") {
        baseTokenURI = "https://bafybeic6lxqeii55d7rrf377ugys6ntlginx3ewbjhoafjttstrulxcn7q.ipfs.dweb.link/metadata/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    
    function mint()
        public
        returns (uint256)
    {
        uint256 tokenId = currentTokenId.current();
        require(!minters[msg.sender], "only 1 mint per wallet");
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(msg.sender, newItemId);
        minters[msg.sender] = true;
        return newItemId;
    }
  
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdrawPayments(address payable payee) public override onlyOwner virtual {
        super.withdrawPayments(payee);
    }
}