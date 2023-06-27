///// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/// @title MarsGenesis Martians wallet contract
/// @author MarsGenesis
/// @dev Equity values are 0 to 10000 (representing 0 to 100 with decimals). So an equity of 3000 means 30%
/// @notice Encapsulates the wallet and cap table management
contract MarsGenesisMartiansWallet is AccessControlEnumerable {

    /// @dev Address of the deployer account
    address private _deployerAddress;

    
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
    /// @param cxo1 founder 1     
    /// @param cxo2 founder 2
    /// @param cxo3 founder 3
    /// @param cdo1 founder 4
    /// @param cdo2 founder 5
    constructor (address cxo1, address cxo2, address cxo3, address cdo1, address cdo2) {
        _deployerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initial cap table
        createInitialFounder(cxo1, 3000);
        createInitialFounder(cxo2, 3000);
        createInitialFounder(cxo3, 3000);
        createInitialFounder(cdo1, 500);
        createInitialFounder(cdo2, 500);
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

    /// @notice Wallet should receive ether from MarsGenesisMartiansCore and MarsGenesisMartiansAuction
    /// @dev Ether received is splitted by equity among wallet founders
    receive() external payable {
        require(msg.value > 0, "INVALID_AMOUNT");
        _updatePendingWithdrawals(msg.value);
    }

    function authorize(bool approved, uint equity, address who) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");

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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
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

    function withdraw() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        
        uint amount = addressToPendingWithdrawal[_msgSender()];
        addressToPendingWithdrawal[_msgSender()] = 0;
        
        payable(_msgSender()).transfer(amount);
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