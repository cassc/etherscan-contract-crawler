// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/***
 *    ███╗   ███╗███████╗████████╗ █████╗ ██████╗ ██╗   ██╗███████╗
 *    ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║   ██║██╔════╝
 *    ██╔████╔██║█████╗     ██║   ███████║██████╔╝██║   ██║███████╗
 *    ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██╔══██╗██║   ██║╚════██║
 *    ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██████╔╝╚██████╔╝███████║
 *    ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC721A.sol";

import "./interface/IProxySale.sol";
import "./interface/IMetaBus.sol";

contract MetaBus is ERC721A, IMetaBus, Ownable {

    string private uri;

    address public proxySaleAddress;

    IProxySale private proxySale;

    constructor(string memory _uri, address _proxySaleAddress) ERC721A("MetaBus Pass", "MBUS", 1) {
        uri = _uri;
        proxySaleAddress = _proxySaleAddress;
        proxySale = IProxySale(proxySaleAddress);
    }

    function setProxySaleAddress(address _proxySaleAddress) public onlyOwner{
        proxySaleAddress = _proxySaleAddress;
        proxySale = IProxySale(proxySaleAddress);
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return uri;
    }

    function setURI(string memory _uri) public virtual onlyOwner{
        uri = _uri;
    }

    function mint(address _to) external override(IMetaBus) {
        require(proxySaleAddress == msg.sender, "Ownable: caller is not the owner");
        _safeMint(_to, 1);
    }

    function numberMinted(address _to) external override(IMetaBus) view returns (uint256){
        return _numberMinted(_to);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        require(!proxySale.isStake(startTokenId), "Cannot transfer stake tokens");
    }
}