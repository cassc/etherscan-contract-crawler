// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "erc721a/contracts/IERC721A.sol";

contract CrypticStaking is EIP712 {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    IERC721A private _mainContract = IERC721A(0xa76746C2dD0123cBd7a207064237b37447E0C2F0);
    IERC20 cryptoken = IERC20(0x31b47644018DaE72A22c77D202F6ddE84b607A32);

    mapping(uint => address) private _tokenIdToOwner;
    mapping(address => EnumerableSet.UintSet) private _addressToStakedTokensSet;
    mapping(uint => uint) private _tokenIdToStakedTimestamp;
    mapping(address => Counters.Counter) accountToNonce;

    event Stake(uint tokenId, address owner);
    event Unstake(uint tokenId, address owner);
    event Withdraw(address owner, uint amount);

    address private _signerAddress = 0xC6dC6F24E0eE70719F5dfe3430ec52E00e83B1C3;
    
    constructor() EIP712("CrypticStaking", "1.0.0") {
    }

    function stake(uint[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            // Assign token to his owner
            _tokenIdToOwner[tokenId] = msg.sender;

            // Transfer token to this smart contract
            _mainContract.safeTransferFrom(msg.sender, address(this), tokenId);

            // Add this token to user staked tokens
            _addressToStakedTokensSet[msg.sender].add(tokenId);

            // Save stake timestamp
            _tokenIdToStakedTimestamp[tokenId] = block.timestamp;

            emit Stake(tokenId, msg.sender);
        }
    }

    function unstake(uint[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            require(_addressToStakedTokensSet[msg.sender].contains(tokenId), "token is not staked");

            // Remove owner of this token
            delete _tokenIdToOwner[tokenId];

            // Transfer token to his owner
            _mainContract.safeTransferFrom(address(this), msg.sender, tokenId);

            // Remove this token from user staked tokens
            _addressToStakedTokensSet[msg.sender].remove(tokenId);

            // Remove stake timestamp
            delete _tokenIdToStakedTimestamp[tokenId];

            emit Unstake(tokenId, msg.sender);
        }
    }

    function withdrawCryptoken(uint amount, bytes calldata signature) external {
        require(_signerAddress == _recoverAddress(msg.sender, amount, accountNonce(msg.sender), signature), "invalid signature");

        uint[] memory tokenIds = stakedTokensOfOwner(msg.sender);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            _tokenIdToStakedTimestamp[tokenId] = block.timestamp;
        }

        cryptoken.transfer(msg.sender, amount);
        accountToNonce[msg.sender].increment();

        emit Withdraw(msg.sender, amount);
    }

    function accountNonce(address accountAddress) public view returns (uint) {
        return accountToNonce[accountAddress].current();
    }
    function stakedTokensOfOwner(address owner) public view returns (uint[] memory) {
        EnumerableSet.UintSet storage userTokens = _addressToStakedTokensSet[owner];
        return _uintSetToUintArray(userTokens);
    }

    function stakedTokenTimestamp(uint tokenId) public view returns (uint) {
        return _tokenIdToStakedTimestamp[tokenId];
    }

    function stakedTokenTimestamps(address account) public view returns (uint[] memory) {
        uint[] memory tokenIds = stakedTokensOfOwner(account);
        uint[] memory timestamps = new uint[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            timestamps[i] = stakedTokenTimestamp(tokenId);
        }

        return timestamps;
    }

    function currentTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function _hash(address account, uint amount, uint nonce) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("CrypticStaking(address account,uint256 amount,uint256 nonce)"),
                        account,
                        amount,
                        nonce
                    )
                )
            );
    }

    function _recoverAddress(address account, uint amount, uint nonce, bytes calldata signature) internal view returns(address) {
        return ECDSA.recover(_hash(account, amount, nonce), signature);
    }

    function onERC721Received(address operator, address, uint256, bytes calldata) external view returns(bytes4) {
        require(operator == address(this), "token must be staked over stake method");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _uintSetToUintArray(EnumerableSet.UintSet storage values) internal view returns (uint[] memory) {
        uint[] memory result = new uint[](values.length());

        for (uint i = 0; i < values.length(); i++) {
            result[i] = values.at(i);
        }

        return result;
    }
}