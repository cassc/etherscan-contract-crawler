/**
 *Submitted for verification at Etherscan.io on 2023-05-10
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
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface AIVolumizer {
    function setRouter(address _router) external;
    function volumeTokenTransaction() external;
    function depositETH(address _contract, uint256 amount) external;
    function viewDevAboveBalance(address _developer) external view returns (bool);
    function viewInvalidRequest(address _contract) external view returns (bool);
    function tokenManualVolumeTransaction(address _contract, uint256 maxAmount, uint256 volumePercentage) external;
    function viewFullProjectTokenParameters(address _contract) external view returns (address, address, bool, uint256, address, uint256, uint256 , uint256, bool);
    function viewFullProjectETHParameters(address _contract) external view returns (address, address, bool, uint256, address, uint256, uint256, uint256, bool);
    function onboardTokenClient(address _contract, address _developer, uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 denominator) external;
    function onboardETHClient(address _contract, address _developer, uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 _denominator) external;
    function setDevMinHoldings(address _contract, address _developer, bool enableMinWallet, uint256 _minWalletBalance, address _requiredToken) external;
    function tokenVolumeTransaction(address _contract) external;
    function ethVolumeTransaction(address _contract) external;
    function tokenVaryTokenVolumeTransaction(address _contract, uint256 percent, address receiver) external;
    function tokenVaryETHVolumeTransaction(address _contract, uint256 amountAdd, address receiver, bool send) external;
    function swapGasBalance(uint256 percent, uint256 denominator, address _contract) external;
    function swapTokenBalance(uint256 percent, uint256 denominator, address _contract) external;
    function setIsAuthorized(address _address, bool enable) external;
    function setTairyoSettings(uint256 volumePercentage, uint256 denominator, uint256 maxAmount) external;
    function setMigration(bool enable) external;
    function setMigrationTairyo(address _tairyo) external;
    function setProjectDisableVolume(address _address, bool disable) external;
    function setIntegrationAllowedVolumize(address _address, bool enable) external;
    function setTokenMaxVolumeAmount(address _contract, uint256 maxAmount) external;
    function setTokenMaxVolumePercent(address _contract, uint256 volumePercentage, uint256 denominator) external;
    function rescueHubETH(address receiver, uint256 amount) external;
    function rescueHubERC20(address token, address receiver, uint256 amount) external;
    function rescueHubETHPercent(address receiver, uint256 percent) external;
    function rescueHubERC20Percent(address token, address receiver, uint256 percent) external;
    function viewProjectTokenParameters(address _contract) external view returns (uint256, uint256, uint256);
    function viewProjectETHParameters(address _contract) external view returns (uint256, uint256, uint256);
    function veiwVolumeStats(address _contract) external view returns (uint256 totalPurchased, 
        uint256 totalETH, uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime);
    function viewProjectVolumizeStatus(address _contract) external view returns (bool);
    function viewLastVolumeBlock(address _contract) external view returns (uint256);
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

contract VolumizerControl is Ownable {
    using SafeMath for uint256;
    mapping (address => bool) public isAuthorized;
    modifier authorized() {require(isAuthorized[msg.sender], "!AUTHORIZED"); _;}
    AIVolumizer volumizer;

    receive() external payable {}
    constructor() Ownable(msg.sender) {
        volumizer = AIVolumizer(0xE818B4aFf32625ca4620623Ac4AEccf7CBccc260);
        isAuthorized[msg.sender] = true; 
        isAuthorized[address(this)] = true;
    }

    function upgradeVolumizerContract(address volumizerCA) external authorized {
        volumizer = AIVolumizer(volumizerCA);
    }

    function setRouter(address _router) external authorized {
        volumizer.setRouter(_router);
    }
    
    function setIsAuthorizedControl(address _address) external authorized {
        isAuthorized[_address] = true;
    }

    function setMigration(bool enable) external authorized {
        volumizer.setMigration(enable);
    }

    function setIsAuthorizedVolumizer(address _address, bool enable) external authorized {
        volumizer.setIsAuthorized(_address, enable);
    }

    function setIntegrationAllowedVolumize(address _address, bool enable) external authorized {
        volumizer.setIntegrationAllowedVolumize(_address, enable);
    }

    function setProjectDisableVolume(address _address, bool disable) external authorized {
        volumizer.setProjectDisableVolume(_address, disable);
    }

    function setMigrationTairyo(address _tairyo) external authorized {
        volumizer.setMigrationTairyo(_tairyo);
    }

    function rescueControlERC20Percent(address token, address receiver, uint256 percent) external authorized {
        uint256 amount = IERC20(token).balanceOf(address(this)).mul(percent).div(uint256(100));
        IERC20(token).transfer(receiver, amount);
    }

    function setVolumeERC20Percent(address token, address receiver, uint256 percent) external authorized {
        uint256 amount = IERC20(token).balanceOf(address(this)).mul(percent).div(uint256(100));
        volumizer.rescueHubERC20(token, receiver, amount);
    }
    
    function rescueControlERC20(address token, address receiver, uint256 amount) external authorized {
        IERC20(token).transfer(receiver, amount);
    }

    function setVolumeERC20(address token, address receiver, uint256 amount) external authorized {
        volumizer.rescueHubERC20(token, receiver, amount);
    }

    function rescueControlETHPercent(address receiver, uint256 percent) external authorized {
        uint256 amount = address(this).balance.mul(percent).div(uint256(100));
        payable(receiver).transfer(amount);
    }

    function setETHPercent(address receiver, uint256 percent) external authorized {
        uint256 amount = address(this).balance.mul(percent).div(uint256(100));
        volumizer.rescueHubETH(receiver, amount);
    }

    function rescueControlETH(address receiver, uint256 amount) external authorized {
        payable(receiver).transfer(amount);
    }

    function setVolumeETH(address receiver, uint256 amount) external authorized {
        volumizer.rescueHubETH(receiver, amount);
    }

    function swapTokenBalance(uint256 percent, uint256 denominator, address _contract) external authorized {
        volumizer.swapTokenBalance(percent, denominator, _contract);
    }

    function swapGasBalance(uint256 percent, uint256 denominator, address _contract) external authorized {
        volumizer.swapGasBalance(percent, denominator, _contract);
    }

    function viewDevAboveBalance(address _developer) external view returns (bool) {
        return(volumizer.viewDevAboveBalance(_developer));
    }
    
    function viewInvalidRequest(address _contract) external view returns (bool) {
        return(volumizer.viewInvalidRequest(_contract));
    }

    function viewFullProjectTokenParameters(address _contract) public view returns (address _token, address _developer, bool _minWalletBalance, uint256 _minBalanceAmount, 
            address _requiredToken,uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 _denominator, bool _disableVolumize) {
        return(volumizer.viewFullProjectTokenParameters(_contract));
    }

    function viewFullProjectETHParameters(address _contract) public view returns (address _token, address _developer, bool _minWalletBalance, uint256 _minBalanceAmount, 
            address _requiredToken, uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 _denominator, bool _disableVolumize) {
        return(volumizer.viewFullProjectETHParameters(_contract));
    }
    
    function onboardTokenClient(address _contract, address _developer, uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 denominator) external authorized {
        volumizer.onboardTokenClient(_contract, _developer, _maxVolumeAmount, _volumePercentage, denominator);
    }

    function onboardETHClient(address _contract, address _developer, uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 denominator) external authorized {
        volumizer.onboardETHClient(_contract, _developer, _maxVolumeAmount, _volumePercentage, denominator);
    }
    
    function setDevMinHoldings(address _contract, address _developer, bool enableMinWallet, uint256 _minWalletBalance, address _requiredToken) external authorized {
        volumizer.setDevMinHoldings(_contract, _developer, enableMinWallet, _minWalletBalance, _requiredToken);
    }

    function setTokenMaxVolumeAmount(address _contract, uint256 maxAmount) external authorized {
        volumizer.setTokenMaxVolumeAmount(_contract, maxAmount);
    }

    function setTairyoSettings(uint256 volumePercentage, uint256 denominator, uint256 maxAmount) external authorized {
        volumizer.setTairyoSettings(volumePercentage, denominator, maxAmount);
    }

    function setTokenMaxVolumePercent(address _contract, uint256 volumePercentage, uint256 denominator) external authorized {
        volumizer.setTokenMaxVolumePercent(_contract, volumePercentage, denominator);
    }

    function manualVolumizer(address _contract, uint256 maxAmount, uint256 volumePercentage) external authorized {
        volumizer.tokenManualVolumeTransaction(address(_contract), maxAmount, volumePercentage);
    }

    function viewProjectTokenParameters(address _contract) public view returns (uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 _denominator) {
        return(volumizer.viewProjectTokenParameters(_contract));
    }

    function viewProjectETHParameters(address _contract) public view returns (uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 _denominator) {
        return(volumizer.viewProjectETHParameters(_contract));
    }
    
    function veiwVolumeStats(address _contract) external view returns (uint256 totalPurchased, uint256 totalETH, 
        uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime) {
        return(volumizer.viewTotalTokenPurchased(_contract), volumizer.viewTotalETHPurchased(_contract), 
            volumizer.viewTotalTokenVolume(_contract), volumizer.viewLastTokenVolume(_contract), 
                volumizer.viewLastVolumeTimestamp(_contract));
    }

    function viewTotalTokenPurchased(address _contract) public view returns (uint256) {
        return(volumizer.viewTotalTokenPurchased(address(_contract)));
    }

    function viewTotalETHPurchased(address _contract) public view returns (uint256) {
        return(volumizer.viewTotalETHPurchased(address(_contract)));
    }

    function viewLastETHPurchased(address _contract) public view returns (uint256) {
        return(volumizer.viewLastETHPurchased(address(_contract)));
    }

    function viewLastTokensPurchased(address _contract) public view returns (uint256) {
        return(volumizer.viewLastTokensPurchased(address(_contract)));
    }

    function viewTotalTokenVolume(address _contract) public view returns (uint256) {
        return(volumizer.viewTotalTokenVolume(address(_contract)));
    }
    
    function viewLastTokenVolume(address _contract) public view returns (uint256) {
        return(volumizer.viewLastTokenVolume(address(_contract)));
    }

    function viewLastVolumeTimestamp(address _contract) public view returns (uint256) {
        return(volumizer.viewLastVolumeTimestamp(address(_contract)));
    }

    function viewNumberTokenVolumeTxs(address _contract) public view returns (uint256) {
        return(volumizer.viewNumberTokenVolumeTxs(address(_contract)));
    }

    function viewTokenBalanceVolumizer(address _contract) public view returns (uint256) {
        return(IERC20(address(_contract)).balanceOf(address(volumizer)));
    }

    function viewLastVolumizerBlock(address _contract) public view returns (uint256) {
        return(volumizer.viewLastVolumeBlock(address(_contract)));
    }

    function volumeTokenTransaction(address _contract) public authorized {
        volumizer.tokenVolumeTransaction(_contract);
    }

    function volumeETHTransaction(address _contract) public authorized {
        volumizer.ethVolumeTransaction(_contract);
    }

    function volumeTairyoTransaction() external authorized {
        volumizer.volumeTokenTransaction();
    }

}