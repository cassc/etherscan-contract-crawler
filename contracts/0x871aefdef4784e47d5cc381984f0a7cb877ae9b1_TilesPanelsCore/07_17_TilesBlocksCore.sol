//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TilesBlocksCore is ERC721Enumerable, AccessControl, Ownable {

    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public scriptArweave;
    string public scriptIPFS;  

    mapping(uint256 => uint256) public tokenHash;

    uint32 public genesisMintLimit = 10000;
    uint256 public totalMints = 0;
    string internal _currentBaseURI = "";

    event Mint(uint256 tokenId);
    
    constructor(address adminAddress, address ownerAddress, string memory baseURI) ERC721("Tiles Blocks", "TILB")  {
        _currentBaseURI = baseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        transferOwnership(ownerAddress);
    }
    
    function setGenesisMintLimit(uint32 _mintLimit) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        genesisMintLimit = _mintLimit;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _currentBaseURI = baseURI;
    }

    function setScriptIPFS(string memory _scriptIPFS) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        scriptIPFS = _scriptIPFS;
    }

    function setScriptArweave(string memory _scriptArweave) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        scriptArweave = _scriptArweave;
    }

    function _generateRandomHash() internal view returns (bytes32) {
        return keccak256(abi.encode(blockhash(block.number-1), block.coinbase, totalMints));
    }

    function _generateNewSeed() internal view returns (uint256) {
        bytes32 hashRandom = _generateRandomHash();
        uint256 value = uint8(hashRandom[20]);
        value = value << 8;
        value = value + uint8(hashRandom[21]);
        value = value << 24;
        value = value.add(totalMints);
        return uint256(value);
    }
    
    function mintGenesis(address _receiver, uint256 qty) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(totalMints + qty <= genesisMintLimit, "Total genesis mint limit reached");
        
        for (uint256 i = 0; i<qty; i++) {
           _mint(_receiver);
        }
    }

    function _mint(address _receiver) internal {
        totalMints = totalMints + 1;
        uint256 token = totalMints;
        tokenHash[token] = _generateNewSeed();
        _safeMint(_receiver, token);
        emit Mint(token);
    }

    function burnToMint(uint256[] memory tokenIds, address _owner) public  {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        //require(totalMints >= genesisMintLimit, "Burns can only start after all Blocks are minted");
        require(tokenIds.length < 10, "Total burn limit is 9");
        for (uint8 i = 0; i < tokenIds.length; i++) {
            require(_owner == ownerOf(tokenIds[i]), "Only the owner can burn pieces");
            _burn(tokenIds[i]);
        }
        for (uint8 i = 0; i < tokenIds.length - 1; i++) {
            _mint(_owner);
        }
        
    }

    function burn(uint256 tokenId) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _burn(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }
 
    function withdrawEther() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}