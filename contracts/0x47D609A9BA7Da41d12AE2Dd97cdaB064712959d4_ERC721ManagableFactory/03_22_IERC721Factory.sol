// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC721Factory {

    event ClientSet(address client);
    event CollectionSet(address collection);
    event FeeSet(uint256 fee);
    event MintingSet(bool active);
    event FirewallSet(address firewall);
    event DefaultUriSet(string uri);

    event Withdrawn(address indexed caller, address indexed receiver, uint256 amount);
    event TokenMinted(address indexed minter, uint256 amount);
    
    function mint() external payable;

    function mint(uint256 amount) external payable;

    function mint(address to, uint256 amount) external payable;

    function mintAdmin() external payable;

    function mintAdmin(uint256 amount) external payable;

    function mintAdmin(address to, uint256 amount) external payable;

    function canMint(address minter, uint256 amount) external view returns(bool, string memory);

    function balanceOf() external returns(uint256);

    function withdraw(address to, uint256 amount) external;

    function withdraw(address to) external;
}