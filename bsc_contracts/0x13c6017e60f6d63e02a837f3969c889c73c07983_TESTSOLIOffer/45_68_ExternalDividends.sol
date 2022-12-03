/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev ExternalDividends handles the payment of an undetermined number of external dividends
 * @notice ExternalDividends é um token customizado onde os dividendos são pagos de forma externa, sem nenhum valor específico.
 */
contract ExternalDividends is TokenTransfer {
    using SafeMath for uint256;

    // Index of the current token snapshot
    uint256 private nCurrentSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;

    // Map of snapshot index to dividend total amount
    mapping(uint256 => uint256) private mapERCPayment;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    /**
     * @dev Constructor for DividendsERC20
     */
    constructor(
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_issuer, _totalTokens, _tokenName, _tokenSymbol) {}

    /**
     * @dev Gets the total count of payments
     */
    function getTotalDividendPayments() public view returns (uint256) {
        return nCurrentSnapshotId;
    }

    /**
     * @dev Gets payment data for the specified index
     */
    function getPayment(uint256 _nIndex)
        public
        view
        returns (uint256 nERCPayment, uint256 nDate)
    {
        nERCPayment = mapERCPayment[_nIndex];
        nDate = mapPaymentDate[_nIndex];
    }

    function setPaidDividendsMultiple(uint256 _count, uint256 _amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _count; i++) {
            setPaidDividends(_amount);
        }
    }

    /**
     * @dev Function made for owner to transfer tokens to contract for dividend payment
     */
    function setPaidDividends(uint256 _amount) public onlyOwner {
        // make sure the amount is not zero
        require(_amount > 0, "Amount cant be zero");

        // snapshot the tokens at the moment the ether enters
        nCurrentSnapshotId = _snapshot();

        // register the balance in ether that entered
        mapERCPayment[nCurrentSnapshotId] = _amount;

        // save the date
        mapPaymentDate[nCurrentSnapshotId] = block.timestamp;
    }

    function getDividends(address _aInvestor, uint256 _nPaymentIndex)
        public
        view
        returns (uint256)
    {
        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(_aInvestor, _nPaymentIndex);

        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[_nPaymentIndex];

        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate, _aInvestor);

        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);

        if (nTokenBalance == 0) {
            return 0;
        } else {
            // get the total supply at this snapshot
            uint256 nTokenSupply = totalSupplyAt(_nPaymentIndex);

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[_nPaymentIndex];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive = LiqiMathLib.mulDiv(
                nTokenBalance,
                nTotalTokens,
                nTokenSupply
            );

            return nToReceive;
        }
    }

    /**
     * @dev Gets the total amount of available dividends
     * to be cashed out for the specified _investor
     */
    function getDividendsRange(
        address _investor,
        uint256 _startIndex,
        uint256 _endIndex
    ) public view returns (uint256) {
        // start total balance 0
        uint256 nBalance = 0;

        // loop
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            // add the balance that would be withdrawn if called for this index
            nBalance = nBalance.add(getDividends(_investor, i));
        }

        return nBalance;
    }

    /**
     * @dev Gets the total amount of dividends for an investor
     */
    function getTotalDividends(address _investor)
        public
        view
        returns (uint256)
    {
        // start total balance 0
        uint256 nBalance = 0;

        // add 16 as the limit
        uint256 nEndPayment = Math.min(
            32,
            nCurrentSnapshotId.add(1)
        );

        // loop
        for (uint256 i = 1; i < nEndPayment; i++) {
            // add the balance that would be withdrawn if called for this index
            nBalance = nBalance.add(getDividends(_investor, i));
        }

        return nBalance;
    }
}