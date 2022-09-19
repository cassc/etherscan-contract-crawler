pragma solidity ^0.8.17;

import '../../PointFactory.sol';
import './Erc721ItemPoint.sol';

contract Erc721ItemFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        address token,
        uint256 itemId,
        address from,
        address to
    ) public {
        addPoint(
            dealId,
            address(
                new Erc721ItemPoint(
                    address(swaper),
                    token,
                    itemId,
                    from,
                    to,
                    swaper.feeAddress(),
                    swaper.feeEth()
                )
            )
        );
    }
}