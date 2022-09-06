// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721X.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ZelenskyNFT is ERC721X, Ownable {

    enum RevealStatus{
        MINT,
        REVEAL,
        REVEALED
    }

    event UriChange(string newURI);
    event NewRoot(bytes32 root);
    event LockTimerStarted(uint _start, uint _end);

    constructor() ERC721X("ZelenskiyNFT Reserve", "ZFT") {
        _mint(0x949c48b29b3F5e75ff30bd8dA4bA6de23Aa34f91, 1);
    }

    uint256 public constant maxTotalSupply = 10000;
    uint256 public constant communityMintSupply = 500;
    uint256 private communitySold = 0;

    string private theBaseURI = "https://zelenskiynft.mypinata.cloud/ipfs/QmcEpX155NaMA1cfpmpFX55E4o9etDdXFZEoVdyp9ew97E/";

    function _baseURI() internal view override returns (string memory) {
        return theBaseURI;
    }

    mapping(address => uint256) private mints;
    mapping(address => bool) private whitelistClaimed;

    bytes32 private root;

    RevealStatus revealStatus = RevealStatus.REVEAL;

    uint public constant whitelist2StartTime = 1654189200;

    uint private functionLockTime = 0;

    address public constant multisigOwnerWallet = 0x15E6733Be8401d33b4Cf542411d400c823DF6187;

    modifier ownerIsMultisig() {
        require(owner() == multisigOwnerWallet, "Owner is not multisignature wallet");
        _;
    }

    modifier whitelistActive(){
        require(block.timestamp >= whitelist2StartTime, "Whitelist2 not started yet");
        _;
    }

    function buy(bytes32[] calldata _proof) public payable whitelistActive {
        require(msg.sender == tx.origin, "payment not allowed from contract");

        require(nextId + 1 <= maxTotalSupply, "Maximum supply reached");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, root, leaf), "Address not in whitelist");
        require(whitelistClaimed[msg.sender] == false, "Whitelist already claimed");

        mints[msg.sender] += 1;

        whitelistClaimed[msg.sender] = true;

        _mint(msg.sender, 1);
    }

    function setRoot(bytes32 _newRoot) public onlyOwner ownerIsMultisig {
        root = _newRoot;
        emit NewRoot(root);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner ownerIsMultisig {
        if(functionLockTime == 0){
            functionLockTime = block.timestamp;
            emit LockTimerStarted(functionLockTime, functionLockTime + 48 hours);
            return;
        }else{
            require(block.timestamp >= functionLockTime + 48 hours, "48 hours not passed yet");
            functionLockTime = 0;
        }
        require(revealStatus != RevealStatus.REVEALED, "URI modifications after reveal are prohibited");
        theBaseURI = newBaseURI;
        emit UriChange(newBaseURI);
        revealStatus = RevealStatus.REVEALED;
    }
}