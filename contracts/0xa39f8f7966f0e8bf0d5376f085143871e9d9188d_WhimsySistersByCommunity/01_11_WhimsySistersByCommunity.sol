// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhimsySistersByCommunity is ERC721, Ownable {

    string public baseURI = "https://storage.googleapis.com/whimsysisters/meta-custom/";

    bool osAutoApproveEnabled = true;
    address public openseaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;
    IERC721 public sisters = IERC721(0xfC23F958C86D944418D7965a5F6582d1E96Db1be);

    constructor() ERC721("Whimsy Sisters by community", "WSCOMM") {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setOsAutoApproveEnabled(bool _osAutoApproveEnabled) external onlyOwner {
        osAutoApproveEnabled = _osAutoApproveEnabled;
    }

    function mintWith(uint sisterId) external {
        require(sisters.ownerOf(sisterId) == msg.sender, "You must own this token");
        _mint(msg.sender, sisterId);
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (osAutoApproveEnabled && operator == openseaConduit) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

}