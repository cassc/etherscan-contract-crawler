// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./Staking20Plus20Into1155.sol";
import "./Staking20Plus1155Into1155.sol";

contract FactoryStakingInto1155 {

    IAccessControl public immutable FACTORY;

    modifier onlyAdmin() {
        require(FACTORY.hasRole(0x0, msg.sender));
        _;
    }

    event NewContract(address indexed instance, uint8 instanceType);

    constructor(IAccessControl _factory) {
        FACTORY = _factory;
    }

    function createStaking20Plus20Into1155(IERC20[2] memory _stakeToken, uint256[2] memory _stakeTokenAmount, IERC1155 _rewardToken, uint256 _rewardTokenID, uint256 _rewardTokenAmount, uint256 _startTime, uint256[2] memory _duration) external onlyAdmin {
        Staking20Plus20Into1155 instance = new Staking20Plus20Into1155(_stakeToken, _stakeTokenAmount, _rewardToken, _rewardTokenID, _startTime, _duration);
        instance.setCreator(msg.sender);
        _rewardToken.safeTransferFrom(msg.sender, address(instance), _rewardTokenID, _rewardTokenAmount, "");
        emit NewContract(address(instance), 0);
    }

    function createStaking20Plus1155Into1155(IERC20 _stakeTokenERC20, uint256 _stakeTokenAmount, IERC1155 _stakeTokenERC1155, uint256 _stakeTokenID, IERC1155 _rewardToken, uint256 _rewardTokenID, uint256 _rewardTokenAmount, uint256 _startTime, uint256[2] memory _duration) external onlyAdmin {
        Staking20Plus1155Into1155 instance = new Staking20Plus1155Into1155(_stakeTokenERC20, _stakeTokenAmount, _stakeTokenERC1155, _stakeTokenID, _rewardToken, _rewardTokenID, _startTime, _duration);
        instance.setCreator(msg.sender);
        _rewardToken.safeTransferFrom(msg.sender, address(instance), _rewardTokenID, _rewardTokenAmount, "");
        emit NewContract(address(instance), 1);
    }
}