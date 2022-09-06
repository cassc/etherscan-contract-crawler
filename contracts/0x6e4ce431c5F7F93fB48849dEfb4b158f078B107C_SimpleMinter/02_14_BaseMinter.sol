// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ContextMixin.sol";

/**
 * @title BaseMinter
 * BaseMinter - a base minter for NFTs
 */
contract BaseMinter is ERC721, Ownable, ContextMixin {
    using Counters for Counters.Counter;
    Counters.Counter internal _nextTokenId;

    uint256 internal constant _PAUSED = 1;
    uint256 internal constant _RUNNING = 2;
    uint256 internal _status;

    uint256 public maxSupply = 1000;
    uint256 public price = 0.0001 ether;

    string public contractURI;
    string public baseURI;
    string public defaultTokenURI;

    address internal _payout;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    constructor(string memory name, string memory symbol) ERC721(name, symbol)
    {
        _nextTokenId.increment();
        _status = _PAUSED;
    }

    modifier whenRunning() {
        require(_status==_RUNNING, "Contract not running");
        _;
    }

    /*
    *  Owner methods
    */
    function setPrice(uint256 _val) external onlyOwner
    {
        price = _val;
    }

    function setContractURI(string memory _uri) external onlyOwner
    {
        contractURI = _uri;
    }

    function setBaseURI(string memory _uri) external onlyOwner
    {
        baseURI = _uri;
    }

    function setDefaultTokenURI(string memory _uri) external onlyOwner
    {
        defaultTokenURI = _uri;
    }

    function setTokenURI(uint256 tokenId, string memory _uri) external onlyOwner
    {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _uri;
    }

    function setStatus(uint256 _val) external onlyOwner {
        require(_val==_PAUSED || _val==_RUNNING, "Invalid status");
        require(_val!=_status, "Status already set");
        _status = _val;
    }

    function setPayout(address _to) external onlyOwner
    {
        _payout = _to;
    }

    function getPayout() external view onlyOwner returns (address)
    {
        return _payout;
    }

    function withdraw(uint256 _percent) public payable onlyOwner {
        uint256 _amount = address(this).balance * _percent / 100;
        require(payable(_payout).send(_amount));
    }

    function setMaxSupply(uint256 _val) external onlyOwner
    {
        maxSupply = _val;
    }

    /* ============ */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(base).length > 0 && bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        // if the default token URI is set return it
        if (bytes(defaultTokenURI).length > 0) {
            return defaultTokenURI;
        }

        return super.tokenURI(tokenId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function status() public view returns (uint256) {
        return _status;
    }

    function paused() public view virtual returns (bool) {
        return _status==_PAUSED;
    }

    function running() public view virtual returns (bool) {
        return _status==_RUNNING;
    }

}