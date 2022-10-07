// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketToken is ERC721, Ownable {

    address Contract;

    constructor() ERC721("TicketToken", "TT") {}

    mapping ( uint256 => string ) private baseUrls;
    mapping ( uint => uint ) private _TokenTransferTimestamp;

    modifier onlyContract {
      require(msg.sender == Contract);
      _;
    }

    function isApprovedOrOwner(address _spender , uint256 _tokenid) public view returns(bool) {
        return _isApprovedOrOwner(_spender, _tokenid);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseUrls[tokenId];
    } 

    function TokenTransferTimestamp(uint256 tokenId) public view returns (uint) {
        return _TokenTransferTimestamp[tokenId];
    }


    /*************************************************
    *                      onlyContract
    **************************************************/

    function setBaseUrl(uint256 tokenId, string memory baseURI) public {
        baseUrls[tokenId] = baseURI;
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(msg.sender == Contract || msg.sender == owner() , "!Owner || !Contract" );
        _burn(tokenId);
    }
    function approveToSmartContract(address to, uint tokenId) public {
        require(msg.sender == Contract || msg.sender == owner() , "!Owner || !Contract" );
        _approve(to, tokenId);
    }

    /*************************************************
    *                      onlyOwner
    **************************************************/
    
    function setContractAddress(address _contract) public onlyOwner {
        Contract = _contract;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _TokenTransferTimestamp[tokenId] = block.timestamp;
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _TokenTransferTimestamp[tokenId] = block.timestamp;
        _safeTransfer(from, to, tokenId, data);
    }

}