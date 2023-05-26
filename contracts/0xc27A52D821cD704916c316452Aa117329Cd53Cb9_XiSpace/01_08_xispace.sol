// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * The Purpose of this contract is to handle the booking of areas to display specific images at coordinates for a determined time.
 * The booking process is two steps, as validation from the contract operators is required.
 * Users can create and cancel submissions, identified by a unique ID.
 * The operator can accept and reject user submissions. Rejected submissions are refunded.
*/
contract XiSpace is AccessControl {

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant PRICE_ROLE = keccak256("PRICE_ROLE");

    uint256 public constant BETA_RHO_SUPPLY = 6790 * 10**18;
    uint256 public constant MAX_X = 1200;
    uint256 public constant MAX_Y = 1080;
    uint256 public PIXEL_X_PRICE = BETA_RHO_SUPPLY / MAX_X / 100;
    uint256 public PIXEL_Y_PRICE = BETA_RHO_SUPPLY / MAX_Y / 100;
    uint256 public SECOND_PRICE = 10**17;

    address public treasury = 0x1f7c453a4cccbF826A97F213706Ee72b79dba466;

    IERC20 public betaToken = IERC20(0x35F67c1D929E106FDfF8D1A55226AFe15c34dbE2);
    IERC20 public rhoToken = IERC20(0x3F3Cd642E81d030D7b514a2aB5e3a5536bEb90Ec);
    IERC20 public kappaToken = IERC20(0x5D2C6545d16e3f927a25b4567E39e2cf5076BeF4);
    IERC20 public gammaToken = IERC20(0x1E1EEd62F8D82ecFd8230B8d283D5b5c1bA81B55);
    IERC20 public xiToken = IERC20(0x295B42684F90c77DA7ea46336001010F2791Ec8c);

    event SUBMISSION(uint256 id, address indexed addr);
    event CANCELLED(uint256 id);
    event BOOKED(uint256 id);
    event REJECTED(uint256 id, bool fundsReturned);

    struct Booking {
        uint16 x;
        uint16 y;
        uint16 width;
        uint16 height;
        bool validated;
        uint256 time;
        uint256 duration;
        bytes32 sha;
        address owner;
    }

    struct Receipt {
        uint256 betaAmount;
        uint256 rhoAmount;
        uint256 kappaAmount;
        uint256 gammaAmount;
        uint256 xiAmount;
    }

    uint256 public bookingsCount = 0;

    // Store the booking submissions
    mapping(uint256 => Booking) public bookings;

    // Store the amounts of Kappa and Gamma provided by the user for an area
    mapping(uint256 => Receipt) public receipts;

    constructor(address beta, address rho, address kappa, address gamma, address xi) {
        // in case we want to override the addresses (for testnet)
        if(beta != address(0)) {
            betaToken = IERC20(beta);
            rhoToken = IERC20(rho);
            kappaToken = IERC20(kappa);
            gammaToken = IERC20(gamma);
            xiToken = IERC20(xi);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VALIDATOR_ROLE, msg.sender);
        _setRoleAdmin(VALIDATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(TREASURER_ROLE, msg.sender);
        _setRoleAdmin(TREASURER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(PRICE_ROLE, msg.sender);
        _setRoleAdmin(PRICE_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function setTreasury(address _treasury) external onlyRole(TREASURER_ROLE) {
        treasury = _treasury;
    }

    function setXiDivisor(uint256 divisor) external onlyRole(PRICE_ROLE) {
        SECOND_PRICE = 10**18 / divisor;
    }

    function setBetaAndRhoDivisor(uint256 divisor) external onlyRole(PRICE_ROLE) {
        PIXEL_X_PRICE = BETA_RHO_SUPPLY / MAX_X / divisor;
        PIXEL_Y_PRICE = BETA_RHO_SUPPLY / MAX_Y / divisor;
    }

    /**
     * @dev Called by the interface to submit a booking of an area to display an image. The user must have created 5 allowances for all tokens
     * At the time of submission, no collisions with previous bookings must be found or validation process will fail
     * User tokens are temporary stored in the contract and will be non refundable after validation
     * @param x X Coordinate of the upper left corner of the area, must be within screen boundaries: 0-MAX_X-1
     * @param y Y Coordinate of the upper left corner of the area, must be within screen boundaries: 0-MAX_Y-1
     * @param width Width of the area
     * @param height Height of the area
     * @param time Start timestamp for the display
     * @param duration Duration in seconds of the display
     * @param sha Must be the sha256 of the image as it is computed during IPFS storage
     * @param computedKappaAmount Amount of Kappa required to pay for the image pixels, this must be correct or the validation process will reject the submission
     * @param computedGammaAmount Amount of Gamma required to pay for the image pixels, this must be correct or the validation process will reject the submission
    */
    function submit(uint16 x, uint16 y, uint16 width, uint16 height, uint256 time, uint256 duration, bytes32 sha, uint256 computedKappaAmount, uint256 computedGammaAmount) external {
        require(width > 0
                && height > 0
                && time > 0
                && duration > 0
                && computedKappaAmount > 0
                && computedGammaAmount > 0
        , "XiSpace: Invalid arguments");
        require(x + width - 1 <= MAX_X, "XiSpace: Invalid area");
        require(y + height - 1 <= MAX_Y, "XiSpace: Invalid area");

        bookings[bookingsCount] = Booking(x, y, width, height, false, time, duration, sha, msg.sender);
        receipts[bookingsCount] = Receipt(PIXEL_X_PRICE * width, PIXEL_Y_PRICE * height, computedKappaAmount, computedGammaAmount, SECOND_PRICE * duration);
        emit SUBMISSION(bookingsCount, msg.sender);

        // Transfer the tokens from the user
        betaToken.transferFrom(msg.sender, address(this), receipts[bookingsCount].betaAmount);
        rhoToken.transferFrom(msg.sender, address(this), receipts[bookingsCount].rhoAmount);
        kappaToken.transferFrom(msg.sender, address(this), computedKappaAmount);
        gammaToken.transferFrom(msg.sender, address(this), computedGammaAmount);
        xiToken.transferFrom(msg.sender, address(this), receipts[bookingsCount].xiAmount);
        
        bookingsCount++;
    }

    /**
     * @dev Called by the user to cancel a submission before validation has been made
     * Tokens are then returned to the user
     * @param id ID of the booking to cancel. The address canceling must be the same as the one which created the submission
    */
    function cancelSubmission(uint256 id) external {
        require(bookings[id].owner == msg.sender, "XiSpace: Access denied");
        require(bookings[id].validated == false, "XiSpace: Already validated");
        require(receipts[id].xiAmount > 0, "XiSpace: Booking not found");
        // Transfer the tokens back to the user
        _moveTokens(id, msg.sender);
        delete bookings[id];
        delete receipts[id];
        emit CANCELLED(id);
    }

    /**
     * @dev Called by the validator: Accept or reject a booking submission
     * In case of rejection, tokens could be refunded, in case of acceptance the tokens are sent to treasury
     * @param id ID of the submission to validate
     * @param accept True to accept the submission, false to reject it
     * @param returnFunds True if the validator choses to return user funds
    */
    function validate(uint256 id, bool accept, bool returnFunds) external onlyRole(VALIDATOR_ROLE) {
        require(bookings[id].validated == false, "XiSpace: Already validated");
        if(accept) {
            // Transfer the tokens to the treasury
            _moveTokens(id, treasury);
            bookings[id].validated = true;
            emit BOOKED(id);
        } else {
            if(returnFunds) {
                // Transfer the tokens back to the user
                _moveTokens(id, bookings[id].owner);
            } else {
                // Transfer the tokens to the treasury
                _moveTokens(id, treasury);
            }
            
            delete bookings[id];
            delete receipts[id];
            emit REJECTED(id, returnFunds);
        }

    }

    /**
     * @dev Moves all 5 tokens from this contract to any destination
     * @param id ID of the submission to move the tokens of
     * @param destination Address to send the tokens to
    */
    function _moveTokens(uint256 id, address destination) internal {
        Receipt memory receipt = receipts[id];
        betaToken.transfer(destination, receipt.betaAmount);
        rhoToken.transfer(destination, receipt.rhoAmount);
        kappaToken.transfer(destination, receipt.kappaAmount);
        gammaToken.transfer(destination, receipt.gammaAmount);
        xiToken.transfer(destination, receipt.xiAmount);
    }
}