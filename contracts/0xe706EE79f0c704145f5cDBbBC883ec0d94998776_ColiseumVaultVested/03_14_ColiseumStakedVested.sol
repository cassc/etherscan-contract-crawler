//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ColiseumVaultVested.sol";

contract ColiseumStakedVested is ERC721, Ownable {
    using Strings for uint256;

    error NotAuthorized();

    ColiseumVaultVested public vault =
        ColiseumVaultVested(0x08244aC887bb5d8d689315ce6335D742350133E6);

    mapping(uint8 => string) public _baseTokenURI;

    mapping(address => bool) controllers;

    constructor() ERC721("Staked Vested Coliseum", "STAKED VESTED COLISEUM") {
        _baseTokenURI[
            0
        ] = "https://nftstorage.link/ipfs/bafybeicmujbwmughix2hbg2isn65e5jf5tdm6ddjnt5bxloqaifbe6e6gm/";

        _baseTokenURI[
            1
        ] = "https://nftstorage.link/ipfs/bafybeicqj42ycal4g55yzavp3pyok5ciwlcyp7w6pes2zwiatrosjamlr4/";

        _baseTokenURI[
            2
        ] = "https://nftstorage.link/ipfs/bafybeie5gtikboptrklm25jttgnwgei56hy6ubf3sgr3r7eesqkkoecexu/";

        _baseTokenURI[
            3
        ] = "https://nftstorage.link/ipfs/bafybeidqxebxc5y2hn5tg6q7rrrsxvczxz3sqc4sck2ktytba2tzhaogiq/";
    }

    function mint(address to, uint256 tokenId) public callerIsController {
        _safeMint(to, tokenId);
    }

    function setVaultContract(address _vault) external onlyOwner {
        vault = ColiseumVaultVested(_vault);
    }

    modifier callerIsController() {
        if (!controllers[msg.sender]) revert NotAuthorized();
        _;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function batchMint(
        address to,
        uint256[] calldata tokenIds
    ) external callerIsController {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mint(to, tokenIds[i]);
        }
    }

    function burn(uint256 tokenId) public callerIsController {
        _burn(tokenId);
    }

    function batchBurn(
        uint256[] calldata tokenIds
    ) external callerIsController {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _baseURI(
        uint256 tokenId
    ) internal view virtual returns (string memory) {
        return _baseTokenURI[vault.getLockOfToken(tokenId)];
    }

    function setBaseURI(
        string calldata baseURI,
        uint8 lock
    ) external onlyOwner {
        _baseTokenURI[lock] = baseURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override{
        require(
            controllers[msg.sender],
            "Staked Coliseum can not be transferred!"
        );
    }
}