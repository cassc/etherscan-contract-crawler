//SPDX-License-Identifier: Unlicense

/**
* $XPRO Faucet
* Charity Wallet Address : 0x1B8dfe4Dc5759A7B7b07EbE224C54971Dbb3F349
* Developed By           : t.me/XProDevJ for $XPRO Community
* Official Group         : https://t.me/xprojectofficial
* Official Website       : https://xpro.community
*/

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

pragma solidity 0.6.2;

contract ReentrancyGuard {
    uint256 private _checkCounter = 1;
    modifier nonReentrant() {
        _checkCounter += 1;
        uint256 localCounter = _checkCounter;
        _;
        require(localCounter == _checkCounter);
    }
}

pragma solidity 0.6.2;

contract XPROFaucet is Ownable {
    uint256  public minAmount = 2500000000 * 10**9;
    uint256  public maxAmount = 25000000000 * 10**9;
    uint256  public waitTime = 1440 minutes;
    bool public isPaused = false;

    using SafeBEP20 for IBEP20;
    IBEP20 public tokenInstance;

    mapping(address => uint256) lastClaimTime;

    constructor(address _tokenInstance) public {
        require(_tokenInstance != address(0));
        tokenInstance = IBEP20(_tokenInstance);
    }

    modifier notPaused() {
        require(!isPaused);
        _;
    }

    function withdraw(uint256 _tokenAmount) public onlyOwner {
        tokenInstance.safeTransfer(address(msg.sender), _tokenAmount);
    }

    function updateFaucet(uint256 _minAmount, uint256 _maxAmount, uint256 _waitTime) public onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        waitTime = _waitTime;
    }

    function setPause(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }

    function claimFaucetRewards() external {
        require(allowedToWithdraw(msg.sender), 'You already claimed!');
        uint amount = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % (maxAmount-minAmount);
        amount = amount + 1;
        tokenInstance.safeTransfer(address(msg.sender), amount);
        lastClaimTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if (lastClaimTime[_address] == 0) {
            return true;
        } else if (block.timestamp >= lastClaimTime[_address]) {
            return true;
        }
        return false;
    }
}