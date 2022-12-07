// SPDX-License-Identifier: --BCOM--

pragma solidity =0.8.17;

contract VerseHelper {

    uint256 public totalRequired;
    address public immutable verseToken;

    event recipientEnrolled(
        address indexed recipient,
        uint256 timeFrame,
        uint256 tokensLocked,
        uint256 tokensOpened
    );

    event tokensScraped(
        address indexed scraper,
        uint256 scrapedAmount,
        uint256 timestamp
    );

    constructor(
        address _verseTokenAddress
    ) {
        if (_verseTokenAddress == address(0x0)) {
            revert("VerseHelper: INVALID_VERSE_TOKEN");
        }

        verseToken = _verseTokenAddress;
    }

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                "transfer(address,uint256)"
            )
        )
    );

    bytes4 private constant BALANCEOF = bytes4(
        keccak256(
            bytes(
                "balanceOf(address)"
            )
        )
    );

    function _safeVerseScrape(
        address _to,
        uint256 _scrapeAmount
    )
        internal
    {
        totalRequired -= _scrapeAmount;

        (bool success, bytes memory data) = verseToken.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _scrapeAmount
            )
        );

        require(
            success && (
                abi.decode(
                    data, (bool)
                )
            ),
            "VerseHelper: TRANSFER_FAILED"
        );
    }

    function _checkVerseBalance(
        uint256 _required
    )
        internal
    {
        (bool success, bytes memory data) = verseToken.call(
            abi.encodeWithSelector(
                BALANCEOF,
                address(this)
            )
        );

        require(
            success && abi.decode(
                data, (uint256)
            ) >= _required,
            "VerseHelper: BALANCE_CHECK_FAILED"
        );
    }

    function getNow()
        public
        view
        returns (uint256 time)
    {
        time = block.timestamp;
    }
}
