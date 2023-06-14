// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IPassport {
    function mintPassport(address to) external returns (uint256);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract MintingModule is AccessControl {
    IPassport public uniNFT;
    IERC20 public uniToken;

    // address => did address mint
    mapping(address => bool) public minted;

    // are users are able to mint
    bool public mintEnabled;

    // how many uni tokens are needed to mint
    uint256 public tokenMinimum;

    constructor(
        address uniNFTContractAddress,
        address uniTokenContractAddress,
        uint256 uniTokenMinimum
    ) {
        uniNFT = IPassport(uniNFTContractAddress);
        uniToken = IERC20(uniTokenContractAddress);
        tokenMinimum = uniTokenMinimum;
        mintEnabled = false;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function claim() external returns (uint256) {
        require(mintEnabled, "minting disabled");
        require(!minted[msg.sender], "address already minted");
        require(uniToken.balanceOf(msg.sender) >= tokenMinimum, "min balance req");
        minted[msg.sender] = true;
        return uniNFT.mintPassport(msg.sender);
    }

    function setEnableMint(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // remember to give the minting module the MINTER role before enabling
        mintEnabled = enabled;
    }

    function setTokenMinimum(uint256 newTokenMinimum) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenMinimum = newTokenMinimum;
    }
}