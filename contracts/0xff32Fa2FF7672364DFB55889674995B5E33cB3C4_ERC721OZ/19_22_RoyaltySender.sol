// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/BasisPoints.sol";
import {Sender} from "./libraries/Sender.sol";
import {BasisPoints} from "./libraries/BasisPoints.sol";

/// @author Polemix team
/// @title A royalties contract
contract RoyaltySender is Ownable, Pausable {
    /**
     * @dev I'm storing basisPoint because fixedPoint is not supported yet.
     * 100 basisPoint = 1%
     *  */
    struct RoyaltyUser {
        address userAddress;
        uint16 basisPoint;
    }

    uint8 private immutable pmixSellPosition;
    uint8 private immutable pmixReSellPosition;
    uint8 private immutable ownerReSellPosition;

    bool private distribute = false;

    RoyaltyUser[] private firstSell;
    RoyaltyUser[] private reSell;

    /**
     * @dev Represents the accumulated amount before the best responses addresses are set in the contract
     *      This variable is used to accumulate amount to distribute when executeRoyalties method is executed
     */
    uint256 private sellAmount;

    /**
     * @notice Represents the quantity of addresses that are going to receive royalties in the primary sale.
     */
    uint8 private firstSellQuantity;

    /**
     * @notice Emited when a royalty is sent
     * @param userAddress destination address
     * @param amount sent amount
     */
    event SentRoyalty(address userAddress, uint256 amount);

    /**
     * @notice Emited when funds are incoming
     * @param amount deposited amount
     */
    event Deposit(uint256 amount);

    /**
     * @notice Emited when contract owner withdraw funds
     * @param withdrawAddress address to send the funds
     * @param amount amount to withdraw
     */
    event WithdrawEvent(
        address indexed withdrawAddress,
        uint256 amount
    );

    /**
    * @notice AddressIsContract event is fired when an address of best responses array is a contract
    */
    event AddressIsContract(address userAddress);

    /**
     * @param firstSellQuantity_ quantity of addresses to give royalties
     * @param pmixAddress polemix address
     * @param pmixSellBasisPoints polemix basis points in the first sale
     * @param pmixReSellBasisPoints polemix basis points in the resale
     * @param ownerAddress owner address
     * @param ownerReSellBasisPoints owner basis points in the resale
     */
    constructor(
        uint8 firstSellQuantity_,
        address pmixAddress,
        uint16 pmixSellBasisPoints,
        uint16 pmixReSellBasisPoints,
        address ownerAddress,
        uint16 ownerReSellBasisPoints
    )
        checkBasisPoint(pmixSellBasisPoints)
        checkBasisPoint(pmixReSellBasisPoints)
        checkBasisPoint(ownerReSellBasisPoints)
        Pausable()
    {
        require(firstSellQuantity_ > 0, "First sell quantity must be > 0");

        firstSellQuantity = firstSellQuantity_;

        firstSell.push(RoyaltyUser(pmixAddress, pmixSellBasisPoints));
        pmixSellPosition = uint8(firstSell.length - 1);

        reSell.push(RoyaltyUser(pmixAddress, pmixReSellBasisPoints));
        pmixReSellPosition = uint8(reSell.length - 1);

        reSell.push(RoyaltyUser(ownerAddress, ownerReSellBasisPoints));
        ownerReSellPosition = uint8(reSell.length - 1);
    }

    /**
     * @notice receive: function that is called when nft is bought in an external marketplace
     * If the contract is paused then this function is disabled
     */
    receive() external payable whenNotPaused {
        emit Deposit(msg.value);
        sendRoyalties(reSell, msg.value);
    }

    /**
     * @notice checkBasisPoint: Modifier used to check basis point boundaries. Basis points should be between 1 and 10000
     */
    modifier checkBasisPoint(uint16 basisPoint) {
        require(
            BasisPoints.check(basisPoint),
            "Basis point beetween 1 and 10000"
        );
        _;
    }

    /**
     * @notice Adds the given addresses to the firstSell array and executes the royalties for all the addresses that must receive royalties.
     * @dev This function is executed only one time by the contract owner and sets royalties in distribute mode.
     *      If it has accumulated funds then it sends royalties to the right addresses
     *      FirstSell addresses which are from an smart contract will not receive royalties
     * @param firstSell_ contains the information used in the first sale
     */
    function executeRoyalties(RoyaltyUser[] memory firstSell_)
        external
        onlyOwner
    {
        require(!distribute, "Method already executed");
        require(
            (firstSell_.length + firstSell.length) <= firstSellQuantity,
            "First sell quantity are invalid"
        );

        for (uint256 i = 0; i < firstSell_.length; i++) {
            if(!Address.isContract(firstSell_[i].userAddress)) { 
                firstSell.push(firstSell_[i]);
            } else {
                emit AddressIsContract(firstSell_[i].userAddress);
            }
        }

        distribute = true;

        if (sellAmount > 0) {
            sendRoyalties(firstSell, sellAmount);
        }
    }

    /**
     * @notice receiveRoyalties
     * It is used to receive eth from mint transactions
     * Variable sellAmount accumulated amount that will be used when contract owner executes royalties
     * Contract owner is able to disable this function pausing the contract
     */
    function receiveRoyalties() external payable whenNotPaused {
        emit Deposit(msg.value);
        if (distribute) {
            sendRoyalties(firstSell, msg.value);
        } else {
            sellAmount = sellAmount + msg.value;
        }
    }

    /**
     * editPmixRoyalties
     * @param pmixAddress contains the wallet address used by polemix to get royalties
     * @param firstSellBasisPoint basis point for calculating the first sale
     * @param reSellBasisPoint basis point for calculating the resales
     */
    function editPmixRoyalties(
        address pmixAddress,
        uint16 firstSellBasisPoint,
        uint16 reSellBasisPoint
    )
        external
        checkBasisPoint(firstSellBasisPoint)
        checkBasisPoint(reSellBasisPoint)
        onlyOwner
    {
        firstSell[pmixSellPosition] = RoyaltyUser(
            pmixAddress,
            firstSellBasisPoint
        );
        reSell[pmixReSellPosition] = RoyaltyUser(pmixAddress, reSellBasisPoint);
    }

    /**
     * @notice editOwnerRoyalties
     * @param ownerAddress contains the wallet address used by owner to get royalties
     * @param reSellBasisPoint basis point for calculating the resales
     */
    function editOwnerRoyalties(address ownerAddress, uint16 reSellBasisPoint)
        external
        checkBasisPoint(reSellBasisPoint)
        onlyOwner
    {
        reSell[ownerReSellPosition] = RoyaltyUser(
            ownerAddress,
            reSellBasisPoint
        );
    }

    /**
     * @notice Returns the contract balance
     * @return Returns the contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns data about polemix royalties
     * @return address polemix address
     * @return saleBasisPoint basis point used in the first sale
     * @return reSaleBasisPoint basis point used in in the secondary sales
     */
    function getPmixRoyalties()
        external
        view
        returns (
            address,
            uint16,
            uint16
        )
    {
        return (
            firstSell[pmixSellPosition].userAddress,
            firstSell[pmixSellPosition].basisPoint,
            reSell[pmixReSellPosition].basisPoint
        );
    }

    /**
     * @notice Returns data about owner royalties
     * @return tuple(address pmixAddress, uint16 reSaleBasisPoint)
     */
    function getOwnerRoyalties() external view returns (address, uint16) {
        return (
            reSell[ownerReSellPosition].userAddress,
            reSell[ownerReSellPosition].basisPoint
        );
    }

    /**
     * @notice getRoyalties returns data related to the royalties
     * @return firstSell_ royalty data associated with the first sale
     * @return reSell_ roayalty data associated with secondary sales in external marketplaces
     */
    function getRoyalties()
        external
        view
        onlyOwner
        returns (RoyaltyUser[] memory firstSell_, RoyaltyUser[] memory reSell_)
    {
        return (firstSell, reSell);
    }

    /**
     * @notice Pause or resume contract state
     * The contract owner is the unique address able to pause/unpause the contract. This is an emergency stop mechanism.
     * @param pauseState. If it is true, contract is paused, otherwise is unpause
     */
    function pauseContract(bool pauseState) external onlyOwner {
        if (pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice send all the royalties. This function iterates all the addresses that must receive royalties and send the amount according to their basis points.
     */
    function sendRoyalties(RoyaltyUser[] memory sell, uint256 amount) private {
        for (uint256 i = 0; i < sell.length; i++) {
            Sender.sendBalancePercentage(
                sell[i].userAddress,
                sell[i].basisPoint,
                amount
            );
        }
    }

    /**
     * @notice Withdraw function. This function is used to extract remaining value from the contract.
     * @param withdrawAddress destination address to send the funds
     */
     function withdrawBalance(address payable withdrawAddress) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawAddress).transfer(balance);
        emit WithdrawEvent(withdrawAddress, balance);
     }
}