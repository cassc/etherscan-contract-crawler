// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

// PERSISTENCE ALONE IS OMNIPOTENT!

// S: CHIPAPIMONANO
// A: EMPATHETIC
// F: Pex-Pef
// E: ETHICAL

// The NFT was minted on CreatiVerse, https://nft.protoverse.ai/.
// Visit the dApp, click "MY NFTs," and connect your wallet to see the art.

// ABOUT CREATIVERSE
// CreatiVerse is a complete, “any-currency” NFT mintpad
// and management platform. It provides creators with sophisticated
// tools to mint, monetize, and fairly distribute NFTs.
// The platform also empowers users with automated
// peer-to-peer NFT scholarships and fixed rental escrows.

// ABOUT PROTOVERSE
// ProtoVerse fulfills projects’ wildest
// NFT and Play-To-Earn game development dreams.

// ProtoVerse’s dApps are custom-built in-house and
// certified by CertiK to ensure the utmost privacy, transparency, and security.
// They can be offered cost-effectively as whitelabel solutions to any qualified project.

// Website: ProtoVerse.ai

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @custom:security-contact [email protected]
contract ProtoVerseGenesisCollection is ERC721, ERC721URIStorage {
    address public dao;
    address public creativerse;
    string public baseUri = "https://ipfs.io/ipfs/";

    modifier onlyDAO() {
        require(msg.sender == dao, "E001");
        _;
    }

    constructor(address _dao, address _creativerse)
        ERC721("ProtoVerse Genesis Collection", "PVR")
    {
        dao = _dao;
        creativerse = _creativerse;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function safeMint(
        address to,
        uint256 newTokenId,
        string calldata uri
    ) external {
        require(msg.sender == creativerse, "E002");
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, uri);
    }

    function withdraw(address token, uint256 amount) external onlyDAO {
        if (token == address(0)) {
            payable(dao).transfer(amount);
        } else {
            IERC20(token).transfer(dao, amount);
        }
    }

    function setBaseURI(string calldata _baseUri) external onlyDAO {
        baseUri = _baseUri;
    }

    function setCreatiVerse(address _creativerse) external onlyDAO {
        creativerse = _creativerse;
    }

    function setDAO(address _dao) external onlyDAO {
        dao = _dao;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}

// Error codes
// E001 - Only DAO can perform this action
// E002 - Only Creativerse can mint NFTs