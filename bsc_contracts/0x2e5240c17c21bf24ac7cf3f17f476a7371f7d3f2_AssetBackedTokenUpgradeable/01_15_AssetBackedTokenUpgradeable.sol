//SPDX-License-Identifier: MIT.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AssetBackedTokenUpgradeable is Initializable, ERC20Upgradeable, AccessControlEnumerableUpgradeable {

    uint256 public constant TIMELOCK = 2 days;
    uint256 public constant PERCENTAGE_FACTOR = 1e6; // Equals 100% with four decimals.

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    string public asset;
    address public FeeCollector;

    mapping(address => bool) public exemptedAddresses;

    bool public transferFees;
    uint256[] public feeRates;
    uint256[] public transferAmounts;
    uint256[] public baseFeeAmounts;

    struct Proposal {
        address account;
        bytes32 role;
        uint256 timestamp;
        bool grant;
        bool executed;
    }

    uint256 private _proposals;

    mapping(uint256 => Proposal) public roleProposals;

    event RoleProposed(uint256 proposal, address account, bytes32 role, bool grant);
    event FeeCollectorSet(address account);
    event NewFeeStructure(uint256[] amounts, uint256[] fees);
    event FeeStructureRemoved();

    function initialize(string memory name_, string memory symbol_, string memory asset_, address _owner) public initializer {
        __ERC20_init(name_, symbol_);
        __Context_init();
        __AccessControlEnumerable_init();
        __AccessControl_init();

        require(_owner != address(0), "Error: Account is the null address");
        
        super._grantRole(OWNER_ROLE, _owner);
        super._setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        super._setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
        super._setRoleAdmin(BURNER_ROLE, OWNER_ROLE);

        asset = asset_;
    }

    function setFeeCollector(address _collector) external onlyRole(OWNER_ROLE) {
        require(_collector != address(0), "Error: Cannot be the zero address");

        FeeCollector = _collector;

        emit FeeCollectorSet(_collector);
    }

    function setTransferFeeStructure(uint256[] memory amounts, uint256[] memory fees) external onlyRole(OWNER_ROLE) {
        require(transferFees == false, "Error: transfer fees have already been set");
        require(amounts.length == fees.length, "Error: arrays length do not match");
        require(amounts.length > 0, "Error: Null amounts array length");
        require(amounts.length <= 10, "Error: Amounts array length exceeds limit");
        require(checkAscendingOrder(amounts), "Error: amounts not provided in ascending order");

        feeRates = fees; // Check each fee is lower than 100.
        transferAmounts = amounts;

        baseFeeAmounts.push(0);

        for (uint256 i = 1; i < amounts.length; i++) {
            require(fees[i] <= PERCENTAGE_FACTOR, "Error: Cannot exceed PERCENTAGE_FACTOR");

            uint256 difAmount = amounts[i] - amounts[i-1];
            uint256 feeAmount = baseFeeAmounts[i-1] + difAmount * fees[i - 1] / PERCENTAGE_FACTOR;
            baseFeeAmounts.push(feeAmount);
        }

        transferFees = true;

        emit NewFeeStructure(amounts, fees);
    } 

    function removeTransferFeeStructure() external onlyRole(OWNER_ROLE) {
        require(transferFees == true, "Error: transfer fees not set");

        transferFees = false;
        delete feeRates;
        delete transferAmounts;
        delete baseFeeAmounts;

        emit FeeStructureRemoved();
    }

    function toggleExemptedAddress(address account) external onlyRole(OWNER_ROLE) {
        exemptedAddresses[account] = !exemptedAddresses[account];
    }

    function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        address sender = _msgSender();

        if (transferFees && !exemptedAddresses[sender]) {
            uint256 transferFee = getTransferFeeAmount(amount);
            uint256 netAmount = amount - transferFee;

            _transfer(sender, FeeCollector, transferFee);
            _transfer(sender, recipient, netAmount);
        } else {
            _transfer(sender, recipient, amount);
        }

        return true;
    }

    function transferFrom(address from, address recipient, uint256 amount) public override returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        if(transferFees && !exemptedAddresses[from]) {
            uint256 transferFee = getTransferFeeAmount(amount);
            uint256 netAmount = amount - transferFee;

            _transfer(from, FeeCollector, transferFee);
            _transfer(from, recipient, netAmount);
        } else {
            _transfer(from, recipient, amount);
        }

        return true;
    }

    function burn(uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external onlyRole(BURNER_ROLE) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /*********** GETTER METHODS ***********/

    function getFeeRates() external view returns (uint256[] memory) {
        return feeRates;
    }

    function getTransferAmounts() external view returns (uint256[] memory) {
        return transferAmounts;
    }

    function getBaseFeeAmounts() external view returns (uint256[] memory) {
        return baseFeeAmounts;
    }


    /*********** ROLE-SETTER METHODS ***********/

    function grantRoleProposal(bytes32 role, address _account) external onlyRole(OWNER_ROLE) {
        _roleProposal(role, _account, true);
    }
    
    function revokeRoleProposal(bytes32 role, address _account) external onlyRole(OWNER_ROLE) {
        _roleProposal(role, _account, false);
    }

    function grantRoleExecution(uint256 _proposal) external onlyRole(OWNER_ROLE) {
        _roleExecution(_proposal, true); 
    }

    function revokeRoleExecution(uint256 _proposal) external onlyRole(OWNER_ROLE) {
        _roleExecution(_proposal, false); 
    }

    function _roleProposal(bytes32 role, address _account, bool grant) internal {
        require(role == OWNER_ROLE || role == MINTER_ROLE || role == BURNER_ROLE, "Error: Role does not exist");
        require(_account != address(0), "Error: Account is the null address");

        roleProposals[_proposals] = Proposal(_account, role, block.timestamp, grant, false);

        emit RoleProposed(_proposals, _account, role, grant);

        _proposals += 1;
    }

    function _roleExecution(uint256 _proposal, bool grant) internal {
        Proposal memory proposal = roleProposals[_proposal];

        require(proposal.executed == false, "Error: Proposal already executed");
        require(proposal.account != address(0), "Error: Invalid proposal");
        require(proposal.timestamp + TIMELOCK <= block.timestamp, "Error: Binding timelock");

        if(grant) {
            require(proposal.grant, "Error: Revoke proposal");
            super._grantRole(proposal.role, proposal.account);
        } else {
            require(!proposal.grant, "Error: Grant proposal");
            super._revokeRole(proposal.role, proposal.account);     
        }

        proposal.executed = true;
    }

    function grantRole(bytes32 role, address _account) public override onlyRole(OWNER_ROLE) {
        revert("Error: Deprecated method");
    }

    function revokeRole(bytes32 role, address _account) public override onlyRole(OWNER_ROLE) {
        revert("Error: Deprecated method");
    }

    /*********** INTERNAL METHODS ***********/

    function checkAscendingOrder(uint256[] memory _array) internal pure returns (bool) {
        for (uint256 i = 1; i < _array.length; i++) {
            uint256 first = _array[i - 1];
            uint256 sec = _array[i];

            if (first >= sec) {
                return false;
            }
        }
        return true;
    } 

    function getTransferFeeAmount(uint256 _amount) public view returns (uint256) {
        uint256 amountLowerBound;
        uint256 index;
        bool set;

        for (uint i = 1; i < transferAmounts.length; i++) {
            if (_amount < transferAmounts[i]) {
                index = i - 1;
                amountLowerBound = transferAmounts[index];
                set = true;
                break;
            } 
        }

        // Case when amount exceeds top lower bound.
        if(set == false) {
            index = transferAmounts.length - 1;
            amountLowerBound = transferAmounts[index];
        }

        uint256 feeAmount = baseFeeAmounts[index] + (_amount - amountLowerBound) * feeRates[index] / PERCENTAGE_FACTOR;

        return feeAmount;
    }   
}