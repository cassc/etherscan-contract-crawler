// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./NFT/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IReferralHandler.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract MembershipNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(uint256 => address) public tokenMinter;
    address public admin;
    address public factory;

    modifier onlyFactory() {
        require(msg.sender == factory, "only factory");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only Admin");
        _;
    }

    constructor(address _factory) ERC721("Quota Membership NFT", "QuotaNFT") {
        admin = msg.sender;
        factory = _factory;
        _tokenIds.increment(); // Start Token IDs from 1 instead of 0, we use 0 to indicate absense of NFT on a wallet
    }

    function setAdmin(address account) public onlyAdmin {
        admin = account;
    }

    function setFactory(address account) public onlyAdmin {
        factory = account;
    }

    function issueNFT(
        address user,
        string memory tokenURI
    ) public onlyFactory returns (uint256) {
        uint256 newNFTId = _tokenIds.current();
        _mint(user, newNFTId);
        _setTokenURI(newNFTId, tokenURI);
        tokenMinter[newNFTId] = user;
        _tokenIds.increment();
        return newNFTId;
    }

    function changeURI(uint256 tokenID, string memory tokenURI) public {
        address handler = INFTFactory(factory).getHandler(tokenID);
        require(msg.sender == handler, "Only Handler can update Token's URI");
        _setTokenURI(tokenID, tokenURI);
    }

    function tier(uint256 tokenID) public view returns (uint256) {
        address handler = INFTFactory(factory).getHandler(tokenID);
        return IReferralHandler(handler).getTier();
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        INFTFactory(factory).registerUserEpoch(to); // Alerting NFT Factory to update incase of new user
        super._transfer(from, to, tokenId);
    }

    function getTransferLimit(uint256 tokenID) public view returns (uint256) {
        address handler = INFTFactory(factory).getHandler(tokenID);
        return IReferralHandler(handler).getTransferLimit();
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) public onlyAdmin {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(benefactor, tokenBalance);
    }
}