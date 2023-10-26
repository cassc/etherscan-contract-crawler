/**
 *Submitted for verification at Etherscan.io on 2023-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ProfitTokenV1 is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;

    uint256 private constant _MULTIPLIER = 2 ** 160;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner = 0x9BE2b75F93195f00BB64e667Fb1e3a29612bC01F;

    address public constant DEAD = 0x0000000000000000000000000000000000000000;

    address public rewardsWallet = 0x71C596d928Ee6257E7d6844ee956007869f7a75f;

    address public constant DARWIN_SWAP_PAIR_ADDRESS =
        0xd9145CCE52D386f254917e481eB44e9943F39138;

    // Reflections
    uint256 public culmulativeRewardPerToken;
    address[] public excludedFromRewards;

    mapping(address => uint256) private _lastCulmulativeRewards;
    mapping(address => bool) private _isExcludedFromRewards;

    mapping(address => bool) private _isDex;

    modifier onlyDeployer() {
        require(
            msg.sender == owner || msg.sender == address(this),
            "ONLY_DEPLOYER"
        );
        _;
    }

    ////////////////////// REWARDS FUNCTIONS /////////////////////////////////////

    function setRewardsWallet(address _rewardsWallet) external onlyDeployer {
        rewardsWallet = _rewardsWallet;
    }

    function setIsDex(address dex, bool status) external onlyDeployer {
        _isDex[dex] = status;
    }

    function _getRewardsOwed(
        uint _cumulativeRewardsPerToken,
        uint _lastCumulativeRewards,
        uint _balance
    ) internal pure returns (uint) {
        return
            ((_cumulativeRewardsPerToken - _lastCumulativeRewards) * _balance) /
            _MULTIPLIER;
    }

    function _distributeRewardToUser(
        uint _culmulativeRewardsPerToken,
        uint _accountsLastCulmulativeRewards,
        uint _balance,
        address _account
    ) internal returns (uint newBalance) {
        uint _rewardsOwed = _getRewardsOwed(
            _culmulativeRewardsPerToken,
            _accountsLastCulmulativeRewards,
            _balance
        );
        if (_rewardsOwed > balanceOf(rewardsWallet)) {
            _rewardsOwed = balanceOf(rewardsWallet);
        }
        _lastCulmulativeRewards[_account] = _culmulativeRewardsPerToken;
        if (_rewardsOwed > 0) {
            _lowGasTransfer(rewardsWallet, _account, _rewardsOwed);
        }
        newBalance = _balance + _rewardsOwed;
    }

    function distributeRewards(uint256 amount) external {
        _updateBalance(msg.sender);
        _lowGasTransfer(msg.sender, rewardsWallet, amount);
        _distributeRewards(amount);
    }

    function _distributeRewards(uint256 amount) internal {
        culmulativeRewardPerToken +=
            (amount * _MULTIPLIER) /
            (totalSupply() - _getExcludedBalances());
    }

    function _getExcludedBalances()


internal
        view
        returns (uint excludedBalances)
    {
        address[] memory _excludedAddresses = excludedFromRewards;
        for (uint i = 0; i < _excludedAddresses.length; i++) {
            excludedBalances += balanceOf(_excludedAddresses[i]);
        }
    }

    function setExcludedFromRewards(address account) public onlyDeployer {
        if (_isExcludedFromRewards[account]) return;

        uint _culmulativeRewardPerToken = culmulativeRewardPerToken;
        uint last = _lastCulmulativeRewards[account];
        if (last < _culmulativeRewardPerToken) {
            _distributeRewardToUser(
                _culmulativeRewardPerToken,
                last,
                balanceOf(account),
                account
            );
        }
        _isExcludedFromRewards[account] = true;
        excludedFromRewards.push(account);
    }

    function removeExcludedFromRewards(address account) public onlyDeployer {
        if (!_isExcludedFromRewards[account]) return;
        delete _isExcludedFromRewards[account];
        address[] memory _excludedAddresses = excludedFromRewards;
        for (uint i = 0; i < _excludedAddresses.length; i++) {
            if (_excludedAddresses[i] == account) {
                excludedFromRewards[i] = _excludedAddresses[
                    _excludedAddresses.length - 1
                ];
                excludedFromRewards.pop();
                break;
            }
        }
        _lastCulmulativeRewards[account] = culmulativeRewardPerToken;
    }

    function _updateBalance(address account) internal {
        if (_isExcludedFromRewards[account]) return;
        uint _culmulativeRewardPerToken = culmulativeRewardPerToken;
        uint _lastCulmulativeReward = _lastCulmulativeRewards[account];
        if (_culmulativeRewardPerToken > _lastCulmulativeReward) {
            _distributeRewardToUser(
                _culmulativeRewardPerToken,
                _lastCulmulativeReward,
                balanceOf(account),
                account
            );
        }
    }

    constructor() {
        owner = msg.sender;
        _name = "PROFIT";
        _symbol = "PROFIT";
        _totalSupply = 100_000_000 * (10 ** _decimals);

        isExcludedFromFees[owner] = true;

        // Add the DarwinSwap pair as an excluded address to avoid tax and have it apply on the DEX side

        // exclude addresses from receiving rewards
        setExcludedFromRewards(msg.sender);
        setExcludedFromRewards(rewardsWallet);
        setExcludedFromRewards(DEAD);
        setExcludedFromRewards(DARWIN_SWAP_PAIR_ADDRESS);
        

        _balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable {}

    function name() public view override returns (string memory) {
        return _name;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply - _balances[DEAD];
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) public view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        require(spender != address(0), "NO_ZERO");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }


function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        require(spender != address(0), "NO_ZERO");
        _allowances[msg.sender][spender] =
            allowance(msg.sender, spender) +
            addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        require(spender != address(0), "NO_ZERO");
        require(
            allowance(msg.sender, spender) >= subtractedValue,
            "INSUFF_ALLOWANCE"
        );
        _allowances[msg.sender][spender] =
            allowance(msg.sender, spender) -
            subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(
                _allowances[sender][msg.sender] >= amount,
                "INSUFF_ALLOWANCE"
            );
            _allowances[sender][msg.sender] -= amount;
            emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _updateBalance(sender);
        _updateBalance(recipient);

        if (!checkTaxFree(sender, recipient)) {
            // Burn 8% of the transfer amount if the sender is not excluded from fees
            _lowGasTransfer(sender, DEAD, (amount * 8) / 100);
            amount = (amount * 92) / 100;
        }
        // Send the full amount to the recipient

        _lowGasTransfer(sender, recipient, amount);

        if (recipient == rewardsWallet) {
            _distributeRewards(amount);
        }

        return true;
    }

    function checkTaxFree(
        address sender,
        address recipient
    ) internal view returns (bool) {
        if (isExcludedFromFees[sender] || isExcludedFromFees[recipient])
            return true;

        if(_isDex[sender] || _isDex[recipient])
            return false;

        // Wallet to wallet transfer
        return true;
    }

    function _lowGasTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "Can't use zero addresses here");
        require(
            amount <= _balances[sender],
            "Can't transfer more than you own"
        );
        if (amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function rescueEth(uint256 amount) external onlyDeployer {
        (bool success, ) = address(owner).call{value: amount}("");
        success = true;
    }

    function rescueToken(address token, uint256 amount) external onlyDeployer {
        IERC20(token).transfer(owner, amount);
    }

    function excludeFromFees(
        address excludedWallet,
        bool status
    ) external onlyDeployer {
        isExcludedFromFees[excludedWallet] = status;
    }

    function renounceOwnership() external onlyDeployer {
        owner = address(0);
    }
}