//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

library BidUtils {
    /**
     * @dev Retrieves the bid and buyer premium amount from the _amount based on _buyerPremiumRate
     *
     * @param _amount The entire amount (bid amount + buyer premium amount)
     * @param _buyerPremiumRate The buyer premium RBS used to calculate _amount
     * @return The bid sent and the premium sent
     */
    function _getSentBidAndPremium(uint256 _amount, uint64 _buyerPremiumRate)
        private
        pure
        returns (
            uint256, /*sentBid*/
            uint256 /*sentPremium*/
        )
    {
        uint256 bpRate = _buyerPremiumRate + 10000;
        uint256 _sentBid = uint256((_amount * 10000) / bpRate);
        uint256 _sentPremium = uint256(_amount - _sentBid);
        return (_sentBid, _sentPremium);
    }

    /**
     * @dev Validates that the total amount sent is valid for the current state of the auction
     *  and returns the bid amount and buyer premium amount sent
     *
     * @param _totalAmount The total amount sent (bid amount + buyer premium amount)
     * @param _buyerPremium The current  buyer premium rate
     * @param _reservePrice The reserve price of the auction
     * @param _currentBidAmount The current bid to validate
     * @param _minimumBidIncrement The minimum bid increase threshold
     * @param _currentBidder The address of the highest bidder of the auction
     * @return boolean true if the amount satisfies the state of the auction; the sent bid; and the sent premium
     */
    function validateAndGetBid(
        uint256 _totalAmount,
        uint64 _buyerPremium,
        uint256 _reservePrice,
        uint256 _currentBidAmount,
        uint256 _minimumBidIncrement,
        address _currentBidder
    )
        internal
        pure
        returns (
            uint256, /*sentBid*/
            uint256 /*sentPremium*/
        )
    {
        (uint256 _sentBid, uint256 _sentPremium) = _getSentBidAndPremium(
            _totalAmount,
            _buyerPremium
        );
        if (_currentBidder == address(0)) {
            // This is the first bid against reserve price
            require(_sentBid >= _reservePrice, 'reserve not met');
        } else {
            // Subsequent bids must meet minimum bid increment
            require(
                _sentBid >= _currentBidAmount + (_currentBidAmount * _minimumBidIncrement) / 10000,
                'minimum bid not met'
            );
        }
        return (_sentBid, _sentPremium);
    }
}