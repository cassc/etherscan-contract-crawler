// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IAirdrop {
    function airdrop(address recipient, uint256 amount) external;
}

interface IAMMRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IAMMFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract AccessModifiers is AccessControl {
    string private _revertMsg;

    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS"));
    }

    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), _revertMsg);
        _;
    }
}

contract Fig is ERC20("Fig", "FIG"), Pausable, Ownable, AccessModifiers {
    // contract Fig is ERC20("Fig", "FIG"), Pausable, Ownable, AccessModifiers {
    // ============ Config ============

    uint256 public initialSupply = 779597721582 * 10**decimals();

    //access control
    bytes32 public constant DEV = keccak256("DEV");
    bytes32 public constant GOV = keccak256("GOV");
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");
    bytes32 public constant BRIDGE = keccak256("BRIDGE");
    bytes32 public constant TRANSFER = keccak256("TRANSFER");
    uint256 public minimumRoleApprovalWaitTime = 28800 * 3; // 3 days

    //boolean flags
    bool public routerCheckEnabled = true;
    bool public contractCheckEnabled = true;
    bool public frontRunningCheckEnabled = true;
    bool public restrictedModeEnabled = false;

    //AMM router
    IAMMRouter public AMMRouter;
    address public AMMPair;

    //trade history
    mapping(address => uint256) private _tradeHistory;

    // ============ Storage ============

    mapping(address => bool) blacklistedAccouts;
    mapping(address => bool) unrestrictedAccounts;
    struct NewRoles {
        bytes32[] roles;
        uint256 inProgress;
    }
    mapping(address => NewRoles) newRoles;

    modifier onlyGov() {
        require(msg.sender == gov, "BaseToken: forbidden");
        _;
    }

    address public gov;

    // ============ Events ============

    // /**
    // * @dev Emitted when an address has been added to or removed from the token transfer allowlist.
    // *
    // * @param  account    Address that was added to or removed from the token transfer allowlist.
    // * @param  isAllowed  True if the address was added to the allowlist, false if removed.
    // */
    // event TransferAllowlistUpdated(
    //     address account,
    //     bool isAllowed
    // );
    // event GrantRequestInitiated(bytes32[] indexed roles, address indexed account, uint indexed block);
    // event ProposedRoleCanceled(address indexed account, uint indexed canceled);

    constructor(address routerAddress, bool setupRouter) {
        if (setupRouter) {
            IAMMRouter _uniswapV2Router = IAMMRouter(routerAddress);
            AMMPair = IAMMFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
            AMMRouter = _uniswapV2Router;
            unrestrictedAccounts[address(AMMPair)] = true;
            unrestrictedAccounts[address(AMMRouter)] = true;
        } else {
            routerCheckEnabled = false;
        }
        _setupRole(TRANSFER, msg.sender);
        _setupRole(DEV, msg.sender);
        _setupRole(GOV, msg.sender);
        _setupRole(MINTER, msg.sender);
        _setupRole(BURNER, msg.sender);
        _setupRole(BRIDGE, msg.sender);

        unrestrictedAccounts[address(this)] = true;
        unrestrictedAccounts[msg.sender] = true;
        gov = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    // // receive() external payable {}

    function pause() public only(DEV) {
        _pause();
    }

    function unpause() public only(DEV) {
        _unpause();
    }

    // function pause() public onlyGov {
    //     _pause();
    // }

    // function unpause() public onlyGov {
    //     _unpause();
    // }

    function grantRole(bytes32 role, address account) public override {
        require(false, "grantRole denied");
    }

    function proposeRoleInProgress(address account) public view returns (bool) {
        NewRoles memory r = newRoles[account];
        return r.roles.length > 0 && r.inProgress > 0;
    }

    function proposeRole(bytes32[] calldata roles, address account) external onlyGov {
        //GOV
        require(!proposeRoleInProgress(account), "Role already proposed for this account");
        newRoles[account] = NewRoles(roles, block.number);
        // emit GrantRequestInitiated(roles, account, block.number);
    }

    function cancelProposedRole(address account) external onlyGov {
        //GOV
        require(proposeRoleInProgress(account), "Role not yet proposed for this account");
        delete newRoles[account];
        // emit ProposedRoleCanceled(account, block.number);
    }

    function executeGrantRequest(address account) public onlyGov {
        //GOV
        require(proposeRoleInProgress(account), "Role not yet proposed for this account");

        NewRoles memory r = newRoles[account];
        require(
            block.number >= r.inProgress + minimumRoleApprovalWaitTime,
            "You must wait for the minimum delay after initiating a request."
        );

        for (uint256 i = 0; i < r.roles.length; i++) {
            _setupRole(r.roles[i], account);
        }

        delete newRoles[account];
    }

    function adjustMinimumRoleApprovalWaitTime(uint256 min) public onlyGov {
        //GOV
        require(min > 28800, "minimum approval time too small");
        minimumRoleApprovalWaitTime = min;
    }

    // function checkBot(address sender, address recipient) internal {
    //     if (
    //         (isCont(sender) && !unrestrictedAccounts[sender] && botOn) ||
    //         (sender == pair && botOn && !unrestrictedAccounts[sender] && msg.sender != tx.origin) ||
    //         startedTime > block.timestamp
    //     ) {
    //         isBot[sender] = true;
    //     }
    //     if (
    //         (isCont(recipient) && !unrestrictedAccounts[recipient] && !isFeeExempt[recipient] && botOn) ||
    //         (sender == pair && !unrestrictedAccounts[sender] && msg.sender != tx.origin && botOn)
    //     ) {
    //         isBot[recipient] = true;
    //     }
    // }

    function isBlacklisted(address sender) public returns (bool) {
        if (unrestrictedAccounts[sender]) {
            return false;
        }
        return blacklistedAccouts[sender] ? true : false;
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transferNew(_msgSender(), recipient, amount);
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        _transferNew(sender, recipient, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    function _checkFrontRunningBot(address _sender, address _recipient) public {
        if (frontRunningCheckEnabled && routerCheckEnabled) {
            if ((_sender == AMMPair || _recipient == AMMPair)) {
                bool CurrentBlockTrade = _tradeHistory[tx.origin] == block.number ? true : false;
                bool PreviousBlockTrade = _tradeHistory[tx.origin] + 1 == block.number ? true : false;
                if (_tradeHistory[tx.origin] != 0) {
                    if (CurrentBlockTrade || PreviousBlockTrade) {
                        revert("suspected bot");
                    }
                }
                _tradeHistory[tx.origin] = block.number;
            }
        }
    }

    function _transferNew(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal whenNotPaused {
        if (restrictedModeEnabled) {
            require(hasRole("TRANSFER", _msgSender()), "_transfer: only TRANSFER role can do transfers");
        }
        if (!unrestrictedAccounts[_sender] && !unrestrictedAccounts[_recipient]) {
            require(!isBlacklisted(_sender), "transfer: sender address blacklisted");
            require(!isBlacklisted(_recipient), "transfer: recipient address blacklisted");
            _checkFrontRunningBot(_sender, _recipient);
        }
        // super.transfer(_recipient, _amount);
    }

    function mint(address to, uint256 amount) external onlyGov whenNotPaused {
        // MINTER
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyGov whenNotPaused {
        // BURNER
        _burn(from, amount);
    }

    function burnAccount(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    function setRouterCheck(bool set) external onlyGov {
        // DEV
        routerCheckEnabled = set;
    }

    function setRestrictedMode(bool set) external onlyGov {
        // DEV
        restrictedModeEnabled = set;
    }

    function setBlacklistedAddress(address _address, bool blacklistStatus) external onlyGov {
        // DEV
        if (!unrestrictedAccounts[_address]) {
            blacklistedAccouts[_address] = blacklistStatus;
        }
    }

    function setRouterAddress(address newAddress) external onlyGov {
        //DEV
        require(newAddress != address(0), "setRouter: router address cannot be zero");
        IAMMRouter _AMMRouter = IAMMRouter(newAddress);
        AMMPair = IAMMFactory(_AMMRouter.factory()).getPair(address(this), _AMMRouter.WETH());

        AMMRouter = _AMMRouter;
        // emit RouterAddressUpdated(newAddress);
    }

    function airdrop(address recipient, uint256 amount) external onlyGov {
        //DEV
        require(recipient != address(0), "recipient can not be address zero!");
        _transfer(_msgSender(), recipient, amount * 10**decimals());
    }

    function airdropInternal(address recipient, uint256 amount) internal {
        _transfer(_msgSender(), recipient, amount);
    }

    function airdropArray(address[] calldata newholders, uint256[] calldata amounts) external onlyGov {
        //DEV
        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while (iterator < newholders.length) {
            airdropInternal(newholders[iterator], amounts[iterator] * 10**decimals());
            iterator += 1;
        }
    }
}