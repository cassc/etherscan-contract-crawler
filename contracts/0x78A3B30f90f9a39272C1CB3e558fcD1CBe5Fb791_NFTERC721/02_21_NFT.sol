// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Context.sol";
import "../Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract NFT is Context, Pausable, ReentrancyGuard {

    string public baseUri;

    struct NFTParam {
        uint256 tokenId;
        uint256 amount;
    }

    struct TransferParam {
        address to;
        uint256 tokenId;
        uint256 amount;
    }

    event SetBaseURI(address indexed sender, string indexed uri);
    
    function initialize(string memory, string memory, string memory uri_, address config_) public virtual {
        baseUri = uri_;
        _checkConfig(IConfig(config_));
    }

    function setPaused(bool isPaused) public onlyAdmin {
        if (isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function mintNFT(NFTParam[] memory) public virtual returns (bool) {
        return true;
    }

    function burnNFT(NFTParam[] memory) public virtual returns (bool) {
        return true;
    }
    
    function transferNFT(TransferParam[] memory) public virtual returns (bool) {
        return true;
    }
    
}