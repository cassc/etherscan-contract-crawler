pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract Test is ERC721, Ownable, DefaultOperatorFilterer {
    constructor() ERC721("Test", "TST") public {
        for(uint i = 1; i<=11; i++){
            _safeMint(msg.sender, i);
        }
    }

    function baseTokenURI() public view returns (string memory) {
        return "";
    }
}