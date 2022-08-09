// SPDX-License-Identifier: MIT

/**
 /$$$$$$$$ /$$   /$$  /$$$$$$ 
| $$_____/| $$  / $$ /$$__  $$
| $$      |  $$/ $$/| $$  \ $$
| $$$$$    \  $$$$/ | $$  | $$
| $$__/     >$$  $$ | $$  | $$
| $$       /$$/\  $$| $$  | $$
| $$$$$$$$| $$  \ $$|  $$$$$$/
|________/|__/  |__/ \______/ 
                              
*/

pragma solidity ^0.8.4;

import "./ERC721XUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "hardhat/console.sol";

error WithdrawToZeroAddress();
error WithdrawToNonOwner();
error WithdrawZeroBalance();
error OnlyOwnerCanBurn();

// v5
error OnlyOwnerCanSetPlanetData();

interface Stargate {
    function travel(address _to, uint256[] memory _tokenId) external;
}

contract ExoV9 is Initializable, OwnableUpgradeable, ERC721XUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using BitMaps for BitMaps.BitMap;

    address public ownerWallet;
    uint256 internal constant MAX_SUPPLY = 10000;
    uint256 internal constant DEV_MINT = 250;
    uint256 internal constant MAX_PER_TX = 2;
    uint256 internal constant MAX_PER_WALLET = 5;
    string internal _rootURI;
    bool internal mintActive;

    mapping(address => AddressData) internal _addressData;

    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
    }

    mapping(address => uint256) internal _mintBalance;

    // v8
    BitMaps.BitMap private _burnedToken;

    mapping(uint256 => bytes32) internal _traits;
    mapping(uint256 => uint256) internal _planetData;

    event Burn(address indexed from, uint256 indexed tokenId);

    // V9
    mapping(uint256 => bool) internal activePlanetIds;
    address public stargate;

    function initialize(
        string memory name_,
        string memory symbol_,
        address ownerWallet_
    ) external initializer {
        __ERC721Psi_init(name_, symbol_);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        ownerWallet = ownerWallet_;
        mintActive = false;
        _rootURI = "";
    }

    /* solhint-disable-next-line no-empty-blocks */
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getMintStatus() public view returns (bool) {
        return mintActive;
    }

    function setMintStatus(bool _mintActive) public onlyOwner {
        mintActive = _mintActive;
    }

    function setOwnerWallet(address _ownerWallet) public onlyOwner {
        ownerWallet = _ownerWallet;
    }

    function safeMint(address to, uint256 quantity) public nonReentrant {
        if (!mintActive) revert MintIsNotActive();
        if (to == address(0)) revert MintToZeroAddress();
        if (_minted + quantity > MAX_SUPPLY) revert MintExceedsMaxSupply();
        if (quantity > MAX_PER_TX) revert MintQuantityLargerThanMaxPerTX();
        if (_mintBalance[to] + quantity > MAX_PER_WALLET) revert MintExceedsWalletAllowance();
        _safeMint(to, quantity);
        _mintBalance[to] += quantity;
    }

    function safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) public nonReentrant {
        if (!mintActive) revert MintIsNotActive();
        if (to == address(0)) revert MintToZeroAddress();
        if (_minted + quantity > MAX_SUPPLY) revert MintExceedsMaxSupply();
        if (quantity > MAX_PER_TX) revert MintQuantityLargerThanMaxPerTX();
        if (_mintBalance[to] + quantity > MAX_PER_WALLET) revert MintExceedsWalletAllowance();
        _safeMint(to, quantity, _data);
        _mintBalance[to] += quantity;
    }

    function devMint(
        address[] memory _to,
        uint256[] memory _quantity,
        uint256 _totalAmount
    ) public onlyOwner {
        if (_minted + _totalAmount > DEV_MINT) revert MintExceedsDevSupply();
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _quantity[i]);
        }
    }

    function devRefund(address[] memory _to, uint256[] memory _quantity) public onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _quantity[i]);
        }
    }

    function getBatchHead(uint256 tokenId) public view {
        _getBatchHead(tokenId);
    }

    function getBaseURI() public view returns (string memory) {
        return _rootURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _rootURI = _baseURI;
    }

    function release() public onlyOwner {
        if (msg.sender == address(0)) revert WithdrawToZeroAddress();
        if (msg.sender != ownerWallet) revert WithdrawToNonOwner();

        AddressUpgradeable.sendValue(payable(ownerWallet), address(this).balance);
    }

    // v5
    function _burn(address from, uint256 tokenId) internal virtual {
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        _burnedToken.set(tokenId);

        emit Transfer(from, address(0), tokenId);

        _afterTokenTransfers(from, address(0), tokenId, 1);
    }

    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        if (_burnedToken.get(tokenId)) {
            return false;
        }
        return super._exists(tokenId);
    }

    function burn(uint256 tokenId) external {
        address from = ownerOf(tokenId);
        if (from != msg.sender) revert OnlyOwnerCanBurn();
        _burn(from, tokenId);
        emit Burn(from, tokenId);
    }

    function burnBulk(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender == ownerOf(tokenIds[i])) {
                _burn(msg.sender, tokenIds[i]);
                emit Burn(msg.sender, tokenIds[i]);
            }
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _minted - _burned();
    }

    function _burned() internal view returns (uint256 burned) {
        uint256 totalBucket = (_minted >> 8) + 1;

        for (uint256 i = 0; i < totalBucket; i++) {
            uint256 bucket = _burnedToken.getBucket(i);
            burned += _popcount(bucket);
        }
    }

    function _popcount(uint256 x) private pure returns (uint256 count) {
        unchecked {
            for (count = 0; x != 0; count++) x &= x - 1;
        }
    }

    function getTokenParams(uint256 tokenId, uint256 planetData) internal pure returns (string memory) {
        return string(abi.encodePacked("?id=", tokenId.toString(), "&data=", planetData));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory tokenParams = getTokenParams(tokenId, _planetData[tokenId]);
        return bytes(_rootURI).length > 0 ? string(abi.encodePacked(_rootURI, tokenParams)) : "";
    }

    function setStargate(address _stargate) public onlyOwner {
        stargate = _stargate;
    }

    function devSetActivePlantIds(uint256[] memory _activePlanetIds) public onlyOwner {
        for (uint256 i = 0; i < _activePlanetIds.length; i++) {
            activePlanetIds[_activePlanetIds[i]] = true;
        }
    }

    function isPlanetActive(uint256 planetId) public view returns (bool) {
        return activePlanetIds[planetId];
    }

    function travel(uint256[] memory _tokenIds) external {
        uint256[] memory tokenIds = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (ownerOf(_tokenIds[i]) == msg.sender && activePlanetIds[_tokenIds[i]] == true) {
                tokenIds[i] = _tokenIds[i];
                transferFrom(msg.sender, stargate, _tokenIds[i]);
            }
        }

        Stargate(stargate).travel(msg.sender, tokenIds);
    }

    /* solhint-disable-next-line no-empty-blocks */
    receive() external payable {}
}