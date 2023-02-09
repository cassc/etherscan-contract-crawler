pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AXPE is ERC20 {
    mapping(address => address) public Recommend;
    mapping(address => address[]) public lowerlevel;
    bool public lock = true;
    address public OWNER;
    address public operationAddress;
    uint public AMOUNT;
    uint public VIPAMOUNT;

    constructor(uint256 initialSupply) ERC20("AXPE", "AXPE") {
        _mint(msg.sender, initialSupply);
        OWNER = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == OWNER);
        _;
    }
    modifier lockTransfer() {
        require(lock == true, "lock transfer is error");
        _;
    }

    function setLock(bool bools) external onlyOwner {
        lock = bools;
    }

    function setOwner(address _address) external onlyOwner {
        OWNER = _address;
    }

    function setAmount(uint _amount) external onlyOwner {
        AMOUNT = _amount * 1E18;
    }

    function lookSuperior(address _addr) public view returns (address) {
        return Recommend[_addr];
    }

    function getVipAmount() external view returns (uint) {
        return VIPAMOUNT;
    }

    function getLowerLevel(
        address _addr
    ) external view returns (address[] memory) {
        return lowerlevel[_addr];
    }

    function invitation(address from, address to) external {
        require(
            msg.sender == operationAddress,
            "Invitation's operationAddress error"
        );
        require(
            Recommend[to] == address(0),
            "Invitation  exist address  error"
        );

        Recommend[to] = from;
        VIPAMOUNT++;
        lowerlevel[from].push(to);
    }

    function updataSuperior(
        address _address,
        address _lowerlevel
    ) external onlyOwner {
        require(_address != address(0) && _lowerlevel != address(0));
        Recommend[_address] = _lowerlevel;
    }

    function getTenHierarchy(
        address _addr
    ) external view returns (address[] memory) {
        address[] memory Ten = new address[](10);
        address temp = Recommend[_addr];
        for (uint i = 0; i < 10; i++) {
            if (temp == address(0)) {
                break;
            } else {
                Ten[i] = temp;
                temp = Recommend[temp];
            }
        }
        return Ten;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override lockTransfer {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        if (Recommend[to] == address(0)) {
            Recommend[to] = from;
            VIPAMOUNT++;
            lowerlevel[from].push(to);
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
}