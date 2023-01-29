// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MultiSend is  UUPSUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public percent;
    address public bank;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        percent = 10;
        // 0.1%
        bank = 0x3Ff0Dc6514d719152692188bD6F0771ADe370852;
    }

    function changePercentage(uint256 _percent) public onlyOwner {
        percent = _percent;
    }

    function changeBankAddress(address _bank) public onlyOwner {
        bank = _bank;
    }

    function multiSendDiffEth(
        address payable[] memory recipients,
        uint256[] memory amounts
    ) public payable {
        require(recipients.length > 0);
        require(recipients.length == amounts.length);

        uint256 currentSum = 0;
        uint256 taxes = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(amounts[i] > 0);
            currentSum = currentSum + amounts[i];
            require(currentSum <= msg.value);
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 FEE = amounts[i].mul(percent).div(10000);
            uint256 _amount = amounts[i].sub(FEE);
            taxes = taxes + FEE;
            recipients[i].transfer(_amount);
        }
        payable(bank).transfer(taxes);
    }

    function multiSendDiffToken(
        address[] memory recipients,
        uint256[] memory amounts,
        address token
    ) public {
        require(recipients.length > 0);
        require(recipients.length == amounts.length);

        uint256 currentSum = 0;
        uint256 taxes = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(amounts[i] > 0, "Value must be more than 0");
            currentSum = currentSum + amounts[i];
            require(
                currentSum <= ERC20(token).balanceOf(msg.sender),
                "Influence balance"
            );
            require(
                currentSum <= ERC20(token).allowance(msg.sender, address(this)),
                "Influence allowance"
            );
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 FEE = amounts[i].mul(percent).div(10000);
            uint256 _amount = amounts[i].sub(FEE);
            taxes = taxes + FEE;
            ERC20(token).transferFrom(msg.sender, recipients[i], _amount);
        }
        ERC20(token).transferFrom(msg.sender, bank, taxes);
    }
}