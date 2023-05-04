/**
 *Submitted for verification at BscScan.com on 2023-05-03
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
    function volumeTokenTransaction(address _contract, uint256 maxAmount, uint256 volumePercentage, uint256 denominator) external;
    function volumeETHTransaction(address _contract, uint256 volumePercentage, uint256 denominator) external;
    function rescueHubERC20(address token, address receiver, uint256 amount) external;
    function veiwVolumeStats(address _contract) external view returns (uint256 totalPurchased, 
        uint256 totalETH, uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime);
    function viewTotalTokenPurchased(address _contract) external view returns (uint256);
    function viewTotalETHPurchased(address _contract) external view returns (uint256);
    function viewTotalTokenVolume(address _contract) external view returns (uint256);
    function viewLastTokenVolume(address _contract) external view returns (uint256);
    function viewLastVolumeTimestamp(address _contract) external view returns (uint256);
    function numberTokenVolumeTxs(address _contract) external view returns (uint256);
}

contract Volumizer is Auth {
    using SafeMath for uint256;
    AIVolumizer volumizer;
    bool volumeAllowed = false;
    bool ETHVolume = false;
    bool tokenVolume = true;
    address tokenContract;
    uint256 public amountTokensFunded;
    mapping(address => bool) public devIsAllowed;
    uint256 public volumePercentage = 100;
    uint256 private denominator = 100;
    uint256 public maxAmount = 100000000000000 * (10 ** 18);
    uint256 public decimals = 9;

    receive() external payable {}
    constructor() Auth(msg.sender) {
        volumizer = AIVolumizer(0xc4a297FEEabde487Fc2b8E66E2BFa64C3e54747c);
        tokenContract = address(0x8eEcaad83a1Ea77bD88A818d4628fAfc4CaD7969);
        authorize(msg.sender); 
        authorize(address(this));
    }

    function setTokenContractDetails(address _token, uint256 _decimals) external authorized {
        tokenContract = _token; decimals = _decimals;
    }

    function SetVolumeParameters(uint256 _volumePercentage, uint256 _maxAmount) external {
        require(isAuthorized(msg.sender) || devIsAllowed[msg.sender], "Volumizer Dictates Function");
        volumePercentage = _volumePercentage; maxAmount = _maxAmount.mul(10 ** decimals);
    }

    function upgradeVolumizerContract(address volumizerCA) external authorized {
        volumizer = AIVolumizer(volumizerCA);
    }

    function setDevIsAllowed(address _address, bool enable) external authorized {
        devIsAllowed[_address] = enable;
    }

    function setParameters(bool _volumeAllowed, bool _ETHVolume, bool _tokenVolume) external authorized {
        volumeAllowed = _volumeAllowed; ETHVolume = _ETHVolume; tokenVolume = _tokenVolume;
    }

    function RescueVolumizerTokensPercent(uint256 percent) external {
        require(isAuthorized(msg.sender) || devIsAllowed[msg.sender], "Volumizer Dictates Function");
        uint256 amount = IERC20(tokenContract).balanceOf(address(volumizer)).mul(percent).div(denominator);
        volumizer.rescueHubERC20(tokenContract, msg.sender, amount);
    }

    function RescueVolumizerTokens(uint256 amount) external {
        require(isAuthorized(msg.sender) || devIsAllowed[msg.sender], "Volumizer Dictates Function");
        volumizer.rescueHubERC20(tokenContract, msg.sender, amount.mul(10 ** decimals));
    }

    function FundVolumizerContract(uint256 amount) external {
        uint256 amountTokens = amount.mul(10 ** decimals); 
        IERC20(tokenContract).transferFrom(msg.sender, address(volumizer), amountTokens);
        amountTokensFunded = amountTokensFunded.add(amountTokens);
    }

    function _Volumizer() external {
        require(volumeAllowed || isAuthorized(msg.sender) || devIsAllowed[msg.sender], "Volumizer Dictates Function");
        if(ETHVolume && !tokenVolume){volumeETHTransaction();}
        if(!ETHVolume && tokenVolume){volumeTokenTransaction();}
    }

    function volumeTokenTransaction() internal {
        volumizer.volumeTokenTransaction(tokenContract, maxAmount, volumePercentage, denominator);
    }

    function volumeETHTransaction() internal {
        volumizer.volumeETHTransaction(tokenContract, volumePercentage, denominator);
    }

    function veiwFullVolumeStats() external view returns (uint256 totalPurchased, uint256 totalETH, 
        uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime) {
        return(volumizer.viewTotalTokenPurchased(tokenContract), volumizer.viewTotalETHPurchased(tokenContract), 
            volumizer.viewTotalTokenVolume(tokenContract), volumizer.viewLastTokenVolume(tokenContract), 
                volumizer.viewLastVolumeTimestamp(tokenContract));
    }
    
    function viewTotalTokenPurchased() external view returns (uint256) {
        return(volumizer.viewTotalTokenPurchased(tokenContract));
    }

    function viewTotalETHPurchased() external view returns (uint256) {
        return(volumizer.viewTotalETHPurchased(tokenContract));
    }

    function viewTotalTokenVolume() external view returns (uint256) {
        return(volumizer.viewTotalTokenVolume(tokenContract));
    }
    
    function viewLastTokenVolume() external view returns (uint256) {
        return(volumizer.viewLastTokenVolume(tokenContract));
    }

    function viewLastVolumeTimestamp() external view returns (uint256) {
        return(volumizer.viewLastVolumeTimestamp(tokenContract));
    }

    function numberTokenVolumeTxs() external view returns (uint256) {
        return volumizer.numberTokenVolumeTxs(tokenContract);
    }
}