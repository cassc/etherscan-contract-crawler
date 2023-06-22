/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

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

interface IERC20_USDT {
    function transferFrom(address from, address to, uint value) external;
}

contract PeterICO is Ownable {

    IERC20 MDSE_token;
    uint public startTime;
    uint public endTime;
    uint public presaleRate;
    uint public hardCap;
    uint public fundRaised;
    //uint MAX_BPS = 10_000;
    address public MDSE;
    address[] public allBuyerAddress;

    struct TokenSale{
        uint soldToken;
        uint tokenForSale;
    }
    TokenSale public tokenSale;

    struct UserInfo{
        uint MDSE_Token;
        uint investDollar;
    }
    mapping (address=> UserInfo) public userInfo;

    enum currencyType {
        native,
        token
    }

    constructor(address _MDSE,uint _startTime,uint _endTime){

        require(_endTime > _startTime,"End Time should be greater than Start Time");
        require(_startTime > block.timestamp,"Start time should be greater than current time");
        MDSE = _MDSE;
        MDSE_token = IERC20(MDSE);
        startTime = _startTime;
        endTime = _endTime;

        presaleRate = 500; // 0.05 * MAX_BPS
        tokenSale.tokenForSale = 40000000 * 10 ** MDSE_token.decimals();
        hardCap = tokenSale.tokenForSale;
    }
   

    //==================================================================================

    function buy(uint256 _dollar, currencyType CurrencyType, address _tokenContractAddress, uint _tokenValue) public payable returns(bool){

        uint256 buyToken = (_dollar * 10**MDSE_token.decimals()) / presaleRate;

        require(isICOOver()==false,"ICO already end");
        
        require(block.timestamp >= startTime,"Out of time window");

        require(tokenSale.tokenForSale >= buyToken,"No enough token for sale");
      
        if (userInfo[msg.sender].MDSE_Token == 0) {
                userInfo[msg.sender] = UserInfo(buyToken,_dollar );
                allBuyerAddress.push(msg.sender);
        } else {
                userInfo[msg.sender].MDSE_Token += buyToken;
                userInfo[msg.sender].investDollar += _dollar;
               
        }

        tokenSale.tokenForSale -= buyToken;
        tokenSale.soldToken += buyToken;

        if (CurrencyType == currencyType.native) {
            payable(owner()).call{value: _tokenValue};
        } else {
            IERC20_USDT(_tokenContractAddress).transferFrom(msg.sender, owner(), _tokenValue);
        }

        MDSE_token.transfer(address(this),buyToken);

        fundRaised += _dollar;

        return true;
        
    }

    //=========================================Admin Functions===========================

    function retrieveStuckedERC20Token( address _tokenAddr, uint256 _amount, address _toWallet ) public onlyOwner returns (bool) {
        IERC20(_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }

    function updateTime(uint256 _startTime, uint256 _endTime) public onlyOwner returns (bool) {
        require( _startTime < _endTime, "End Time should be greater than start time");
        require( startTime > block.timestamp, "Can not change time after ICO starts" );      
        require(_startTime > block.timestamp,"Start time should be greater than current time" );
        
        startTime = _startTime;
        endTime = _endTime;
        return true;
    }

    //==================================================================================

    function isICOOver() public view returns (bool) {
        if (
            block.timestamp > endTime ||
            tokenSale.tokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isHardCapReach() public view returns(bool){
        if(hardCap == tokenSale.soldToken){
            return true;
        }else{
            return false;
        }
    }

    //==================================================================================
    
}