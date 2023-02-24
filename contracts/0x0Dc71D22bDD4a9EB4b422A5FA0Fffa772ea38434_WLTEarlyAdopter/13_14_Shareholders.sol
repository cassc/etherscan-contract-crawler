// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
 * @title Shareholders
 * Shareholders - Allows defining sharesplit between shareholders and having payouts of contract balance based on share splits.
 * Can be used with ERC-721 or ERC-1155.
 */
abstract contract Shareholders {

    // Constants
    uint16 private constant TOTAL_SHARES = 10000;

    // Contract shareholders
    struct Shareholder {
        uint256 share;
        address payable shareholder_address;
    }
    Shareholder[] public shareholders;

    event Payout(address indexed _to, uint256 _value);

    /**
     * @dev Constructor
     * @param _shares The number of shares each shareholder has
     * @param _shareholder_addresses Payment address for each shareholder
     */
    constructor(
        uint256[] memory _shares,
        address payable[] memory _shareholder_addresses
    ) {

        // there should be at least one shareholder
        require(
            _shareholder_addresses.length > 0,
            "_shareholder_addresses must have at least one item."
        );

        // the _shares and _shareholder_addresses provided should be the same length
        require(
            _shares.length == _shareholder_addresses.length,
            "_shareholder_addresses and _shares must be of the same length"
        );

        // keep track of the total number of shares
        uint256 _total_number_of_shares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            _total_number_of_shares += _shares[i];
            Shareholder memory x = Shareholder({
                share: _shares[i],
                shareholder_address: _shareholder_addresses[i]
            });
            shareholders.push(x);
        }

        // there should be exactly 10,000 shares, this amount is used to calculate payouts
        require(
            _total_number_of_shares == TOTAL_SHARES,
            "Total number of shares must be 10,000"
        );
    }

    /**
     * @dev Once the royalty contract has a balance, call this to payout to the shareholders
     */
    function payout() public payable {
        // the balance must be greater than 0
        require(address(this).balance > 0, "Contract balance is 0");

        // get the balance of ETH held by the royalty contract
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < shareholders.length; i++) {
            // 10,000 shares represents 100.00% ownership
            uint256 amount = (balance * shareholders[i].share) / TOTAL_SHARES;

            // https://solidity-by-example.org/sending-ether/
            // this considered the safest way to send ETH
            (bool success, ) = shareholders[i].shareholder_address.call{
                value: amount
            }("");

            // it should not fail
            require(success, "Transfer failed.");

            emit Payout(shareholders[i].shareholder_address, amount);
        }
    }

    // https://solidity-by-example.org/sending-ether/
    // receive is called when msg.data is empty.
    receive() external payable {}

    // https://solidity-by-example.org/sending-ether/
    // fallback function is called when msg.data is not empty.
    fallback() external payable {}

}