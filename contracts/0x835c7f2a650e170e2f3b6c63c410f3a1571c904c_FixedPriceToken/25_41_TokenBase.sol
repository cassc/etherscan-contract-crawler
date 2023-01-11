// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IToken} from "./tokens/interfaces/IToken.sol";
import {IObservability} from "./observability/Observability.sol";
import {UUPS} from "./lib/proxy/UUPS.sol";
import {ITokenFactory} from "./interfaces/ITokenFactory.sol";
import {VersionedContract} from "./VersionedContract.sol";

abstract contract TokenBase is
    IToken,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    VersionedContract,
    UUPS
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(uint256 => bytes32) public tokenIdToPreviousBlockHash;
    mapping(address => bool) public allowedMinters;

    address public immutable factory;
    address public immutable o11y;
    uint256 internal immutable FUNDS_SEND_GAS_LIMIT = 210_000;

    TokenInfo public tokenInfo;

    //[[[[MODIFIERS]]]]
    /// @notice restricts to only users with minter role
    modifier onlyAllowedMinter() {
        if (!allowedMinters[msg.sender]) revert SenderNotMinter();
        _;
    }

    //[[[[SETUP FUNCTIONS]]]]

    constructor(address _factory, address _o11y) {
        factory = _factory;
        o11y = _o11y;
    }

    //[[[[VIEW FUNCTIONS]]]]

    /// @notice gets the total supply of tokens
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    //[[[[WITHDRAW FUNCTIONS]]]]

    /// @notice withdraws the funds from the contract
    function withdraw() external nonReentrant returns (bool) {
        uint256 amount = address(this).balance;

        (bool successFunds, ) = tokenInfo.fundsRecipent.call{
            value: amount,
            gas: FUNDS_SEND_GAS_LIMIT
        }("");

        if (!successFunds) revert FundsSendFailure();

        IObservability(o11y).emitFundsWithdrawn(
            msg.sender,
            tokenInfo.fundsRecipent,
            amount
        );
        return successFunds;
    }

    /// @notice sets the funds recipent for token funds
    function setFundsRecipent(address fundsRecipent) external onlyOwner {
        tokenInfo.fundsRecipent = fundsRecipent;
    }

    //[[[[MINT FUNCTIONS]]]]

    /// @notice sets the minter role for the given user
    function setMinter(address user, bool isAllowed) public onlyOwner {
        allowedMinters[user] = isAllowed;
    }

    /// @notice mint a token for the given address
    function safeMint(address to) public onlyAllowedMinter {
        if (totalSupply() >= tokenInfo.maxSupply) revert MaxSupplyReached();
        _seedAndMint(to);
    }

    //[[[[PRIVATE FUNCTIONS]]]]

    /// @notice seeds the token id and mints the token
    function _seedAndMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();

        tokenIdToPreviousBlockHash[tokenId] = blockhash(block.number - 1);

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /// @notice checks if an upgrade is valid
    function _authorizeUpgrade(address newImpl) internal override onlyOwner {
        if (
            !ITokenFactory(factory).isValidUpgrade(
                _getImplementation(),
                newImpl
            )
        ) {
            revert ITokenFactory.InvalidUpgrade(newImpl);
        }
    }
}