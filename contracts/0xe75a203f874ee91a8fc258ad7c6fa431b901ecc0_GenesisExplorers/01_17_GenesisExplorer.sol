// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Base64.sol";
import "./Helpers.sol";

contract GenesisExplorers is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter;

    event GenesisExplorerSummoned(
        address indexed from,
        uint256 indexed tokenId
    );

    // Stop mint in case of emergency / contract migration
    bool public emergencyStop = false;

    address public immutable gaAddress;
    address public immutable leAddress;

    uint256 public immutable freeGenesisExplorers;
    uint256 public mintPrice = 0.1 ether;

    // Pre-revealed baseUri
    string private _baseURIextended =
        "ipfs://bafybeihdjg7sc5qqo5a755ut2laq5qafnvhhjtjvam5iyzolagqwiq6aty/metadata/";

    // Address that is allowed to setTokenURI()
    address private metadataUpdaterAddress;

    constructor(
        address _gaAddress,
        address _leAddress,
        address _newOwner,
        address _metadataUpdaterAddress,
        uint256 _freeGenesisExplorers
    ) ERC721("GenesisExplorers", "GEXPLRS") {
        gaAddress = _gaAddress;
        leAddress = _leAddress;
        metadataUpdaterAddress = _metadataUpdaterAddress;
        freeGenesisExplorers = _freeGenesisExplorers;

        transferOwnership(_newOwner);
    }

    // ========================
    //     PUBLIC FUNCTIONS
    // ========================
    function totalSupply() public view returns (uint256) {
        return tokenCounter.current();
    }

    function price() public view returns (uint256){
        // First 600 mint is free. Every subsequent mint cost 0.1 ETH
        return totalSupply() < freeGenesisExplorers ? 0 ether : mintPrice;
    }

    modifier canMintGenesisExplorer(uint256 _tokenId, uint256[3] calldata _leTokenIds) {
        require(!emergencyStop, "Emergency Stop!");
        require(msg.value == price(), "Ether value sent is not correct");
        require(
            IERC721(gaAddress).ownerOf(_tokenId) ==
                msg.sender,
            "You don't own this!"
        );
        for (uint8 i = 0; i < 3; i++) {
            require(
                IERC721(leAddress).ownerOf(_leTokenIds[i]) == 
                    msg.sender, 
                "You don't own the Loot Explorers!");
        }
        _;
    }

    modifier canSetBaseURI() {
        require(
            (msg.sender == metadataUpdaterAddress) || (msg.sender == owner()),
            "Only owner or metadata updater can set tokenURI"
        );
        _;
    }

    // =========================
    //      UPDATE BASE URI
    // =========================
    function setBaseURI(string memory baseURI) public canSetBaseURI {
        _baseURIextended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mintGenesisExplorer(uint256 _tokenId, uint256[3] calldata _leTokenIds)
        public
        payable
        nonReentrant
        canMintGenesisExplorer(_tokenId, _leTokenIds)
    {
        _safeMint(msg.sender, _tokenId);
        tokenCounter.increment();
        emit GenesisExplorerSummoned(msg.sender, _tokenId);
    }

    // =============================
    //      WITHDRAWAL FUNCTIONS
    // =============================
    // IF VAULT EXISTS, WITHDRAW TO VAULT
    // ELSE WITHDRAW TO OWNER
    function withdrawAll() public{
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAllTokens(IERC20 token) public {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    // ========================
    //      OWNER FUNCTIONS
    // ========================
    function setMetadataUpdaterAddress(address _metadataUpdaterAddress)
        public
        onlyOwner
    {
        metadataUpdaterAddress = _metadataUpdaterAddress;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setEmergencyStop(bool stop) public onlyOwner {
        emergencyStop = stop;
    }
}