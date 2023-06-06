//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721A.sol";

contract Ronin is ERC721A, Ownable {
    struct BurnedTokens {
        uint256 bushidoID;
        uint256 daitoID;
    }

    bool public sashimonoSaleActive = false;
    bool public publicSaleActive = false;

    string public tokenBaseURI;

    IERC721 public sashimonoContract;
    IERC721 public bushidoContract;
    IERC721 public daitoContract;

    address private DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping(address => bool) private teamAllowlist;
    mapping(uint256 => bool) public sashimonoUsed;
    mapping(uint256 => BurnedTokens) public tokensBurntForRonin;

    uint256 public MAX_MINT_PER_TXN = 3;
    uint256 public MAX_SUPPLY = 2000;

    constructor(
        string memory uri,
        address sashimonoAddress,
        address bushidoAddress,
        address daitoAddress
    ) ERC721A("Ronin", "RONIN") {
        tokenBaseURI = uri;
        sashimonoContract = IERC721(sashimonoAddress);
        bushidoContract = IERC721(bushidoAddress);
        daitoContract = IERC721(daitoAddress);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        tokenBaseURI = uri;
    }

    function toggleSashimonoSaleActive() external onlyOwner {
        sashimonoSaleActive = !sashimonoSaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        sashimonoSaleActive = false;
        publicSaleActive = !publicSaleActive;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTeamAllowlist(address addr, bool isAllowed) external onlyOwner {
        teamAllowlist[addr] = isAllowed;
    }

    function sashimonoMint(
        uint256[] calldata sashimonoIds,
        uint256[] calldata bushidoIds,
        uint256[] calldata daitoIds
    ) external payable {
        require(sashimonoSaleActive, "sashimono sale is not active");

        require(
            sashimonoIds.length > 0 &&
                bushidoIds.length > 0 &&
                daitoIds.length > 0,
            "must provide ids for all args"
        );
        require(
            sashimonoIds.length <= MAX_MINT_PER_TXN &&
                bushidoIds.length <= MAX_MINT_PER_TXN &&
                daitoIds.length <= MAX_MINT_PER_TXN,
            "max 3 mint"
        );
        require(
            sashimonoIds.length == bushidoIds.length &&
                bushidoIds.length == daitoIds.length,
            "must provide equal length arrays"
        );
        require(
            totalSupply() + sashimonoIds.length <= MAX_SUPPLY,
            "mint would exceed max supply."
        );

        for (uint256 i = 0; i < sashimonoIds.length; i++) {
            uint256 sashimonoId = sashimonoIds[i];
            uint256 bushidoId = bushidoIds[i];
            uint256 daitoId = daitoIds[i];

            require(
                sashimonoContract.ownerOf(sashimonoId) == msg.sender,
                "you are not the sashimono owner"
            );
            require(!sashimonoUsed[sashimonoId], "sashimono already used");

            require(
                bushidoContract.ownerOf(bushidoId) == msg.sender,
                "you are not the bushido owner"
            );
            require(
                bushidoContract.isApprovedForAll(msg.sender, address(this)),
                "bushido not approved"
            );

            require(
                daitoContract.ownerOf(daitoId) == msg.sender,
                "you are not the daito owner"
            );
            require(
                daitoContract.isApprovedForAll(msg.sender, address(this)),
                "daito not approved"
            );

            sashimonoUsed[sashimonoId] = true;

            bushidoContract.transferFrom(msg.sender, DEAD_ADDRESS, bushidoId);
            daitoContract.transferFrom(msg.sender, DEAD_ADDRESS, daitoId);

            tokensBurntForRonin[totalSupply() + i] = BurnedTokens(
                bushidoId,
                daitoId
            );
        }

        _safeMint(msg.sender, sashimonoIds.length);
    }

    function mint(uint256[] calldata bushidoIds, uint256[] calldata daitoIds)
        external
    {
        require(publicSaleActive, "public sale is not active");

        require(
            bushidoIds.length > 0 && daitoIds.length > 0,
            "must provide ids for all args"
        );
        require(
            bushidoIds.length <= MAX_MINT_PER_TXN &&
                daitoIds.length <= MAX_MINT_PER_TXN,
            "max 3 mint"
        );
        require(
            bushidoIds.length == daitoIds.length,
            "must provide equal length id arrays"
        );
        require(
            totalSupply() + bushidoIds.length <= MAX_SUPPLY,
            "mint would exceed max supply."
        );

        for (uint256 i = 0; i < bushidoIds.length; i++) {
            uint256 bushidoId = bushidoIds[i];
            uint256 daitoId = daitoIds[i];

            require(
                bushidoContract.ownerOf(bushidoId) == msg.sender,
                "you are not the bushido owner"
            );
            require(
                bushidoContract.isApprovedForAll(msg.sender, address(this)),
                "bushido not approved"
            );

            require(
                daitoContract.ownerOf(daitoId) == msg.sender,
                "you are not the daito owner"
            );
            require(
                daitoContract.isApprovedForAll(msg.sender, address(this)),
                "daito not approved"
            );

            bushidoContract.transferFrom(msg.sender, DEAD_ADDRESS, bushidoId);
            daitoContract.transferFrom(msg.sender, DEAD_ADDRESS, daitoId);

            tokensBurntForRonin[totalSupply() + i] = BurnedTokens(
                bushidoId,
                daitoId
            );
        }

        _safeMint(msg.sender, bushidoIds.length);
    }

    function teamMint(
        uint256[] calldata bushidoIds,
        uint256[] calldata daitoIds
    ) external {
        require(teamAllowlist[msg.sender], "address not in team allowlist");

        require(
            bushidoIds.length > 0 && daitoIds.length > 0,
            "must provide ids for all args"
        );
        require(
            bushidoIds.length <= MAX_MINT_PER_TXN &&
                daitoIds.length <= MAX_MINT_PER_TXN,
            "max 3 mint"
        );
        require(
            bushidoIds.length == daitoIds.length,
            "must provide equal length arrays"
        );
        require(
            totalSupply() + bushidoIds.length <= MAX_SUPPLY,
            "mint would exceed max supply."
        );

        for (uint256 i = 0; i < bushidoIds.length; i++) {
            uint256 bushidoId = bushidoIds[i];
            uint256 daitoId = daitoIds[i];

            require(
                bushidoContract.ownerOf(bushidoId) == msg.sender,
                "you are not the bushido owner"
            );
            require(
                bushidoContract.isApprovedForAll(msg.sender, address(this)),
                "bushido not approved"
            );

            require(
                daitoContract.ownerOf(daitoId) == msg.sender,
                "you are not the daito owner"
            );
            require(
                daitoContract.isApprovedForAll(msg.sender, address(this)),
                "daito not approved"
            );

            bushidoContract.transferFrom(msg.sender, DEAD_ADDRESS, bushidoId);
            daitoContract.transferFrom(msg.sender, DEAD_ADDRESS, daitoId);

            tokensBurntForRonin[totalSupply() + i] = BurnedTokens(
                bushidoId,
                daitoId
            );
        }

        _safeMint(msg.sender, bushidoIds.length);
    }
}