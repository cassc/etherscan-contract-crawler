// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LightningSwapBase.sol";
import "./PriceOracle.sol";

contract LightningSwap is LightningSwapBase {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Deposit {
        address depositor;
        address beneficiary;
        address token;
        uint256 amount;
        bytes32 secretHash;
        uint256 deadline;
        string invoice;
        bool withdrawn;
        uint256 btcPrice;
        uint256 tokenPrice;
    }

    mapping(bytes32 => Deposit) private deposits;

    function deposit(address token, uint256 amount, address beneficiary, bytes32 secretHash, uint256 deadline, string memory invoice) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        require(deposits[secretHash].depositor == address(0), "Deposit already exists");

        uint256 btcPrice = 0;
        uint256 tokenPrice = 0;
        if (oracle != address(0)) {
            btcPrice = PriceOracle(oracle).getBTCPrice();
            tokenPrice = PriceOracle(oracle).getTokenPrice(token);
        }

        deposits[secretHash] = Deposit({
            depositor: msg.sender,
            beneficiary: beneficiary,
            token: token,
            amount: amount,
            secretHash: secretHash,
            deadline: deadline,
            invoice: invoice,
            withdrawn: false,
            btcPrice: btcPrice,
            tokenPrice: tokenPrice
        });

        depositors[msg.sender].add(secretHash);
        withdrawers[beneficiary].add(secretHash);

        emit DepositCreated(secretHash, msg.sender, beneficiary, token, amount, deadline, invoice);
    }

    function withdraw(bytes memory secret) external {
        bytes32 secretHash = sha256(abi.encodePacked(secret));
        Deposit memory depositItem = deposits[secretHash];

        require(depositItem.beneficiary == msg.sender, "Invalid beneficiary");
        require(depositItem.deadline >= block.timestamp, "Deposit has expired");
        require(!depositItem.withdrawn, "Deposit has already been withdrawn");

        deposits[secretHash].withdrawn = true;
        withdrawers[msg.sender].remove(secretHash);
        depositors[depositItem.depositor].remove(secretHash);
        IERC20(depositItem.token).transfer(msg.sender, depositItem.amount);

        emit Withdrawn(secretHash, msg.sender, depositItem.token, depositItem.amount);
    }

    function delegateWithdraw(bytes memory secret, address account) external {
        bytes32 secretHash = sha256(abi.encodePacked(secret));
        Deposit memory depositItem = deposits[secretHash];

        require(depositItem.beneficiary == account, "Invalid beneficiary");
        require(depositItem.deadline >= block.timestamp, "Deposit has expired");
        require(!depositItem.withdrawn, "Deposit has already been withdrawn");

        deposits[secretHash].withdrawn = true;
        withdrawers[account].remove(secretHash);
        depositors[depositItem.depositor].remove(secretHash);
        IERC20(depositItem.token).transfer(account, depositItem.amount);

        emit Withdrawn(secretHash, account, depositItem.token, depositItem.amount);
    }

    function refund(bytes32 secretHash) external {
        Deposit memory depositItem = deposits[secretHash];

        require(depositItem.depositor == msg.sender && depositItem.deadline < block.timestamp, "Invalid refund requester");
        require(!depositItem.withdrawn, "Deposit has already been withdrawn");

        deposits[secretHash].withdrawn = true;
        withdrawers[depositItem.beneficiary].remove(secretHash);
        depositors[msg.sender].remove(secretHash);
        IERC20(depositItem.token).transfer(depositItem.depositor, depositItem.amount);

        emit Refunded(secretHash, msg.sender, depositItem.token, depositItem.amount);
    }

    function delegateRefund(bytes32 secretHash, address depositor) external {
        Deposit memory depositItem = deposits[secretHash];

        require(depositItem.depositor == depositor && depositItem.deadline < block.timestamp, "Invalid refund requester");
        require(!depositItem.withdrawn, "Deposit has already been withdrawn");

        deposits[secretHash].withdrawn = true;
        withdrawers[depositItem.beneficiary].remove(secretHash);
        depositors[depositor].remove(secretHash);
        IERC20(depositItem.token).transfer(depositItem.depositor, depositItem.amount);

        emit Refunded(secretHash, depositor, depositItem.token, depositItem.amount);
    }

    function getDeposit(bytes32 secretHash) external view returns (address depositor, address beneficiary, address token, uint256 amount, uint256 deadline, bool withdrawn, string memory invoice, uint256 btcPrice, uint256 tokenPrice) {
        Deposit memory depositItem = deposits[secretHash];

        require(depositItem.depositor != address(0), "Deposit does not exist");

        return (depositItem.depositor, depositItem.beneficiary, depositItem.token, depositItem.amount,
            depositItem.deadline, depositItem.withdrawn, depositItem.invoice, depositItem.btcPrice, depositItem.tokenPrice);
    }

}