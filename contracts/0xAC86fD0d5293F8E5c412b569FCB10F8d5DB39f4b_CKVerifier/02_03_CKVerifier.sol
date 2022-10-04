//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./EllipticCurve.sol";
import "./BlockSynthesis.sol";

struct SingleTxBitcoinBlockSplit {
    bytes genTx0;
    bytes4 extraNonce1;
    bytes extraNonce2;

    // response is the first 32 bytes of genTx1
    bytes32 response;
    // remainingTx is the remaining bytes of genTx1
    bytes remainingTx;

    bytes4 nonce;
    bytes4 bits;
    bytes4 nTime;
    bytes32 previousBlockHash;
    bytes4 version;
}

/**
 * @dev A contract that attests to proofs of complete knowledge
 */
interface ICKVerifier {
    /**
     * @dev Returns true if the address has shown a proof of complete knowledge
     * to this verifier.
     */
    function isCKVerified(address addr) external returns (bool);
}

contract CKVerifier is BlockSynthesis, ICKVerifier {

    uint public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint public constant AA = 0;
    uint public constant BB = 7;
    uint public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint public difficulty;
    uint public timeThreshold;
    uint public currJob = 0;
    uint public nonceRange;
    uint public numberOfRounds;

    mapping (uint => uint[]) public commitmentsX; // job id to commitment
    mapping (uint => uint[]) public commitmentsY; // job id to commitment
    mapping (uint => uint) public randomnessInputs; // job id to trusted random input
    mapping (uint => uint) public pubKeysX;
    mapping (uint => uint) public pubKeysY;
    mapping (uint => uint) public startTimes;
    mapping (address => bool) public isCKVerified;
    
    event NewJob(uint indexed jobId, uint indexed pubKeyX, uint indexed pubKeyY);
    event ChallengeInitialized(uint indexed jobId, uint indexed randomness, uint startTime);
    event CKVerified(uint indexed jobId, address indexed addr);

    constructor(uint _d, uint _tau, uint nRounds, uint _nonceRange) {
        difficulty = _d;
        timeThreshold = _tau;
        numberOfRounds = nRounds;
        // Length of extraNonce2, in bytes
        nonceRange = _nonceRange;
    }
    
    function registerJob(uint[] calldata _aX, uint[] calldata _aY, uint _pkX, uint _pkY) public returns(uint) {
        require(_aX.length == numberOfRounds);
        require(_aY.length == numberOfRounds);
        currJob += 1;
        commitmentsX[currJob] = _aX;
        commitmentsY[currJob] = _aY;
        pubKeysX[currJob] = _pkX;
        pubKeysY[currJob] = _pkY;
        emit NewJob(currJob, _pkX, _pkY);
        return currJob;
    }

    function initChallenge(uint jobId) public returns(uint) {
        require(jobId <= currJob, "Job not registered");
        require(startTimes[jobId] == 0, "Challenge already initialized");
        randomnessInputs[jobId] = uint(keccak256(abi.encodePacked(jobId, block.difficulty)));
        uint startTime = block.timestamp;
        startTimes[jobId] = startTime;
        emit ChallengeInitialized(jobId, randomnessInputs[jobId], startTime);
        return startTime;
    }

    function powAccept(bytes32 dataHash) private view returns(bool) {
        if (difficulty == 0) return true;
        return blockDifficulty(dataHash) >= difficulty;
    }

    function zkAccept(uint aX, uint aY, uint challenge, uint response, uint pkX, uint pkY) private pure returns(bool) {
        (uint gsX, uint gsY) = EllipticCurve.ecMul(response, GX, GY, AA, PP);
        (uint tempX, uint tempY) = EllipticCurve.ecMul(challenge, pkX, pkY, AA, PP);
        (uint rhsX, uint rhsY) = EllipticCurve.ecAdd(aX, aY, tempX, tempY, AA, PP);
        return (gsX == rhsX) && (gsY == rhsY);
    }
    
    function deriveAddress(uint jobId) private view returns (address) {
        uint pkx = pubKeysX[jobId];
        uint pky = pubKeysY[jobId];
        return address(uint160(uint256(keccak256(bytes.concat(bytes32(pkx), bytes32(pky))))));
    }

    function verify(uint jobId, SingleTxBitcoinBlock[] calldata blocks) public returns (bool) {
        require(startTimes[jobId] > 0, "Challenge not initiated");
        uint randomInput = randomnessInputs[jobId];
        bool accepted = wouldVerify(jobId, blocks, randomInput); 
        if (accepted) {
            address addr = deriveAddress(jobId);
            isCKVerified[addr] = true;
            emit CKVerified(jobId, addr);
        }
        // Maybe emit Verify log for ease of use only
        return accepted;
    }
	
    // Bitcoin block struct containing everything
    // accept BitcoinBlock[] - numberOfRounds in length or more
    // [genTx0, genTx1, extraNonce1, extraNonce2] -> merkle hash, previousBlockHash, nonce, bits, nTime, version
    // Instead of genTx1: have response, and remaining tx as arguments
    //    	genTx1 = bytes.concat(response, remainingTx)
    
    function wouldVerify(uint jobId, SingleTxBitcoinBlock[] calldata blocks, uint randomInput) public view returns (bool) {
        require(blocks.length == numberOfRounds);
        if (block.timestamp - startTimes[jobId] > timeThreshold) {
            return false;
        }
        // response = gentx1 (first 32 bytes)
        // bitcoin block hash
        for (uint i = 0; i < blocks.length; i++) {
	        bytes32 dataHash = blockHash(createSingleTxHeader(blocks[i]));
	        if (!powAccept(dataHash)) {
	            return false;
	        }
	        if (blocks[i].extraNonce2.length > nonceRange) {
	            return false;
	        }
        }
        // challenge can be determined by all arguments except the response (just hash all arguments together, including randomness - concat at end)
        for (uint i = 0; i < blocks.length; i++) {
            SingleTxBitcoinBlock calldata currentBlock = blocks[i];
            bytes32 challenge = sha256(bytes.concat(currentBlock.version, currentBlock.previousBlockHash,
                currentBlock.genTx0, currentBlock.extraNonce1, currentBlock.genTx1[32:],
                currentBlock.nTime, currentBlock.bits, bytes32(randomInput + i)));

	        bytes32 response = bytes32(currentBlock.genTx1[:32]);
	        
	        uint aXi = commitmentsX[jobId][i];
	        uint aYi = commitmentsY[jobId][i];
	        uint pkX = pubKeysX[jobId];
	        uint pkY = pubKeysY[jobId];
	        if (!zkAccept(aXi, aYi, uint(challenge), uint(response), pkX, pkY)) {
	        	return false;
	        }
        }
        return true;
    }
}

