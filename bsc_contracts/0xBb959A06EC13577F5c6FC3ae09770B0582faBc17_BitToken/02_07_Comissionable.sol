// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './Subwallet.sol';


/**
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Comissionable {

    struct Details {
        string firstName; // person delegated to
        string lastName;
        string avatarUrl;
        bool exists; // person delegated to
        uint totalTurnover; // person delegated to
        uint totalPackages; // person delegated to
        uint level;
    }

    struct Member {
        address sponsor; // person delegated to
        address[] childrens;
        bool exists; // person delegated to
    }

    struct Product {
        uint price; // person delegated to
        uint pruchaseTimestamp;
        bool exists; // person delegated to
    }

    struct ChildrenSummary {
        address adr; // person delegated to
        uint totalTurnover;
    }

    struct Wrapper {
        Details profile;
        Member tree;
        uint[] products;
        bool exists;
    }

    struct Level {
        uint totalPackages;
        uint256[] branches;
        uint percentage;
    }

    event Bonus (
        address indexed wallet,
        uint256 amount,
        string bonusName
    );

    address public chairperson;

    mapping(address => Wrapper) public members;

    mapping(uint => Product) public products;

    uint public _productLenght;

    uint internal _activeSince;

    Level[] public levels;

    Subwallet internal commissionWallet;



    /**
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param headAccount fist account in struct
     */
    constructor(address headAccount) {
        commissionWallet = new Subwallet();

        Member memory headMember;
        Details memory headDetails;
        Wrapper memory headWrapper;

        headMember.sponsor = headAccount;
        headMember.exists = true;


        headDetails.firstName = "Bitmonsters";
        headDetails.lastName = "Affilaite";
        headDetails.exists = true;
        headDetails.level = 10;

        headWrapper.tree = headMember;
        headWrapper.profile = headDetails;
        headWrapper.exists = true;
        members[headAccount] = headWrapper;

        initLevels();
        _activeSince  = block.timestamp;
    }

    /**
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param sponsorId address of voter
     */
    function _joinReferralSystem(address sender, address sponsorId, Details  memory details) internal {
        bool doesSponsorExists = members[sponsorId].tree.exists || sponsorId == sender;
        require(
            doesSponsorExists,
            "Sponsor doesnt exists"
        );
        bool alreadyInTree = members[sender].tree.exists;
        require(
            !alreadyInTree,
            "User has joined affiliate already."
        );
        Member memory joiner;
        joiner.sponsor = sponsorId;
        joiner.exists = true;
        details.totalTurnover = 0;
        details.totalPackages = 0;
        details.level = 1;
        Wrapper memory wrapper;
        wrapper.tree = joiner;
        wrapper.profile = details;
        wrapper.exists = true;

        if(sponsorId != sender) {
            members[sponsorId].tree.childrens.push(sender);
        }
        members[sender] = wrapper;

    }

    function _setSponsor(address sender, address sponsorId, Details  memory details) internal {
        bool doesSponsorExists = members[sponsorId].tree.exists;
        require(
            doesSponsorExists,
            "Sponsor doesnt exists"
        );
        bool alreadyInTree = members[sender].tree.exists;
        bool doesntHaveSponsorNow = members[sender].tree.sponsor == sender;
        require(
            doesntHaveSponsorNow,
            "User has a sponsor already"
        );
        members[sender].tree.sponsor = sponsorId;
        members[sender].profile.firstName = details.firstName;
        members[sender].profile.lastName = details.lastName;
        members[sender].profile.avatarUrl = details.avatarUrl;
        members[sponsorId].tree.childrens.push(sender);

    }

    function _setProfile(address sender, Details  memory details) internal returns (bool) {
        bool exists = members[sender].profile.exists;
        require(
            exists,
            "User doesnt exist"
        );
        members[sender].profile.firstName = details.firstName;
        members[sender].profile.lastName = details.lastName;
        members[sender].profile.avatarUrl = details.avatarUrl;
        return true;
    }

    function initLevels() private {
        levels.push(Level(100000000000000000000, new uint[](0), 50));
        levels.push(Level(100000000000000000000, new uint[](0), 80));
        levels[levels.length - 1].branches.push(2500000000000000000000);
        levels[levels.length - 1].branches.push(2500000000000000000000);
        levels.push(Level(100000000000000000000, new uint[](0), 110));
        levels[levels.length - 1].branches.push(5000000000000000000000);
        levels[levels.length - 1].branches.push(5000000000000000000000);
        levels.push(Level(500000000000000000000, new uint[](0), 140));
        levels[levels.length - 1].branches.push(10000000000000000000000);
        levels[levels.length - 1].branches.push(10000000000000000000000);
        levels.push(Level(1000000000000000000000, new uint[](0), 160));
        levels[levels.length - 1].branches.push(25000000000000000000000);
        levels[levels.length - 1].branches.push(25000000000000000000000);
        levels.push(Level(2000000000000000000000, new uint[](0), 180));
        levels[levels.length - 1].branches.push(45000000000000000000000);
        levels[levels.length - 1].branches.push(45000000000000000000000);
        levels[levels.length - 1].branches.push(10000000000000000000000);
        levels.push(Level(5000000000000000000000, new uint[](0), 195));
        levels[levels.length - 1].branches.push(90000000000000000000000);
        levels[levels.length - 1].branches.push(90000000000000000000000);
        levels[levels.length - 1].branches.push(20000000000000000000000);
        levels.push(Level(10000000000000000000000, new uint[](0), 210));
        levels[levels.length - 1].branches.push(175000000000000000000000);
        levels[levels.length - 1].branches.push(175000000000000000000000);
        levels[levels.length - 1].branches.push(100000000000000000000000);
        levels[levels.length - 1].branches.push(50000000000000000000000);
        levels.push(Level(15000000000000000000000, new uint[](0), 225));
        levels[levels.length - 1].branches.push(250000000000000000000000);
        levels[levels.length - 1].branches.push(250000000000000000000000);
        levels[levels.length - 1].branches.push(200000000000000000000000);
        levels[levels.length - 1].branches.push(150000000000000000000000);
        levels[levels.length - 1].branches.push(150000000000000000000000);
        levels.push(Level(20000000000000000000000, new uint[](0), 240));
        levels[levels.length - 1].branches.push(625000000000000000000000);
        levels[levels.length - 1].branches.push(625000000000000000000000);
        levels[levels.length - 1].branches.push(500000000000000000000000);
        levels[levels.length - 1].branches.push(375000000000000000000000);
        levels[levels.length - 1].branches.push(375000000000000000000000);
        levels.push(Level(30000000000000000000000, new uint[](0), 250));
        levels[levels.length - 1].branches.push(1250000000000000000000000);
        levels[levels.length - 1].branches.push(1250000000000000000000000);
        levels[levels.length - 1].branches.push(1000000000000000000000000);
        levels[levels.length - 1].branches.push(750000000000000000000000);
        levels[levels.length - 1].branches.push(750000000000000000000000);
        levels.push(Level(50000000000000000000000, new uint[](0), 260));
        levels[levels.length - 1].branches.push(2500000000000000000000000);
        levels[levels.length - 1].branches.push(2500000000000000000000000);
        levels[levels.length - 1].branches.push(2000000000000000000000000);
        levels[levels.length - 1].branches.push(1500000000000000000000000);
        levels[levels.length - 1].branches.push(1500000000000000000000000);
        levels.push(Level(70000000000000000000000, new uint[](0), 270));
        levels[levels.length - 1].branches.push(6250000000000000000000000);
        levels[levels.length - 1].branches.push(6250000000000000000000000);
        levels[levels.length - 1].branches.push(5000000000000000000000000);
        levels[levels.length - 1].branches.push(3750000000000000000000000);
        levels[levels.length - 1].branches.push(3750000000000000000000000);
        levels.push(Level(100000000000000000000000, new uint[](0), 280));
        levels[levels.length - 1].branches.push(12500000000000000000000000);
        levels[levels.length - 1].branches.push(12500000000000000000000000);
        levels[levels.length - 1].branches.push(10000000000000000000000000);
        levels[levels.length - 1].branches.push(7500000000000000000000000);
        levels[levels.length - 1].branches.push(7500000000000000000000000);
        levels.push(Level(100000000000000000000000, new uint[](0), 290));
        levels[levels.length - 1].branches.push(18750000000000000000000000);
        levels[levels.length - 1].branches.push(18750000000000000000000000);
        levels[levels.length - 1].branches.push(15000000000000000000000000);
        levels[levels.length - 1].branches.push(11250000000000000000000000);
        levels[levels.length - 1].branches.push(11250000000000000000000000);
        levels.push(Level(100000000000000000000000, new uint[](0), 300));
        levels[levels.length - 1].branches.push(25000000000000000000000000);
        levels[levels.length - 1].branches.push(25000000000000000000000000);
        levels[levels.length - 1].branches.push(20000000000000000000000000);
        levels[levels.length - 1].branches.push(15000000000000000000000000);
        levels[levels.length - 1].branches.push(15000000000000000000000000);
        levels.push(Level(100000000000000000000000, new uint[](0), 310));
        levels[levels.length - 1].branches.push(50000000000000000000000000);
        levels[levels.length - 1].branches.push(50000000000000000000000000);
        levels[levels.length - 1].branches.push(40000000000000000000000000);
        levels[levels.length - 1].branches.push(30000000000000000000000000);
        levels[levels.length - 1].branches.push(30000000000000000000000000);
    }



    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return addresses  index of winning proposal in the proposals array
     */
    function getParents(address adr) public view
    returns (address[] memory addresses)
    {
        return _getParents(adr, new address[](0));
    }

    /**
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return returnedAddress the name of the winner
     */
    function _getParents(address adr, address[] memory list) internal view
    returns (address[] memory returnedAddress)
    {
        address[] memory localList = new address[](list.length + 1);
        if (list.length > 0) {
            for (uint i = 0; i < list.length; i++) {
                localList[i] = list[i];
            }

        }
        localList[list.length] = adr;
        if (members[adr].tree.sponsor != adr) {
            return _getParents(members[adr].tree.sponsor, localList);
        }
        return localList;
    }

    function processPurchase(address adr, uint price) internal {
        bool doesSponsorExists = members[adr].tree.exists;
        require(
            doesSponsorExists,
            "Account doesn't exists in affiliate program"
        );
        products[_productLenght + 1] = Product(price, 1, true);
        members[adr].profile.totalPackages += price;
        members[adr].products.push(_productLenght);
        _productLenght++;

        _addTurnoverToSponsors(adr, price, 0);
    }

    function _addTurnoverToSponsors(address adr, uint price, uint bussinessBonusSum) internal {
        address sponsor = members[adr].tree.sponsor;
        Details memory profile = members[adr].profile;
        if (sponsor == adr) {
            return;
        }
        bussinessBonusSum = processBussinessBonus(sponsor, price, bussinessBonusSum);
        members[sponsor].profile.totalTurnover += price;
        members[adr].profile.level = getLevel(profile, getChildrensWithBalance(adr));
        return _addTurnoverToSponsors(sponsor, price, bussinessBonusSum);
    }


    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return childrenSummary  index of winning proposal in the proposals array
     */
    function getChildrensWithBalance(address adr) public
    returns (ChildrenSummary[] memory)
    {
        ChildrenSummary[] memory childrenSummary = new ChildrenSummary[](members[adr].tree.childrens.length);
        for (uint i = 0; i < members[adr].tree.childrens.length; i++) {
            childrenSummary[i] = ChildrenSummary(members[adr].tree.childrens[i], members[members[adr].tree.childrens[i]].profile.totalTurnover + members[members[adr].tree.childrens[i]].profile.totalPackages);
        }
        return childrenSummary;
    }

    function getLevel(Details  memory person, ChildrenSummary[] memory childrens) public returns (uint)
    {
        uint newLevel = qualifiesForLevel(person.totalPackages, childrens, person.level);
        return newLevel > person.level ? newLevel : person.level;

    }

    function qualifiesForLevel(uint totalPackages, ChildrenSummary[] memory childrens, uint level) public returns (uint) {
        if (levels[level - 1].totalPackages > totalPackages) {
            return level - 1;
        }
        address[] memory selectedChildrens = new address[](levels[level - 1].branches.length);
        uint matchedRequirements = 0;
        for (uint i = 0; i < levels[level - 1].branches.length; i++) {
            for (uint j = 0; j < childrens.length; j++) {
                if (childrens[j].totalTurnover >= levels[level - 1].branches[i] && !arrayIncludes(selectedChildrens, childrens[j].adr) && selectedChildrens[i] == address(0)) {
                    selectedChildrens[i] = childrens[j].adr;
                    matchedRequirements++;
                }
            }
        }
        if (matchedRequirements >= levels[level - 1].branches.length) {
            return qualifiesForLevel(totalPackages, childrens, level + 1);
        }
        return level - 1;


    }

    function processDirectBonus(address adr, uint price) private {
        if (members[adr].tree.sponsor != adr && members[members[adr].tree.sponsor].profile.totalPackages > 0) {
            uint bonus = min(multiplyByHalvingMultiplier(price * 5 / 100), commissionWallet.balanceOf(address(this)));
            emit Bonus(members[adr].tree.sponsor, bonus, "DIRECT_BONUS");
            commissionWallet.sendFundsTo(address(this), bonus, members[adr].tree.sponsor);
            processMatchingBonus(members[adr].tree.sponsor, bonus);
        }
    }

    function processMatchingBonus(address adr, uint price) private {
        if (price > 0 && members[adr].tree.sponsor != adr && members[members[adr].tree.sponsor].profile.totalPackages > 0) {
            uint matchingBonus = members[members[adr].tree.sponsor].profile.level >= members[adr].profile.level ? 5 : 2;
            uint bonus =  min(price * matchingBonus / 100, commissionWallet.balanceOf(address(this)));
            emit Bonus(members[adr].tree.sponsor, bonus, "MATCHING_BONUS");
            commissionWallet.sendFundsTo(address(this), bonus, members[adr].tree.sponsor);
        }
    }


    // WE PROCESSS BONUSES * 1000 to mage division correctly
    function processBussinessBonus(address adr, uint price, uint usedBonus) private returns (uint) {
        uint level = members[adr].profile.level;
        int leftBonus = int(levels[level - 1].percentage) - int(usedBonus);
        if (leftBonus > 0 && members[adr].profile.totalPackages > 0) {
            uint bonus = min(multiplyByHalvingMultiplier(uint(leftBonus) * price / 1000), commissionWallet.balanceOf(address(this)));
            emit Bonus(adr, bonus, "BUSINESS_BONUS");
            commissionWallet.sendFundsTo(address(this), bonus, adr);
            processMatchingBonus(adr, bonus);
            return usedBonus + uint(leftBonus);
        }
        return usedBonus;

    }


    function arrayIncludes(address[] memory array, address adr) public view returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == adr) {
                return true;
            }
        }
        return false;
    }

    function getCommissionAddress() public view returns (address) {
        return commissionWallet.selfAddress();
    }


    function multiplyByHalvingMultiplier(uint numberToMultiply) public view returns (uint) {
        uint daysNumber =  (block.timestamp - _activeSince) / 1 days;

        if(daysNumber < 300) {
            return numberToMultiply;
        }
        if(daysNumber < 600) {
            return numberToMultiply * 9 / 10;
        }
       if(daysNumber < 900) {
            return numberToMultiply * 8 / 10;
        }
       if(daysNumber < 1200) {
            return numberToMultiply * 7 / 10;
        }
       if(daysNumber < 1500) {
            return numberToMultiply * 6 / 10;
        }
       if(daysNumber < 1800) {
            return numberToMultiply * 5 / 10;
        }
       if(daysNumber < 2100) {
            return numberToMultiply * 4 / 10;
        }
       if(daysNumber < 2400) {
            return numberToMultiply * 3 / 10;
        }
       if(daysNumber < 2700) {
            return numberToMultiply * 2 / 10;
        }
       if(daysNumber < 3000) {
            return numberToMultiply  / 10;
        }
        return 0;
    }

    function min(uint256 a, uint256 b) private view returns (uint256) {
        return a <= b ?  a: b;
    }

}
