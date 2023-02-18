/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IBONEHub {
    function withdraw() external;
    function recalibrate() external;
    function setMultiplier(uint256 _multiplier) external;
    function rescue(address token, address recipient, uint256 amount) external;
    function setIsAuthorized(address _address) external;
    function setParameters(address _token, address _construct) external;
}

contract BONEcHub is Ownable {
    using SafeMath for uint256;
    mapping (address => bool) public isAuthorized;
    modifier authorized() {require(isAuthorized[msg.sender], "!TOKEN"); _;}
    IBONEHub hub;
    constructor() Ownable(msg.sender) {
        isAuthorized[msg.sender] = true;
        hub = IBONEHub(0x2FE147DEC3a89b1059E80d1B3942dA1527620191);
    }

    function setIBONEHub(address _contract) external authorized {
        hub = IBONEHub(_contract);
    }

    function setParameters(address _token, address _construct) external authorized {
        hub.setParameters(_token, _construct);
    }

    function withdraw() external authorized {
        hub.withdraw();
    }
    
    function setIsAuthorized(address _address) external authorized {
        hub.setIsAuthorized(_address);
    }
    
    function setMultiplier(uint256 _multiplier) external authorized {
        hub.setMultiplier(_multiplier);
    }
    
    function recalibrate() external {
        hub.recalibrate();
    }
    
    function rescue(address token, address recipient, uint256 amount) external authorized {
        hub.rescue(token, recipient, amount);
    }
}