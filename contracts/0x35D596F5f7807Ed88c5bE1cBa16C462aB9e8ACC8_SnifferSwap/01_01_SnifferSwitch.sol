// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// ExecutionContext provides information about the execution context.
abstract contract ExecutionContext {
    // Returns the sender of the current context.
    function getContextSender() internal view virtual returns(address) {
        return msg.sender;
    }

    // Returns the data of the current context.
    function getContextData() internal view virtual returns(bytes calldata) {
        return msg.data;
    }
}

// Proprietorship provides owner functionality for contracts.
abstract contract Proprietorship is ExecutionContext {
    address private _admin;

    // Emitted when ownership has been transferred.
    event AdminshipTransferred(address indexed oldAdmin, address indexed newAdmin);

    constructor() {
        _reassignAdmin(getContextSender());
    }

    // Returns the current owner.
    function admin() public view virtual returns(address) {
        return _admin;
    }

    // Ensures that only the owner can call a function.
    modifier soleOwner() {
        require(admin() == getContextSender(), "Proprietorship: caller isn't the admin");
        _;
    }

    // Abandons ownership.
    function abandonOwnership() public virtual soleOwner {
        _reassignAdmin(address(0));
    }

    // Changes ownership to a new address.
    function changeOwnership(address newAdmin) public virtual soleOwner {
        require(newAdmin != address(0), "Proprietorship: new admin is the null address");
        _reassignAdmin(newAdmin);
    }

    // Internal function to reassign adminship.
    function _reassignAdmin(address newAdmin) internal virtual {
        address priorAdmin = _admin;
        _admin = newAdmin;
        emit AdminshipTransferred(priorAdmin, newAdmin);
    }
}

// Interface for ERC20 tokens.
interface ERC20Blueprint {
    function totalSupply() external view returns(uint256);
    function balanceOf(address entity) external view returns(uint256);
    function transfer(address recipient, uint256 quantity) external returns(bool);
    function allowance(address holder, address agent) external view returns(uint256);
    function approve(address agent, uint256 quantity) external returns(bool);
    function transferFrom(address source, address recipient, uint256 quantity) external returns(bool);
    event FundsMoved(address indexed fromEntity, address indexed toEntity, uint256 value);
    event Consent(address indexed holder, address indexed agent, uint256 value);
}

// AntiReentry provides protection against re-entrancy attacks.
abstract contract AntiReentry {
    uint256 private constant _OUTSIDE = 1;
    uint256 private constant _INSIDE = 2;
    uint256 private _guardStatus;
    
    error AntiReentryBreach();

    constructor() {
        _guardStatus = _OUTSIDE;
    }

    // Modifier to protect against re-entrancy.
    modifier nonReentry() {
        _beforeEntry();
        _;
        _afterExit();
    }

    // Internal function to check before entry.
    function _beforeEntry() private {
        if (_guardStatus == _INSIDE) {
            revert AntiReentryBreach();
        }
        _guardStatus = _INSIDE;
    }

    // Internal function to handle after exit.
    function _afterExit() private {
        _guardStatus = _OUTSIDE;
    }
}

// SnifferSwap is the main contract for migrating old Sniffer tokens to new ones.
contract SnifferSwap is Proprietorship, AntiReentry {
    ERC20Blueprint oldSnifferToken;
    ERC20Blueprint newSnifferToken;
    uint stage = 0;

    // Constructor sets the initial addresses of the old and new Sniffer tokens.
    constructor() {
        oldSnifferToken = ERC20Blueprint(address(0x68E47eeCFd76fd289fa0CF4B25009c7e00E10bA6)); // Old Sniffer Token address
        newSnifferToken = ERC20Blueprint(address(0x7592b42b15aBEea1FEB767AfA727952C23e1aF38)); // New Sniffer Token address
    }

    // Receives Ether.
    receive() external payable {}

    // Stage 1 - users deposit old Sniffer tokens to receive new ones.
    function claim(uint oldSnifferTokenQty) external nonReentry {
        require(stage != 0, "Migration not initialized.");
        require(stage == 1, "Stage 1 of migration has concluded.");
        uint userHoldings = oldSnifferToken.balanceOf(msg.sender);
        require(userHoldings >= oldSnifferTokenQty, "Insufficient old Sniffer tokens.");
        uint contractNewSnifferTokenReserve = newSnifferToken.balanceOf(address(this));
        require(contractNewSnifferTokenReserve >= oldSnifferTokenQty, "Not enough new Sniffer tokens in the contract.");
        oldSnifferToken.transferFrom(msg.sender, address(this), oldSnifferTokenQty);
        newSnifferToken.transfer(msg.sender, oldSnifferTokenQty);
    }

    // Modify to adjust the token addresses.
    function adjustSnifferTokenAddresses(address oldTkn, address newTkn) external soleOwner {
        oldSnifferToken = ERC20Blueprint(oldTkn);
        newSnifferToken = ERC20Blueprint(newTkn);
    }

    // Modify to switch migration stage.
    function switchStage(uint _stage) external soleOwner {
        stage = _stage;
    }

    // Retrieve any token sent to this contract by mistake.
    function retrieveToken(address _tokenAddr, address _destination) external soleOwner {
        require(_tokenAddr != address(0), "Token address cannot be null.");
        uint256 contractReserve = ERC20Blueprint(_tokenAddr).balanceOf(address(this));
        ERC20Blueprint(_tokenAddr).transfer(_destination, contractReserve);
    }

    // Withdraw stranded Ether sent to this contract.
    function withdrawStrandedEther(address recipientAddr) external soleOwner {
        (bool success, ) = recipientAddr.call{value: address(this).balance}("");
        require(success);
    }
}