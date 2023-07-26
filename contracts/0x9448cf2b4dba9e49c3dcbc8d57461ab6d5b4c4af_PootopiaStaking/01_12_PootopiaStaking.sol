// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PootopiaStaking is EIP712, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    
    IERC20 flush = IERC20(0xf07e62de6321158E1d06527919D945D73545C195);

    struct StakedContract {
        bool active;
        IERC721 instance;
    }

    mapping(address => mapping(address => EnumerableSet.UintSet)) addressToStakedTokensSet;
    mapping(address => mapping(uint => address)) contractTokenIdToOwner;
    mapping(address => mapping(uint => uint)) contractTokenIdToStakedTimestamp;
    mapping(address => StakedContract) public contracts;
    mapping(address => Counters.Counter) accountToNonce;
    mapping(address => uint) public accountToLastWithdrawTimestamp;
    mapping(address => uint) public accountToLastWithdrawAmount;
    
    EnumerableSet.AddressSet activeContracts;
    address _signerAddress;
    
    event Stake(uint tokenId, address contractAddress, address owner);
    event Unstake(uint tokenId, address contractAddress, address owner);
    event Withdraw(address owner, uint nonce, uint amount);

    modifier ifContractExists(address contractAddress) {
        require(activeContracts.contains(contractAddress), "contract does not exists");
        _;
    }

    constructor() EIP712("PootopiaStaking", "1.0.0") {
        _signerAddress = 0x42bC5465F5b5D4BAa633550e205A1d7D81e6cACf;
    }

    function stake(address contractAddress, uint[] memory tokenIds) external {
        StakedContract storage _contract = contracts[contractAddress];
        require(_contract.active, "token contract is not active");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            // Assign token to his owner
            contractTokenIdToOwner[contractAddress][tokenId] = msg.sender;

            // Transfer token to this smart contract
            _contract.instance.safeTransferFrom(msg.sender, address(this), tokenId);

            // Add this token to user staked tokens
            addressToStakedTokensSet[contractAddress][msg.sender].add(tokenId);

            // Save stake timestamp
            contractTokenIdToStakedTimestamp[contractAddress][tokenId] = block.timestamp;

            emit Stake(tokenId, contractAddress, msg.sender);
        }
    }

    function unstake(address contractAddress, uint[] memory tokenIds) external ifContractExists(contractAddress) {
        StakedContract storage _contract = contracts[contractAddress];

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(addressToStakedTokensSet[contractAddress][msg.sender].contains(tokenId), "token is not staked");

            // Remove owner of this token
            delete contractTokenIdToOwner[contractAddress][tokenId];

            // Transfer token to his owner
            _contract.instance.safeTransferFrom(address(this), msg.sender, tokenId);

            // Remove this token from user staked tokens
            addressToStakedTokensSet[contractAddress][msg.sender].remove(tokenId);

            // Remove stake timestamp
            delete contractTokenIdToStakedTimestamp[contractAddress][tokenId];

            emit Unstake(tokenId, contractAddress, msg.sender);
        }
    }

    function stakedTokensOfOwner(address contractAddress, address owner) external view ifContractExists(contractAddress) returns (uint[] memory) {
        EnumerableSet.UintSet storage userTokens = addressToStakedTokensSet[contractAddress][owner];

        uint[] memory tokenIds = new uint[](userTokens.length());

        for (uint i = 0; i < userTokens.length(); i++) {
            tokenIds[i] = userTokens.at(i);
        }

        return tokenIds;
    }

    function stakedTokenTimestamp(address contractAddress, uint tokenId) external view ifContractExists(contractAddress) returns (uint) {
        return contractTokenIdToStakedTimestamp[contractAddress][tokenId];
    }

    function withdrawFlush(uint amount, bytes calldata signature) external {
        require(_signerAddress == recoverAddress(msg.sender, amount, accountNonce(msg.sender), signature), "invalid signature");
        flush.transfer(msg.sender, amount);
        accountToNonce[msg.sender].increment();
        accountToLastWithdrawTimestamp[msg.sender] = block.timestamp;
        accountToLastWithdrawAmount[msg.sender] = amount;
        emit Withdraw(msg.sender, accountToNonce[msg.sender].current() - 1, amount);
    }

    function addContract(address contractAddress) public onlyOwner {
        contracts[contractAddress].active = true;
        contracts[contractAddress].instance = IERC721(contractAddress);
        activeContracts.add(contractAddress);
    }

    function updateContract(address contractAddress, bool active) public onlyOwner ifContractExists(contractAddress) {
        require(activeContracts.contains(contractAddress), "contract not added");
        contracts[contractAddress].active = active;
    }

    function accountNonce(address accountAddress) public view returns (uint) {
        return accountToNonce[accountAddress].current();
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function _hash(address account, uint amount, uint nonce) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Flush(uint256 amount,address account,uint256 nonce)"),
                        amount,
                        account,
                        nonce
                    )
                )
            );
    }

    function recoverAddress(address account, uint amount, uint nonce, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, amount, nonce), signature);
    }

    function onERC721Received(address _operator, address, uint256, bytes calldata) external returns(bytes4) {
        require(_operator == address(this), "token must be staked over stake method");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}