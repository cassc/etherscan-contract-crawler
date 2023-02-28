// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Bytes.sol";

contract BattlePass is ERC721Royalty, Ownable {
    uint256 public constant MAX_SUPPLY = 999;

    string tokenBaseURI;

    uint256 public totalSupply = 0;

    address imx;

    modifier isMinter() {
        require(msg.sender == imx || msg.sender == owner(), "NOT AUTHORIZED");
        _;
    }

    constructor(
        address _imx,
        address royaltyReceiver,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        imx = _imx;
        _setDefaultRoyalty(royaltyReceiver, 250);
    }

    event AssetMinted(address indexed to, uint256 indexed tokenId, bytes blueprint);

    function mintFor(
        address to,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external isMinter {
        require(totalSupply < MAX_SUPPLY && quantity == 1, "SUPPLY_EXCEEDS");

        totalSupply += 1;

        uint256 _tokenId = getTokenId(mintingBlob);

        super._safeMint(to, _tokenId);

        emit AssetMinted(to, _tokenId, mintingBlob);
    }

    function getTokenId(bytes calldata blob) internal pure returns (uint256) {
        int256 colonIndex = Bytes.indexOf(blob, ":", 0);

        require(colonIndex >= 0, "Separator must exist");

        return Bytes.toUint(blob[1:uint256(colonIndex) - 1]);
    }

    function updateBaseUri(string memory baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}