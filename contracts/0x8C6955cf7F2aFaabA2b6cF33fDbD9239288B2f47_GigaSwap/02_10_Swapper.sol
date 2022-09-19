pragma solidity ^0.8.17;

//import "hardhat/console.sol";
import './ISwapper.sol';
import './Deal.sol';
import './IDealPoint.sol';
import './IDealPointFactory.sol';
import 'contracts/lib/ownable/Ownable.sol';

/// @dev data about one position in a deal
struct DealPointData {
    address factory;
    address point;
}

abstract contract Swapper is ISwapper, Ownable {
    mapping(uint256 => Deal) public deals;
    mapping(uint256 => mapping(uint256 => DealPointData)) public dealPoints; // deal points
    mapping(uint256 => uint256) public dealPointsCounts; // deal points counts
    mapping(address => bool) public factories; // deal point factories
    mapping(address => uint256) public dealsCountByAccount; // deals county by account
    mapping(address => mapping(uint256 => uint256)) dealsByAccounts; // deals by accounts
    uint256 public dealsCount;

    event NewDeal(uint256 indexed dealId, address indexed creator);

    function makeDeal(address anotherAccount) external {
        // create a deal
        Deal memory deal = Deal(
            1, // editing
            msg.sender, // 0 owner
            anotherAccount // 1 owner
        );
        ++dealsCount;
        deals[dealsCount] = deal;
        dealsByAccounts[msg.sender][
            dealsCountByAccount[msg.sender]++
        ] = dealsCount;
        emit NewDeal(dealsCount, msg.sender);
    }

    function addDealPoint(uint256 dealId, address point) external override {
        require(factories[msg.sender], 'only for factories');
        require(deals[dealId].state == 1, 'deal is not in edit state');
        uint256 pointsCount = dealPointsCounts[dealId];
        dealPoints[dealId][pointsCount] = DealPointData(msg.sender, point);
        dealPointsCounts[dealId] = pointsCount + 1;
    }

    function addFactory(address factory) public onlyOwner {
        factories[factory] = true;
    }

    function removeFactory(address factory) public onlyOwner {
        factories[factory] = false;
    }

    function setFactories(address[] memory factories_, bool value)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < factories_.length; ++i)
            factories[factories_[i]] = value;
    }

    /// @dev returns a deal, if there is no such deal, it gives an error
    function getDeal(uint256 dealId)
        external
        view
        override
        returns (Deal memory)
    {
        Deal memory deal = deals[dealId];
        require(deal.state > 0, 'deal is not exists');
        return deal;
    }

    function getDealIdByIndex(address account, uint256 index)
        public
        view
        returns (uint256)
    {
        return dealsByAccounts[account][index];
    }

    /// @dev returns the deal page for the address
    /// @param account who to get the deals on
    /// @param startIndex start index
    /// @param count how many deals to get
    /// @return how many deals are open in total, deal id, deals, number of points per deal
    function getDealsPage(
        address account,
        uint256 startIndex,
        uint256 count
    )
        external
        view
        returns (
            uint256,
            uint256[] memory,
            Deal[] memory,
            uint256[] memory
        )
    {
        uint256 playerDealsCount = dealsCountByAccount[account];
        if (startIndex + count > playerDealsCount) {
            if (startIndex >= playerDealsCount)
                return (
                    playerDealsCount,
                    new uint256[](0),
                    new Deal[](0),
                    new uint256[](0)
                );
            count = playerDealsCount - startIndex;
        }

        uint256[] memory ids = new uint256[](count);
        Deal[] memory dealsResult = new Deal[](count);
        uint256[] memory pointsCount = new uint256[](count);

        for (uint256 i = 0; i < count; ++i) {
            uint256 id = getDealIdByIndex(account, i);
            ids[startIndex + i] = id;
            dealsResult[startIndex + i] = deals[id];
            uint256 pc = dealPointsCounts[id];
            pointsCount[startIndex + i] = pc;
        }

        return (playerDealsCount, ids, dealsResult, pointsCount);
    }

    /// @dev if true, then the transaction is completed and it can be swapped
    function isComplete(uint256 dealId) public view returns (bool) {
        // get the count of details per transaction
        uint256 pointsCount = dealPointsCounts[dealId];
        if (pointsCount == 0) return false;
        // take the details
        mapping(uint256 => DealPointData) storage points = dealPoints[dealId];
        // checking all details
        for (uint256 i = 0; i < pointsCount; ++i)
            if (!IDealPoint(points[i].point).isComplete()) return false;
        return true;
    }

    /// @dev makes swap deals.
    /// Если If the deal is not completed - an error
    /// Если If the deal is already swapped - an error
    function swap(uint256 dealId) external {
        // take a deal
        Deal storage deal = deals[dealId];
        require(deal.state == 2, 'only in execution state');
        // take the amount of details
        uint256 pointsCount = dealPointsCounts[dealId];
        require(pointsCount > 0, 'deal has no points');
        // swap all the details
        mapping(uint256 => DealPointData) storage points = dealPoints[dealId];
        for (uint256 i = 0; i < pointsCount; ++i) {
            IDealPoint point = IDealPoint(points[i].point);
            require(point.isComplete(), 'there are uncompleted parts');
            point.swap();
        }

        ++deal.state; // next state to avoid double swap
        deals[dealId] = deal;
    }

    /// @dev makes a withdrawal of funds from the deal
    function withdraw(uint256 dealId) external {
        // take a deal
        Deal storage deal = deals[dealId];
        require(deal.state > 0, 'deal id is not exists');
        // take the amount of details
        uint256 pointsCount = dealPointsCounts[dealId];
        require(pointsCount > 0, 'deal has no points');
        // user restriction
        require(
            msg.sender == deal.owner0 || msg.sender == deal.owner1,
            'only for deal member'
        );
        // swap all the details
        mapping(uint256 => DealPointData) storage points = dealPoints[dealId];
        for (uint256 i = 0; i < pointsCount; ++i) {
            IDealPoint point = IDealPoint(points[i].point);
            point.withdraw();
        }
    }

    function stopEdit(uint256 dealId) external {
        Deal storage deal = deals[dealId];
        require(deal.state == 1, 'only in editing state');
        require(
            msg.sender == deal.owner0 || msg.sender == deal.owner1,
            'only for owner'
        );
        ++deal.state;
    }

    /// @dev returns the deal point
    /// @param dealId deal id
    /// @param dealPointIndex deal point index
    function getDealPoint(uint256 dealId, uint256 dealPointIndex)
        external
        view
        returns (DealPointData memory)
    {
        return dealPoints[dealId][dealPointIndex];
    }

    /// @dev returns all deal points
    /// @param dealId deal id
    function getDealPoints(uint256 dealId)
        external
        view
        returns (DealPointData[] memory)
    {
        uint256 count = dealPointsCounts[dealId];
        DealPointData[] memory res = new DealPointData[](count);
        for (uint256 i = 0; i < count; ++i) res[i] = dealPoints[dealId][i];
        return res;
    }
}