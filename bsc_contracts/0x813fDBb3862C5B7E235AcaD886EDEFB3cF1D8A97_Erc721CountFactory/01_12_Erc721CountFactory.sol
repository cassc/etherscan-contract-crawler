pragma solidity ^0.8.17;

import '../../PointFactory.sol';
import './Erc721CountPoint.sol';

contract Erc721CountFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        address token,
        uint256 needCount,
        address from,
        address to
    ) public {
        addPoint(
            dealId,
            address(
                new Erc721CountPoint(
                    address(swaper),
                    token,
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