// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

contract HonoraryRASC is ERC721A, Ownable {
    using Address for address;

    string public baseURI_;

    constructor() ERC721A("Honorary Rotten Anti Social Club", "HRASC") Ownable() {}

    function mint(address _to, uint256 _amount) public onlyOwner {
        _safeMint(_to, _amount);
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI_ = __baseURI;
    }

    function withdraw() public onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }  

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}