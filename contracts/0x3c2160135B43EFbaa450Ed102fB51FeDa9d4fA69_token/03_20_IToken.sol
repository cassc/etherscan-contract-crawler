// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


struct revealStruct {
    uint256 REQUEST_ID;
    uint256 RANDOM_NUM;
    uint256 SHIFT;
    uint256 RANGE_START;
    uint256 RANGE_END;
    bool processed;
}

struct TokenInfoForSale {
    uint256 _projectID;
    uint256 _maxSupply;
    uint256 _reservedSupply;
}

struct TokenInfo {
    string _name;
    string _symbol;
    uint256 _projectID;
    uint256 _maxSupply;
    uint256 _mintedSupply;
    uint256 _mintedReserve;
    uint256 _reservedSupply;
    uint256 _giveawaySupply;
    string _tokenPreRevealURI;
    string _tokenRevealURI;
    bool _transferLocked;
    bool _lastRevealRequested;
    uint256 _totalSupply;
    revealStruct[] _reveals;
}

interface IToken {

    function mintIncrementalCards(uint256, address) external;
    function mintReservedCards(uint256, address) external;
    function mintGiveawayCard(uint256, address) external;

    function setPreRevealURI(string calldata) external;
    function setRevealURI(string calldata) external;

    function revealAtCurrentSupply() external;
    function lastReveal() external;
    function process(uint256, uint256) external;
    
    function uri(uint256) external view returns (uint256);
    function tokenURI(uint256) external view returns (string memory);

    function setTransferLock(bool) external;
    function setAllowed(address, bool) external;
    function isAllowed(address) external view returns(bool);

    function getFirstGiveawayCardId() external view returns (uint256);
    function tellEverything() external view returns (TokenInfo memory);
    function getTokenInfoForSale() external view returns (TokenInfoForSale memory);
}