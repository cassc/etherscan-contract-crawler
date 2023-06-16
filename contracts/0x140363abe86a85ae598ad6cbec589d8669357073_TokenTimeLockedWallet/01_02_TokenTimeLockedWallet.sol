// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenTimeLockedWallet {
    struct LockLevel {
        uint256 unlockTime;
        uint256 amount;
        bool isWithdraw;
    }

    address public creator;
    address public owner; //beneficiary
    uint256 public createdAt;

    LockLevel[] internal locks;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Caller is not creator");
        _;
    }

    constructor(
        address _creator,
        address _owner,
        uint256[] memory _lockTimeFrames,
        uint256[] memory _lockAmounts
    ) {
        // verify unlock time
        require(_lockTimeFrames.length > 0, "Invalid lock periods");
        require(
            _lockTimeFrames.length == _lockAmounts.length,
            "Unlock period and amount defined is not the same"
        );

        creator = _creator;
        owner = _owner;
        createdAt = block.timestamp;

        for (uint256 idx = 0; idx < _lockTimeFrames.length; idx++)
            locks.push(
                LockLevel(_lockTimeFrames[idx], _lockAmounts[idx], false)
            );
    }

    function addNewLock(uint256 _lockTimeFrame, uint256 _unlockAmount)
        public
        onlyCreator
        returns (bool)
    {
        locks.push(LockLevel(_lockTimeFrame, _unlockAmount, false));

        return true;
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract)
        public
        onlyOwner
        returns (bool)
    {
        require(_tokenContract != address(0), "Invalid token contract");

        // calculate amount token can withdraw
        IERC20 token = IERC20(_tokenContract);
        uint256 currentTime = block.timestamp;
        for (uint256 idx; idx < locks.length; idx++) {
            if (
                locks[idx].unlockTime <= currentTime && !locks[idx].isWithdraw
            ) {
                //now send all the token balance
                uint256 tokenBalance = token.balanceOf(address(this));
                uint256 desiredAmount = locks[idx].amount;
                uint256 withdrawToken = desiredAmount > tokenBalance
                    ? tokenBalance
                    : desiredAmount;

                if (withdrawToken != 0) {
                    locks[idx].isWithdraw = true;
                    token.transfer(owner, withdrawToken);
                    emit WithdrewTokens(
                        _tokenContract,
                        msg.sender,
                        withdrawToken
                    );
                }
            }
        }

        return true;
    }

    function info()
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        uint256 len = locks.length;
        uint256[] memory unlockTimeFrames = new uint256[](len);
        uint256[] memory unLockAmounts = new uint256[](len);
        bool[] memory isWithdraw = new bool[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            unlockTimeFrames[idx] = locks[idx].unlockTime;
            unLockAmounts[idx] = locks[idx].amount;
            isWithdraw[idx] = locks[idx].isWithdraw;
        }

        return (
            creator,
            owner,
            createdAt,
            unlockTimeFrames,
            unLockAmounts,
            isWithdraw
        );
    }

    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}