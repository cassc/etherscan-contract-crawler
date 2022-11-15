//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEtherukoGame {
    event SetMaxSupply(uint256 maxSupply);
    event GrantMinter(address minter);
    event RevokeMinter(address minter);
    event GrantPauser(address pauser);
    event RevokePauser(address pauser);
    event SetTokenURI(uint256 tokenId, string tokenURI);
    event SetBaseURI(string baseURI);
    event SetName(string name);
    event SetSymbol(string symbol);
    event SafeMint(address to, uint256 tokenId, string uri);

    function setMaxSupply(uint256 newMaxSupply) external;

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function setBaseURI(string memory baseURI) external;

    function setName(string memory newName) external;

    function setSymbol(string memory newSymbol) external;

    function isMinter(address account) external view returns (bool);

    function grantMinter(address account) external;

    function revokeMinter(address account) external;

    function isPauser(address account) external view returns (bool);

    function grantPauser(address account) external;

    function revokePauser(address account) external;

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) external returns (uint256);

    function sequencialSafeMint(address to) external returns (uint256);

    function safeMassMint(
        address to,
        uint256[] memory tokenIds,
        string[] memory uris
    ) external returns (uint256[] memory);

    function sequencialSafeMassMint(address to, uint256 amount)
        external
        returns (uint256[] memory);

    function sequencialSafeBatchMint(
        address[] calldata toList,
        uint256[] calldata amountList
    ) external;
}