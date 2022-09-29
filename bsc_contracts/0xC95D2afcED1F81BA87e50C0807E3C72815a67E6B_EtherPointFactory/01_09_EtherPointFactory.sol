pragma solidity ^0.8.17;

import '../PointFactory.sol';
import './EtherPoint.sol';

contract EtherPointFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        uint256 needCount,
        address from,
        address to
    ) public {
        addPoint(
            dealId,
            address(
                new EtherPoint(
                    address(swaper),
                    needCount,
                    from,
                    to,
                    swaper.feeAddress(),
                    swaper.feeEth()
                )
            )
        );
    }
}