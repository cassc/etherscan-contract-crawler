pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    struct PoolAddress{
        address poolReward;
        bool isActive;
        bool isExist;

    }

    struct WhitelistTransfer{
        address waddress;
        bool isActived;
        string name;

    }
    mapping (address => uint256) private _balances;

    mapping (address => WhitelistTransfer) public whitelistTransfer;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address[] rewardPool;
    mapping(address=>PoolAddress) mapRewardPool;
   
    address internal tokenOwner;
    uint256 internal beginFarming;

    function addRewardPool(address add) public {
        require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        require(!mapRewardPool[add].isExist,"Pool already exist");
        mapRewardPool[add].poolReward=add;
        mapRewardPool[add].isActive=true;
        mapRewardPool[add].isExist=true;
        rewardPool.push(add);
    }

    function addWhitelistTransfer(address add, string memory name) public{
         require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
         whitelistTransfer[add].waddress=add;
        whitelistTransfer[add].isActived=true;
        whitelistTransfer[add].name=name;

    }

     function removeWhitelistTransfer(address add) public{
         require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        
        whitelistTransfer[add].isActived=false;
        

    }



    function removeRewardPool(address add) public {
        require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        mapRewardPool[add].isActive=false;
       
        
    }

    function countActiveRewardPool() public  view returns (uint256){
        uint length=0;
     for(uint i=0;i<rewardPool.length;i++){
         if(mapRewardPool[rewardPool[i]].isActive){
             length++;
         }
     }
      return  length;
    }
   function getRewardPool(uint index) public view  returns (address){
    
        return rewardPool[index];
    }

   
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(whitelistTransfer[recipient].isActived || whitelistTransfer[_msgSender()].isActived){//withdraw from exchange will not effect
            _transferWithoutDeflationary(_msgSender(), recipient, amount);
        }
        else{
            _transfer(_msgSender(), recipient, amount);
        }
        
        return true;
    }
 function transferWithoutDeflationary(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithoutDeflationary(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 burnAmount;
        uint256 rewardAmount;
         uint totalActivePool=countActiveRewardPool();
         if (block.timestamp > beginFarming && totalActivePool>0) {
            (burnAmount,rewardAmount)=_caculateExtractAmount(amount);

        }     
        //div reward
        if(rewardAmount>0){
           
            uint eachPoolShare=rewardAmount.div(totalActivePool);
            for(uint i=0;i<rewardPool.length;i++){
                 if(mapRewardPool[rewardPool[i]].isActive){
                    _balances[rewardPool[i]] = _balances[rewardPool[i]].add(eachPoolShare);
                    emit Transfer(sender, rewardPool[i], eachPoolShare);

                 }
                
       
            }
        }


        //burn token
        if(burnAmount>0){
          _burn(sender,burnAmount);
            _balances[sender] = _balances[sender].add(burnAmount);//because sender balance already sub in burn

        }
      
        
        uint256 newAmount=amount-burnAmount-rewardAmount;

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      
        _balances[recipient] = _balances[recipient].add(newAmount);
        emit Transfer(sender, recipient, newAmount);

        
        
    }
    
 function _transferWithoutDeflationary(address sender, address recipient, uint256 amount) internal virtual {
          require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        
    }
    
    function _deploy(address account, uint256 amount,uint256 beginFarmingDate) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        tokenOwner = account;
        beginFarming=beginFarmingDate;

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    
    function _caculateExtractAmount(uint256 amount)
        internal
        
        returns (uint256, uint256)
    {
       
            uint256 extractAmount = (amount * 5) / 1000;

            uint256 burnAmount = (extractAmount * 10) / 100;
            uint256 rewardAmount = (extractAmount * 90) / 100;

            return (burnAmount, rewardAmount);
      
    }

    function setBeginDeflationFarming(uint256 beginDate) public {
        require(msg.sender == tokenOwner, "ERC20: Only owner can call");
        beginFarming = beginDate;
    }

    function getBeginDeflationary() public view returns (uint256) {
        return beginFarming;
    }

    

}