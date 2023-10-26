/**
 *Submitted for verification at Etherscan.io on 2023-09-09
*/

// File: contracts/StorageContract.sol



pragma solidity ^0.8.6;

contract StorageContract {
    address public nativeCryptoReceiver;
    address[] public owners;

    constructor(address defaultNativeCryptoReceiver, address firstOwner) {
        nativeCryptoReceiver = defaultNativeCryptoReceiver;
        owners.push(firstOwner);
    }

    modifier onlyOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Caller is not an owner");
        _;
    }

    function addOwner(address newOwner) public onlyOwner {
        owners.push(newOwner);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function removeOwner(address ownerToRemove) public onlyOwner {
        uint256 index = type(uint256).max;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                index = i;
                break;
            }
        }

        require(index != type(uint256).max, "Owner not found");
        require(owners.length > 1, "Cannot remove the last owner");

        owners[index] = owners[owners.length - 1];
        owners.pop();
    }

    function changeNativeCryptoReceiver(address newNativeCryptoReceiver)
        public
        onlyOwner
    {
        nativeCryptoReceiver = newNativeCryptoReceiver;
    }
}

// File: contracts/Receiver.sol


pragma solidity ^0.8.4;


contract Receiver {
    StorageContract storageContract;

    mapping(address => uint256) private balances;

    constructor(address storageContractAddress) {
        storageContract = StorageContract(storageContractAddress);
    }

    modifier onlyOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < storageContract.getOwners().length; i++) {
            if (msg.sender == storageContract.owners(i)) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Caller is not an owner");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function withdraw(uint256 amount, address recipient) public onlyOwner {
        require(
            amount <= address(this).balance,
            "Not enough balance in the contract"
        );

        (bool sent, ) = payable(recipient).call{value: amount}("");
        require(sent, "Fail");
    }

    function bulkWithdraw(uint256[] memory amounts, address[] memory recipients)
        public
        onlyOwner
    {
        require(
            amounts.length == recipients.length,
            "The amounts and recipients length mismatch"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = amounts[i];
            address recipient = recipients[i];

            require(
                amount <= address(this).balance,
                "Not enough balance in the contract"
            );

            (bool sent, ) = payable(recipient).call{value: amount}("");
            require(sent, "Fail");
        }
    }
}