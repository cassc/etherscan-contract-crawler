//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    function transfer(address to, uint amount) external;
    function decimals() external view returns(uint);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract DAOAllocation {

    uint256 constant public min = 50000000000000000;
    uint256 public totalAllocated = 0;

    address public dead = 0x000000000000000000000000000000000000dEaD;
    address public owner;
    bool public isClaimStarted;

    mapping (address => uint256) public allocations;

    IERC20 aitron;
    IERC20 cctron;
    
    // Reentrancy storage
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(address _aitron, address _cctron) {
        aitron = IERC20(_aitron);
        cctron = IERC20(_cctron);

        owner = msg.sender;
    }

    function burn(uint256 amount) public nonReentrant {
        require(amount >= min);
        require(aitron.balanceOf(msg.sender) >= amount);

        aitron.transferFrom(msg.sender, dead, amount);

        uint256 allocation = amount / 1000;
        allocations[msg.sender] = allocations[msg.sender] + allocation;
        totalAllocated += allocation;
    }

    function claim() public nonReentrant {
        address sender = msg.sender;
        require(isClaimStarted);
        require(allocations[sender] >= 0);

        uint256 allocation = allocations[sender];
        allocations[sender] = 0;
        cctron.transfer(sender, allocation);
    }

    function enable() public {
        require(msg.sender == owner);
        isClaimStarted = true;
    }

    function withdrawERC20() public {
        address sender = msg.sender;
        require(sender == owner);
        cctron.transfer(sender, cctron.balanceOf(address(this)));
    }
}