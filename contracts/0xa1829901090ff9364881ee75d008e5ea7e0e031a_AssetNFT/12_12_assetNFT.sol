pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "tinlake-auth/auth.sol";

contract AssetNFT is ERC721, Auth {
    uint256 public count = 0;

    constructor() ERC721("Tinlake Asset NFT", "TNLK") {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function mintTo(address usr) public auth returns (uint256) {
        count++;
        _mint(usr, count);
        return count;
    }
}