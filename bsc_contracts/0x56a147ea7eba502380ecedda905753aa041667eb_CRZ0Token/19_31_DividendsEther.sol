// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "./../TokenTransfer.sol";

abstract contract DividendsEther is TokenTransfer {
    uint256 private nSnapshotId;

    mapping(address => uint256) private mapLastPaymentSnapshot;
    mapping(uint256 => uint256) private mapEtherPayment;

    function withdrawDividends() public {
        // use payable so we can send the dividends
        address payable aSender = _msgSender();

        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[aSender];

        // make sure we have a next payment
        require(nLastPayment < nSnapshotId, "No new withdrawal");

        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);

        // save back that we have paid this user
        mapLastPaymentSnapshot[aSender] = nNextPayment;

        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(aSender, nNextPayment);

        // if there's balance, pay dividends
        if (nTokenBalance == 0) {
            // get the total eth balance for this payment
            uint256 nTotalEther = mapEtherPayment[nNextPayment];

            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalEther, nTokenSuppy);

            // send the ether value to the user
            aSender.transfer(nToReceive);
        }
        // console.log("Last Payment: %s", nLastPayment);
        // console.log("Next Payment: %s", nNextPayment);
        // console.log("Latest Payment: %s", nSnapshotId);
        // console.log("-------");
        // console.log("Total Supply: %s", nTokenSuppy);
        // console.log("Total Ether: %s", nTotalEther);
        // console.log("To Receive: %s", nToReceive);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        // snapshot the tokens at the moment the ether enters
        nSnapshotId = _snapshot();
        // register the balance in ether that entered
        mapEtherPayment[nSnapshotId] = msg.value;

        // console.log("Ether To be Paid: %s", msg.value);
        // console.log("Total Token supply: %s", totalSupplyAt(nSnapshotId));
    }

    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 xl = uint128(x);
        uint256 xh = x >> 128;
        uint256 yl = uint128(y);
        uint256 yh = y >> 128;
        uint256 xlyl = xl * yl;
        uint256 xlyh = xl * yh;
        uint256 xhyl = xh * yl;
        uint256 xhyh = xh * yh;

        uint256 ll = uint128(xlyl);
        uint256 lh = (xlyl >> 128) + uint128(xlyh) + uint128(xhyl);
        uint256 hl = uint128(xhyh) + (xlyh >> 128) + (xhyl >> 128);
        uint256 hh = (xhyh >> 128);
        l = ll + (lh << 128);
        h = (lh >> 128) + hl + (hh << 128);
    }

    /**
    * @dev Very cheap x*y/z
    */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }
}