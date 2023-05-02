/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

interface AIVolumizer {
    function setMaxAmount(uint256 max) external;
    function setRouter(address _router) external;
    function setVolumePercentage(uint256 percent) external;
    function volumeTokenTransaction(address _contract) external;
    function volumeETHTransaction(address _contract) external;
    function swapGasBalance(uint256 percent, address _contract) external;
    function swapTokenBalance(uint256 percent, address _contract) external;
    function setIsAuthorized(address _address) external;
    function rescueHubETH(address receiver, uint256 percent) external;
    function rescueHubERC20(address token, address receiver, uint256 percent) external;
    function veiwVolumeStats(address _contract) external view returns (uint256 totalPurchased, 
        uint256 totalETH, uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime);
}

contract NFAiVolumizerControl is Auth {
    using SafeMath for uint256;
    AIVolumizer volumizer;
    bool volumeAllowed = true;
    address tokenContract;

    receive() external payable {}
    constructor() Auth(msg.sender) {
        volumizer = AIVolumizer(0xc4a297FEEabde487Fc2b8E66E2BFa64C3e54747c);
        authorize(msg.sender); 
        authorize(address(this));
    }

    function setTokenContract(address _token) external authorized {
        tokenContract = _token;
    }

    function toggleVolumeAllowed(bool enable) external authorized {
        volumeAllowed = enable;
    }

    function setRouter(address _router) external authorized {
        volumizer.setRouter(_router);
    }
    
    function setIsAuthorized(address _address) external authorized {
        volumizer.setIsAuthorized(_address);
    }

    function setMaxAmount(uint256 max) external authorized {
        volumizer.setMaxAmount(max);
    }

    function setVolumePercentage(uint256 percent) external authorized {
        volumizer.setVolumePercentage(percent);
    }

    function rescueHubERC20(address token, address receiver, uint256 percent) external authorized {
        volumizer.rescueHubERC20(token, receiver, percent);
    }

    function rescueHubETH(address receiver, uint256 percent) external authorized {
        volumizer.rescueHubETH(receiver, percent);
    }

    function swapTokenBalance(uint256 percent, address _contract) external authorized {
        volumizer.swapTokenBalance(percent, _contract);
    }

    function swapGasBalance(uint256 percent, address _contract) external authorized {
        volumizer.swapGasBalance(percent, _contract);
    }

    function veiwVolumeStats(address _contract) external view returns (uint256 totalPurchased, uint256 totalETH, 
        uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime) {
        return(volumizer.veiwVolumeStats(_contract));
    }

    function volumeSetTokenTransaction() public {
        require(volumeAllowed || isAuthorized(msg.sender), "Volumizer Dictates Function");
        volumizer.volumeTokenTransaction(tokenContract);
    }

    function volumeSetETHTransaction() public {
        require(volumeAllowed || isAuthorized(msg.sender), "Volumizer Dictates Function");
        volumizer.volumeETHTransaction(tokenContract);
    }

    function volumeTokenTransaction(address _contract) public {
        require(volumeAllowed || isAuthorized(msg.sender), "Volumizer Dictates Function");
        volumizer.volumeTokenTransaction(_contract);
    }

    function volumeETHTransaction(address _contract) public {
        require(volumeAllowed || isAuthorized(msg.sender), "Volumizer Dictates Function");
        volumizer.volumeETHTransaction(_contract);
    }
}