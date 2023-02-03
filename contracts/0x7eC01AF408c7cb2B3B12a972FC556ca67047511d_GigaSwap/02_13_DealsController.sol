// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../lib/factories/HasFactories.sol';
import './IDealsController.sol';
import './IDealPointsController.sol';
import './Deal.sol';
import './DealPointRef.sol';
import './DealPointData.sol';

abstract contract DealsController is IDealsController, HasFactories {
    mapping(uint256 => Deal) internal _deals; // deal headers by id
    mapping(uint256 => mapping(uint256 => DealPointRef)) internal _dealPoints; // controllers for each deal point
    uint256 internal _dealsCount;
    uint256 internal _totalDealPointsCount;
    uint256 constant dealPointsLimit = 20;

    modifier onlyEditDealState(uint256 dealId) {
        require(_deals[dealId].state == 1, 'deal is not in edit state');
        _;
    }

    modifier onlyExecutionDealState(uint256 dealId) {
        require(_deals[dealId].state == 2, 'deal is not in execution state');
        _;
    }

    function getTotalDealPointsCount() external view returns (uint256) {
        return _totalDealPointsCount;
    }

    function createDeal(address owner1, address owner2)
        external
        onlyFactory
        returns (uint256)
    {
        // create a deal
        Deal memory dealHeader = Deal(
            1, // editing
            owner1, // 1 owner
            owner2, // 2 owner
            0
        );
        ++_dealsCount;
        _deals[_dealsCount] = dealHeader;
        emit NewDeal(_dealsCount, owner1);

        return _dealsCount;
    }

    function addDealPoint(
        uint256 dealId,
        address dealPointsController,
        uint256 newPointId
    ) external onlyFactory onlyEditDealState(dealId) {
        Deal storage deal = _deals[dealId];
        require(deal.state == 1, 'only for editing deal state');
        _dealPoints[dealId][deal.pointsCount] = DealPointRef(
            dealPointsController,
            newPointId
        );
        ++deal.pointsCount;
        require(
            deal.pointsCount <= dealPointsLimit,
            'deal points count exceeds of limit'
        );
        ++_totalDealPointsCount;
    }

    function getDealHeader(uint256 dealId) external view returns (Deal memory) {
        Deal memory header = _deals[dealId];
        require(header.state > 0, 'deal is not exists');
        return header;
    }

    /// @dev returns a deal, if there is no such deal, it gives an error
    function getDeal(uint256 dealId)
        external
        view
        override
        returns (Deal memory, DealPointData[] memory)
    {
        Deal memory deal = _deals[dealId];
        DealPointData[] memory points = new DealPointData[](deal.pointsCount);
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            points[i] = this.getDealPoint(dealId, i);
        }
        return (deal, points);
    }

    /// @dev if true, then the transaction is completed and it can be swapped
    function isExecuted(uint256 dealId) external view returns (bool) {
        // get the count of deal points
        Deal memory deal = _deals[dealId];
        if (deal.pointsCount == 0) return false;
        // take the deal points
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        // checking all deal points
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            if (
                !IDealPointsController(payable(pointRef.controller)).isExecuted(
                    pointRef.id
                )
            ) return false;
        }
        return true;
    }

    function swap(uint256 dealId) external onlyExecutionDealState(dealId) {
        // take the amount of points
        Deal storage deal = _deals[dealId];
        require(deal.pointsCount > 0, 'deal has no points');
        // check all points to be executed
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            require(
                IDealPointsController(payable(pointRef.controller)).isExecuted(
                    pointRef.id
                ),
                'there are not executed deal points'
            );
        }
        // set header as swapped
        deal.state = 3; // deal is now swapped
        // emit event
        emit Swap(dealId);
    }

    function isSwapped(uint256 dealId) external view returns (bool) {
        return _deals[dealId].state == 3;
    }

    function withdraw(uint256 dealId) external payable {
        // take a deal
        Deal storage deal = _deals[dealId];
        require(deal.state > 0, 'deal id is not exists');
        require(deal.pointsCount > 0, 'deal has no points');
        // user restriction
        require(
            msg.sender == deal.owner1 || msg.sender == deal.owner2,
            'only for deal member'
        );
        // withdraw all the details
        uint256 dif = msg.value;
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            if (controller.owner(pointRef.id) == msg.sender) {
                if (deal.state == 3 && controller.feeIsEthOnWithdraw()) {
                    uint256 v = controller.fee(pointRef.id);
                    controller.withdraw{ value: v }(pointRef.id);
                    dif -= v;
                } else {
                    controller.withdraw(pointRef.id);
                }
            }
        }

        if (dif > 0) {
            (bool sent, ) = payable(msg.sender).call{ value: dif }('');
            require(sent, 'sent ether error: ether is not sent');
        }

        // emit deal not executed (if not swapped)
        if (deal.state != 3) emit Execute(dealId, msg.sender, false);

        // emit event
        emit OnWithdraw(dealId, msg.sender);
    }

    function feeEthOnWithdraw(uint256 dealId, uint256 ownerNumber)
        external
        view
        returns (uint256)
    {
        uint256 fee;
        Deal storage deal = _deals[dealId];
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            if (ownerNumber == 1) {
                if (controller.owner(pointRef.id) == deal.owner1) {
                    if (controller.feeIsEthOnWithdraw())
                        fee += controller.fee(pointRef.id);
                }
            } else if (ownerNumber == 2) {
                if (controller.owner(pointRef.id) == deal.owner2) {
                    if (controller.feeIsEthOnWithdraw())
                        fee += controller.fee(pointRef.id);
                }
            }
        }
        return fee;
    }

    function getDealPoint(uint256 dealId, uint256 pointIndex)
        external
        view
        returns (DealPointData memory)
    {
        DealPointRef storage ref = _dealPoints[dealId][pointIndex];
        IDealPointsController controller = IDealPointsController(
            payable(ref.controller)
        );
        return
            DealPointData(
                ref.controller,
                ref.id,
                controller.dealPointTypeId(),
                dealId,
                controller.from(ref.id),
                controller.to(ref.id),
                controller.owner(ref.id),
                controller.value(ref.id),
                controller.balance(ref.id),
                controller.fee(ref.id),
                controller.tokenAddress(ref.id),
                controller.isSwapped(ref.id),
                controller.isExecuted(ref.id)
            );
    }

    function getDealPointsCount(uint256 dealId)
        external
        view
        returns (uint256)
    {
        return _deals[dealId].pointsCount;
    }

    /// @dev returns all deal points
    /// @param dealId deal id
    function getDealPoints(uint256 dealId)
        external
        view
        returns (DealPointRef[] memory)
    {
        Deal memory deal = _deals[dealId];
        DealPointRef[] memory res = new DealPointRef[](deal.pointsCount);
        for (uint256 i = 0; i < deal.pointsCount; ++i)
            res[i] = _dealPoints[dealId][i];
        return res;
    }

    function stopDealEditing(uint256 dealId)
        external
        onlyFactory
        onlyEditDealState(dealId)
    {
        _deals[dealId].state = 2;
    }

    function execute(uint256 dealId) external payable {
        // if it is openswap - set owner
        Deal storage deal = _deals[dealId];
        require(deal.state == 2, 'only executing state');
        bool isOpenSwapNotOwner;
        if (deal.owner2 == address(0) && msg.sender != deal.owner1) {
            deal.owner2 = msg.sender;
            isOpenSwapNotOwner = true;
        }

        // take the amount of points
        require(deal.pointsCount > 0, 'deal has no points');
        // check all points to be executed
        uint256 dif = msg.value;
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            address from = controller.from(pointRef.id);
            if (
                controller.to(pointRef.id) == address(0) && isOpenSwapNotOwner
            ) {
                controller.setTo(pointRef.id, msg.sender);
                continue;
            }
            if (
                from == msg.sender || (from == address(0) && isOpenSwapNotOwner)
            ) {
                uint256 v = controller.executeEtherValue(pointRef.id);
                controller.execute{ value: v }(pointRef.id, msg.sender);
                dif -= v;
            }
        }

        if (dif > 0) {
            (bool sent, ) = payable(msg.sender).call{ value: dif }('');
            require(sent, 'sent ether error: ether is not sent');
        }

        // emit event
        emit Execute(dealId, msg.sender, true);
    }

    function executeEtherValue(uint256 dealId, uint256 ownerNumber)
        external
        view
        returns (uint256)
    {
        uint256 value;
        Deal storage deal = _deals[dealId];
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            if (ownerNumber == 1) {
                if (controller.owner(pointRef.id) == deal.owner1) {
                    value += controller.executeEtherValue(pointRef.id);
                }
            } else if (ownerNumber == 2) {
                if (controller.owner(pointRef.id) == deal.owner2) {
                    value += controller.executeEtherValue(pointRef.id);
                }
            }
        }
        return value;
    }
}