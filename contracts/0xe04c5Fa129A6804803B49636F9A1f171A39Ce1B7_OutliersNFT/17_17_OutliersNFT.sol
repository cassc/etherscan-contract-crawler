//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gsgalloway/solidity-erc721-transfer-restricted/contracts/ERC721TransferRestricted.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract OutliersNFT is ERC721TransferRestricted {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    string public baseURI;
    Counters.Counter private _tokenIdTracker;    

    constructor(address admin, string memory name, string memory symbol) ERC721TransferRestricted(admin, name, symbol) {}

    function mint() public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "OutliersNFT: must have minter role to mint");
        
        _revokeRole(MINTER_ROLE, _msgSender());

        _mint(_msgSender(), _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function setBaseURI(string memory _baseURI) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "OutliersNFT: URI query for nonexistent token");
        require(bytes(baseURI).length > 0, "OutliersNFT: baseURI must be set");
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }
}