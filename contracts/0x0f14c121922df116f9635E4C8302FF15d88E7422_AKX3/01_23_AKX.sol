// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Roles.sol";

error ZeroValueSent();

contract AKX3 is ERC20, ERC20Burnable, ERC20Permit, ReentrancyGuard, AKXRoles {

    using SafeERC20 for IERC20;
    event Deposit(address indexed from, uint256 _value);
    address public treasury = 0x39b9fdA7d6cfE6987126c9010aaA56635E224bdB;

bool canTransfer;
    constructor() ERC20("AKX3 ECOSYSTEM", "AKX") ERC20Permit("AKX3 ECOSYSTEM") {
        canTransfer = false;
        initRoles();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(AKX_OPERATOR_ROLE, _msgSender());
        
    }

    function mint(address _sender, uint256 amount) public  onlyRole(AKX_OPERATOR_ROLE) {
    super._mint(_sender, amount);
    }

    
 function _afterTokenTransfer(address from, address to, uint256 amount)
        internal override
        
    {
        super._afterTokenTransfer(from, to, amount);
    }

     function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal override
      
    {
        super._afterTokenTransfer(from, to, amount);
    }

 function enableTransfer() public onlyRole(AKX_OPERATOR_ROLE) {
        canTransfer = true;
    }

    modifier isTransferable() {
        require(canTransfer != false || hasRole(AKX_OPERATOR_ROLE, msg.sender), "cannot trade or transfer");
        _;
    }

    function transfer(address _to, uint _value) public isTransferable virtual override returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            IERC20(this).safeTransfer( _to, _value);
            success = true;
        }
       revert("cannot transfer");
    }

    

    // withdraw function in case of emergency only executable by the operator and only transferable to the gnosis multisignature treasury wallet
    function withdraw() external onlyRole(AKX_OPERATOR_ROLE) {
        payable(treasury).transfer(address(this).balance);
    }

    receive() external payable {
        if(msg.value <= 0) {
            revert ZeroValueSent();
        }
        emit Deposit(msg.sender, msg.value);
    }

}