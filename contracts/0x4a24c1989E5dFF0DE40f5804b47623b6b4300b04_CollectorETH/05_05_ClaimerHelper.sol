// SPDX-License-Identifier: --BCOM--

pragma solidity =0.8.18;

contract ClaimerHelper {

    uint256 public totalRequired;
    address public immutable wiserToken;

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
        address _wiserTokenAddress
    ) {
        if (_wiserTokenAddress == address(0x0)) {
            revert("ClaimerHelper: INVALID_TOKEN");
        }

        wiserToken = _wiserTokenAddress;
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

    function _safeScrape(
        address _to,
        uint256 _scrapeAmount
    )
        internal
    {
        totalRequired -= _scrapeAmount;

        (bool success, bytes memory data) = wiserToken.call(
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
            "ClaimerHelper: TRANSFER_FAILED"
        );
    }

    function _checkBalance(
        uint256 _required
    )
        internal
    {
        (bool success, bytes memory data) = wiserToken.call(
            abi.encodeWithSelector(
                BALANCEOF,
                address(this)
            )
        );

        require(
            success && abi.decode(
                data, (uint256)
            ) >= _required,
            "ClaimerHelper: BALANCE_CHECK_FAILED"
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