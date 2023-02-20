// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/common/ERC2981.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract MintedVersePlanets is ERC721, ERC721Enumerable, ERC2981, Ownable, DefaultOperatorFilterer {
    uint256 public MINT_PRICE;
    bool public PUBLIC_MINT_ENABLED;
    bool public PUBLIC_MINT_NOTVISITING_ENABLED;
    string internal BASE_URI;
    uint256 public MAX_COLLECTION_SIZE;
    uint256 public NUM_MT_PLANETS;
    address public MINTED_TEDDY_CONTRACT; // a list of NFTs that have been approved.. will only include contracts allowed to use MintedVerse planets
    address public treasuryAddress;
    mapping(address => bool) private _approvedContracts; // a list of NFTs that have been approved.. will only include contracts allowed to use MintedVerse planets
    mapping(uint256 => mapping(string => bool)) private _planetCurrentVisitors; // all currently visiting nft's
    mapping(uint256 => mapping(uint256 => string)) private _planetAllVisitors; // all nft's that have ever visited.
    mapping(string => uint256) private _visitorCurrentPlanet; // the planet a teddy currently is visiting
    mapping(uint256 => uint256) private _planetNumVisitors; // the count of number of visitors that have ever visited the planet (including repeat visitors)

    // set up events to be emitted
    event MintPriceChanged(uint256 mintPrice);
    event MaxCollectionSizeChanged(uint256 maxCollectionSize);
    event NumMTPlanetsChanged(uint256 numMTPlanets);
    event BaseURIChanged(string baseURI);
    event PublicMintEnabledChanged(bool publicMintEnabled);
    event PublicMintNotVisitingEnabledChanged(bool publicMintNotVisitingEnabled);
    event VisitPlanet(uint256 planetId, address contractAddress, uint256 tokenId);
    event RoyaltyInfoChanged(uint96 royalty);
    event TreasuryAddressChanged(address treasuryAddress);

    constructor() ERC721("Minted Teddy Planets", "PLANET") {
        BASE_URI = "ipfs://";
        MAX_COLLECTION_SIZE = 50;
        MINT_PRICE = 2 ether;
        PUBLIC_MINT_ENABLED = false;
        PUBLIC_MINT_NOTVISITING_ENABLED = true;
        NUM_MT_PLANETS = 4;
        treasuryAddress = msg.sender;

        _setDefaultRoyalty(treasuryAddress, 500);
    }

    // allow the public to mint a planet
    function mintPlanetNV(address to, uint256 planetId) public payable {
        require(PUBLIC_MINT_NOTVISITING_ENABLED, "The public mint from  period has not started.");
        require(msg.value == MINT_PRICE, "Not enough ETH sent, check price");
        require(planetId >= 1 && planetId <= MAX_COLLECTION_SIZE, "Invalid Planet ID");
        _safeMint(to, planetId);
    }

    // allow the public to mint a planet
    function mintPlanet(address to, uint256 planetId, address contractId, uint256 tokenId) public payable {
        require(PUBLIC_MINT_ENABLED, "The public mint period has not started.");
        require(msg.value == MINT_PRICE, "Not enough ETH sent, check price");
        require(planetId >= 1 && planetId <= MAX_COLLECTION_SIZE, "Invalid Planet ID");
        require(ERC721(contractId).ownerOf(tokenId) == to, "You aren't the owner of the visitor");
        require(_approvedContracts[contractId], "This is not an approved NFT.");
        require(
            _visitorCurrentPlanet[getTokenKey(contractId, tokenId)] == planetId,
            "You must be visiting this planet to mint it."
        );
        _safeMint(to, planetId);
    }

    // allow the admin to mint a planet on behalf of a recipient
    function adminMint(address to, uint256 planetId) external onlyOwner {
        require(planetId >= 1 && planetId <= MAX_COLLECTION_SIZE, "Invalid Planet ID");
        _safeMint(to, planetId);
    }

    // Allow Minted Teddy to mint special MT planets that are to be used for Minted Teddy special projects.
    function adminMintMT(address to, uint256 planetId) external onlyOwner {
        require(
            planetId > MAX_COLLECTION_SIZE && planetId <= MAX_COLLECTION_SIZE + NUM_MT_PLANETS,
            "Invalid Planet ID"
        );
        _safeMint(to, planetId);
    }

    function setMintPrice(uint256 mintPrice) external onlyOwner {
        require(mintPrice != 0, "Should be a positive integer");
        MINT_PRICE = mintPrice;
        emit MintPriceChanged(MINT_PRICE);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
        emit BaseURIChanged(BASE_URI);
    }

    function setPublicMintEnabled(bool publicMintEnabled) external onlyOwner {
        PUBLIC_MINT_ENABLED = publicMintEnabled;
        emit PublicMintEnabledChanged(publicMintEnabled);
    }

    function setPublicMintNotVisitingEnabled(bool publicMintNotVisitingEnabled) external onlyOwner {
        PUBLIC_MINT_NOTVISITING_ENABLED = publicMintNotVisitingEnabled;
        emit PublicMintNotVisitingEnabledChanged(publicMintNotVisitingEnabled);
    }

    // allow the owner of an nft, or the mintedverse teddies contract, visit a planet
    function setVisiting(uint256 planetId, address contractAddress, uint256 tokenId) external {
        string memory tokenKey = getTokenKey(contractAddress, tokenId);

        require(
            ERC721(contractAddress).ownerOf(tokenId) == msg.sender || msg.sender == MINTED_TEDDY_CONTRACT,
            "You aren't the owner of the visitor"
        );

        // set the tokenKey's current planet visiting status to false (leave current planet)
        if (_planetCurrentVisitors[_visitorCurrentPlanet[tokenKey]][tokenKey]) {
            _planetCurrentVisitors[_visitorCurrentPlanet[tokenKey]][tokenKey] = false;
        }

        // set the tokenKey's current planet to planetId
        _visitorCurrentPlanet[tokenKey] = planetId;

        // add the tokenKey to the list of current visitors to planetId
        _planetCurrentVisitors[planetId][tokenKey] = true;

        // increment the total number of visitors
        _planetNumVisitors[planetId] = _planetNumVisitors[planetId] + 1;

        // record that this tokenKey has visited planetId (guest book)
        _planetAllVisitors[planetId][_planetNumVisitors[_visitorCurrentPlanet[tokenKey]]] = tokenKey;

        // emit event after planet visited.
        emit VisitPlanet(planetId, contractAddress, tokenId);
    }

    // allow admin to send an NFT to a planet
    function setVisitingAdmin(uint256 planetId, address contractAddress, uint256 tokenId) external onlyOwner {
        string memory tokenKey = getTokenKey(contractAddress, tokenId);

        // set the tokenKey's current planet visiting status to false (leave current planet)
        if (_planetCurrentVisitors[_visitorCurrentPlanet[tokenKey]][tokenKey]) {
            _planetCurrentVisitors[_visitorCurrentPlanet[tokenKey]][tokenKey] = false;
        }

        // set the tokenKey's current planet to planetId
        _visitorCurrentPlanet[tokenKey] = planetId;

        // add the tokenKey to the list of current visitors to planetId
        _planetCurrentVisitors[planetId][tokenKey] = true;

        // increment the total number of visitors
        _planetNumVisitors[planetId] = _planetNumVisitors[planetId] + 1;

        // record that this tokenKey has visited planetId (guest book)
        _planetAllVisitors[planetId][_planetNumVisitors[_visitorCurrentPlanet[tokenKey]]] = tokenKey;

        // emit event after planet visited.
        emit VisitPlanet(planetId, contractAddress, tokenId);
    }

    function setMintedTeddyContract(address contractAddress) public onlyOwner {
        MINTED_TEDDY_CONTRACT = contractAddress;
    }

    // set contract as approved
    function approveContract(address contractAddress, bool isApproved) external onlyOwner {
        _approvedContracts[contractAddress] = isApproved;
    }

    /// @notice This will transfer all ETH from the smart contract to the contract owner.
    function withdraw() external onlyOwner {
        payable(treasuryAddress).transfer(address(this).balance);
    }

    // the max number of planets that will be mintable
    function setMaxCollectionSize(uint256 maxCollectionSize) external onlyOwner {
        require(maxCollectionSize != 0, "Should be a positive integer");
        MAX_COLLECTION_SIZE = maxCollectionSize;
        emit MaxCollectionSizeChanged(MAX_COLLECTION_SIZE);
    }

    // max number of special reserved planets for minted teddy.  teddies that are minted
    // will not automatically be assigned to these planets.
    function setNumMTPlanets(uint256 numMtPlanets) external onlyOwner {
        require(numMtPlanets != 0, "Should be a positive integer");
        NUM_MT_PLANETS = numMtPlanets;
        emit NumMTPlanetsChanged(numMtPlanets);
    }

    // This sets the planet contract that will be used to keep track of teddy visitors.
    function setDefaultRoyalty(uint96 defaultRoyalty) external onlyOwner {
        require(defaultRoyalty > 0, "Default royalty must not be negative.");
        _setDefaultRoyalty(msg.sender, defaultRoyalty);

        // emit event when planet contract is changed.
        emit RoyaltyInfoChanged(defaultRoyalty);
    }

    // This sets the planet contract that will be used to keep track of teddy visitors.
    function setTreasuryAddress(address treasury) external onlyOwner {
        require(treasuryAddress != address(0), "This must be a valid address.");
        treasuryAddress = treasury;

        // emit event when planet contract is changed.
        emit TreasuryAddressChanged(treasuryAddress);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return string(abi.encodePacked(BASE_URI, Strings.toString(tokenId)));
    }

    // Check whether an NFT is visiting a specific planet
    function isVisiting(uint256 planetId, address contractAddress, uint256 tokenId) external view returns (bool) {
        string memory tokenKey = getTokenKey(contractAddress, tokenId);
        return _planetCurrentVisitors[planetId][tokenKey] == true;
    }

    // Check if an nft has ever visted a planet
    function hasVisited(uint256 planetId, address contractAddress, uint256 tokenId) external view returns (bool) {
        string memory tokenKey = getTokenKey(contractAddress, tokenId);
        for (uint256 i = 0; i < _planetNumVisitors[planetId]; i++) {
            if (keccak256(bytes(_planetAllVisitors[planetId][i])) == keccak256(bytes(tokenKey))) {
                return true;
            }
        }
        return false;
    }

    // Get all the current visitors of a planet
    function getAllPlanetVisitors(uint256 planetId) external view returns (bytes32[] memory) {
        bytes32[] memory ret = new bytes32[](_planetNumVisitors[planetId]);
        uint256 j = 0;
        for (uint256 i = 0; i < _planetNumVisitors[planetId]; i++) {
            if (_planetCurrentVisitors[planetId][_planetAllVisitors[planetId][i]] == true) {
                ret[j] = keccak256(bytes(_planetAllVisitors[planetId][i]));
                j++;
            }
        }
        return ret;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    // create a unique string consisting of a contract address + token id
    function getTokenKey(address contractAddress, uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(contractAddress, "|", Strings.toString(tokenId)));
    }
}