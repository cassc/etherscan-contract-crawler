// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";

//
//            :7^
//        ^Y#@@&P                  ...
//     ~#@@&5~.                    [email protected]@@&B5~
//   .#@Y:                          .:~?P#&@B^
//   #P...:^^.                             :[email protected]&^
//     5B##GGBY!                             [email protected]&^
//    [email protected]@@@G^&&?                  .~!~~^:.      [email protected]
//   [email protected]@@@: [email protected]@?                 .~!?5GB#BGJ^    J
//  :[email protected]@@&[email protected]@@@.                .5&@@@@G~7!G^
//    ~^@@@@@@@^5:               [email protected]@@@@@@!.~#@@P.
//    [email protected]@@@@5 @^               @@@@@@@@@@@@J7#@~
//     G~?&@@J ^&               ~&[email protected]@@@@@@@@P #^!&
//      5. ..:?P.               ^G ^@@@@@@@J [email protected]  Y.
//      ?PGP57.                 [email protected] .?G#G?. J&.
//      ..                       .&#:    .!PJ
//                                 .~P5G&@G.
//                                     .^~:
//
// USING THIS CONTRACT ENGAGE US IN NOTHING
// USING THIS CONTRACT ENGAGE YOU IN EVERYTHING
// BROUGHT TO YOU WITH LOVE, BY REWILIA CORPORATION
// Qmc8MnYG8kbvRVrjYUM8YLHfUivXfzeMLNc6LCGoWZU1zk

contract FAKER is ERC721A, Ownable {
    address public DISTRIBUTOR;
    uint256 public constant MAX_SUPPLY = 10_000;

    constructor() ERC721A("Milady Faker", "FAKER") {}

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
        return "ipfs://QmXVvUHxDs31FUcPENDmBUM8UhrKoxJXvj3oohmn7kiucp/";
    }

    function _startTokenId()
    internal view virtual override returns (uint256) {
        return 0;
    }

    error OnlyDistributor();
    error MaxSupplyExceeded();
}