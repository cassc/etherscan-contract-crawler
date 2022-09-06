// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AccessControl.sol";
import "./Pausable.sol";


contract Presale_Swap is AccessControl, Pausable {
    using SafeMath for uint256;
    address public _tokenCVN;
    address public _tokenUSDT;
    address public ownerAddress;
    
    mapping(address => bool) public _hasPurchased;
    address[] public _buyers;

    uint256 public _minUSDT = 1000e6;
    uint256 public _cvnPrice = 10000;

    uint256 public purchaseCount = 0;
    uint256 public purchaseUsdt = 0;
    uint256 public purchaseCvn = 0;

    constructor(address cvn, address usdt, address ownerAddr) {
        _tokenCVN = cvn;
        _tokenUSDT = usdt;
        ownerAddress = ownerAddr;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        super._pause();
    }

    modifier onlyAdminRole() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Presale Swap: !admin"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyAdminRole {
        require(msg.sender != newOwner, "Presale Swap: !same address");
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function swap(uint256 amount) public whenNotPaused returns (bool) {

        uint256 token_amount = amount * 1e18 / _cvnPrice;

        require(
            _minUSDT <= amount,
            "Presale Swap: Smaller than Min USDT amount!"
        );

        require(
            ERC20(_tokenUSDT).balanceOf(address(msg.sender)) >= amount,
            "Presale Swap: Not enough USDT !"
        );

        require(
            ERC20(_tokenCVN).balanceOf(address(this)) >= token_amount,
            "Presale Swap: Not enough CVN Token !"
        );

        if(_hasPurchased[msg.sender] != true) purchaseCount = purchaseCount + 1;
        purchaseUsdt = purchaseUsdt + amount;
        purchaseCvn = purchaseCvn + token_amount;
        
        _hasPurchased[msg.sender] = true;
        _buyers.push(msg.sender);
        ERC20(_tokenUSDT).transferFrom(msg.sender, ownerAddress, amount - 1);

        ERC20(_tokenCVN).transfer(msg.sender, token_amount);
    }

    function sendToken(address token, uint256 amount, address to) public onlyAdminRole {
        require(
            ERC20(token).balanceOf(address(this)) >= amount,
            "Presale Swap: Token balance is not enough !"
        );
        ERC20(token).transfer(
            to,
            amount
        );
    }

    function resetRound() public onlyAdminRole {
        for (uint256 i = 0; i < _buyers.length; i++) {
            _hasPurchased[_buyers[i]] = false;
        }
        delete _buyers;
    }


    function setMinUSDT(uint256 amount) public onlyAdminRole {
        _minUSDT = amount;
    }

    function setCvnPrice(uint256 price) public onlyAdminRole {
        _cvnPrice = price;
    }

    function setTokenUsdt(address usdt) public onlyAdminRole {
        _tokenUSDT = usdt;
    }

    function setTokenCvn(address cvn) public onlyAdminRole {
        _tokenCVN = cvn;
    }

    function setOwnerAddress(address ownerAddr) public onlyAdminRole {
        ownerAddress = ownerAddr;
    }

    function pause() external onlyAdminRole {
        super._pause();
    }

    function unpause() external onlyAdminRole {
        super._unpause();
    }
}