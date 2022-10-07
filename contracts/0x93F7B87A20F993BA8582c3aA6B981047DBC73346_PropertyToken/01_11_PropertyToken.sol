// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PropertyToken is ERC721, Ownable {

    address Contract;

    constructor() ERC721("PropertyToken", "PT") {}

    mapping ( uint256 => string ) baseUrls;

    modifier onlyContract {
      require(msg.sender == Contract, "!Contract");
      _;
    }


    function isApprovedOrOwner(address _spender , uint256 _tokenid) public view returns(bool) {
        return _isApprovedOrOwner(_spender, _tokenid);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _baseURI(tokenId); 
    }

    function _baseURI(uint256 tokenId) internal view virtual returns (string memory) {
        return baseUrls[tokenId];
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: !Owner nor !Approved");
        _burn(tokenId);
    }


    /*************************************************
    *                      onlyOwner
    **************************************************/
    
    function setContractAddress(address _contract) public onlyOwner {
        Contract = _contract;
    }



    /*************************************************
    *                      onlyOwner
    **************************************************/

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyContract {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyContract {
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
    ) public override onlyContract {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

}