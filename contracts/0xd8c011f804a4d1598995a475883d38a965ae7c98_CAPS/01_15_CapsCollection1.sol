//SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract CAPS is
    ERC721("CAPS (Monsters)", "CAPS"),
    Ownable,
    ERC721Enumerable,
    ERC721URIStorage
{
    using Strings for uint256;

    string private _baseURIextended;
    address internal ticketContract;
    address internal tokenContract;
    address internal gameContract;
    address internal zeroAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public immutable maxSupply = 100000;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bytes32) public _tokenIdToRequestId;
    mapping(uint256 => address) public _tokenIdToAddress;
    mapping(uint256 => uint256) public _tokenIdToStats;
    mapping(uint256 => uint256) public _tokenIdToConditionId;

    modifier onlyTicketContract() {
        require(msg.sender == ticketContract, "Only Ticket can call me");
        _;
    }
    
    
    modifier onlyTokenContract() {
        require(msg.sender == tokenContract, "Only Token can call me");
        _;
    }

    modifier onlyGameContract() {
        require(msg.sender == gameContract, "Only Game can call me");
        _;
    }

    constructor(string memory baseURI) {
        setBaseURI(baseURI);
    }

    function getConditionIdByTokenId(uint256 tokenId) external view returns (uint256) {
        return _tokenIdToConditionId[tokenId];
    }

    function setTicketContract(address value) public onlyOwner {
        ticketContract = value;
    }

    function setGameContract(address value) public onlyOwner {
        gameContract = value;
    }

    function setTokenContract(address value) public onlyOwner {
        tokenContract = value;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batch
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batch);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) internal onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
       
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mintUseTicket(address ticketOwner, uint256 conditionId)
        external
        onlyTicketContract
    {
        require(maxSupply >= totalSupply(), "Not enough caps");
        uint256 newItemId = totalSupply() + 1;
        _safeMint(ticketOwner, newItemId);
        setStats(1000, newItemId, conditionId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function setStats(
        uint256 health,
        uint256 tokenId,
        uint256 conditionId
    ) internal onlyTicketContract {
        _tokenIdToStats[tokenId] = health;
        _tokenIdToConditionId[tokenId] = conditionId;
        _setTokenURI(tokenId, Strings.toString(conditionId));
    }

    function hitCaps(uint256 tokenId) public onlyGameContract {
        uint256 health = _tokenIdToStats[tokenId];
        if (health == 0) {
            return;
        }
        else if ((health % 100) != 0) {
            _tokenIdToStats[tokenId] = health - 5;
            return;
        } else {
            _tokenIdToStats[tokenId] = health - 5;
            uint256 conditionId = _tokenIdToConditionId[tokenId];
            _tokenIdToConditionId[tokenId] = conditionId + 1;
            _setTokenURI(tokenId, Strings.toString(conditionId + 1));
            return;
        }
    }

    function burnCaps(address owner, uint256 tokenId) external onlyTokenContract{
        safeTransferFrom(owner, zeroAddress, tokenId, "burn");
    }
    
    function batchTransferFrom(address account, uint256[] memory tokenIds, address to) public {
        for (uint i=0; i< tokenIds.length; i++) {
            safeTransferFrom(account, to, tokenIds[i]);
        }
    }
}