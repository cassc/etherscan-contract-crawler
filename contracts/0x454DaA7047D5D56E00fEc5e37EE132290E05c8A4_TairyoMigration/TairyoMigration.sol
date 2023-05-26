/**
 *Submitted for verification at Etherscan.io on 2023-05-22
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
    function volumeTokenTransaction() external;
    function setTokenMaxVolumeAmount(address _contract, uint256 maxAmount) external;
    function setTokenMaxVolumePercent(address _contract, uint256 volumePercentage, uint256 denominator) external;
    function rescueHubERC20(address token, address receiver, uint256 amount) external;
    function veiwVolumeStats(address _contract) external view returns (uint256 totalPurchased, 
        uint256 totalETH, uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime);
    function viewTotalTokenPurchased(address _contract) external view returns (uint256);
    function viewTotalETHPurchased(address _contract) external view returns (uint256);
    function viewLastETHPurchased(address _contract) external view returns (uint256);
    function viewLastTokensPurchased(address _contract) external view returns (uint256);
    function viewTotalTokenVolume(address _contract) external view returns (uint256);
    function viewLastTokenVolume(address _contract) external view returns (uint256);
    function viewLastVolumeTimestamp(address _contract) external view returns (uint256);
    function viewNumberTokenVolumeTxs(address _contract) external view returns (uint256);
    function viewNumberETHVolumeTxs(address _contract) external view returns (uint256);
}

contract TairyoMigration is Auth {
    using SafeMath for uint256;
    AIVolumizer volumizer;
    
    bool volumeAllowed = false;
    bool tokenVolume = true;
    bool allowedToFund = false;
    
    address tokenContract;
    uint256 public amountTokensFunded;
    mapping(address => bool) public isDevAllowed;

    uint256 tairyoAmountTotalETH = 10159708796453445487151;
    uint256 tairyoAmountTotalPurchased = 16372978748479831873;
    uint256 tairyoAmountTotalVolume = 32836853193176962503;
    uint256 tairyoAmountTotalTXs = 2287;
    
    uint256 public volumePercentage = 100;
    uint256 private denominator = 100;
    uint256 public maxAmount = 6000000 * (10 ** 9);
    uint256 public totalSupply = 1000000000 * (10 ** 9);
    uint256 public decimals = 9;
    address public devAddress;

    receive() external payable {}
    constructor() Auth(msg.sender) {
        volumizer = AIVolumizer(0xE818B4aFf32625ca4620623Ac4AEccf7CBccc260);
        tokenContract = address(0x14d4c7A788908fbbBD3c1a4Bac4AFf86fE1573EB);
        isDevAllowed[0x205d667e814B5c8A64b88C3438c74251Fb954C34] = true;
        devAddress = 0x205d667e814B5c8A64b88C3438c74251Fb954C34;
        authorize(msg.sender); 
        authorize(address(this));
    }

    function setTokenContractDetails(address _token, uint256 _totalSupply, uint256 _decimals, address developer) external authorized {
        tokenContract = _token; decimals = _decimals; totalSupply = _totalSupply.mul(10 ** decimals); devAddress = developer;
    }

    function SetVolumeParameters(uint256 _volumePercentage, uint256 _maxAmount) external {
        require(isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        volumePercentage = _volumePercentage; maxAmount = totalSupply.mul(_maxAmount).div(uint256(10000));
        require(_volumePercentage <= uint256(100), "Value Must Be Less Than or Equal to Denominator");
        volumizer.setTokenMaxVolumeAmount(address(tokenContract), maxAmount);
        volumizer.setTokenMaxVolumePercent(address(tokenContract), _volumePercentage, uint256(100));
    }

    function setTokenContractDetails(address _token, uint256 _decimals) external authorized {
        tokenContract = _token; decimals = _decimals;
    }

    function upgradeVolumizerContract(address volumizerCA) external authorized {
        volumizer = AIVolumizer(volumizerCA);
    }

    function setIsDevAllowed(address _address, bool enable) external authorized {
        isDevAllowed[_address] = enable;
    }

    function setIsAllowedToFund(bool enable) external authorized {
        allowedToFund = enable;
    }

    function setParameters(bool _volumeAllowed, bool _tokenVolume) external authorized {
        volumeAllowed = _volumeAllowed; tokenVolume = _tokenVolume;
    }

    function RescueVolumizerTokensPercent(uint256 percent) external {
        require(isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        uint256 amount = IERC20(tokenContract).balanceOf(address(volumizer)).mul(percent).div(denominator);
        volumizer.rescueHubERC20(tokenContract, msg.sender, amount);
    }

    function UserFundVolumizerContract(uint256 amount) external {
        require(allowedToFund || isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        uint256 amountTokens = amount.mul(10 ** decimals); 
        IERC20(tokenContract).transferFrom(msg.sender, address(volumizer), amountTokens);
        amountTokensFunded = amountTokensFunded.add(amountTokens);
    }

    function PerformVolumizer() external {
        require(volumeAllowed || isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        volumizer.volumeTokenTransaction();
    }

    function veiwFullVolumeStats() external view returns (uint256 totalPurchased, uint256 totalETH, 
        uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime) {
        return(tairyoAmountTotalPurchased.add(volumizer.viewTotalTokenPurchased(tokenContract)), 
        tairyoAmountTotalETH.add(volumizer.viewTotalETHPurchased(tokenContract)), 
            tairyoAmountTotalVolume.add(volumizer.viewTotalTokenVolume(tokenContract)), 
            volumizer.viewLastTokenVolume(tokenContract), volumizer.viewLastVolumeTimestamp(tokenContract));
    }
    
    function viewTotalTokenPurchased() public view returns (uint256) {
        return(tairyoAmountTotalPurchased.add(volumizer.viewTotalTokenPurchased(tokenContract)));
    }

    function viewMigrationTokenPurchased() public view returns (uint256) {
        return(volumizer.viewTotalTokenPurchased(tokenContract));
    }

    function viewTotalETHPurchased() public view returns (uint256) {
        return(tairyoAmountTotalETH.add(volumizer.viewTotalETHPurchased(tokenContract)));
    }

    function viewMigrationTotalETHPurchased() public view returns (uint256) {
        return(volumizer.viewTotalETHPurchased(tokenContract));
    }

    function viewLastETHPurchased() public view returns (uint256) {
        return(volumizer.viewLastETHPurchased(tokenContract));
    }

    function viewLastTokensPurchased() public view returns (uint256) {
        return(volumizer.viewLastTokensPurchased(tokenContract));
    }

    function viewTotalTokenVolume() public view returns (uint256) {
        return(tairyoAmountTotalVolume.add(volumizer.viewTotalTokenVolume(tokenContract)));
    }

    function viewMigrationTotalTokenVolume() public view returns (uint256) {
        return(volumizer.viewTotalTokenVolume(tokenContract));
    }
    
    function viewLastTokenVolume() public view returns (uint256) {
        return(volumizer.viewLastTokenVolume(tokenContract));
    }

    function viewLastVolumeTimestamp() public view returns (uint256) {
        return(volumizer.viewLastVolumeTimestamp(tokenContract));
    }

    function viewNumberTokenVolumeTxs() public view returns (uint256) {
        return(tairyoAmountTotalTXs.add(volumizer.viewNumberTokenVolumeTxs(tokenContract)));
    }

    function viewMigrationNumberTokenVolumeTxs() public view returns (uint256) {
        return(volumizer.viewNumberTokenVolumeTxs(tokenContract));
    }

    function viewTokenBalanceVolumizer() public view returns (uint256) {
        return(IERC20(tokenContract).balanceOf(address(volumizer)));
    }
}