// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./utils/TransferHelper.sol";
import "./libs/SafeMath.sol";
import "./libs/SignedSafeMath.sol";

struct Transfer {
    bytes32 hash;
    address from;
    address coin;
    uint256 quantity;
    string  fromChain;
    string  toChain;
    uint256 feesInCDT;
    uint256 feesInETH;
    uint256 blockTimestamp;
    uint256 blockNumber;
    string  data;
}

struct Bridge {
    address addr;
    string chain;
}

struct Validator {
    address addr;
    uint256 warrantyAmount;
    uint256 totalLossAmount;
}

/**
 * @title EVMBridge
 * @author Jeremy Guyet (@jguyet)
 * @dev 
 * Smart Contract for manage the transfers between two blockchains
 * who respect the Ethereum Virtual Machine normal. This Smart contract
 * contains the list of the chains accepted and list all transactions initialized
 * with their hash proof from the destination chain. this smart contract is decentralized
 * but managed by one wallet address (The owner wallet of the CheckDot project).
 * This contract is managed by API in Nodejs and we wait 100 block before transfer anything.
 */
contract EVMBridge {

    using SafeMath for uint256;
    using SignedSafeMath for int256;

    address public token;
    address public owner;
    address public program;
    string  public chain;

    uint256 public feesInDollar;
    uint256 public feesInCDTPercentage;
    uint256 public minimumTransferQuantity;

    uint256 public bridgeFeesInCDT;
    uint256 public lockedQuantity;
    
    uint256 private blocksLength;
    mapping(bytes32 => uint256) private transfersIndexs;
    Transfer[] private transfers;
    mapping(bytes32 => bytes32) private transfersHashs;

    // Private dex information
    address private dex_in;
    address private dex_out;
    address private dex_pool;

    bool internal paused;
    bool internal locked;

    constructor(
        string memory _bridgeChain,
        address _token,
        uint256 _feesInDollar,
        uint256 _feesInCDTPercentage,
        address _dex_in,
        address _dex_out,
        address _dex_pool) {
        require(msg.sender != address(0), "ABORT sender - address(0)");
        token = _token;
        owner = msg.sender;
        program = msg.sender;
        chain = _bridgeChain;
        feesInDollar = _feesInDollar;
        feesInCDTPercentage = _feesInCDTPercentage;
        dex_in = _dex_in;
        dex_out = _dex_out;
        dex_pool = _dex_pool;
        minimumTransferQuantity = 1 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this action");
        _;
    }

    modifier onlyProgramOrOwner() {
        require(msg.sender == program || msg.sender == owner, "Only program or Owner");
        _;
    }

    modifier activated() {
        require(paused == false, "Bridge actually paused");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function getFeesInDollar() public view returns (uint256) {
        return feesInDollar;
    }

    function setFeesInDollar(uint256 cost) public onlyOwner {
        feesInDollar = cost;
    }

    function getFeesInETH() public view returns (uint256) {
        uint256 oneDollar = getTokenPriceOutFromPoolBalance(dex_in, dex_out, dex_pool);
        return oneDollar.mul(1 ether).div(feesInDollar).mul(100); // multiplication 1 ether pour decaler les decimals.
    }

    function getFeesInCDTByQuantity(uint256 quantity) public view returns (uint256) {
        if (feesInCDTPercentage == 0) {
            return 0;
        }
        uint256 transferFees = quantity.div(100).mul(feesInCDTPercentage);
        return transferFees;
    }

    function setFeesInCDTPercentage(uint256 feesInPercentage) public onlyOwner {
        feesInCDTPercentage = feesInPercentage;
    }
    
    function initTransfer(uint256 quantity, string calldata toChain, string calldata data) public payable noReentrant activated {
        require(msg.value >= getFeesInETH(),
            "PAYMENT_ABORT"
        );
        require(quantity >= minimumTransferQuantity,
            "INSUFISANT_QUANTITY"
        );
        require(IERC20(token).balanceOf(msg.sender) >= quantity, "INSUFISANT_BALANCE");
        require(IERC20(token).allowance(msg.sender, address(this)) >= quantity, "INSUFISANT_ALLOWANCE");
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), quantity);
        
        uint256 transferFeesInCDT = getFeesInCDTByQuantity(quantity);
        uint256 transferQuantity = quantity.sub(transferFeesInCDT);
        uint256 transferETHFees = msg.value;

        bridgeFeesInCDT += transferFeesInCDT;
        uint256 index = transfers.length;
        bytes32 transferHash = _getHash(block.timestamp, 0, msg.sender);

        transfers.push(Transfer(
            transferHash,
            msg.sender,
            token,
            transferQuantity,
            chain,
            toChain,
            transferFeesInCDT,
            transferETHFees,
            block.timestamp,
            block.number,
            data
        ));
        transfersIndexs[transferHash] = index;
        transfersHashs[transferHash] = transferHash;
        lockedQuantity = lockedQuantity.add(transferQuantity);
    }

    function transferExists(bytes32 transferHash) public view returns (bool) {
        return transfersHashs[transferHash] == transferHash;
    }

    function getTransfer(bytes32 transferHash) public view returns (Transfer memory) {
        return transfers[transfersIndexs[transferHash]];
    }

    function getTransferLength() public view returns (uint256) {
        return transfers.length;
    }

    function getTransfers(int256 page, int256 pageSize) external view returns (Transfer[] memory) {
        uint256 poolLength = transfers.length;
        int256 queryStartPoolIndex = int256(poolLength).sub(pageSize.mul(page.add(1))).add(pageSize);
        require(queryStartPoolIndex >= 0, "Out of bounds");
        int256 queryEndPoolIndex = queryStartPoolIndex.sub(pageSize);
        if (queryEndPoolIndex < 0) {
            queryEndPoolIndex = 0;
        }
        int256 currentPoolIndex = queryStartPoolIndex;
        require(uint256(currentPoolIndex) <= poolLength, "Out of bounds");
        Transfer[] memory results = new Transfer[](uint256(currentPoolIndex - queryEndPoolIndex));
        uint256 index = 0;

        for (currentPoolIndex; currentPoolIndex > queryEndPoolIndex; currentPoolIndex--) {
            Transfer memory transfer = transfers[uint256(currentPoolIndex).sub(1)];
            results[index] = transfer;
            index++;
        }
        return results;
    }

    function addLockQuantity(uint256 quantity) public onlyOwner {
        lockedQuantity = lockedQuantity.add(quantity);
    }

    function subLockQuantity(uint256 quantity) public onlyOwner {
       lockedQuantity = lockedQuantity.sub(quantity);
    }

    function collectCDTFees() public onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= bridgeFeesInCDT, "INSUFISANT_BALANCE");
        TransferHelper.safeTransfer(token, msg.sender, bridgeFeesInCDT);
        bridgeFeesInCDT = 0;
    }

    function deposit(address coin, uint256 quantity) public onlyOwner noReentrant {
        require(IERC20(coin).balanceOf(msg.sender) >= quantity, "INSUFISANT_BALANCE");
        require(IERC20(coin).allowance(msg.sender, address(this)) >= quantity, "INSUFISANT_ALLOWANCE");
        TransferHelper.safeTransferFrom(coin, msg.sender, address(this), quantity);
    }

    function balance() public view returns (uint256){
        return payable(address(this)).balance;
    }

    function depositETH(uint256 quantity) public payable onlyOwner noReentrant {
        require(msg.value >= quantity,
            "PAYMENT_ABORT"
        );
    }

    function withdraw(address coin, uint256 quantity) public onlyOwner noReentrant {
        require(IERC20(coin).balanceOf(address(this)) >= quantity, "INSUFISANT_BALANCE");
        TransferHelper.safeTransfer(coin, msg.sender, quantity);
    }

    function withdrawUnlocked() public onlyOwner noReentrant {
        uint256 balanceOfToken = IERC20(token).balanceOf(address(this));

        require(balanceOfToken >= lockedQuantity, "INSUFISANT_BALANCE");
        TransferHelper.safeTransfer(token, msg.sender, balanceOfToken - lockedQuantity);
    }

    function withdrawETH(uint quantity) public onlyOwner noReentrant {
        require(quantity <= balance(), "Insufficient balance");
        (bool success,)=owner.call{value:quantity}("");
        require(success, "Transfer failed!");
    }

    function emergencyWithdrawAll() external onlyOwner noReentrant {
        (bool success,)= owner.call{value:address(this).balance}("");
        require(success,"Transfer failed!");
    }

    function getLastsTransfers(uint256 size) external view returns (Transfer[] memory) {
        uint256 poolLength = transfers.length;
        uint256 start = 0;
        uint256 memorySize = size;

        if (transfers.length > size) {
            start = transfers.length.sub(size);
        } else {
            memorySize = transfers.length;
        }
        uint256 currentIndex = start;
        Transfer[] memory results = new Transfer[](memorySize);
        uint256 memoryIndex = 0;

        for (currentIndex; currentIndex < poolLength; currentIndex++) {
            Transfer memory transfer = transfers[currentIndex];
            results[memoryIndex++] = transfer;
        }
        return results;
    }

    function addTransfersFrom(string[] memory /* fromChains */, address[] memory transfersAddresses, uint256[] memory amounts, bytes32[] memory _transfersHashs) public onlyProgramOrOwner {
        for (uint256 i = 0; i < transfersAddresses.length; i++) {
            address transferAddress = transfersAddresses[i];
            uint256 amount = amounts[i];
            bytes32 transferHash = _transfersHashs[i];

            require(transfersHashs[transferHash] == 0, "Already transfered");
            TransferHelper.safeTransfer(token, transferAddress, amount);
            transfersHashs[transferHash] = transferHash;
        }
    }

    function getDex() public view returns (address, address, address) {
        return (dex_in, dex_out, dex_pool);
    }

    /**
     * Only 18 decimals tokens.
     */
    function setDex(address _in, address _out, address _pool) public onlyOwner {
        dex_in = _in;
        dex_out = _out;
        dex_pool = _pool;
    }

    function getTokenPriceOutFromPoolBalance(address _in, address _out, address _pool) public view returns (uint256) {
        uint256 balanceIn = IERC20(_in).balanceOf(_pool);
        uint256 balanceOut = IERC20(_out).balanceOf(_pool);
        require(balanceOut > 0);
        return balanceIn.mul(1 ether).div(balanceOut);
        // ex: in=USDC,out=ETH = price of ETH in USDC
        // ex: in=ETH,out=USDC = price of USDC in ETH
    }

    function updateTransferCost(uint256 _feesInDollar) public onlyOwner {
        feesInDollar = _feesInDollar;
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    function setPaused(bool p) public onlyOwner {
        paused = p;
    }

    function setMinimumTransferQuantity(uint256 quantity) public onlyOwner {
        minimumTransferQuantity = quantity;
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "No zero address");
        owner = newOwner;
    }

    function changeProgram(address newProgram) public onlyOwner {
        require(newProgram != address(0), "No zero address");
        program = newProgram;
    }

    function _getHash(uint256 timestamp, uint256 nonce, address addr) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(timestamp, addr, nonce));
    }
}