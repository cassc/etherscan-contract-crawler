pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using MerkleProof for bytes32[];

    ERC20 public token;
    uint256 public numPaymentCycles = 1;
    mapping(address => uint256) public withdrawals;

    mapping(uint256 => bytes32) payeeRoots;
    uint256 currentPaymentCycleStartBlock;

    event PaymentCycleEnded(
        uint256 paymentCycle,
        uint256 startBlock,
        uint256 endBlock
    );
    event PayeeWithdraw(address indexed payee, uint256 amount);

    constructor(ERC20 _token) {
        token = _token;
        currentPaymentCycleStartBlock = block.number;
    }

    function startNewPaymentCycle() internal onlyOwner returns (bool) {
        require(block.number > currentPaymentCycleStartBlock);

        emit PaymentCycleEnded(
            numPaymentCycles,
            currentPaymentCycleStartBlock,
            block.number
        );

        numPaymentCycles = numPaymentCycles.add(1);
        currentPaymentCycleStartBlock = block.number.add(1);

        return true;
    }

    function submitPayeeMerkleRoot(bytes32 payeeRoot)
        public
        onlyOwner
        returns (bool)
    {
        payeeRoots[numPaymentCycles] = payeeRoot;

        startNewPaymentCycle();

        return true;
    }

    function balanceForProofWithAddress(address _address, bytes memory proof)
        public
        view
        returns (uint256)
    {
        bytes32[] memory meta;
        bytes32[] memory _proof;

        (meta, _proof) = splitIntoBytes32(proof, 2);
        if (meta.length != 2) {
            return 0;
        }

        uint256 paymentCycleNumber = uint256(meta[0]);
        uint256 cumulativeAmount = uint256(meta[1]);
        if (payeeRoots[paymentCycleNumber] == 0x0) {
            return 0;
        }

        bytes32 leaf = keccak256(abi.encodePacked(_address, cumulativeAmount));
        if (
            withdrawals[_address] < cumulativeAmount &&
            _proof.verify(payeeRoots[paymentCycleNumber], leaf)
        ) {
            return cumulativeAmount.sub(withdrawals[_address]);
        } else {
            return 0;
        }
    }

    function balanceForProof(bytes memory proof) public view returns (uint256) {
        return balanceForProofWithAddress(msg.sender, proof);
    }

    function withdraw(uint256 amount, bytes memory proof)
        public
        returns (bool)
    {
        require(amount > 0);
        require(token.balanceOf(address(this)) >= amount);

        uint256 balance = balanceForProof(proof);
        require(balance >= amount);

        withdrawals[msg.sender] = withdrawals[msg.sender].add(amount);
        token.safeTransfer(msg.sender, amount);

        emit PayeeWithdraw(msg.sender, amount);
    }

    function withdrawTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function splitIntoBytes32(bytes memory byteArray, uint256 numBytes32)
        internal
        pure
        returns (bytes32[] memory bytes32Array, bytes32[] memory remainder)
    {
        if (
            byteArray.length % 32 != 0 ||
            byteArray.length < numBytes32.mul(32) ||
            byteArray.length.div(32) > 50
        ) {
            // Arbitrarily limiting this function to an array of 50 bytes32's to conserve gas

            bytes32Array = new bytes32[](0);
            remainder = new bytes32[](0);
            return (bytes32Array, remainder);
        }

        bytes32Array = new bytes32[](numBytes32);
        remainder = new bytes32[](byteArray.length.sub(64).div(32));
        bytes32 _bytes32;
        for (uint256 k = 32; k <= byteArray.length; k = k.add(32)) {
            assembly {
                _bytes32 := mload(add(byteArray, k))
            }
            if (k <= numBytes32 * 32) {
                bytes32Array[k.sub(32).div(32)] = _bytes32;
            } else {
                remainder[k.sub(96).div(32)] = _bytes32;
            }
        }
    }
}