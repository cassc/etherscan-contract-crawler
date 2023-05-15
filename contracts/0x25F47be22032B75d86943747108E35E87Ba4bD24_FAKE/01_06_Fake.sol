// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//
//                 :~?JJJJJJJJJJJJ?!:
//             :JJ##JJJ^:.......:~?JJ#J?:
//          .JJ&#J~..:!?JJJJJJJJJJ^..:JJ&J?.
//        .J#&#J.:JJ##&#############JJ~.:J&#J.
//       JJ&#J:!J######################JJ:^J&#?
//      J&##!~J###########################J:J&#J.
//     J###JJ##############################J~J##J.
//    J###JJ&################################JJ##J
//   J############################################J
//   J###########W#####################W##########J
//   J#########J.$.J#################J.$.J########J
//   J########J     J###############J     J#######J
//   ~J######J       J#############J       J#####J~
//    J######J       J#############J       J#####J
//    .J&####J       J#############J       J####J.
//     .J####J       J#############J       J###J.
//       J###J       J#############J       J&#?
//        .J#J       J#############J       JJ.
//          .!       J#############J       .
//                  ~&#############&~
//                  .~?JJJJJJJJJJJ?~.
//
// USING THIS CONTRACT ENGAGE US IN NOTHING
// USING THIS CONTRACT ENGAGE YOU IN EVERYTHING
// BROUGHT TO YOU WITH LOVE, BY REWILIA CORPORATION
// Qmc8MnYG8kbvRVrjYUM8YLHfUivXfzeMLNc6LCGoWZU1zk

contract FAKE is ERC20, Ownable {
    address public DISTRIBUTOR;
    uint256 public constant PER_UNIT = 1_000_000 * 10**18;
    uint256 public constant MAX_CLAIMABLE = 10_000_000_000 * 10**18;
    uint256 public constant INITIAL_SUPPLY = 11_800_000_000 * 10**18;

    constructor() ERC20("Rewilia Corporation", "FAKE") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 amount)
    public {
        if (msg.sender != DISTRIBUTOR) revert OnlyDistributor();
        uint256 amountToMint = amount * PER_UNIT;
        uint256 total = totalSupply() + amountToMint - INITIAL_SUPPLY;
        if (total > MAX_CLAIMABLE) revert MaxClaimableExceeded();
        _mint(to, amountToMint);
    }

    function setDistributor(address _distributor)
    external onlyOwner {
        DISTRIBUTOR = _distributor;
    }

    error OnlyDistributor();
    error MaxClaimableExceeded();
}