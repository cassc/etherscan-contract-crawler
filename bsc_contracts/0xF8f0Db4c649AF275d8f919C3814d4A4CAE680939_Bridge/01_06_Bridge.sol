// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Bridge is Ownable{
    
    address public bSVC;
    uint256 public fee;
    address public walletFee = 0xE1706Cf31f47E34d1E1eA8621F05FDc9E2067183;
    mapping(address => bool) public whitelist;
    event LockBSC(address indexed sender, address indexed recipient, uint256 amount, uint256 chain_id_to);
    event UnlockBSC(address indexed sender, address indexed recipient, uint256 amount);
    event WithdrawAllBSC(uint256 amountWithdrawAll);
    modifier onlyDev() {
        require(whitelist[msg.sender] == true, "can not access");
        _;
    }
    constructor (address _bSVC){
        bSVC = _bSVC;
        fee = 10;
    }
    function updateAddress(address _bSVC) public onlyDev {
        bSVC = _bSVC;
    }
    function updateWhitelist(address dev) public onlyOwner {
        whitelist[dev] = true;
    }
    function lock( address _recipient, uint256 _amountbSVC, uint256 chain_id_to) external{
        require(1000 ether<= _amountbSVC && _amountbSVC <= 100000 ether, "invalid lock amount");
        require(IERC20(bSVC).balanceOf(msg.sender) >= _amountbSVC, "Insufficient wSVC account balance !!!");
        IERC20(bSVC).transferFrom(msg.sender, address(this), _amountbSVC);
        emit LockBSC(msg.sender, _recipient, _amountbSVC, chain_id_to);
    }

    function unlock( address _recipient, uint256 _amountbSVC) external onlyDev {
        require(IERC20(bSVC).balanceOf(address(this)) >= _amountbSVC, "Insufficient SVC account balance !!!");
        IERC20(bSVC).transfer(walletFee, _amountbSVC * fee /100);
        IERC20(bSVC).transfer(_recipient, _amountbSVC * (100-fee)/100);
        emit UnlockBSC(msg.sender, _recipient, _amountbSVC);
    }
    function revertBSC(address _recipient, uint256 _amountbSVC) external onlyDev {
        require(IERC20(bSVC).balanceOf(address(this)) >= _amountbSVC, "Insufficient SVC account balance !!!");
        IERC20(bSVC).transfer(_recipient, _amountbSVC);
        emit UnlockBSC(msg.sender, _recipient, _amountbSVC);
    }
    function withdrawAll() public onlyOwner{
        
        IERC20(bSVC).transfer(msg.sender, IERC20(bSVC).balanceOf(address(this)));
        emit WithdrawAllBSC(IERC20(bSVC).balanceOf(address(this)));
    }
    
    function updateFeeBSC(uint256 _fee) public onlyOwner{
        // fee is percentage for example: 10, 20,...
        require(1<= _fee && _fee <100, "invalid fee");
        fee = _fee;
    }
    function updateFeeWalletBSC(address _walletFee) public onlyOwner{
        walletFee = _walletFee;
    }

}