pragma solidity ^0.5.0;

import "./TradeableERC721Token.sol";

contract Splinterlands is TradeableERC721Token {

    address minter;
    string dynamicBaseURI;

    mapping(uint256 => Card) public cards;
    mapping(string => uint256) public ethIds;

    struct Card {
        string splinterlandsId;
    }

    event LockCard(address indexed holder, string cardId, string steemAddr, uint256 indexed ethId);
    event MintCard(address indexed holder, string cardId, uint256 indexed ethId);

    constructor(address _proxyAddr,
                address _minter,
                string memory _baseTokenURI) public TradeableERC721Token("Splinterlands", "SLCARD", _proxyAddr) {

        minter = _minter;
        dynamicBaseURI = _baseTokenURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return dynamicBaseURI;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return Strings.strConcat(
            baseTokenURI(),
            cards[_tokenId].splinterlandsId
        );
    }

    function setDynamicBaseURI(string memory _newBaseURI) public onlyOwner {
        dynamicBaseURI = _newBaseURI;
    }

    function setMinter(address _newMinter) public onlyOwner {
        minter = _newMinter;
    }

    function mintCard(string memory _splinterId, address _holder) public onlyMinter {
        require(0 == ethIds[_splinterId], "Splinterlands: Card Exists");

        uint256 newEthId = _getNextTokenId();

        cards[newEthId].splinterlandsId = _splinterId;
        ethIds[_splinterId] = newEthId;

        mintTo(_holder);
        require(_getNextTokenId() == newEthId + 1, "Splinterlands: Safety Check");

        emit MintCard(_holder, _splinterId, newEthId);
    }

    function lockCard(uint256 _ethId, string memory _steemAddr) public {
        require(ownerOf(_ethId) == msg.sender, "Splinterlands: Not Holder");

        string memory cardId = cardIdForTokenId(_ethId);
        transferFrom(msg.sender, address(this), _ethId);

        emit LockCard(msg.sender, cardId, _steemAddr, _ethId);
    }

    function unlockCard(uint256 _ethId, address _newHolder) public onlyMinter isLockedCard(_ethId) {
        transferFrom(address(this), _newHolder, _ethId);
    }

    function burnCard(uint256 _ethId) public onlyMinter isLockedCard(_ethId) {
        _burn(_ethId);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        if (owner == address(this) && operator == minter) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

     function tokensOfHolder(address holder) public view returns (uint256[] memory) {
        return _tokensOfOwner(holder);
    }

    function tokenIdForCardId(string memory _splinterId) public view returns (uint256) {
        return ethIds[_splinterId];
    }

    function cardIdForTokenId(uint256 _tokenId) public view returns (string memory) {
        return cards[_tokenId].splinterlandsId;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Splinterlands: Not Minter");
        _;
    }

    modifier isLockedCard(uint256 _ethId) {
        require(ownerOf(_ethId) == address(this), "Splinterlands: Not Locked");
        _;
    }
}
