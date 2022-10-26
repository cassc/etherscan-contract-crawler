// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IOTMintBonus {
    function mintBonus(address to, uint256 numTokens) external;
}

contract LombokKidz is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_ART_SETS = 256;
    uint256 private constant MAX_PER_MINT = 20;

    // Reserve
    uint256 public reserved = 100;
    event ReserveReduced(uint256 amount);

    // Sale
    bool public isSaleActive;

    // Art sets
    struct ArtSetDetail {
        string cid;
        uint256 price;
    }
    uint256[] private artSets;
    mapping(uint256 => ArtSetDetail) public artSetDetails;

    // $OPENTOWN
    IOTMintBonus public otNFTBonusIssuerContract;

    // Wallets
    address payable public sssWallet;
    address payable public artistWallet;
    address payable public devWallet;

    constructor(address addr) ERC721("Lombok Kidz", "LK") {
        require(addr != address(0), "Invalid address");
        otNFTBonusIssuerContract = IOTMintBonus(addr);
    }

    // Art sets
    function getArtSets() external view returns (uint256[] memory) {
        return artSets;
    }

    function addArtSet(uint256 lastTokenId) external onlyOwner {
        require(artSets.length < MAX_ART_SETS, "Art set count exceeded");
        require(lastTokenId <= MAX_SUPPLY, "Token ID exceeds max supply");

        if (artSets.length > 0) {
            require(
                lastTokenId > artSets[artSets.length - 1],
                "Token ID belongs to existing set"
            );
            require(
                bytes(artSetDetails[artSets.length - 1].cid).length > 0,
                "Previous art set detail undefined"
            );
            require(
                totalSupply() == artSets[artSets.length - 1],
                "Previous art set has unminted tokens"
            );
        }

        artSets.push(lastTokenId);
    }

    function setArtSetDetail(string calldata baseURI, uint256 price)
        external
        onlyOwner
    {
        require(artSets.length > 0, "No art sets are defined");
        artSetDetails[artSets.length - 1] = ArtSetDetail(baseURI, price);
    }

    // ERC721Metadata
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        (, uint256 artSetId) = artSetIdForTokenId(tokenId);

        ArtSetDetail memory artSetDetail = artSetDetails[artSetId];
        string memory collectionBaseURI = _baseURI();
        string memory artSetCID = artSetDetail.cid;

        return
            bytes(collectionBaseURI).length > 0 && bytes(artSetCID).length > 0
                ? string(
                    abi.encodePacked(
                        collectionBaseURI,
                        artSetCID,
                        "/",
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    // Reserve
    function reserve(address[] calldata addrs, uint256 amountPerAddr)
        external
        onlyOwner
    {
        uint256 totalAmount = addrs.length * amountPerAddr;
        require(totalAmount > 0, "Need at least 1 token");
        require(totalAmount <= MAX_PER_MINT, "20 tokens per call max");
        require(totalAmount <= reserved, "Exceeds reserved supply");

        uint256 supply = totalSupply();
        (bool isArtSetFound, uint256 artSetId) = artSetIdForTokenId(supply + 1);
        require(isArtSetFound, "Art set not found");
        require(
            supply + totalAmount <= artSets[artSetId],
            "Exceeds art set supply"
        );

        reserved -= totalAmount;
        emit ReserveReduced(totalAmount);

        for (uint256 i = 0; i < addrs.length; i++) {
            require(addrs[i] != address(0), "Invalid address");
            supply = totalSupply();

            for (uint256 j = 1; j <= amountPerAddr; j++) {
                _safeMint(addrs[i], supply + j);
            }
            otNFTBonusIssuerContract.mintBonus(addrs[i], amountPerAddr);
        }
    }

    // Sale
    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function mint(address to, uint256 mintAmount) external payable {
        require(isSaleActive, "Sale is not active");
        require(to != address(0), "Invalid address");
        require(mintAmount > 0, "Need at least 1 token");
        require(mintAmount <= MAX_PER_MINT, "20 tokens per call max");

        uint256 supply = totalSupply();
        require(
            supply + mintAmount <= MAX_SUPPLY - reserved,
            "Exceeds maximum supply"
        );

        (bool isArtSetFound, uint256 artSetId) = artSetIdForTokenId(supply + 1);
        require(isArtSetFound, "Art set not found");
        require(
            supply + mintAmount <= artSets[artSetId],
            "Exceeds art set supply"
        );

        uint256 price = artSetDetails[artSetId].price;
        require(price > 0, "Art set price not defined");
        require(msg.value >= price * mintAmount, "Incorrect Ether amount");

        for (uint256 i = 1; i <= mintAmount; i++) {
            _safeMint(to, supply + i);
        }
        otNFTBonusIssuerContract.mintBonus(to, mintAmount);
    }

    // $OPENTOWN
    function setOTNFTBonusIssuerContract(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        otNFTBonusIssuerContract = IOTMintBonus(addr);
    }

    // Wallets
    function setSSSWallet(address payable addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        sssWallet = addr;
    }

    function setArtistWallet(address payable addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        artistWallet = addr;
    }

    function setDevWallet(address payable addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        devWallet = addr;
    }

    function withdraw() external onlyOwner {
        require(sssWallet != address(0), "SSS address not set");
        require(artistWallet != address(0), "Artist address not set");
        require(devWallet != address(0), "Dev address not set");

        uint256 sssPart = (address(this).balance * 60) / 100;
        uint256 artistPart = (address(this).balance * 10) / 100;

        // Send 60% of funds to SSS
        (bool sssSuccess, ) = sssWallet.call{value: sssPart}("");
        require(sssSuccess, "Failed to send Ether to SSS");

        // Send 10% of funds to the artist
        (bool artistSuccess, ) = artistWallet.call{value: artistPart}("");
        require(artistSuccess, "Failed to send Ether to Artist");

        // Send the other 30% to developer
        (bool devSuccess, ) = devWallet.call{value: address(this).balance}("");
        require(devSuccess, "Failed to send Ether to dev");
    }

    // Utilities
    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function artSetIdForTokenId(uint256 tokenId)
        internal
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < artSets.length; i++) {
            if (tokenId <= artSets[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}