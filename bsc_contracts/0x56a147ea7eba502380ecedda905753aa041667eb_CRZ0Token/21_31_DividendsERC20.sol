// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";

abstract contract DividendsERC20 is TokenTransfer {
    using SafeMath for uint256;

    // Index of the last token snapshot
    uint256 private nLastSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;

    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend total amount
    mapping(uint256 => uint256) private mapERCPayment;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    constructor(address _dividendsToken) public {
        // make sure the dividends token isnt empty
        require(_dividendsToken != address(0), "Dividends token cant be zero");

        // convert the address to an interface
        dividendsToken = IERC20(_dividendsToken);

        // get the balance of this contract to check if the interface works
        uint256 nBalance = dividendsToken.balanceOf(address(this));

        // this is never false, it's just a failsafe so that we execute balanceOf
        require(nBalance == 0, "Contract must have no balance");
    }

    /*
     * @dev Gets the address of the token used for dividends
     */
    function getDividendsToken() public view returns (address) {
        return address(dividendsToken);
    }

    /*
     * @dev Gets the total count of payments
     */
    function getTotalDividendPayments() public view returns (uint256) {
        return nLastSnapshotId;
    }

    function getPayment(uint256 _nIndex)
        public
        view
        returns (uint256 nERCPayment, uint256 nDate)
    {
        nERCPayment = mapERCPayment[_nIndex];
        nDate = mapPaymentDate[_nIndex];
    }

    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /*
     * @dev Function made for owner to transfer tokens to contract for dividend payment
     */
    function payDividends(uint256 _amount) public onlyOwner {
        // make sure the amount is not zero
        require(_amount > 0, "Amount cant be zero");

        // grab our current allowance
        uint256 nAllowance =
            dividendsToken.allowance(_msgSender(), address(this));

        // make sure we at least have the balance added
        require(_amount <= nAllowance, "Not enough balance to pay dividends");

        // transfer the tokens from the sender to the contract
        dividendsToken.transferFrom(_msgSender(), address(this), _amount);

        // snapshot the tokens at the moment the ether enters
        nLastSnapshotId = _snapshot();

        // register the balance in ether that entered
        mapERCPayment[nLastSnapshotId] = _amount;

        // save the date
        mapPaymentDate[nLastSnapshotId] = block.timestamp;
    }

    /*
     * @dev Withdraws dividends up to 16 times
     */
    function withdrawDividends() public {
        require(_withdrawDividends(), "No new withdrawal");

        for (uint256 i = 0; i < 15; i++) {
            if (!_withdrawDividends()) {
                return;
            }
        }
    }

    function _recursiveGetTotalDividends(address _investor)
        internal
        view
        returns (uint256)
    {
        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[_investor];

        // make sure we have a next payment
        if (nLastPayment >= nLastSnapshotId) {
            return 0;
        }

        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);

        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(_investor, nNextPayment);

        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[nNextPayment];

        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate);

        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);

        if (nTokenBalance == 0) {
            return 0;
        } else {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[nNextPayment];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalTokens, nTokenSuppy);

            return nToReceive;
        }
    }

    /**
     * @dev Gets the total amount of dividends for an investor
     */
    function getTotalDividends(address _investor)
        public
        view
        returns (uint256)
    {
        uint256 nBalance = 0;

        for (uint256 i = 0; i < 16; i++) {
            nBalance = nBalance.add(_recursiveGetTotalDividends(_investor));
        }

        return nBalance;
    }

    /*
     * @dev Based on how many tokens the user had at the snapshot,
     * pay dividends of the erc20 token
     * (also pays for tokens inside offer)
     */
    function _withdrawDividends() private returns (bool) {
        // cache the sender
        address aSender = _msgSender();

        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[aSender];

        // make sure we have a next payment
        if (nLastPayment >= nLastSnapshotId) {
            return false;
        }

        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);

        // save back that we have paid this user
        mapLastPaymentSnapshot[aSender] = nNextPayment;

        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(aSender, nNextPayment);

        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[nNextPayment];

        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate);

        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);

        if (nTokenBalance != 0) {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[nNextPayment];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalTokens, nTokenSuppy);

            // send the ERC20 value to the user
            dividendsToken.transfer(aSender, nToReceive);
        }

        return true;
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