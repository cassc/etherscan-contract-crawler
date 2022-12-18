// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**  
 *                                                                                                         
 * ██████  ██  ██████ ██   ██ ██      ███████                
 * ██   ██ ██ ██      ██  ██  ██      ██                     
 * ██████  ██ ██      █████   ██      █████                  
 * ██      ██ ██      ██  ██  ██      ██                     
 * ██      ██  ██████ ██   ██ ███████ ███████                
 *                                                           
 *                                                           
 * ██████  ███████  ██████  ██████  ██      ███████ 
 * ██   ██ ██      ██    ██ ██   ██ ██      ██      
 * ██████  █████   ██    ██ ██████  ██      █████   
 * ██      ██      ██    ██ ██      ██      ██      
 * ██      ███████  ██████  ██      ███████ ███████          
 *       
 *            A Mustard Labs Project      
 *      by @wij_not + @p0pps • December 2022                 
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract PicklePeople is ERC721, Pausable, AccessControl, ERC721Royalty, ERC721Burnable {
    using Random for Random.Manifest;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public root;
    string private ipfsHash = "QmbRH2eUmygGihxo1EegnccrdM2EwBEVVSJZDwXjtKi1AT";
    string private metadataSuffix = ".json";
    string private _contractURI;
    uint public totalCount = 3045;

    Random.Manifest private collectionDeck;

    event Sale(address to, uint256 id);

    constructor() ERC721("PicklePeople", "PP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setDefaultRoyalty(0x3bC076F574648beA112BdD4E1aB4c6Ac178E7116, 750);
        collectionDeck.setup(totalCount);
    }

// Mint

    function mint(address _to) public whenNotPaused onlyRole(MINTER_ROLE) {
        uint _pull = collectionDeck.draw();
        _safeMint(_to, _pull);
        emit Sale(_to, _pull);
    }

// View

    function remaining() public view returns (uint256) {
        return collectionDeck.remaining();
    } 

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), metadataSuffix)) : "";
    }

// Admin

    function setContractURI(string calldata newURI) public onlyRole(MINTER_ROLE) {
        _contractURI = newURI;
    }

    function setIPFSHash(string calldata _hash) public onlyRole(MINTER_ROLE) {
        ipfsHash = _hash;
    }

    function setURISuffix(string calldata _suffix) public onlyRole(MINTER_ROLE) {
        metadataSuffix = _suffix;
    }

    function pause() public onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MINTER_ROLE) {
        _unpause();
    }

    function push(uint256 _count) public onlyRole(MINTER_ROLE) {
        collectionDeck.put(_count); //no
    }

// Internal

    function _baseURI() internal view virtual override returns (string memory) {
        return string(bytes.concat("ipfs://", bytes(ipfsHash), "/"));
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

library Random {
    function random() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

    struct Manifest {
        uint256[] _data;
    }

    function setup(Manifest storage self, uint256 length) internal {
        uint256[] storage data = self._data;

        require(data.length == 0, "cannot-setup-during-active-draw");
        assembly { sstore(data.slot, length) }
    }

    function draw(Manifest storage self) internal returns (uint256) {
        return draw(self, random());
    }

    function draw(Manifest storage self, bytes32 seed) internal returns (uint256) {
        uint256[] storage data = self._data;
        uint256 l = data.length;
        uint256 i = uint256(seed) % l;
        uint256 x = data[i];
        uint256 y = data[--l];
        if (x == 0) { x = i + 1;   }
        if (y == 0) { y = l + 1;   }
        if (i != l) { data[i] = y; }
        data.pop();
        return x - 1;
    }

    function put(Manifest storage self, uint256 i) internal {
        self._data.push(i + 1);
    }

    function remaining(Manifest storage self) internal view returns (uint256) {
        return self._data.length;
    }
}