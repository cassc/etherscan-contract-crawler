//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17; 

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ChanceCoxNFT is  Initializable, ERC721Upgradeable, OwnableUpgradeable {

    uint256 public tokenCounter;
    mapping (uint256 => string) private _tokenURIs;

    function initialize() external initializer{
        __ERC721_init("ChanceCoxNFT", "CMCNFT");
        __Ownable_init();
    }

    function mint(string memory _tokenURI) public onlyOwner {
        _safeMint(msg.sender, tokenCounter);
        _setTokenURI(tokenCounter, _tokenURI);

        tokenCounter++;
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );  // Checks if the tokenId exists
        _tokenURIs[_tokenId] = _tokenURI;
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        return _tokenURIs[_tokenId];
    }

}