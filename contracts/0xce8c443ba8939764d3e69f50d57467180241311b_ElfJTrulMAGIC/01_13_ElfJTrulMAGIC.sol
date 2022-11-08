//               @@@@@@@@@                                                                           @@@@@@@@@@
//               @@@@@@@@@                                                                           @@@@@@@@@@
//          @@@@@@@@@@@@@@@@@@@@@@@@                                                        @@@@@@@@@@@@@@@@@@@@@@@
//          @@@@@@@@@@@@@@@@@@@@@@@@                                                        @@@@@@@@@@@@@@@@@@@@@@@
//          @@@@@     @@@@@@@@@@@@@@@@@@@                                              @@@@@@@@@@@@@@@@@@@     @@@@
//          @@@@@     @@@@@@@@@@@@@@@@@@@                                              @@@@@@@@@@@@@@@@@@@     @@@@
//                        @@@@@@@@@@@@@@@@@@@                                      @@@@@@@@@@@@@@@@@@
//                        @@@@@@@@@@@@@@@@@@@                                      @@@@@@@@@@@@@@@@@@
//                             @@@@@@@@@@@@@@@@@@@                            @@@@@@@@@@@@@@@@@@@
//                                  @@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@
//                                  @@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@
//                                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//               @@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@          ((((@@@@@@@@@(((((          @@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((((((((
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// (((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((         @@@@@@@@@          (((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((
//      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//      (((((((((@@@@@@@@@@@@@@@@@@@(((((((((@@@@@(((((    @@@@@@@@@     (((((@@@@@(((((((((@@@@@@@@@@@@@@@@@@@(((((((((
//               @@@@@@@@@@@@@@@@@@@         @@@@@@@@@@    @@@@@@@@@     @@@@@@@@@@         @@@@@@@@@@@@@@@@@@@
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                           @@@@@@@@@@    @@@@@@@@@     @@@@@@@@@@
//                                           @@@@@@@@@@    @@@@@@@@@     @@@@@@@@@@
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                                     @@@@@@@@@@@@@@@@@@
//                                                     @@@@@@@@@@@@@@@@@@
//
//
// ElfJTrul!MAGIC
// Twitter: https://twitter.com/ElfJTrul
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ElfJTrulMAGIC is ERC721, Ownable {
    mapping(uint256 => string) private _tokenURIs;
    uint256 totalSupply;

    constructor() ERC721("ElfJTrulMAGIC", "ELFJTRULMAGIC") {}

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenURIs[tokenId];
    }

    function mint(address _to, uint256 _tokenId) public onlyOwner {
        totalSupply += 1;
        _mint(_to, _tokenId);
    }

    function setTokenURI(uint256 _tokenId, string calldata _newTokenURI)
        public
        onlyOwner
    {
        _tokenURIs[_tokenId] = _newTokenURI;
    }

    // Emergency exit functions
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function forwardTransferFrom(
        IERC721 token,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        token.transferFrom(address(this), to, tokenId);
    }

    function forwardSetApprovalForAll(
        IERC721 token,
        address operator,
        bool approved
    ) public onlyOwner {
        token.setApprovalForAll(operator, approved);
    }
}