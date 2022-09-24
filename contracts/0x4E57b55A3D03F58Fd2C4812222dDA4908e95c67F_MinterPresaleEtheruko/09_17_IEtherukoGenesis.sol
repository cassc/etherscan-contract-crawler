//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEtherukoGenesis {
    function setName(string memory newName) external;

    function setSymbol(string memory newSymbol) external;

    function isMinter(address account) external view returns (bool);

    function grantMinter(address account) external;

    function revokeMinter(address account) external;

    function isPauser(address account) external view returns (bool);

    function grantPauser(address account) external;

    function revokePauser(address account) external;

    function setBaseURI(string memory newBaseURI) external;

    function safeMint(address to, uint256 quantity) external;

    function pause() external;

    function unpause() external;

    function burn(uint256 tokenId) external;

    event SetName(string newName);
    event SetSymbol(string newSymbol);
    event SetMaxSupply(uint256 newMaxSupply);
    event GrantMinter(address account);
    event RevokeMinter(address account);
    event GrantPauser(address account);
    event RevokePauser(address account);
    event SetBaseURI(string newBaseURI);
    event SafeMint(address to, uint256 quantity);
    event Burn(uint256 tokenId);
}