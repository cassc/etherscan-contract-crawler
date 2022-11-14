// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyContracts.sol";

contract Proxy is Ownable, ProxyContracts {

    string constant BASE_CURRENCY_SYMBOL = "ETH";
    uint constant BASE_CURRENCY_DECIMALS = 18;

    uint constant FEE = 1000; // 0.1%
    uint constant FEE_MUL = 1;
    uint constant MIN_FEE = 1;

    struct Deposit {
        string hash;
        address from;
        string symbol;
        uint amount;
        bytes data;
    }

    Deposit[] public deposits;

    event DepositAddedEvent(string hash, address from, string symbol, uint amount, bytes data);
    event DepositExecEvent(string hash, address from, address to, string symbol, uint amount, bytes data);

    /**
     * Add coins
     */
    function addCoins() public payable {
        
    }

    /**
     * Add deposit
     */
    function addDeposit(string memory hash, address sender, uint amount, bytes calldata data) public onlyOwner {
        addDepositData(hash, sender, BASE_CURRENCY_SYMBOL, amount, data);
    }

    /**
     * Add token deposit
     */
    function addTokenDeposit(string memory hash, address sender, string memory symbol, uint amount, bytes calldata data) public onlyOwner {
        addDepositData(hash, sender, symbol, amount, data);
    }

    /**
     * Add deposit data record
     */
    function addDepositData(string memory hash, address from, string memory symbol, uint amount, bytes calldata data) internal {
        bool _elementExists = false;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.hash)) == keccak256(bytes(hash))) {
                _elementExists = true;
                break;
            }
        }

        require(!_elementExists, "Deposit already exists");

        deposits.push(Deposit({
            hash: hash,
            from: from,
            symbol: symbol,
            amount: amount,
            data: data
        }));
        emit DepositAddedEvent(hash, from, symbol, amount, data);
    }

    /**
     * Exec deposits
     */
    function execDeposit(string memory hash, address to) public onlyOwner {
        int index = -1;
        bool isSended = false;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.hash)) != keccak256(bytes(hash))) {
                continue;
            }

            index = int(i);

            delete deposits[i];

            uint fee = element.amount / FEE * FEE_MUL;
            fee = fee < MIN_FEE ? MIN_FEE : fee;
            uint resultAmount = element.amount - fee;

            if (keccak256(bytes(element.symbol)) == keccak256(bytes(BASE_CURRENCY_SYMBOL))) {
                sendCoins(to, resultAmount, element.data);
            } else {
                sendTokens(getContractAddress(element.symbol), to, resultAmount, element.data);
            }

            emit DepositExecEvent(hash, element.from, to, element.symbol, element.amount, element.data);

            isSended = true;

            break;
        }

        require(isSended, "Deposit not sended");

        if (index >= 0) {
            for (uint i = uint(index); i < deposits.length - 1; i++) {
                deposits[i] = deposits[i + 1];
            }

            deposits.pop();
        }
    }

    /**
     * Delete deposit by hash
     */
    function delDepositByHash(string memory hash) public onlyOwner {
        int index = -1;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.hash)) == keccak256(bytes(hash))) {
                index = int(i);
                break;
            }

        }

        require(index >= 0, "Deposit by hash not found");

        delete deposits[uint(index)];
        for (uint i = uint(index); i < deposits.length - 1; i++) {
            deposits[i] = deposits[i + 1];
        }

        deposits.pop();
    }

    /**
     * Send coins
     */
    function sendCoins(address to, uint amount, bytes memory data) internal onlyOwner {
        require(address(this).balance >= amount, "Balance not enough");
        (bool success, ) = to.call{value: amount}(data);
        require(success, "Transfer not sended");
    }

    /**
     * Send tokens
     */
    function sendTokens(address contractAddress, address to, uint amount, bytes memory data) internal onlyOwner {
        (bool success, bytes memory result) = contractAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(success, "balanceOf request failed");
        require(abi.decode(result, (uint256)) >= amount, "Not enough tokens");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");

        (success, ) = to.call(data);
        require(success, "transfer data request failed");
    }


    /**
     * =================
     * Withdrawal logic
     * =================
     */

    address constant DEFAULT_ADDRESS = 0x0000000000000000000000000000000000000000;

    event TokenBalanceEvent(uint amount, string symbol);

    /**
     * Return coins balance
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
     * Return tokens balance
     */
    function getTokenBalance(string memory symbol) public returns(uint) {
        address contractAddress = getContractAddress(symbol);
        require(contractAddress != DEFAULT_ADDRESS, "Contract address not found");

        (bool success, bytes memory result) = contractAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(success, "balanceOf request failed");

        uint256 amount = abi.decode(result, (uint256));

        emit TokenBalanceEvent(amount, symbol);

        return amount;
    }

    /**
     * Transfer coins
     */
    function transfer(address payable to, uint amount) public onlyOwner {
        uint _balance = address(this).balance;
        require(_balance >= amount, "Balance not enough");
        to.transfer(amount);
    }

    /**
     * Transfer tokens
     */
    function transferToken(string memory symbol, address to, uint amount) public onlyOwner {
        address contractAddress = getContractAddress(symbol);
        require(contractAddress != DEFAULT_ADDRESS, "Contract address not found");

        uint _balance = getTokenBalance(symbol);
        require(_balance >= amount, "Not enough tokens");

        (bool success, ) = contractAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");
    }

    /**
     * Withdrawal comission coins (excluding deposites)
     */
    function withdrawal(address payable to, uint amount) public onlyOwner {
        uint depositesSum = 0;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.symbol)) == keccak256(bytes(BASE_CURRENCY_SYMBOL))) {
                depositesSum += element.amount;
            }
        }

        uint _balance = address(this).balance;
        uint _resultBalance = _balance - depositesSum;
        require(_resultBalance >= amount, "Balance not enough");
        to.transfer(amount);
    }

    /**
     * Withdrawal comission tokens (excluding deposites)
     */
    function withdrawalToken(string memory symbol, address to, uint amount) public onlyOwner {
        address contractAddress = getContractAddress(symbol);
        require(contractAddress != DEFAULT_ADDRESS, "Contract address not found");

        uint depositesSum = 0;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.symbol)) == keccak256(bytes(symbol))) {
                depositesSum += element.amount;
            }
        }

        uint _balance = getTokenBalance(symbol);
        uint _resultBalance = _balance - depositesSum;
        require(_resultBalance >= amount, "Not enough tokens");

        (bool success, ) = contractAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");
    }
}