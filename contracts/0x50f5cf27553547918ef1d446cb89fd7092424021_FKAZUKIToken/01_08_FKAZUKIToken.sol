// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FKAZUKIToken is ERC20, Ownable {
    bool public mintingEnabled = true;

    uint256 public constant MAX_TOTAL_SUPPLY = 10e8 * 1e18;
    uint256 public constant MAX_MINT_SUPPLY = 8e8 * 1e18;

    uint256 public constant MAX_AZUKIELEMENTLS_USER = 5000;
    uint256 public constant MAX_AZUKI_USER = 4000;
    uint256 public constant MAX_NORMAL_USER = 1000;

    mapping(address => bool) public whitelistMintAddresses;
    mapping(address => bool) public azukiElementlsMintAddresses;
    mapping(address => bool) public azukiMintAddresses;
    mapping(address => bool) public normalUserMintAddresses;

    address[] public azukiElementlsMintAddressList;
    address[] public azukiMintAddressList;
    address[] public normalUserMintAddressList;

    uint256 public constant LIQUIDITY_POOL_SUPPLY = 1e8 * 1e18;
    uint256 public constant DEVTEAM_SUPPLY = 1e8 * 1e18;
    address public constant DEVTEAM_ADDRESS =
        0x38c4f0f7dd61a6d04a95ceE15e6b24c910279899;
    // mainnet 0x8baa047E673b6581E8C7C75EfA8c5B029cc209CD
    // testnet 0x38c4f0f7dd61a6d04a95ceE15e6b24c910279899

    address[] public whitelist;
    uint256 public constant MAX_WHITELIST_SIZE = 100;

    address public constant AZUKI_ADDRESS =
        0x3Af2A97414d1101E2107a70E7F33955da1346305;
    address public constant AZUKIELEMENTLS_ADDRESS =
        0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e;
    address public constant AZUKIELEMENTLSBEANS_ADDRESS =
        0x3Af2A97414d1101E2107a70E7F33955da1346305;

    constructor() ERC20("FKAZUKI", "FKAZUKI") {
        _mint(msg.sender, LIQUIDITY_POOL_SUPPLY);
        _mint(DEVTEAM_ADDRESS, DEVTEAM_SUPPLY);
    }

    function mint() public {
        require(mintingEnabled, "Minting is currently disabled");
        require(!hasMinted(msg.sender), "Already minted");
        require(totalSupply() < MAX_MINT_SUPPLY, "Exceeds max mint supply");

        uint256 mintAmount = 1;
        uint256 userType = 0; // 0=normal, 1=azuki, 2=azukielementls, 3=whitelist

        if (isInWhitelist(msg.sender)) {
            userType = 3;
            mintAmount = 120000 * 1e18;
        } else if (
            hasNFTToken(AZUKIELEMENTLS_ADDRESS, msg.sender) ||
            hasNFTToken(AZUKIELEMENTLSBEANS_ADDRESS, msg.sender)
        ) {
            userType = 2;
            mintAmount = azukiElementlsMintAddressList.length <
                MAX_AZUKIELEMENTLS_USER / 2
                ? 120000 * 1e18
                : 40000 * 1e18;
        } else if (hasNFTToken(AZUKI_ADDRESS, msg.sender)) {
            userType = 1;
            mintAmount = azukiMintAddressList.length < MAX_AZUKI_USER / 2
                ? 120000 * 1e18
                : 40000 * 1e18;
        } else {
            userType = 0;
            mintAmount = normalUserMintAddressList.length < MAX_NORMAL_USER / 2
                ? 120000 * 1e18
                : 40000 * 1e18;
        }

        require(
            totalSupply() + mintAmount < MAX_MINT_SUPPLY,
            "Exceeds max mint supply"
        );

        if (mintAmount > 0) {
            _mint(msg.sender, mintAmount);

            if (userType == 0) {
                normalUserMintAddresses[msg.sender] = true;
                normalUserMintAddressList.push(msg.sender);
            } else if (userType == 1) {
                azukiMintAddresses[msg.sender] = true;
                azukiMintAddressList.push(msg.sender);
            } else if (userType == 2) {
                azukiElementlsMintAddresses[msg.sender] = true;
                azukiElementlsMintAddressList.push(msg.sender);
            }
        }
    }

    function mintRemainingTokens(address _to) public onlyOwner {
        require(mintingEnabled, "Minting is currently disabled");
        uint256 remainingSupply = MAX_TOTAL_SUPPLY - totalSupply();
        _mint(_to, remainingSupply);
    }

    function hasNFTToken(
        address tokenContractAddress,
        address _address
    ) internal view returns (bool) {
        return IERC721(tokenContractAddress).balanceOf(_address) > 0;
    }

    function setWhitelist(address[] memory _whitelist) public onlyOwner {
        require(
            _whitelist.length <= MAX_WHITELIST_SIZE,
            "Exceeds max whitelist size"
        );
        whitelist = _whitelist;
    }

    function isInWhitelist(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function hasMinted(address _address) public view returns (bool) {
        if (
            whitelistMintAddresses[_address] ||
            azukiElementlsMintAddresses[_address] ||
            azukiMintAddresses[_address] ||
            normalUserMintAddresses[_address]
        ) {
            return true;
        }
        return false;
    }

    function disableMinting() public onlyOwner {
        mintingEnabled = false;
    }
}