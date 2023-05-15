// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";

//                                                                                                    
//   [email protected]&GJ~:.                                        
//   !G#&&@@@&#GJ!:.                        ..^~?!   
//       !P55PGBBB#&#:         ..^~7J5GB#&&&&&&&&G   
//     .#@@@@[email protected]@^          :PBBGPP5J77!^:..         
//     &@&@@@[email protected]@@~                 ^YY7~^.          
//     B#[email protected]@&[email protected]@&@&               [email protected]@@@@J5&&&7      
//      P?&@@&@@J#&              [email protected]@@@@@@[email protected]@&@G.    
//      ^B5&@@&B^#?             [email protected]?&@@&[email protected]@@@[email protected]@@7   
//       !#5?~~~7Y              .&[email protected]@@@@@@7^@^.77.  
//        !G?^:.                 [email protected]@&@&P^!#~       
//                                P&B7^^~7Y5:        
//                                 ^Y55P&@~          
//
// USING THIS CONTRACT ENGAGE US IN NOTHING
// USING THIS CONTRACT ENGAGE YOU IN EVERYTHING
// BROUGHT TO YOU WITH LOVE, BY REWILIA CORPORATION
// Qmc8MnYG8kbvRVrjYUM8YLHfUivXfzeMLNc6LCGoWZU1zk                                                 

contract FAKIES is ERC721A, Ownable {
    address public DISTRIBUTOR;
    uint256 public constant MAX_SUPPLY = 10_000;

    constructor() ERC721A("Redacted Rewilio Fakies", "FAKIES") {}

    function mint(address to, uint256 amount)
    public {
        if (msg.sender != DISTRIBUTOR) revert OnlyDistributor();
        if (totalSupply() + amount > MAX_SUPPLY) revert MaxSupplyExceeded();
        _safeMint(to, amount);
    }

    function setDistributor(address _distributor)
    external onlyOwner {
        DISTRIBUTOR = _distributor;
    }

    function _baseURI()
    internal view virtual override returns (string memory) {
        return "ipfs://QmcxZi5FFChJaTMSY6Pe8ZDoZsyTTXV9P9BV2aSDjNrgkv/";
    }

    function _startTokenId()
    internal view virtual override returns (uint256) {
        return 1;
    }

    error OnlyDistributor();
    error MaxSupplyExceeded();
}