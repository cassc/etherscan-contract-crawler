// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BONETax is Initializable {
    BNBOneInterface public stakingInfo;

    uint256 public tax;
    uint256 public divider;
    mapping(address => uint256) public coveredAmount;

    address public taxTo;
    address public taxTo2;

    address public owner;

    function initialize(
        address _stakingInfo,
        address _taxTo,
        address _taxTo2
    ) external initializer {
        owner = msg.sender;

        stakingInfo = BNBOneInterface(_stakingInfo);
        taxTo = _taxTo;
        taxTo2 = _taxTo2;

        tax = 10;
        divider = 100;
    }

    function payTax() public payable {
        uint256 amount = msg.value;
        (, , uint112 totalClaimed, , ) = stakingInfo.stakeInfo(msg.sender);

        transfer(taxTo, amount / 2);
        transfer(taxTo2, amount / 2);

        if (coveredAmount[msg.sender] == 0) {
            coveredAmount[msg.sender] =
                totalClaimed +
                ((amount * divider) / tax);
        } else {
            coveredAmount[msg.sender] += ((amount * divider) / tax);
        }
    }

    function changeTaxto(uint256 index, address n) public {
        require(msg.sender == owner);
        if (index == 0) {
            taxTo = n;
        } else {
            taxTo2 = n;
        }
    }

    function transfer(address addr, uint256 value) internal {
        payable(addr).transfer(value);
    }
}

interface BNBOneInterface {
    function stakeInfo(
        address
    )
        external
        view
        returns (
            uint112 totalReturn,
            uint112 activeStakes,
            uint112 totalClaimed,
            uint256 claimable,
            uint112 cps
        );
}

interface token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}