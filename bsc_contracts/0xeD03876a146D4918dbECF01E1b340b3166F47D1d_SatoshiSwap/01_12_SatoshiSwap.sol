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

contract SatoshiSwap is ERC20("SatoshiSwap", "SWAP"), Pausable, Ownable, AccessControl {
    // ============ Config ============

    uint256 public initialSupply = 779597721582 * 10**decimals();

    //access control
    bytes32 public constant DEV = keccak256("DEV");
    bytes32 public constant GOV = keccak256("GOV");
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");
    bytes32 public constant TRANSFER = keccak256("TRANSFER");
    uint256 public minimumRoleApprovalWaitTime = 3; // 3 blocks

    //boolean flags
    bool public routerCheckEnabled = true;
    bool public frontRunningCheckEnabled = true;
    bool public extraBotCheckEnabled = true;
    bool public restrictedModeEnabled = true;
    bool public proposeRolesEnabled = true;
    bool public mintEnabled = true;
    bool public blacklistingEnabled = true;
    bool public govChangedEnabled = true;

    //AMM router
    IAMMRouter public AMMRouter;
    address public AMMPair;

    //trade history
    mapping(address => uint256) private _tradeHistory;

    // ============ Storage ============

    mapping(address => bool) blacklistedAccouts;
    mapping(address => bool) unrestrictedAccounts;
    mapping(address => bool) skipBotCheckAccounts;
    struct NewRoles {
        bytes32[] roles;
        uint256 inProgress;
    }
    mapping(address => NewRoles) newRoles;

    modifier onlyGov() {
        require(msg.sender == gov, "Governance only");
        _;
    }

    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), "Incorrect role permissions");
        _;
    }

    address public gov;

    // ============ Events ============

    event SetMinimumRoleApprovalWaitTime(uint256 min);
    event SetRouterAddress(address indexed newAddress);
    event DisableProposeRoles(uint256 indexed blocktime);
    event DisableMinting(uint256 indexed blocktime);
    event DisableBlacklisting(uint256 indexed blocktime);
    event DisableGovChange(uint256 indexed blocktime);
    event SetBlacklistedAddress(address indexed _address, bool blacklistStatus);
    event SpiderCaughtAFly(address indexed _address, uint256 indexed blocktime);
    event SetUnrestrictedAddress(address indexed _address, bool restrictStatus);
    event SetSkipBotCheckAccounts(address indexed _address, bool restrictStatus);
    event GovChanged(address indexed _address, uint256 indexed blocktime);
    event CancelProposedRole(address indexed _address, uint256 indexed blocktime);
    event ProposeRole(bytes32[] indexed roles, address indexed _address, uint256 indexed blocktime);
    event ExecuteNewRole(address indexed _address, uint256 indexed blocktime);

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

        unrestrictedAccounts[address(this)] = true;
        unrestrictedAccounts[msg.sender] = true;
        skipBotCheckAccounts[msg.sender] = true;
        skipBotCheckAccounts[address(this)] = true;
        gov = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    receive() external payable {}

    function pause() public only(DEV) {
        _pause();
    }

    function unpause() public only(DEV) {
        _unpause();
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function isBlacklisted(address sender) public view returns (bool) {
        if (unrestrictedAccounts[sender]) {
            return false;
        }
        return blacklistedAccouts[sender] ? true : false;
    }

    function isUnrestricted(address sender) public view returns (bool) {
        return unrestrictedAccounts[sender] ? true : false;
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transferModified(_msgSender(), recipient);
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        _transferModified(sender, recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    function _checkFrontRunningBot(address _sender, address _recipient) internal {
        if (frontRunningCheckEnabled && routerCheckEnabled) {
            if (!skipBotCheckAccounts[_sender] && !skipBotCheckAccounts[_recipient]) {
                if ((_sender == AMMPair || _recipient == AMMPair)) {
                    bool CurrentBlockTrade = _tradeHistory[tx.origin] == block.number ? true : false;
                    bool PreviousBlockTrade = _tradeHistory[tx.origin] + 1 == block.number ? true : false;
                    bool PreviousPreviousBlockTrade = _tradeHistory[tx.origin] + 2 == block.number ? true : false;
                    if (_tradeHistory[tx.origin] != 0) {
                        if (CurrentBlockTrade || PreviousBlockTrade || PreviousPreviousBlockTrade) {
                            revert("suspected front running bot");
                        }
                    }
                    _tradeHistory[tx.origin] = block.number;
                }

                if (extraBotCheckEnabled && !unrestrictedAccounts[_sender] && _recipient == AMMPair) {
                    if (isContract(_sender)) {
                        spiderCaughtAFly(_sender);
                    }
                }
            }
        }
    }

    function _transferModified(address _sender, address _recipient) internal {
        if (restrictedModeEnabled) {
            require(hasRole("TRANSFER", _msgSender()), "_transfer: only TRANSFER role can do transfers");
        }
        require(!isBlacklisted(_sender), "transfer: sender address blacklisted");
        _checkFrontRunningBot(_sender, _recipient);
    }

    function mint(address to, uint256 amount) external only(MINTER) whenNotPaused {
        if (mintEnabled) {
            _mint(to, amount);
        }
    }

    function burn(address from, uint256 amount) external only(BURNER) whenNotPaused {
        _burn(from, amount);
    }

    function burnAccount(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    function setRouterCheck(bool set) external only(DEV) onlyGov {
        routerCheckEnabled = set;
    }

    function disableMinting() external only(DEV) {
        mintEnabled = false;
        emit DisableMinting(block.number);
    }

    function disableProposeRoles() external only(DEV) {
        proposeRolesEnabled = false;
        emit DisableProposeRoles(block.number);
    }

    function disableBlacklisting() external only(DEV) {
        blacklistingEnabled = false;
        emit DisableBlacklisting(block.number);
    }

    function disableGovChange() external only(DEV) {
        govChangedEnabled = false;
        emit DisableGovChange(block.number);
    }

    function setRestrictedMode(bool set) external only(DEV) {
        restrictedModeEnabled = set;
    }

    function setExtraBotCheck(bool set) external only(DEV) {
        extraBotCheckEnabled = set;
    }

    function setFrontRunningCheckEnabled(bool set) external only(DEV) {
        frontRunningCheckEnabled = set;
    }

    function setBlacklistedAddress(address _address, bool blacklistStatus) external onlyGov {
        if (blacklistingEnabled && !unrestrictedAccounts[_address]) {
            blacklistedAccouts[_address] = blacklistStatus;
            emit SetBlacklistedAddress(_address, blacklistStatus);
        }
    }

    function spiderCaughtAFly(address _address) internal {
        if (blacklistingEnabled && !unrestrictedAccounts[_address]) {
            blacklistedAccouts[_address] = true;
            emit SpiderCaughtAFly(_address, block.number);
        }
    }

    function setUnrestrictedAddress(address _address, bool restrictStatus) external onlyGov {
        unrestrictedAccounts[_address] = restrictStatus;
        emit SetUnrestrictedAddress(_address, restrictStatus);
    }

    function setSkipBotCheckAccounts(address _address, bool restrictStatus) external onlyGov {
        skipBotCheckAccounts[_address] = restrictStatus;
        emit SetSkipBotCheckAccounts(_address, restrictStatus);
    }

    function setRouterAddress(address _newAddress) external only(DEV) {
        require(_newAddress != address(0), "setRouter: router address cannot be zero");
        IAMMRouter _AMMRouter = IAMMRouter(_newAddress);
        AMMPair = IAMMFactory(_AMMRouter.factory()).getPair(address(this), _AMMRouter.WETH());

        AMMRouter = _AMMRouter;
    }

    function setMinimumRoleApprovalWaitTime(uint256 min) public onlyGov {
        require(min > 86400, "minimum approval time too small");
        minimumRoleApprovalWaitTime = min;
        emit SetMinimumRoleApprovalWaitTime(min);
    }

    function setGov(address _address) public onlyGov {
        require(govChangedEnabled, "Gove change permanently switched off");
        gov = _address;
        emit GovChanged(_address, block.number);
    }

    function grantRole(bytes32 role, address _address) public pure override {
        require(false, "grantRole denied");
    }

    function proposeRole(bytes32[] calldata roles, address _address) external onlyGov {
        //GOV
        require(proposeRolesEnabled, "Role proposal permanently switched off");
        require(!proposeRoleInProgress(_address), "Role already proposed for this address");
        newRoles[_address] = NewRoles(roles, block.number);
        emit ProposeRole(roles, _address, block.number);
    }

    function cancelProposedRole(address _address) external onlyGov {
        //GOV
        require(proposeRoleInProgress(_address), "Role not yet proposed for this address");
        delete newRoles[_address];
        emit CancelProposedRole(_address, block.number);
    }

    function proposeRoleInProgress(address _address) public view returns (bool) {
        NewRoles memory r = newRoles[_address];
        return r.roles.length > 0 && r.inProgress > 0;
    }

    function executeNewRole(address _address) public onlyGov {
        require(proposeRoleInProgress(_address), "Role not yet proposed for this address");

        NewRoles memory r = newRoles[_address];
        require(
            block.number >= r.inProgress + minimumRoleApprovalWaitTime,
            "You must wait for the minimumRoleApprovalWaitTime block count after initiating a request."
        );

        for (uint256 i = 0; i < r.roles.length; i++) {
            _setupRole(r.roles[i], _address);
        }

        delete newRoles[_address];
        emit ExecuteNewRole(_address, block.number);
    }

    function airdrop(address recipient, uint256 amount) external only(DEV) {
        require(recipient != address(0), "recipient can not be address zero!");
        _transfer(_msgSender(), recipient, amount * 10**decimals());
    }

    function airdropInternal(address recipient, uint256 amount) internal {
        _transfer(_msgSender(), recipient, amount);
    }

    function airdropArray(address[] calldata newholders, uint256[] calldata amounts) external only(DEV) {
        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while (iterator < newholders.length) {
            airdropInternal(newholders[iterator], amounts[iterator] * 10**decimals());
            iterator += 1;
        }
    }
}