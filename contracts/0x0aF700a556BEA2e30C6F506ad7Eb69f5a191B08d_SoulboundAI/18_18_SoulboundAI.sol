// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SoulboundAI is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    uint256 public fee;
    uint256 private referralPercentage;

    // To start, only whitelisted users can mint
    bool public whitelistPeriod;
    mapping(address => bool) whitelist;

    event Referral(address referrer, bool sent);

    function initialize(
        uint256 _fee,
        uint256 _referralPercentage
    ) public initializer {
        __Ownable_init();
        __ERC721_init("SoulboundAI", "SBAI");

        fee = _fee;
        referralPercentage = _referralPercentage;
        whitelistPeriod = true;
    }

    function safeMint(address to) public payable {
        require(canMint(to), "User not whitelisted");
        require(msg.value >= fee, "Insufficient fee");
        require(balanceOf(to) == 0, "Only one SBT is allowed per user");

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeMintWithReferral(address to, address referrer) public payable {
        require(balanceOf(referrer) > 0, "Must have an SBT to refer others");

        uint256 referrerCut = (msg.value * referralPercentage) / 100;
        (bool sent, ) = referrer.call{value: referrerCut}("");
        emit Referral(referrer, sent);

        safeMint(to);
    }

    function canMint(address to) public view returns (bool) {
        if (whitelistPeriod) {
            return whitelist[to];
        }
        return true;
    }

    function burn() external {
        require(balanceOf(msg.sender) > 0, "No token to burn");
        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        require(
            from == address(0) || to == address(0),
            "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner."
        );

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _baseURI() internal view override returns (string memory) {
        if (block.chainid == 1) {
            return "https://soulbound-ai.com/api/token-metadata/";
        }

        if (block.chainid == 5) {
            return "https://soulbound-ai-goerli.vercel.app/api/token-metadata/";
        }

        if (block.chainid == 31337) {
            return "http://localhost:3000/api/token-metadata/";
        }

        revert("Invalid chain ID");
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        string memory owner = Strings.toHexString(uint160(ownerOf(tokenId)));

        return string(abi.encodePacked(baseURI, owner));
    }

    function withdrawFees(address payable recipient) external onlyOwner {
        (bool sent, ) = recipient.call{value: address(this).balance}("");

        require(sent, "Failed to transfer ether");
    }

    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function updateReferralPercentage(
        uint256 _referralPercentage
    ) external onlyOwner {
        referralPercentage = _referralPercentage;
    }

    function getReferralPercentage() external view returns (uint256) {
        return referralPercentage;
    }

    function updateWhitelist(address receiver, bool state) external onlyOwner {
        whitelist[receiver] = state;
    }

    function updateWhitelistPeriod(bool state) external onlyOwner {
        whitelistPeriod = state;
    }
}