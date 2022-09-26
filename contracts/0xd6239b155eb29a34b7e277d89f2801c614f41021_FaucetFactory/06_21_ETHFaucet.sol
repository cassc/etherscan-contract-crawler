// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFaucet.sol";
import "./strategies/IFaucetStrategy.sol";
import {IFaucetMetadataRenderer} from "./renderer/IFaucetMetadataRenderer.sol";

contract ETHFaucet is IFaucet, ERC721Upgradeable {
    uint256 public totalSupply;
    uint256 mintCounter;
    mapping(uint256 => FaucetDetails) internal faucetDetailsForToken;
    mapping(uint256 => uint256) public claimedAmountForToken;
    IFaucetMetadataRenderer public immutable metadataRenderer;

    constructor(IFaucetMetadataRenderer _metadataRenderer) {
        metadataRenderer = _metadataRenderer;
    }

    /// @param _name The name of this Faucet
    /// @param _symbol The token symbol of this Faucet
    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC721_init(_name, _symbol);
    }

    /// @dev See {IFaucet-getFaucetDetailsForToken}
    function getFaucetDetailsForToken(uint256 _tokenId) external view returns (FaucetDetails memory) {
        return faucetDetailsForToken[_tokenId];
    }

    /// @dev See {IFaucet-faucetTokenAddress}
    function faucetTokenAddress() external pure returns (address) {
        return address(0);
    }

    /// @dev See {IFaucet-claimableAmountForFaucet}
    function claimableAmountForFaucet(uint256 _tokenID, uint256 _timestamp) public view returns (uint256) {
        FaucetDetails memory faucetDetails = faucetDetailsForToken[_tokenID];

        uint256 totalClaimableAmount = IFaucetStrategy(faucetDetails.faucetStrategy).claimableAtTimestamp(
            faucetDetails.totalAmount,
            faucetDetails.faucetStart,
            faucetDetails.faucetExpiry,
            _timestamp
        );

        if (totalClaimableAmount > faucetDetails.totalAmount) revert ClaimableOverflow(totalClaimableAmount, faucetDetails.totalAmount);

        return totalClaimableAmount - claimedAmountForToken[_tokenID];
    }

    /// @dev See {IFaucet-mint}
    function mint(
        address _to,
        uint256 _amt,
        uint256 _faucetDuration,
        address _faucetStrategy,
        bool _canBeRescinded
    ) external payable returns (uint256) {
        if (msg.value != _amt) revert MintValueMismatch(msg.value, _amt);
        if (_amt == 0) revert MintNoValue();
        if (_faucetDuration == 0) revert MintNoDuration();
        if (!IFaucetStrategy(_faucetStrategy).supportsInterface(type(IFaucetStrategy).interfaceId)) revert MintInvalidStrategy(_faucetStrategy);

        uint256 tokenId = mintCounter;

        _mint(_to, tokenId);
        faucetDetailsForToken[tokenId] = FaucetDetails({
            totalAmount: _amt,
            claimedAmount: 0,
            faucetStart: block.timestamp,
            faucetExpiry: block.timestamp + _faucetDuration,
            faucetStrategy: _faucetStrategy,
            supplier: msg.sender,
            canBeRescinded: _canBeRescinded
        });

        totalSupply++;
        mintCounter++;
        return tokenId;
    }

    /// @dev See {IFaucet-claim}
    function claim(address _to, uint256 _tokenID) external {
        if (msg.sender != ownerOf(_tokenID)) revert OnlyOwner(msg.sender, ownerOf(_tokenID));
        uint256 claimable = claimableAmountForFaucet(_tokenID, block.timestamp);
        _to.call{value: claimable}("");
        claimedAmountForToken[_tokenID] += claimable;

        if (claimedAmountForToken[_tokenID] == faucetDetailsForToken[_tokenID].totalAmount) {
            _burn(_tokenID);
        }
    }

    /// @dev See {IFaucet-rescind}
    function rescind(address _remainingTokenDest, uint256 _tokenID) external {
        if (msg.sender != faucetDetailsForToken[_tokenID].supplier) revert OnlySupplier(msg.sender, faucetDetailsForToken[_tokenID].supplier);
        if (!faucetDetailsForToken[_tokenID].canBeRescinded) revert RescindUnrescindable();

        FaucetDetails memory faucetDetails = faucetDetailsForToken[_tokenID];

        _remainingTokenDest.call{value: faucetDetails.totalAmount - claimedAmountForToken[_tokenID]}("");

        _burn(_tokenID);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert FaucetDoesNotExist();

        FaucetDetails memory fd = faucetDetailsForToken[_tokenId];

        return metadataRenderer.getTokenURIForFaucet(address(this), _tokenId, fd);
    }

    function _burn(uint256 _tokenID) internal override {
        super._burn(_tokenID);
        totalSupply--;
        delete faucetDetailsForToken[_tokenID];
        delete claimedAmountForToken[_tokenID];
    }
}