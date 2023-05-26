// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "./Treasury.sol";
import "./Distribution.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint) external;
}

interface IDistribution {
    function estimateEndBlock() external view returns (uint);
    function init(address, address, uint, uint) external;
    function depositToken(uint) external;
    function refixBlockAmount(uint) external;
    function removeDistribution() external;
    function distribute(address) external;
    function updateDistributionIndex() external;
    function totalAmount() external view returns (uint);
    function blockAmount() external view returns (uint);
    function distributableBlock() external view returns (uint);
    function distribution() external view returns (uint);
    function withdrawToken(uint amount) external;
}

interface IFactory {
    function poolExist(address) external view returns (bool);
}


contract TreasuryImpl is Treasury {

    using SafeMath for uint256;

    event ChangeNextOwner(address nextOwner);
    event ChangeOwner(address owner);
    event SetPolicyAdmin(address policyAdmin);
    event SetOperator(address operator, bool valid);
    event SetTrustedForwarder(address forwarder);

    event CreateDistribution(address token, address lp, uint totalAmount, uint blockAmount, uint blockNumber);
    event RemoveDistribution(address lp, address token);

    event Deposit(address lp, address token, uint amount);
    event RefixBlockAmount(address lp, address token, uint blockAmount);
    event Withdraw(address lp, address token, uint amount);

    constructor() public Treasury(address(0), address(0), address(0), address(0)){}

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == owner || msg.sender == policyAdmin);
        _;
    }

    modifier onlyOperator {
        require(msg.sender == owner || msg.sender == policyAdmin || validOperator[msg.sender]);
        _;
    }

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    function version() public pure returns (string memory) {
        return "TreasuryImpl20220901";
    }

    function changeNextOwner(address _nextOwner) public onlyOwner {
        nextOwner = _nextOwner;

        emit ChangeNextOwner(_nextOwner);
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);

        owner = nextOwner;
        nextOwner = address(0);

        emit ChangeOwner(owner);
    }

    function setPolicyAdmin(address _policyAdmin) public onlyOwner {
        policyAdmin = _policyAdmin;

        emit SetPolicyAdmin(_policyAdmin);
    }

    function setOperator(address _operator, bool _valid) public onlyPolicyAdmin {
        validOperator[_operator] = _valid;

        emit SetOperator(_operator, _valid);
    }

    function setTrustedForwarder(address forwarder) public onlyOwner {
        require(msg.sender == owner);

        _setTrustedForwarder(forwarder);

        emit SetTrustedForwarder(forwarder);
    }

    function createTokenDistribution(
        address token, address lp, uint amount, uint blockAmount, uint blockNumber
    ) public onlyOperator nonReentrant {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount));
        require(IFactory(factory).poolExist(lp));

        create(token, lp, amount, blockAmount, blockNumber);
    }

    function create(address token, address lp, uint amount, uint blockAmount, uint blockNumber) private {
        require(distributions[lp][token] == address(0));

        require(blockNumber >= block.number);
        require(amount != 0 && blockAmount != 0);

        address distribution = address(new Distribution());

        IDistribution(distribution).init(token, lp, blockAmount, blockNumber);
        distributions[lp][token] = distribution;
        distributionOperator[distribution] = msg.sender;

        require(IERC20(token).approve(distribution, amount));
        IDistribution(distribution).depositToken(amount);

        uint index = distributionCount[lp];

        distributionEntries[lp][index] = distribution;
        distributionCount[lp] = index + 1;

        emit CreateDistribution(token, lp, amount, blockAmount, blockNumber);
    }

    function depositToken(address lp, address token, uint amount) public onlyOperator nonReentrant {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount));

        deposit(lp, token, amount);
    }

    function deposit(address lp, address token, uint amount) private {
        address distribution = distributions[lp][token];
        require(distribution != address(0));
        require(amount != 0);

        require(IERC20(token).approve(distribution, amount));
        IDistribution(distribution).depositToken(amount);

        emit Deposit(lp, token, amount);
    }

    function refixBlockAmount(address lp, address token, uint blockAmount) public onlyPolicyAdmin nonReentrant {
        address distribution = distributions[lp][token];
        require(distribution != address(0));
        require(blockAmount != 0);

        IDistribution(distribution).refixBlockAmount(blockAmount);

        emit RefixBlockAmount(lp, token, blockAmount);
    }

    function withdrawToken(address lp, address token, uint amount) public nonReentrant onlyPolicyAdmin {
        address distribution = distributions[lp][token];
        require(distribution != address(0));
        require(amount != 0);

        IDistribution(distribution).withdrawToken(amount);
        require(IERC20(token).transfer(owner, amount));

        emit Withdraw(lp, token, amount);
    }


    function removeDistribution(address lp, address token) public nonReentrant onlyPolicyAdmin {
        address distribution = distributions[lp][token];
        require(distribution != address(0));

        uint endBlock = IDistribution(distribution).estimateEndBlock();
        if (endBlock.add(7 days) <= block.number) {
            IDistribution(distribution).removeDistribution();

            distributionOperator[distribution] = address(0);
            distributions[lp][token] = address(0);
            emit RemoveDistribution(lp, token);
        }
    }

    // for user
    function claim(address target) public nonReentrant {
        _claim(_msgSender(), target);
    }

    // for exchange
    function claim(address user, address target) public nonReentrant {
        require(target == msg.sender);

        _claim(user, target);
    }

    function _claim(address user, address target) private {
        updateEntries(target);

        if (distributionCount[target] == 0) return;

        for (uint i = 0; i < distributionCount[target]; i++) {
            IDistribution(distributionEntries[target][i]).distribute(user);
        }
    }

    function updateEntries(address target) private {
        uint index = distributionCount[target];
        if (index == 0) return;

        address[] memory entries = new address[](index);
        uint count = 0;
        uint i;
        for (i = 0; i < index; i++) {
            address dis = distributionEntries[target][i];
            if (distributionOperator[dis] != address(0)) {
                entries[count] = dis;
                count = count + 1;
            }
        }

        for (i = 0; i < index; i++){
            if (i < count) {
                distributionEntries[target][i] = entries[i];
            } else {
                distributionEntries[target][i] = address(0);
            }
        }

        distributionCount[target] = count;
    }

    function updateDistributionIndex(address target) public nonReentrant {
        if (distributionCount[target] == 0) return;

        for (uint i = 0; i < distributionCount[target]; i++) {
            IDistribution(distributionEntries[target][i]).updateDistributionIndex();
        }
    }


    function getAirdropStat(address lp, address token) public view returns (
        address distributionContract, // airdrop distribution contract address
        uint totalAmount, // Total amount of tokens to be distributed
        uint blockAmount, // Amount of tokens to be distributed per block
        uint distributableBlock, // Block number to airdrop start
        uint endBlock, // Block number to airdrop end
        uint distributed,  // Amount of tokens distributed
        uint remain // amount remaining in the contract
    ){
        distributionContract = distributions[lp][token];

        IDistribution dis = IDistribution(distributionContract);
        totalAmount = dis.totalAmount();
        blockAmount = dis.blockAmount();
        distributableBlock = dis.distributableBlock();
        endBlock = dis.estimateEndBlock();
        distributed = dis.distribution();
        remain = IERC20(token).balanceOf(distributionContract);
    }

    function inCaseTokensGetStuck(address token) public onlyOwner {
        uint balance = 0;
        if (token == address(0)){
            balance = (address(this)).balance;
            if (balance > 0){
                (bool res, ) = owner.call.value(balance)("");
                require(res);
            }
        }
        else {
            balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                require(IERC20(token).transfer(owner, balance));
            }
        }
    }

    function () payable external {
        revert();
    }
}