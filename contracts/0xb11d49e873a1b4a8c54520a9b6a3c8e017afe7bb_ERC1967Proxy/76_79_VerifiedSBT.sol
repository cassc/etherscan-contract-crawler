// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IVerifiedSBT.sol";

contract VerifiedSBT is
    IVerifiedSBT,
    UUPSUpgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    address public override verifier;
    uint256 public override nextTokenId;
    string public override tokensURI;

    modifier onlyVerifier() {
        require(msg.sender == verifier, "VerifiedSBT: only verifier can call this function");
        _;
    }

    function __VerifiedSBT_init(
        address verifier_,
        string memory name_,
        string memory symbol_,
        string memory tokensURI_
    ) external override initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init();

        verifier = verifier_;
        tokensURI = tokensURI_;
    }

    function setVerifier(address newVerifier_) external override onlyOwner {
        verifier = newVerifier_;
    }

    function setTokensURI(string calldata newTokensURI_) external override onlyOwner {
        tokensURI = newTokensURI_;
    }

    function mint(address recipientAddr_) external override onlyVerifier {
        _mint(recipientAddr_, nextTokenId++);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return bytes(tokensURI).length > 0 ? tokensURI : "";
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal override {
        require(
            from_ == address(0) || to_ == address(0),
            "VerifiedSBT: token transfers are not allowed"
        );

        super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}