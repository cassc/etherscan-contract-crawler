// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ImmoCryptoGenesis
/// @author Unblocked
/// @notice an ERC1155 contract that allows users to mint NFT tokens using a specified USDC token as payment.
/// It has a maximum supply of 5220 tokens, and each token is priced at 100USDC tokens.

contract ImmoCryptoGenesis is ERC1155, Ownable {

    string public constant name = "NFT PRE SALE IMMO CRYPTO";
    string public constant symbol = "IMMO CRYPTO";
    uint256 public constant TOKEN_PRICE = 100 ether;
    uint256 public constant MINT_LIMIT = 10;
    address public constant TEAM_WALLET =
        0xc8E10bB9eF9D9Bc8e7BaFeD869D6C5074E276821;
    address public constant AIRDROP_WALLET =
        0xd854E3ef756E3571D36F6A377DEFd254fdaf9743;
    uint256 public constant MAX_SUPPLY = 5220;
    uint256 private constant TOKEN_ID = 0;
    uint256 public constant START_DATE = 1677517200;
    IERC20 public constant TOKEN =
        IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);

    uint256 public supply;

    event Minted(address indexed _owner, uint256 _NFTAmount);

    /// @dev Modifier to check the conditions before minting NFT.
    /// @param _NFTAmount The amount of NFT tokens to be minted.
    /// @param _tokenamount The amount of USDC sent as payment for the NFT tokens.
    modifier checkBeforeMint(uint256 _NFTAmount, uint256 _tokenamount) {
        require(block.timestamp >= START_DATE, "Drop not started yet");
        require(_NFTAmount <= MINT_LIMIT && _NFTAmount > 0, "Wrong NFT amount");
        require(supply + _NFTAmount <= MAX_SUPPLY, "Token supply insufisent");
        uint256 total = TOKEN_PRICE * _NFTAmount;
        require(_tokenamount == total, "Token amount insufisent");
        require(
            TOKEN.allowance(msg.sender, address(this)) >= total,
            "Token not approved"
        );
        _;
    }

    /// @dev The constructor mints tokens to the team and airdrop wallets, and sets the URI for the contract.
    /// @param _uri The URI for the contract.
    constructor(string memory _uri) ERC1155(_uri) {
        _mint(TEAM_WALLET, TOKEN_ID, 200, "");
        supply += 200;
        _mint(AIRDROP_WALLET, TOKEN_ID, 20, "");
        supply += 20;
    }

    /// @dev Allows users to mint NFT tokens using ERC20 tokens as payment.
    /// @param _NFTAmount The amount of NFT tokens to be minted.
    /// @param _tokenamount The amount of ERC20 tokens sent as payment for the NFT tokens.
    function mintNFT(uint256 _NFTAmount, uint256 _tokenamount)
        public
        checkBeforeMint(_NFTAmount, _tokenamount)
    {
        TOKEN.transferFrom(msg.sender, address(this), _tokenamount);
        _mint(msg.sender, TOKEN_ID, _NFTAmount, "");
        supply += _NFTAmount;
        emit Minted(msg.sender, _NFTAmount);
    }

    /// @dev Allows Admin change the URI
    /// @param newuri The new URI to set.
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @dev Allows Admin to withdraw the token balance of the smart contract
    function withdraw() public onlyOwner {
        uint256 amount = TOKEN.balanceOf(address(this));
        TOKEN.transfer(msg.sender, amount);
    }

}