//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AvidlinesCore is ERC721Enumerable, AccessControl, Ownable {
    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public scriptArweave;
    string public scriptIPFS;  
    string public p5jsArweave;
    string public p5jsIPFS;  
    mapping(uint256 => uint256) public baseAutoglyph;

    uint256 public totalMints = 0;
    string internal _currentBaseURI = "";
    uint256 internal _lastTokenId = 0;
    
    constructor(address adminAddress, string memory baseURI) ERC721("Avid Lines", "ALIN")  {
        _currentBaseURI = baseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        transferOwnership(adminAddress);
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

    function setP5jsIPFS(string memory _p5jsIPFS) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        p5jsIPFS = _p5jsIPFS;
    }
    
    function setP5jsArweave(string memory _p5jsArweave) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        p5jsArweave = _p5jsArweave;
    }

    function _generateRandomHash() internal view returns (bytes32) {
        return keccak256(abi.encode(blockhash(block.number-1), block.coinbase, _lastTokenId));
    }

    function _generateNewTokenId() internal view returns (uint256) {
        bytes32 hashRandom = _generateRandomHash();
        uint8 i = 28;
        uint256 value = uint8(hashRandom[i]);
        for (i = 29; i < 30; i++) {
            value = value << 8;
            value = value + uint8(hashRandom[i]);
        }
        value = value << 16;
        value = value.add(totalMints);
        return uint256(value);
    }
    
    function mintGenesis(address _receiver, uint256 _baseGlyph) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(totalMints < 500, "Total mint limit is 500");
        uint256 token = _generateNewTokenId();
        totalMints = totalMints + 1;
        baseAutoglyph[token] = _baseGlyph;
        _lastTokenId = token;
        _safeMint(_receiver, token);
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
        address payable to;
        to.transfer(balance);
    }
}