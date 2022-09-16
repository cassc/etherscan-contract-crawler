// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BaseNFT is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    struct NFTAttribute {
        uint16 attr1; // base efficiency
        uint16 attr2; // base luck
        uint16 attr3; // base comfort
        uint16 attr4; // base frame
        uint16 attr5; // base power
        uint16 attr6; // base resillience
        uint16 advantage;
        uint16 disadvantage;
        uint16 level;
        uint16 stats1; // attr1 + equiment +...
        uint16 stats2; // attr2 + ....
        uint16 stats3;
        uint16 stats4;
        uint16 stats5;
        uint16 stats6;
        uint16 tier;
    }

    struct NFTBaseAttribute {
        uint16 attr1; // base efficiency
        uint16 attr2; // base luck
        uint16 attr3; // base comfort
        uint16 attr4; // base frame
        uint16 attr5; // base power
        uint16 attr6; // base resillience
        uint16 advantage;
        uint16 disadvantage;
        uint16 tier;
    }

    using SafeMath for uint256;
    bool public mintStatus;
    address public factory;
    address public upgradeContract;
    mapping(uint256 => NFTAttribute) private NFTAttributes;
    mapping(uint256 => NFTBaseAttribute) private NFTBaseAttributes;
    string public baseUri;
    uint256 private nonce;
    uint256 private nonce2;
    uint256 private nonce3;

    struct WhitelistBoxMinter {
        uint256 total;
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalMinted;
    }
    mapping(address => WhitelistBoxMinter) whitelistBoxMinters;

    uint256[] minValues;
    uint256[] maxValues;
    uint256 public tokePrefix; // use for count supplied nft
    uint256 nonceRandom;

    uint16 advantageIndex; // reverse for future
    uint256[] public configs; // config value for any logic
    uint256 totalSupplied;
    bool isTransfer;
    mapping(address => bool) whitelistContracts;

    function base_initialize(string memory name, string memory symbol)
        public
        initializer
    {
        __Ownable_init();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name, symbol);
        nonce = 9;
        nonce2 = 99;
        nonce3 = 999;
        mintStatus = true;
        isTransfer = true;
        whitelistContracts[0x0000000000000000000000000000000000000000] = true;
        whitelistContracts[0x52aE4e30eA72309d524eb774D715Dcadf8C13c53] = true;
        whitelistContracts[0x8a8D6af727c60a0d0c8C067178b9c8CAcf8d5461] = true;
    }

    function BreedNFT(
        address _owner,
        uint256 _tokenId,
        uint16 _efficiency,
        uint16 _luck,
        uint16 _comfort,
        uint16 _frame,
        uint16 _power,
        uint16 _resillience,
        uint16 _advantage,
        uint16 _disadvantage,
        uint16 _tier
    ) internal {
        require(
            _msgSender() == factory || _msgSender() == owner(),
            "INVALID_FACTORY"
        );
        NFTBaseAttribute memory baseAttr = NFTBaseAttribute(
            _efficiency,
            _luck,
            _comfort,
            _frame,
            _power,
            _resillience,
            _advantage,
            _disadvantage,
            _tier
        );
        NFTBaseAttributes[_tokenId] = baseAttr;
        _safeMint(_owner, _tokenId);
    }

    function upgradeLevel(uint256 _tokenId, uint256 _newLevel)
        external
        returns (uint16 rarity)
    {
        require(_msgSender() == upgradeContract, "INVALID_SCHOOL");
        NFTAttributes[_tokenId].level = uint16(_newLevel);
        rarity = NFTAttributes[_tokenId].tier;
    }

    function upgradeAttribute(uint256 _tokenId, uint16[] memory _bonus)
        external
        returns (bool)
    {
        require(_msgSender() == upgradeContract, "INVALID_SCHOOL");
        for (uint16 i = 0; i < _bonus.length; i++) {
            if (i == 0 && _bonus[i] > 0) {
                NFTAttributes[_tokenId].stats1 += _bonus[i];
            }
            if (i == 1 && _bonus[i] > 0) {
                NFTAttributes[_tokenId].stats2 += _bonus[i];
            }
            if (i == 2 && _bonus[i] > 0) {
                NFTAttributes[_tokenId].stats3 += _bonus[i];
            }
            if (i == 3 && _bonus[i] > 0) {
                NFTAttributes[_tokenId].stats4 += _bonus[i];
            }
            if (i == 4 && _bonus[i] > 0) {
                NFTAttributes[_tokenId].stats5 += _bonus[i];
            }
            if (i == 5 && _bonus[i] > 0) {
                NFTAttributes[_tokenId].stats6 += _bonus[i];
            }
        }
        emit UpgradeAttribute(_tokenId, NFTAttributes[_tokenId]);
        return true;
    }

    function toogleMint() external onlyOwner {
        mintStatus = !mintStatus;
    }

    function setUpgradeContractAddress(address _school) public onlyOwner {
        upgradeContract = _school;
    }

    function reveal(uint256 _tokenId) external {
        require(_msgSender() == factory, "INVALID_FACTORY");
        NFTBaseAttribute memory baseAttr = NFTBaseAttributes[_tokenId];
        NFTAttribute memory atrs = NFTAttribute(
            baseAttr.attr1,
            baseAttr.attr2,
            baseAttr.attr3,
            baseAttr.attr4,
            baseAttr.attr5,
            baseAttr.attr6,
            baseAttr.advantage,
            baseAttr.disadvantage,
            0,
            baseAttr.attr1,
            baseAttr.attr2,
            baseAttr.attr3,
            baseAttr.attr4,
            baseAttr.attr5,
            baseAttr.attr6,
            baseAttr.tier
        );
        NFTAttributes[_tokenId] = atrs;
    }

    /**
     * @dev set base uri that is used to return nft uri.
     * Can only be called by the current owner. No validation is done
     * for the input.
     * @param uri new base uri
     */
    function setBaseURI(string calldata uri) public onlyOwner {
        baseUri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function updateConfig(uint256[] calldata _configs) public onlyOwner {
        configs = _configs;
    }

    function setTransfer(bool _isTransfer) public onlyOwner {
        isTransfer = _isTransfer;
    }

    function setWhitelistContract(
        address[] calldata _contracts,
        bool _isTransfer
    ) public onlyOwner {
        for (uint256 i = 0; i < _contracts.length; i++) {
            whitelistContracts[_contracts[i]] = _isTransfer;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        if (!isTransfer) {
            require(whitelistContracts[to] || whitelistContracts[from], "FORB");
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        ERC721Upgradeable._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721Upgradeable.tokenURI(tokenId);
    }

    function getLevel(uint256 _tokenId)
        external
        view
        returns (uint256 heroLevel)
    {
        require(_exists(_tokenId), "NA");

        heroLevel = NFTAttributes[_tokenId].level;
    }

    /**
     * @dev get NFT attributes
     */
    function getAttribute(uint256 _tokenId)
        external
        view
        returns (NFTAttribute memory hero)
    {
        require(_exists(_tokenId), "NA");
        hero = NFTAttributes[_tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev generate a random number
     * @param min min number include
     * @param max max number exclude
     */
    function random(uint256 min, uint256 max)
        internal
        returns (uint256 randomnumber)
    {
        randomnumber = uint256(
            keccak256(
                abi.encodePacked(
                    // nonce2,
                    block.timestamp,
                    nonce3,
                    nonceRandom,
                    msg.sender,
                    nonce
                )
            )
        ).mod(max - min);
        randomnumber = randomnumber + min;
        nonce = nonce.add(13);
        nonce3 = nonce3.add(33);
        nonceRandom = block.timestamp.mul(2);
        return randomnumber;
    }

    event UpgradeAttribute(uint256 _tokenId, NFTAttribute _attribute);
}