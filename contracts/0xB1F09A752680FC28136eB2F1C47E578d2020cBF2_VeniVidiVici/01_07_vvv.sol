// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VeniVidiVici is ERC20, Ownable {
    using SafeMath for uint256;

    address public devTeam;
    address public marketingAddress;
    uint256 public constant MAX_SUPPLY = 500000000000000 * 10**18;
    uint256 private constant DEV_FEE_PERCENTAGE = 2;
    uint256 private constant MARKETING_FEE_PERCENTAGE = 1;
    uint256 private totalDevFeeEarned;
    uint256 private totalMarketingFeeEarned;
    uint256 private totalDevFeeClaimed;
    uint256 private totalMarketingFeeClaimed;
    bool public isOwnershipRenounced;

    event Burn(address indexed burner, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    event DevTeamAddressUpdated(address indexed previousDevTeam, address indexed newDevTeam);
    event MarketingAddressUpdated(address indexed previousMarketingAddress, address indexed newMarketingAddress);

    constructor(address _devTeam, address _marketingAddress) ERC20("VeniVidiVici", "VVV") {
        devTeam = _devTeam;
        marketingAddress = _marketingAddress;
        _mint(address(this), MAX_SUPPLY);
        _transfer(address(this), msg.sender, MAX_SUPPLY);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 devFeeAmount = amount.mul(DEV_FEE_PERCENTAGE).div(100);
        uint256 marketingFeeAmount = amount.mul(MARKETING_FEE_PERCENTAGE).div(100);
        uint256 transferAmount = amount.sub(devFeeAmount).sub(marketingFeeAmount);

        _transfer(_msgSender(), recipient, transferAmount);
        if (devFeeAmount > 0) {
            totalDevFeeEarned = totalDevFeeEarned.add(devFeeAmount);
            _transfer(_msgSender(), devTeam, devFeeAmount);
        }
        if (marketingFeeAmount > 0) {
            totalMarketingFeeEarned = totalMarketingFeeEarned.add(marketingFeeAmount);
            _transfer(_msgSender(), marketingAddress, marketingFeeAmount);
        }

        return true;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    function renounceOwnership() public override onlyOwner {
        isOwnershipRenounced = true;
        emit OwnershipRenounced(owner());
        super.renounceOwnership();
    }

    function updateDevTeamAddress(address newDevTeam) public onlyOwner {
        require(newDevTeam != address(0), "Invalid address");
        emit DevTeamAddressUpdated(devTeam, newDevTeam);
        devTeam = newDevTeam;
    }

    function updateMarketingAddress(address newMarketingAddress) public onlyOwner {
        require(newMarketingAddress != address(0), "Invalid address");
        emit MarketingAddressUpdated(marketingAddress, newMarketingAddress);
        marketingAddress = newMarketingAddress;
    }

    function getTotalDevFeeEarned() public view returns (uint256) {
        require(msg.sender == devTeam, "Unauthorized");
        return totalDevFeeEarned;
    }

    function getTotalMarketingFeeEarned() public view returns (uint256) {
        require(msg.sender == marketingAddress, "Unauthorized");
        return totalMarketingFeeEarned;
    }

    function getTotalDevFeeClaimed() public view returns (uint256) {
        require(msg.sender == devTeam, "Unauthorized");
        return totalDevFeeClaimed;
    }

    function getTotalMarketingFeeClaimed() public view returns (uint256) {
        require(msg.sender == marketingAddress, "Unauthorized");
        return totalMarketingFeeClaimed;
    }

    function claimDevFee(uint256 amount) public {
        require(msg.sender == devTeam, "Unauthorized");
        require(amount <= totalDevFeeEarned.sub(totalDevFeeClaimed), "Insufficient available dev fee");
        totalDevFeeClaimed = totalDevFeeClaimed.add(amount);
        _transfer(devTeam, address(0), amount);
    }

    function claimMarketingFee(uint256 amount) public {
        require(msg.sender == marketingAddress, "Unauthorized");
        require(amount <= totalMarketingFeeEarned.sub(totalMarketingFeeClaimed), "Insufficient available marketing fee");
        totalMarketingFeeClaimed = totalMarketingFeeClaimed.add(amount);
        _transfer(marketingAddress, address(0), amount);
    }
}