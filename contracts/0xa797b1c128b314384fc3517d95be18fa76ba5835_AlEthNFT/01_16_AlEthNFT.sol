// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./IAlEthNFT.sol";

contract AlEthNFT is ERC721, IAlEthNFT, AccessControlEnumerable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string internal baseTokenURI;
    mapping(uint256 => uint256) internal tokenDatas;

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, _msgSender()), "AlEthNFT.onlyMinter: msg.sender not minter");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI
    ) ERC721(name, symbol) {
        baseTokenURI = _baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function mint(uint256 _tokenId, uint256 _tokenData, address _receiver) external override onlyMinter {
        _mint(_receiver, _tokenId);
        tokenDatas[_tokenId] = _tokenData;
    }

    function tokenData(uint256 _tokenId) external view override returns(uint256) {
        return tokenDatas[_tokenId];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}