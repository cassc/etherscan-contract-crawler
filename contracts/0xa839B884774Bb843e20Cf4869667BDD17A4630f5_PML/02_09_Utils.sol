// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not owner");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = _newOwner;
    }
}

abstract contract Lockable {
    mapping(address => bool) public lockers;

    constructor() {
        lockers[msg.sender] = true;
    }

    modifier onlyLocker() {
        require(lockers[msg.sender], "Lockable: caller is not locker");
        _;
    }

    function setLocker(address newLocker, bool lockable) public virtual onlyLocker {
        require(
            newLocker != address(0),
            "newLocker: new locker is the zero address"
        );
        lockers[newLocker] = lockable;
    }
}

abstract contract Mintable {
    mapping(address => bool) public minters;

    constructor() {
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Mintable: caller is not minter");
        _;
    }

    function setMinter(address newMinter, bool mintable) public virtual onlyMinter {
        require(
            newMinter != address(0),
            "Mintable: new minter is the zero address"
        );
        minters[newMinter] = mintable;
    }
}

abstract contract Burnable {
    mapping(address => bool) public burners;

    constructor() {
        burners[msg.sender] = true;
    }

    modifier onlyBurner() {
        require(burners[msg.sender], "Burnable: caller is not burner");
        _;
    }

    function isBurner(address addr) public view returns(bool) {
        return burners[addr];
    }

    function setBurner(address newBurner, bool burnable) public virtual onlyBurner {
        require(
            newBurner != address(0),
            "Burnable: new burner is the zero address"
        );
        burners[newBurner] = burnable;
    }
}

abstract contract SupportSig is EIP712 {
    uint256 private MAX_NONCE_DIFFERENCE = 100 * 365 * 24 * 60 * 60;

    constructor(string memory name, string memory version) EIP712(name,version) {}
    
    function validNonce(uint256 nonce, uint256 lastNonce) internal view returns(bool) {
        return nonce > lastNonce && nonce - lastNonce < MAX_NONCE_DIFFERENCE;
    }
    function getChainId() public view returns(uint256) {
        return block.chainid;
    }
    
    function getSigner(bytes memory typedContents, bytes memory sig) internal view returns (address) {
        return ECDSA.recover(_hashTypedDataV4(keccak256(typedContents)), sig);
    }
}

abstract contract SupportTokenUpdateHistory {

    struct  TokenUpdateHistoryItem {
        uint256 tokenId;
        uint256 updatedAt;
    }

    uint256 public tokenUpdateHistoryCount;
    TokenUpdateHistoryItem[] public tokenUpdateHistory;

    constructor() {
        TokenUpdateHistoryItem memory dummy;
        tokenUpdateHistory.push(dummy);
    }

    function onTokenUpdated(uint256 tokenId) internal {
        tokenUpdateHistory.push(TokenUpdateHistoryItem(tokenId, block.timestamp));
        tokenUpdateHistoryCount++;
    }
}

interface ILocker {
    function isLocked(address _user, uint256 volume) external view returns (bool);
}