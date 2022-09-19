pragma solidity ^0.8.17;

import '../../PointFactory.sol';
import './Erc20CountPoint.sol';

contract Erc20CountPointFactory is PointFactory {
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
                new Erc20CountPoint(
                    address(swaper),
                    token,
                    needCount,
                    from,
                    to,
                    swaper.feeAddress(),
                    swaper.feePercent(),
                    swaper.feeDecimals()
                )
            )
        );
    }
}