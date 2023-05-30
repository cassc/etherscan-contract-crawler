///// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @dev Equity values are 0 to 10000 (representing 0 to 100 with decimals). So an equity of 3000 means 30%
/// @notice Encapsulates the wallet and cap table management
contract DevWallet is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    event PaymentReceived(address from, uint256 amount);
    event TransferERC20Sent(address _from, address _destAddr, uint _amount);

    /// @dev Address of the deployer account
    address private _deployerAddress;
    address private _devMultiSigWalletAddress;

    address internal paymentToken;
    uint256 internal _totalTokenReleased;
    mapping(address => uint256) internal _tokenReleased;


    /*** CAP TABLE ***/

    address[] private _founders;
    mapping(address => uint) public founderToEquity;
    mapping(address => FounderAuthorization[]) private _addressToFounderAuthorization;

    /// @dev A mapping of cxo address to their pending withdrawal
    mapping (address => uint) public addressToPendingWithdrawal;
    
    /// @dev The max shares being 100 represented by 10000 (to accept decimal positions)
    uint private constant TOTAL_CAP = 10000;


    struct FounderAuthorization {
        address founder;
        uint equity;
        bool approved;
        bool isRemoval;
    }


    /*** INIT ***/
    /// @notice Inits the wallet
    /// @dev defines a initial cap table with specific equity per founder. Equity values 0 - 10000 representing 0-100% equity
    /// @param founders list of founders     

    constructor (address _paymentToken, address[] memory founders, address devMultiSigWallet) {
        paymentToken = _paymentToken;

        _devMultiSigWalletAddress = devMultiSigWallet;

        _deployerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Initial cap table
        createInitialFounder(founders[0], 1500); // Max 15%
        createInitialFounder(founders[1], 1500); // Greg 15%
        createInitialFounder(founders[2], 1500); // Nart 15%
        createInitialFounder(founders[3], 500); // Pann 5%
        createInitialFounder(founders[4], 2000); // DevMultiSig 20%
        createInitialFounder(founders[5], 3000); // DaoMultiSig 30%
    }

    /// @notice Inits the a initial founder.
    /// @dev Only callable once on contract construction
    /// @param founderAddress The address of a initial founder 
    /// @param equity The equity of the initial founder. Equity values 0 - 10000 representing 0-100% equity
    function createInitialFounder(address founderAddress, uint equity) private {
        require(msg.sender == _deployerAddress, "ONLY_DEPLOYER");
        require(equity <= TOTAL_CAP, "INVALID EQUITY (0-10000)");

        _founders.push(founderAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, founderAddress);
        founderToEquity[founderAddress] = equity;
    }

    /*** PUBLIC ***/
    /// @dev ETH received is splitted by equity among wallet founders
    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);

        require(msg.value > 0, "INVALID_AMOUNT");
        _updatePendingWithdrawals(msg.value);
    }

    function authorize(bool approved, uint equity, address who) public {
        require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
        require(equity <= TOTAL_CAP, "INVALID EQUITY (0-10000)");
        require(equity >= 0, "INVALID EQUITY (0-10000)");

        FounderAuthorization[] storage auths = _addressToFounderAuthorization[who];
        bool exists = false;
        for (uint i = 0; i < auths.length; i++) {
            if (auths[i].founder == msg.sender) {
                exists = true;
                auths[i].equity = equity;
                auths[i].approved = approved;
                auths[i].isRemoval = false;
            }
        }

        if (!exists) {
            auths.push(FounderAuthorization({founder: msg.sender, equity: equity, approved: approved, isRemoval: false}));
        }
    }

    function revoke(bool approved, address who) public {
        require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");

        FounderAuthorization[] storage auths = _addressToFounderAuthorization[who];
        bool exists = false;
        for (uint i = 0; i < auths.length; i++) {
            if (auths[i].founder == msg.sender) {
                exists = true;
                auths[i].equity = 0;
                auths[i].approved = approved;
                auths[i].isRemoval = true;
            }
        }

        if (!exists) {
            auths.push(FounderAuthorization({founder: msg.sender, equity: 0, approved: approved, isRemoval: true}));
        }
    }

    function updateCapTable(address who, uint equity, bool isRemoval) public {
        require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
        require(equity <= TOTAL_CAP, "INVALID EQUITY (0-10000)");
        require(equity >= 0, "INVALID EQUITY (0-10000)");

        FounderAuthorization[] storage auths = _addressToFounderAuthorization[who];
        uint equityYes = 0;

        for (uint i = 0; i < auths.length; i++) {
            if (equity == auths[i].equity && auths[i].approved == true && isRemoval == auths[i].isRemoval) {
                equityYes += founderToEquity[auths[i].founder];
            } 
        }

        if (equityYes >= 7000) {
            if (isRemoval) {
                _removeFounder(who);
            } else {
                _addFounder(who, equity);
            }  
            delete _addressToFounderAuthorization[who];
        } 
    }

    function transferERC20(IERC20 token, address to, uint256 amount) external {
        require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        emit TransferERC20Sent(msg.sender, to, amount);
    }

    function updateDevMultiSigWallet(address devMultiSigWalletAddress_) external {
        require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
        _devMultiSigWalletAddress = devMultiSigWalletAddress_;
    }



    // EACH FOUNDER CAN DO TO THEIR OWN PORTION

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        require(amount <= addressToPendingWithdrawal[_msgSender()], "can't withdraw more than that");

        addressToPendingWithdrawal[_msgSender()] -= amount;        
        payable(_msgSender()).transfer(amount);
    }

    function getPendingWETHBalance() external view returns(uint256) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        uint256 tokenTotalReceived = IERC20(paymentToken).balanceOf(address(this)) + _totalTokenReleased;
        uint256 payment = (tokenTotalReceived * founderToEquity[_msgSender()]) /
            TOTAL_CAP - _tokenReleased[_msgSender()];
        return payment;
    }

    function releaseWETH(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");

        uint256 tokenTotalReceived = IERC20(paymentToken).balanceOf(address(this)) + _totalTokenReleased;
        uint256 totalPayable = (tokenTotalReceived * founderToEquity[_msgSender()]) /
            TOTAL_CAP - _tokenReleased[_msgSender()];

        require(totalPayable != 0, "TokenPaymentSplitter: account is not due payment");
        require(amount <= totalPayable, "can't withdraw more than that");

        _tokenReleased[_msgSender()] = _tokenReleased[_msgSender()] + amount;
        _totalTokenReleased = _totalTokenReleased + amount;

        IERC20(paymentToken).safeTransfer(_msgSender(), amount);
        emit TransferERC20Sent(msg.sender, _msgSender(), amount);
    }

    /*** PRIVATE ***/

    function _addFounder(address who, uint equity) private {
        require(!_founderExists(who), "FOUNDER ALREADY EXISTS");

        for (uint i = 0; i < _founders.length; i++) {
            founderToEquity[_founders[i]] = founderToEquity[_founders[i]] * (TOTAL_CAP - equity) / TOTAL_CAP;
        }

        _founders.push(who);
        grantRole(DEFAULT_ADMIN_ROLE, who);
        founderToEquity[who] = equity;
    }

    function _removeFounder(address who) private {
        require(_founderExists(who), "FOUNDER DOESNT EXIST");

        uint equityToSplit = founderToEquity[who];
        uint indexToRemove;
        for (uint i = 0; i < _founders.length; i++) {
            if (_founders[i] == who) {
                indexToRemove = i;
                founderToEquity[who] = 0;
            } else {
               founderToEquity[_founders[i]] =  TOTAL_CAP * founderToEquity[_founders[i]] / (TOTAL_CAP - equityToSplit);
            }
        }

        delete _founders[indexToRemove];
        revokeRole(DEFAULT_ADMIN_ROLE, who);
    }

    function _founderExists(address who) private view returns(bool) {
        bool exists = false;
        for (uint i = 0; i < _founders.length; i++) {
            if (_founders[i] == who) {
                exists = true;
            }
        }
        return exists;
    }

    function _updatePendingWithdrawals(uint amount) private {
        for (uint i = 0; i < _founders.length; i++) {
            addressToPendingWithdrawal[_founders[i]] = addressToPendingWithdrawal[_founders[i]] + (amount * founderToEquity[_founders[i]] / TOTAL_CAP);
        }
    }
}