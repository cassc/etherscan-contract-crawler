/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

  
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    
    address private _owner;
    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function ownable_init(address __owner) internal {
        _owner = __owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

    function owner() public view returns(address) {
        return _owner;
    }
}

contract Initializable {

    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract MetaLifeGlobe is Ownable, Initializable, Pausable {
    
    using SafeERC20 for IERC20;

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint workingIncome;
        uint nonWorkingIncome;
        mapping(uint8 => uint) holdAmount;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => bool) activeX2Levels;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => X2) x2Matrix;
    }

    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    struct X2 {
        address currentReferrer;
        address[] refferals;
    }

    uint8 public LAST_LEVEL;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId;
    mapping(uint8 => uint) public levelPrice;

    mapping(uint8 => mapping(uint256 => address)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;


    IERC20 public daiToken;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event UserIncome(address indexed sender, address indexed receiver , uint matrix, uint level ,uint amount , string incomeType);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint matrix, uint level, uint place);
    event Test(address ,uint ,address ,bool);
    
    function initialize(address _ownerAddress,IERC20 _depositToken) external initializer { 
        LAST_LEVEL = 12;

        levelPrice[1] = 10e18;
        for (uint8 i = 2; i <= 12; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }     

        users[_ownerAddress].id = 1;
        idToAddress[1] = _ownerAddress;
        emit Registration(_ownerAddress, address(0), 1, 0);
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[_ownerAddress].activeX6Levels[i] = true;
            users[_ownerAddress].activeX2Levels[i] = true;
            x2vId_number[i][1]=_ownerAddress;
            x2Index[i]=1;
            x2CurrentvId[i]=1;
            emit Upgrade(_ownerAddress,address(0),i);
        }
        
        lastUserId = 2;
        ownable_init(_ownerAddress);
        daiToken = _depositToken;
    }

    function registrationExt(address referrerAddress) external whenNotPaused {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 level) external whenNotPaused {
        require(daiToken.allowance(msg.sender,address(this))>=levelPrice[level],"ERC20: allowance exceed! ");
        daiToken.transferFrom(msg.sender,address(this),levelPrice[level]);
        _buyNewLevel(msg.sender,  level);

        if(users[msg.sender].holdAmount[level-1] != 0) {
            users[msg.sender].workingIncome += users[msg.sender].holdAmount[level-1];
            daiToken.transfer(msg.sender,users[msg.sender].holdAmount[level-1]);
            emit UserIncome(address(0), msg.sender, 1, level-1 ,users[msg.sender].holdAmount[level-1] , "workingIncome");
            users[msg.sender].holdAmount[level-1] = 0;
        }
    }

    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        users[userAddress].id = lastUserId;
        users[userAddress].referrer = referrerAddress;
        idToAddress[lastUserId] = userAddress;

        // users[userAddress].activeX6Levels[1] = true;
        // users[userAddress].activeX2Levels[1] = true;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        // updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            // users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner()) {
                // return sendETHDividends(referrerAddress, userAddress, 2, level);
                daiToken.transfer(owner(),levelPrice[level]);
                return;
            }

            address ref = users[referrerAddress].referrer; 
            return updateX6Referrer( userAddress,  ref,  level);
            
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if(users[referrerAddress].x6Matrix[level].secondLevelReferrals.length==1){
            users[referrerAddress].workingIncome+=levelPrice[level];
            daiToken.transfer(referrerAddress,levelPrice[level]);
            emit UserIncome(userAddress,  referrerAddress, 1,  level ,levelPrice[level] , "workingIncome");
        } else if(users[referrerAddress].x6Matrix[level].secondLevelReferrals.length==2||users[referrerAddress].x6Matrix[level].secondLevelReferrals.length==3) {
            if(!users[referrerAddress].activeX6Levels[level+1]&& level != LAST_LEVEL){
                users[referrerAddress].holdAmount[level]+= levelPrice[level]; 
                autoUpgrade(referrerAddress,  level , level+1);
            } else{
                users[referrerAddress].workingIncome+=levelPrice[level];
                daiToken.transfer(referrerAddress,levelPrice[level]);
                emit UserIncome(userAddress,  referrerAddress, 1,  level ,levelPrice[level] , "workingIncome");    
            }
        } 

        emit NewUserPlace(userAddress, referrerAddress, 1, level,  2+users[referrerAddress].x6Matrix[level].secondLevelReferrals.length);
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

    }

    function _buyNewLevel(address user, uint8 level) internal {
        require(isUserExists(user), "user is not exists. Register first.");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[user].activeX6Levels[level], "level already activated"); 
        if(level!=1) {
            require(users[user].activeX6Levels[level-1], "buy previous level first");
            if (users[user].x6Matrix[level-1].blocked) {
                users[user].x6Matrix[level-1].blocked = false;
            }
        }

        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=user;
        x2Index[level]=newIndex;

        address freeX6Referrer = findFreeX6Referrer(user, level);
        
        users[user].activeX6Levels[level] = true;
        users[user].activeX2Levels[level] = true;
        updateX6Referrer(user, freeX6Referrer, level);
        emit Upgrade(user, freeX6Referrer,  level);
        
    }   

    function autoUpgrade(address _user, uint8 _currentLevel , uint8 _nextLevel) internal {
        if(users[_user].holdAmount[_currentLevel]>=levelPrice[_nextLevel]){
            _buyNewLevel(_user,_nextLevel);
            users[_user].holdAmount[_currentLevel]-=levelPrice[_nextLevel];
            if(users[_user].holdAmount[_currentLevel]>0) {
                users[_user].workingIncome+=users[_user].holdAmount[_currentLevel];
                daiToken.transfer(_user,users[_user].holdAmount[_currentLevel]);
                emit UserIncome(address(0), _user , 1, _currentLevel ,users[_user].holdAmount[_currentLevel], "workingIncome");
                users[_user].holdAmount[_currentLevel] = 0;
            }                    
        } 
    }

    function withdrawHolding(address _user,uint8 _level) external {
        if(users[_user].holdAmount[_level]>0) {
            users[_user].workingIncome+=users[_user].holdAmount[_level];
            daiToken.transfer(_user,users[_user].holdAmount[_level]-((users[_user].holdAmount[_level]*25)/100));
            daiToken.transfer(owner(),((users[_user].holdAmount[_level]*25)/100));
            emit UserIncome(address(0), _user , 1, _level ,users[_user].holdAmount[_level], "workingIncome");
            users[_user].holdAmount[_level] = 0;
        }

    }

    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            // return sendETHDividends(referrerAddress, userAddress, 2, level);
            return;
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        // go to Non working pool
        address freeX2Referrer = findFreeX2Referrer(level);
        users[userAddress].x2Matrix[level].currentReferrer = freeX2Referrer;
        updateX2Referrer(referrerAddress, freeX2Referrer, level);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
    }

    function updateX2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(level<=LAST_LEVEL,"not valid level");
        if(users[referrerAddress].x2Matrix[level].refferals.length < 2) {
          users[referrerAddress].x2Matrix[level].refferals.push(userAddress);
          users[referrerAddress].nonWorkingIncome+=levelPrice[level];
          daiToken.transfer(referrerAddress,levelPrice[level]);
          emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x2Matrix[level].refferals.length));
          emit UserIncome(userAddress, referrerAddress , 2, level, levelPrice[level] , "NonWorking Income");
        }
        if(users[referrerAddress].x2Matrix[level].refferals.length==2){
          users[referrerAddress].x2Matrix[level].refferals= new address[](0); 
          x2CurrentvId[level]=x2CurrentvId[level]+1; 
        //   address(uint160(referrerAddress)).transfer(alevelPrice[level]*2);
         
        }

    }

    //owner method 

    function registrationFor(address userAddress, address referrerAddress) external whenNotPaused onlyOwner {
        registration(userAddress, referrerAddress);
    }

    function buyNewLevelFor(address userAddress,  uint8 level) external whenNotPaused onlyOwner {
        // require(daiToken.allowance(msg.sender,address(this))>=levelPrice[level],"ERC20: allowance exceed! ");
        // daiToken.transferFrom(msg.sender,address(this),levelPrice[level]);
        _buyNewLevelFor(userAddress,  level);

        if(users[userAddress].holdAmount[level-1] != 0) {
            users[userAddress].workingIncome += users[userAddress].holdAmount[level-1];
            // daiToken.transfer(userAddress,users[userAddress].holdAmount[level-1]);
            emit UserIncome(address(0), userAddress, 1, level-1 ,users[userAddress].holdAmount[level-1] , "workingIncome");
            users[userAddress].holdAmount[level-1] = 0;
        }
    }

    function updateX6ReferrerFor(address userAddress, address referrerAddress, uint8 level) private {
        // require(users[referrerAddress].activeX6Levels[level], "Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            // users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner()) {
                // return sendETHDividends(referrerAddress, userAddress, 2, level);
                // daiToken.transfer(owner(),levelPrice[level]);
                return;
            }

            address ref = users[referrerAddress].referrer; 
            return updateX6ReferrerFor( userAddress,  ref,  level);
            
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if(users[referrerAddress].x6Matrix[level].secondLevelReferrals.length==1){
            users[referrerAddress].workingIncome+=levelPrice[level];
            // daiToken.transfer(referrerAddress,levelPrice[level]);
            emit UserIncome(userAddress,  referrerAddress, 1,  level ,levelPrice[level] , "workingIncome");
        } else if(users[referrerAddress].x6Matrix[level].secondLevelReferrals.length==2||users[referrerAddress].x6Matrix[level].secondLevelReferrals.length==3) {
            if(!users[referrerAddress].activeX6Levels[level+1]&& level != LAST_LEVEL){
                users[referrerAddress].holdAmount[level]+= levelPrice[level]; 
                autoUpgradeFor(referrerAddress,  level , level+1);
            } else{
                users[referrerAddress].workingIncome+=levelPrice[level];
                // daiToken.transfer(referrerAddress,levelPrice[level]);
                emit UserIncome(userAddress,  referrerAddress, 1,  level ,levelPrice[level] , "workingIncome");    
            }
        } 

        emit NewUserPlace(userAddress, referrerAddress, 1, level,  2+users[referrerAddress].x6Matrix[level].secondLevelReferrals.length);
        
        updateX6ReferrerSecondLevelFor(userAddress, referrerAddress, level);

    }

    function _buyNewLevelFor(address user, uint8 level) internal {
        // require(isUserExists(user), "user is not exists.");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[user].activeX6Levels[level], "level already activated"); 
        // if(level>1) {
        //     require(users[user].activeX6Levels[level-1], "buy previous level first");
        //     if (users[user].x6Matrix[level-1].blocked) {
        //         users[user].x6Matrix[level-1].blocked = false;
        //     }
        // }

        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=user;
        x2Index[level]=newIndex;

        address freeX6Referrer = findFreeX6Referrer(user, level);
     
        users[user].activeX6Levels[level] = true;
        users[user].activeX2Levels[level] = true;
        updateX6ReferrerFor(user, freeX6Referrer, level);
        emit Upgrade(user, freeX6Referrer,  level);
        
    }   

    function autoUpgradeFor(address _user, uint8 _currentLevel , uint8 _nextLevel) internal {
        if(users[_user].holdAmount[_currentLevel]>=levelPrice[_nextLevel]){
            _buyNewLevelFor(_user,_nextLevel);
            users[_user].holdAmount[_currentLevel]-=levelPrice[_nextLevel];
            if(users[_user].holdAmount[_currentLevel]>0) {
                users[_user].workingIncome+=users[_user].holdAmount[_currentLevel];
                // daiToken.transfer(_user,users[_user].holdAmount[_currentLevel]);
                emit UserIncome(address(0), _user , 1, _currentLevel ,users[_user].holdAmount[_currentLevel], "workingIncome");
                users[_user].holdAmount[_currentLevel] = 0;
            }                    
        } 
    }

    function updateX6ReferrerSecondLevelFor(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            // return sendETHDividends(referrerAddress, userAddress, 2, level);
            return;
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        // go to Non working pool
        address freeX2Referrer = findFreeX2Referrer(level);
        users[userAddress].x2Matrix[level].currentReferrer = freeX2Referrer;
        updateX2ReferrerFor(referrerAddress, freeX2Referrer, level);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
    }

    function updateX2ReferrerFor(address userAddress, address referrerAddress, uint8 level) private {
        require(level<=LAST_LEVEL,"not valid level");
        if(users[referrerAddress].x2Matrix[level].refferals.length < 2) {
          users[referrerAddress].x2Matrix[level].refferals.push(userAddress);
          users[referrerAddress].nonWorkingIncome+=levelPrice[level];
        //   daiToken.transfer(referrerAddress,levelPrice[level]);
          emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x2Matrix[level].refferals.length));
          emit UserIncome(userAddress, referrerAddress , 2, level, levelPrice[level] , "NonWorking Income");
        }
        if(users[referrerAddress].x2Matrix[level].refferals.length==2){
          users[referrerAddress].x2Matrix[level].refferals= new address[](0); 
          x2CurrentvId[level]=x2CurrentvId[level]+1; 
        //   address(uint160(referrerAddress)).transfer(alevelPrice[level]*2);
         
        }

    }

    //END


    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeX2Referrer(uint8 level) public view returns(address){
        uint256 id=x2CurrentvId[level];
        return x2vId_number[level][id];
    }

    function usersActiveX2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX2Levels[level];
    }
        
    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, uint, address ) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount,
                users[userAddress].x6Matrix[level].closedPart
                );
    }

    function userX6HoldAmount(address userAddress , uint8 level) public view returns (uint) {
        return users[userAddress].holdAmount[level];
    }

    function usersX2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].x2Matrix[level].currentReferrer,
                users[userAddress].x2Matrix[level].refferals);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function withdrawToken(address _token,uint amount) external onlyOwner {
        IERC20(_token).transfer(owner(),amount);
    }

    function withdraw(uint amount) external onlyOwner {
       payable(owner()).transfer(amount);
    }
}