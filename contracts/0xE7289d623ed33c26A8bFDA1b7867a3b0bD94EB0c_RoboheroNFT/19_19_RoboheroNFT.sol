// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract RoboheroNFT is
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable,
    EIP712Upgradeable,
    OwnableUpgradeable
{
    using StringsUpgradeable for uint256;

    bytes32 public constant MINT_TYPEHASH =
        keccak256("Mint(address to,uint256 tokenId)");

    function initialize() public initializer {
        __EIP712_init("RoboHero Genesis NFT", "1");
        __ERC721_init("RoboHero Genesis NFT", "ROBOGEN");
        __Ownable_init();
        _setDefaultRoyalty(owner(), 500);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://xvrm.parlour.construction/robo/";
    }

    function claimToken(
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(abi.encode(MINT_TYPEHASH, msg.sender, tokenId))
            );
        address signer = ECDSAUpgradeable.recover(digest, v, r, s);
        require(signer == owner(), "Invalid signature");
        require(!_exists(tokenId), "Token already minted");

        _safeMint(msg.sender, tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function contractURI() public pure returns (string memory) {
        return "https://xvrm.parlour.construction/robo/contract.json";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}