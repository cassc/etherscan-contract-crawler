// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//import "./ERC721Burnable.sol";
import "./ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Blockchain Nuggets contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BlockchainNuggets is ERC721 {
    using Counters for Counters.Counter;

    enum Type {
        Standard,
        Copper,
        Silver,
        Gold,
        Home,
        Special
    }

    Counters.Counter private _tokenIdCounterStandard;
    Counters.Counter private _tokenIdCounterCopper;
    Counters.Counter private _tokenIdCounterSilver;
    Counters.Counter private _tokenIdCounterGold;
    Counters.Counter private _tokenIdCounterHome;
    Counters.Counter private _tokenIdCounterSpecial;

    bool public openMint = false;

    mapping (address => uint256) whitelist;
    mapping (address => uint256) numberMinted;

    struct PassSpec {
        uint256 maxSupply;
        uint256 startingTokenId;
        uint256 numberBurned;
    }

    mapping (Type => PassSpec) passSpecs;

    mapping (Type => mapping(address => uint256)) whitelistByType;

    string private _contractURI;
    string public baseURI = "";

    uint256 public maxMintPerWL = 1;

    constructor() ERC721("Blockchain Nuggets Baby", "BNC") {
        passSpecs[Type.Standard] = PassSpec(6000, 1, 0);
        passSpecs[Type.Copper] = PassSpec(1500, 6001, 0);
        passSpecs[Type.Silver] = PassSpec(1000, 7501, 0);
        passSpecs[Type.Gold] = PassSpec(500, 8501, 0);
        passSpecs[Type.Home] = PassSpec(500, 9001, 0);
        passSpecs[Type.Special] = PassSpec(500, 9501, 0);
    }

    /******************** MODIFIER ********************/

    modifier _notContract() {
        require(msg.sender == tx.origin, "no contracts please");
        _;
    }

    modifier mintComplianceWithWL(Type typ) {
        require(openMint, "mint not open");
        PassSpec memory pass = getSpec(typ);

        require(whitelist[msg.sender] < maxMintPerWL, "over WL limit");
        require(whitelistByType[typ][msg.sender] > 0, "Address does not exist in the white list");
        require(getCounter(typ).current() + maxMintPerWL <= pass.maxSupply, "over supply");
        _;
    }

    /******************** OWNER SETTER ********************/

    function seedWhitelist(Type typ, address[] memory addresses) external onlyOwner {
        if (typ != Type.Standard && typ != Type.Copper && typ != Type.Silver && typ != Type.Gold) {
            revert("invalid type");
        }
        for (uint256 i = 0 ; i < addresses.length; i ++ ) {
            whitelistByType[typ][addresses[i]] = maxMintPerWL;
        }
    }

    //Set Base URI
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function flipMintState() public onlyOwner {
        openMint = !openMint;
    }

    function burn(uint256 tokenId) external virtual onlyOwner {
        _burnByTokenId(tokenId);
    }

    /******************** OVERRIDES ********************/

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId))) : "";
    }

    /******************** MINT ********************/

    function mintWhitelist(Type typ) external {
        _mintWithWL(typ);
    }

    function mintForAddress(Type typ, address[] calldata receiver) external onlyOwner {
        for (uint256 i = 0 ; i < receiver.length; i ++ ) {
            _mintForAddress(typ, receiver[i]);
        }
    }

    function upgrade(Type typ, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not owner this token");
        require(whitelistByType[typ][msg.sender] > 0, "Address does not exist in the white list");
        require(tokenId < getSpec(typ).startingTokenId, "Type not match");

        _burnByTokenId(tokenId);
        _safeMintType(typ, msg.sender);
        whitelistByType[typ][msg.sender] --;
    }

    /******************** INTERNAL ********************/

    function _mintWithWL(Type typ)
    internal
    _notContract
    mintComplianceWithWL(typ)
    {
        whitelist[msg.sender] ++;
        _safeMintType(typ, msg.sender);
        whitelistByType[typ][msg.sender] --;
        whitelist[msg.sender] ++;
    }

    function _mintForAddress(Type typ, address receiver) internal _notContract onlyOwner {
        PassSpec memory pass = getSpec(typ);
        require(getCounter(typ).current() + maxMintPerWL <= pass.maxSupply, "over supply");
        _safeMintType(typ, receiver);
    }

    function _safeMintType(Type typ, address to) internal {
        uint256 tokenId = getCounter(typ).current() + getSpec(typ).startingTokenId;
        increaseSupplyByType(typ);
        _safeMint(to, tokenId);
    }

    function increaseSupplyByType(Type typ) internal {
        getCounter(typ).increment();
    }

    function _burnByTokenId(uint256 tokenId) internal {
        if (tokenId >= getSpec(Type.Standard).startingTokenId && tokenId < getSpec(Type.Copper).startingTokenId) {
            passSpecs[Type.Standard].numberBurned ++;
        } else if (tokenId >= getSpec(Type.Copper).startingTokenId && tokenId < getSpec(Type.Silver).startingTokenId) {
            passSpecs[Type.Copper].numberBurned ++;
        } else if (tokenId >= getSpec(Type.Silver).startingTokenId && tokenId < getSpec(Type.Gold).startingTokenId) {
            passSpecs[Type.Silver].numberBurned ++;
        } else if (tokenId >= getSpec(Type.Gold).startingTokenId && tokenId < getSpec(Type.Home).startingTokenId) {
            passSpecs[Type.Gold].numberBurned ++;
        } else if (tokenId >= getSpec(Type.Home).startingTokenId && tokenId < getSpec(Type.Special).startingTokenId) {
            passSpecs[Type.Home].numberBurned ++;
        } else if (tokenId >= getSpec(Type.Special).startingTokenId) {
            passSpecs[Type.Special].numberBurned ++;
        } else {
            revert("invalid type");
        }
        _burn(tokenId);
    }

    /******************** GETTER ********************/

    function totalSupplyByType(Type typ) public view returns (uint256) {
        return getCounter(typ).current() - getSpec(typ).numberBurned;
    }

    function maxSupplyByType(Type typ) public view returns (uint) {
        return getSpec(typ).maxSupply;
    }

    function getSpec(Type typ) private view returns (PassSpec memory) {
        return passSpecs[typ];
    }

    function getCounter(Type typ) private view returns (Counters.Counter storage) {
        if (typ == Type.Standard) {
            return _tokenIdCounterStandard;
        }
        if (typ == Type.Copper) {
            return _tokenIdCounterCopper;
        }
        if (typ == Type.Silver) {
            return _tokenIdCounterSilver;
        }
        if (typ == Type.Gold) {
            return _tokenIdCounterGold;
        }
        if (typ == Type.Home) {
            return _tokenIdCounterHome;
        }
        if (typ == Type.Special) {
            return _tokenIdCounterSpecial;
        }
        revert("invalid type");
    }

    function checkWhitelist(Type typ, address addr) public view returns (bool) {
        return whitelistByType[typ][addr] > 0;
    }

    function walletOfOwner(Type typ, address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);

        uint256 ownedTokenIndex = 0;

        uint256 currentTokenId = getSpec(typ).startingTokenId;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId < getCounter(typ).current() + getSpec(typ).startingTokenId) {
            if (ownerOf(currentTokenId) == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
            unchecked{ ownedTokenIndex ++ ;}
            }
        unchecked{ currentTokenId ++ ;}
        }

        // 0 is not exist
        if (ownedTokenIndex == 0) {
            ownedTokenIds[ownedTokenIndex] = 0;
        }
        return ownedTokenIds;
    }
}