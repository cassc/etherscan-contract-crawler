// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LggNftNew is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {

    using Strings for uint256;
    
    mapping(address => bool) public _permit;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseUri = "https://rpd.realplayer.io/upload/meta/";

    constructor() ERC721("RPDP", "RPD") {}

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, getURI(tokenId));
    }

    modifier checkPermit(address acount) {
        require(_permit[acount], "Not permit");
        _;
    }

    function safeMintBlindBox(address to) external checkPermit(msg.sender) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, getURI(tokenId));
    }

    function getURI(uint256 tokenId) pure private returns (string memory) {
        return string(abi.encodePacked(tokenId.toString(), ".json"));
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function permit(address _account) external onlyOwner {
        _permit[_account] = true;
    }

    function Unpermit(address _account) external onlyOwner {
        _permit[_account] = false;
    }

    receive() external payable {}

    /* ========== EMERGENCY ========== */
    /*
        Users make mistake by transferring usdt/busd ... to contract address.
        This function allows contract owner to withdraw those tokens and send back to users.
    */
    function rescueStuckToken(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), amount);
    }

    function refund(address _addr, uint256 _amount) external onlyOwner {
        payable(_addr).transfer(_amount);
    }

    function airdrop(address[] memory _tos) public onlyOwner {
        for (uint8 i = 0; i < _tos.length; i++) {
            safeMint(_tos[i]);
        }
    }

}