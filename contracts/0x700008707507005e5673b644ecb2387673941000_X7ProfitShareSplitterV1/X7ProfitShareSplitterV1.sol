/**
 *Submitted for verification at Etherscan.io on 2023-08-28
*/

/**
 *Submitted for verification at Etherscan.io on 2023-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract representing a profit sharing agreement

This contract will NOT be renounced.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IWETH {
    function withdraw(uint) external;
}

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract X7ProfitShareSplitterV1 is Ownable {

    uint256 public reservedETH;
    uint256 public totalShares = 0;

    uint256[] public outletShares;
    mapping(uint256 => uint256) public outletBalance;
    mapping(uint256=> address) public outletRecipient;
    mapping(address => uint256) public outletLookup;
    mapping(uint256 => mapping(address => bool)) public outletController;
    mapping(uint256 => bool) public outletFrozen;

    address public WETH;
    address public tokenReceiver;
    bool public initialized = false;

    event TokenReceiverSet(address indexed oldReceiver, address indexed newReceiver);
    event OutletControllerAuthorizationSet(uint256 indexed outlet, address indexed setter, address indexed controller, bool authorization);
    event OutletRecipientSet(uint256 indexed outlet, address indexed oldRecipient, address indexed newRecipient);
    event OutletSharesSet(uint256 indexed outlet, uint256 oldShares, uint256 newShares);
    event OutletFrozen(uint256 indexed outlet);
    event NewRecipientAdded(uint256 indexed outlet, address indexed recipient, address indexed controller, uint256 shares);
    event TotalSharesChanged(uint256 oldShareCount, uint256 newShareCount);

    constructor (address weth, address tokenReceiver_) Ownable(msg.sender) {
        // index 0 is skipped
        outletShares.push(0);
        WETH = weth;
        tokenReceiver = tokenReceiver_;
    }

    receive () external payable {}

    function setInitialized() external onlyOwner {
        require(!initialized);
        initialized = true;
    }

    function setTokenReceiver(address receiver) external onlyOwner {
        address oldReceiver = tokenReceiver;
        tokenReceiver = receiver;

        emit TokenReceiverSet(oldReceiver, receiver);
    }

    function addNewRecipient(address newRecipient, address controller, uint256 shares) external onlyOwner {
        // A new recipient can only be added after the current state has been resolved
        divvyUp();

        // No duplicate recipients allowed
        require(outletLookup[newRecipient] == 0);

        // All new recipients must have shares
        require(shares > 0);

        outletShares.push(shares);

        uint256 outlet = outletShares.length-1;

        outletRecipient[outlet] = newRecipient;
        outletLookup[newRecipient] = outlet;

        outletController[outlet][owner()] = true;

        // New recipient is advised to remove the above entry as a signal
        // of positive control of their controller address
        outletController[outlet][controller] = true;
        totalShares += shares;

        emit NewRecipientAdded(outlet, newRecipient, controller, shares);
        emit TotalSharesChanged(totalShares - shares, totalShares);
    }

    function setOutletShares(uint256 outlet, uint256 newShares) external onlyOwner {
        // Shares can only be reset if the current state has been resolved
        divvyUp();

        require(outlet != 0 && outlet < outletShares.length);
        uint256 currentShares = outletShares[outlet];
        uint originalTotalShares = totalShares;

        if (newShares > currentShares) {
            outletShares[outlet] = newShares;
            totalShares += (newShares - currentShares);
        } else if (newShares < currentShares) {
            outletShares[outlet] = newShares;
            totalShares -= (currentShares - newShares);
        }

        if (originalTotalShares != totalShares) {
            emit TotalSharesChanged(originalTotalShares, totalShares);
        }

        if (newShares != currentShares) {
            emit OutletSharesSet(outlet, currentShares, newShares);
        }
    }

    function divvyUp() public {
        if (!initialized) {
            return;
        }

        uint256 newETH = address(this).balance - reservedETH;
        uint256 spentETH = 0;

        if (newETH > 0) {
            for (uint256 i = 1; i < outletShares.length - 1; i++) {
                uint256 addBalance = newETH * outletShares[i] / totalShares;
                spentETH += addBalance;
                outletBalance[i] += addBalance;
            }

            outletBalance[outletShares.length-1] += (newETH - spentETH);
            reservedETH = address(this).balance;
        }
    }

    function setOutletControllerAuthorization(uint256 outlet, address controller, bool authorization) external {
        require(!outletFrozen[outlet]);
        require(outletController[outlet][msg.sender]);
        outletController[outlet][controller] = authorization;
        emit OutletControllerAuthorizationSet(outlet, msg.sender, controller, authorization);
    }

    function setOutletRecipient(uint256 outlet, address recipient) external {
        require(!outletFrozen[outlet]);
        require(outletRecipient[outlet] != recipient);
        require(outletController[outlet][msg.sender]);
        require(outletLookup[recipient] == 0);

        address oldRecipient = outletRecipient[outlet];

        outletLookup[recipient] = outlet;
        outletLookup[oldRecipient] = 0;
        outletRecipient[outlet] = recipient;

        emit OutletRecipientSet(outlet, oldRecipient, recipient);
    }

    function freezeOutlet(uint256 outlet) external {
        require(outletController[outlet][msg.sender]);
        outletFrozen[outlet] = true;
        emit OutletFrozen(outlet);
    }

    function takeBalance() external {
        uint256 outlet = outletLookup[msg.sender];
        require(outlet != 0);
        divvyUp();
        _sendBalance(outlet);
    }

    function takeCurrentBalance() external {
        uint256 outlet = outletLookup[msg.sender];
        require(outlet != 0);
        _sendBalance(outlet);
    }

    function pushAll() public {
        divvyUp();
        for (uint256 i = 1; i < outletShares.length; i++) {
            _sendBalance(i);
        }
    }

    function rescueWETH() public {
        IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        pushAll();
    }

    function rescueTokens(address tokenAddress) external {
        if (tokenAddress == WETH) {
            rescueWETH();
        } else {
            IERC20(tokenAddress).transfer(tokenReceiver, IERC20(tokenAddress).balanceOf(address(this)));
        }
    }

    function _sendBalance(uint256 outlet) internal {
        bool success;
        address recipient = outletRecipient[outlet];

        if (recipient == address(0)) {
            return;
        }

        uint256 ethToSend = outletBalance[outlet];

        if (ethToSend > 0) {
            outletBalance[outlet] = 0;
            reservedETH -= ethToSend;

            (success,) = recipient.call{value: ethToSend}("");
            if (!success) {
                outletBalance[outlet] += ethToSend;
                reservedETH += ethToSend;
            }
        }
    }
}