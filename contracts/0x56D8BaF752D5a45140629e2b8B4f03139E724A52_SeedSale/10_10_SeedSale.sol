// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {SeedSaleSupplyProvider} from "abstracts/SeedSaleSupplyProvider.sol";
import {EarlySaleReceiver} from "abstracts/EarlySaleReceiver.sol";

contract SeedSale is Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableMap.AddressToUintMap private _investorToAmount;
    SeedSaleSupplyProvider public supplyProvider;
    EarlySaleReceiver public receiver;
    bool public isClosed = false;

    event TokenReserved(address indexed investor, uint128 tokens);

    /**
     * @notice Sets the receiver of the token reservation amounts
     * @notice Contract must implement ERC165 and SeedSaleSupplyProvider
     * @notice Used to reduce the supply of another sale happening in parallel
     * @notice Set to the zero address to disable
     * @param _address, contract address
     */
    function setSupplyProvider(address _address) external onlyOwner {
        require(
            _address == address(0) ||
                ERC165Checker.supportsInterface(
                    _address,
                    type(SeedSaleSupplyProvider).interfaceId
                ),
            "not a compatible receiver"
        );

        supplyProvider = SeedSaleSupplyProvider(_address);
    }

    /**
     * @notice Reserves tokens for the specified investor
     */
    function reserveTokensFor(
        address investor,
        uint128 tokens
    ) external onlyOwner {
        require(!isClosed, "seed sale is closed");

        (, uint256 balance) = _investorToAmount.tryGet(investor);
        _investorToAmount.set(investor, balance + tokens);

        if (address(supplyProvider) != address(0))
            supplyProvider.reduceSupply(tokens);

        emit TokenReserved(investor, tokens);
    }

    /**
     * @notice Initializes the receiver of the token buy orders
     * @notice Contract must implement ERC165 and EarlySaleReceiver
     * @param _address, contract address
     */
    function setReceiver(address _address) external onlyOwner {
        require(address(receiver) == address(0), "address already set");
        require(
            ERC165Checker.supportsInterface(
                _address,
                type(EarlySaleReceiver).interfaceId
            ),
            "not a compatible receiver"
        );

        receiver = EarlySaleReceiver(_address);
    }

    /**
     * @notice Transfers a batch of buy orders to the receiver contract
     * @notice Ends the sale and locks the `reserveTokensFor` function
     * @notice Can only be called if the receiver address has been set
     * @param _count, the size of the batch to send
     */
    function sendBuyOrders(uint256 _count) external onlyOwner {
        require(address(receiver) != address(0), "receiver not set yet");
        require(
            _count <= _investorToAmount.length(),
            "count above investor count"
        );

        isClosed = true;

        while (_count != 0) {
            (address investor, uint256 tokens) = _investorToAmount.at(0);

            receiver.earlyDeposit(investor, 0, uint128(tokens));

            _investorToAmount.remove(investor);

            --_count;
        }
    }

    /**
     * @notice View the number of distinct investors
     */
    function investorCount() external view returns (uint256) {
        return _investorToAmount.length();
    }

    /**
     * @notice View the total amount of tokens a user has bought
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint256) {
        (, uint256 balance) = _investorToAmount.tryGet(_user);
        return balance;
    }
}