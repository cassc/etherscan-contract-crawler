// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";

error NotAdmin();
error BelowPrice();
error AboveMaxSupply();
error AlreadyMinted(uint256 id);
error TokenIdNotFound(uint256 id);
error NotOwner(uint256 id);
error BadRarity();
error NotElections();

enum Rarity {
    COMMON,
    RARE,
    SUPER_RARE,
    ULTRA_RARE,
    LEGENDARY
}

contract OGP is ERC721, ERC2981 {
    string public baseUri;
    mapping(address => bool) public admins;
    uint public price;

    mapping(uint => Rarity) public rarity;
    mapping(Rarity => uint) public supply;
    mapping(Rarity => uint) public maxSupply;

    address public elections;

    event SetBaseURI(string baseUri);
    event AdminStatus(address indexed admin, bool status);
    event SetPrice(uint price);
    event SetElections(address elections);
    event MintVaulted(address indexed to, uint256 indexed id, Rarity rarity);
    event LegendaryTransfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    constructor(
        string memory _baseUri,
        uint _price
    ) ERC721("OG Potheads", "OGP") {
        baseUri = _baseUri;
        price = _price;
        admins[msg.sender] = true;
        owner = msg.sender;

        _setDefaultRoyalty(msg.sender, 500);

        maxSupply[Rarity.COMMON] = 3218;
        maxSupply[Rarity.RARE] = 420;
        maxSupply[Rarity.SUPER_RARE] = 420;
        maxSupply[Rarity.ULTRA_RARE] = 100;
        maxSupply[Rarity.LEGENDARY] = 42;
    }

    /// @dev Mint a new NFT
    function mint(address to, uint256 amount) external payable {
        if (msg.value < price * amount) {
            revert BelowPrice();
        }
        if (supply[Rarity.COMMON] + amount > maxSupply[Rarity.COMMON]) {
            revert AboveMaxSupply();
        }

        for (uint i = 0; i < amount; ) {
            _mint(to, 982 + supply[Rarity.COMMON] + i);
            unchecked {
                ++i;
            }
        }
        unchecked {
            supply[Rarity.COMMON] += amount;
        }
    }

    /// @dev Mint a new vaulted NFT
    function mintVaulted(address to, uint tokenId) external onlyAdmin {
        if (_ownerOf[tokenId] != address(0)) {
            revert AlreadyMinted(tokenId);
        }

        Rarity _rarity;
        if (tokenId < 42) {
            _rarity = Rarity.LEGENDARY;
        } else if (tokenId < 142) {
            _rarity = Rarity.ULTRA_RARE;
        } else if (tokenId < 562) {
            _rarity = Rarity.SUPER_RARE;
        } else if (tokenId < 982) {
            _rarity = Rarity.RARE;
        } else {
            revert BadRarity();
        }

        if (_rarity == Rarity.COMMON) {
            revert BadRarity();
        }
        if (supply[_rarity] == maxSupply[_rarity]) {
            revert AboveMaxSupply();
        }

        _mint(to, tokenId);
        rarity[tokenId] = _rarity;
        unchecked {
            supply[_rarity]++;
        }

        emit MintVaulted(to, tokenId, _rarity);
    }

    function burn(uint256 id) external {
        if (ownerOf(id) != msg.sender) {
            revert NotOwner(id);
        }
        _burn(id);
    }

    /// @dev Returns the total supply of NFTs
    function totalSupply() public view returns (uint256) {
        return
            supply[Rarity.COMMON] +
            supply[Rarity.RARE] +
            supply[Rarity.SUPER_RARE] +
            supply[Rarity.ULTRA_RARE] +
            supply[Rarity.LEGENDARY];
    }

    /// @dev Returns the URI for a given token ID
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (bytes(baseUri).length == 0) {
            return "";
        }
        if (_ownerOf[id] == address(0)) {
            revert TokenIdNotFound(id);
        }
        return string.concat(baseUri, "/", LibString.toString(id), ".json");
    }

    /// @dev Set the base URI
    function setBaseUri(string memory _baseUri) external onlyAdmin {
        baseUri = _baseUri;
        emit SetBaseURI(_baseUri);
    }

    /// @dev Add an admin
    function addAdmin(address admin, bool status) external onlyAdmin {
        admins[admin] = status;
        emit AdminStatus(admin, status);
    }

    /// @dev Set the price
    function setPrice(uint _price) external onlyAdmin {
        price = _price;
        emit SetPrice(_price);
    }

    /// @dev Withdraw all funds from the contract
    function withdrawAll() external payable onlyAdmin {
        require(payable(msg.sender).send(address(this).balance));
    }

    /// @dev Modifier to check if the caller is an admin
    modifier onlyAdmin() {
        if (!admins[msg.sender]) {
            revert NotAdmin();
        }
        _;
    }

    //ERC2981 stuff
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyAdmin {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // owner for open sea
    address owner;

    function setOwner(address _owner) external onlyAdmin {
        owner = _owner;
    }

    // legendaries
    function setElections(address _elections) external onlyAdmin {
        elections = _elections;
        emit SetElections(_elections);
    }

    function transferLegendary(address to, uint256 id) external {
        if (msg.sender != elections) {
            revert NotElections();
        }
        if (rarity[id] != Rarity.LEGENDARY) {
            revert BadRarity();
        }

        // transferFrom
        address from = _ownerOf[id];
        require(to != address(0), "INVALID_RECIPIENT");
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }
        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
        // end transferFrom

        emit LegendaryTransfer(from, to, id);
    }
}