// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface GuarantedToMakeProfitIfYouInvestInThisProject {
    function mint(address, uint256) external;
}

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

contract DISTRIBUTOR is Ownable {
    GuarantedToMakeProfitIfYouInvestInThisProject public FAKE;
    GuarantedToMakeProfitIfYouInvestInThisProject public FAKER;
    GuarantedToMakeProfitIfYouInvestInThisProject public FAKIES;

    uint256 public constant TheCostOfLove = 0.01 ether;
    uint256 public constant TheMaxAmountOfLoveWeDecidedYouCanHavePerTx = 20;

    uint256 public TheAmountOfFakeShitAlreadyClaimed = 0;

    constructor(address REWILIA, address MILADY,  address REWILIO) {
        FAKE = GuarantedToMakeProfitIfYouInvestInThisProject(REWILIA);
        FAKER = GuarantedToMakeProfitIfYouInvestInThisProject(MILADY);
        FAKIES = GuarantedToMakeProfitIfYouInvestInThisProject(REWILIO);
    }

    receive() external payable {}

    function JoinTheCultureWar(uint256 TheAmountOfLoveYouHaveForMoney)
    public payable {
        if (TheAmountOfLoveYouHaveForMoney == 0)
            revert WeFiguredOutYouHatedMoney();
        if (TheAmountOfLoveYouHaveForMoney > TheMaxAmountOfLoveWeDecidedYouCanHavePerTx) 
            revert CalmDownFakies();
        if (TheAmountOfLoveYouHaveForMoney * TheCostOfLove != msg.value)
            revert CopeHarderCodeIsLaw();

        TheAmountOfFakeShitAlreadyClaimed += TheAmountOfLoveYouHaveForMoney;
        FAKE.mint(msg.sender, TheAmountOfLoveYouHaveForMoney);
        FAKER.mint(msg.sender, TheAmountOfLoveYouHaveForMoney);
        FAKIES.mint(msg.sender, TheAmountOfLoveYouHaveForMoney);
    }

    function IfWeRunThisFunctionItIsMissionFailedButWeBalls()
    external onlyOwner {
        uint256 AllTheMoneyYouDidntLoved = 10_000 - TheAmountOfFakeShitAlreadyClaimed;
        if (AllTheMoneyYouDidntLoved == 0)
            revert ItsEmptyNow();

        TheAmountOfFakeShitAlreadyClaimed += AllTheMoneyYouDidntLoved;
        FAKE.mint(msg.sender, AllTheMoneyYouDidntLoved);
        FAKER.mint(msg.sender, AllTheMoneyYouDidntLoved);
        FAKIES.mint(msg.sender, AllTheMoneyYouDidntLoved);
    }

    function ThisIsTheFunctionWeGonnaUseToRugAllTheETH()
    external onlyOwner {
        address TheDev = msg.sender;
        address RewiliaBank = address(this);
        uint256 YourMoneyThatWeLove = RewiliaBank.balance;
        require(payable(TheDev).send(YourMoneyThatWeLove));
    }

    error ItsEmptyNow();
    error CopeHarderCodeIsLaw();
    error WeFiguredOutYouHatedMoney();
    error CalmDownFakies();
}