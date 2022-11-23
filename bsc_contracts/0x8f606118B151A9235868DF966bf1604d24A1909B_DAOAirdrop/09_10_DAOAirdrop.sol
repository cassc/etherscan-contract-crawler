//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.9;

import './interfaces/IDAOFactory.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract DAOAirdrop {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public immutable factoryAddress;
    mapping(uint256 => Airdrop) public airdrops;
    mapping(uint256 => mapping(address => bool)) private claimedMap;

    constructor(address factoryAddress_) {
        factoryAddress = factoryAddress_;
    }

    struct Airdrop {
        address token;
        uint256 tokenStaked;
        uint256 tokenClaimed;
        bytes32 merkleRoot;
        uint256 startTime;
        uint256 endTime;

        address creator;
    }

    event CreateAirdrop(
        address indexed creator,
        uint256 indexed airdropId,
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    );
    event SettleAirdrop(
        uint256 indexed airdropId,
        uint256 amount,
        bytes32 merkleTreeRoot
    );
    event Claimed(
        uint256 indexed airdropId,
        uint256 index,
        address account,
        uint256 amount
    );

    function createAirdrop(
        uint256 airdropId_,
        address token_,
        uint256 amount_,
        uint256 startTime_,
        uint256 endTime_,
        bytes calldata signature_
    ) external payable {
        require(airdrops[airdropId_].creator == address(0), 'DAOAirdrop: duplicate airdrop id.');
        require(endTime_ > startTime_, 'DAOAirdrop: invalid time.');

        bytes32 _hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    block.chainid,
                    msg.sender,
                    airdropId_
                )
            )
        );
        require(IDAOFactory(factoryAddress).isSigner(ECDSAUpgradeable.recover(_hash, signature_)), 'DAOAirdrop: invalid signer.');
        if (token_ == address(0)) {
            require(msg.value == amount_, 'DAOAirdrop: invalid amount.');
        } else {
            IERC20Upgradeable(token_).safeTransferFrom(msg.sender, address(this), amount_);
        }

        airdrops[airdropId_] = Airdrop({
            token: token_,
            tokenStaked: amount_,
            tokenClaimed: 0,
            merkleRoot: bytes32(0),
            startTime: startTime_,
            endTime: endTime_,
            creator: msg.sender
        });

        emit CreateAirdrop(msg.sender, airdropId_, token_, amount_, startTime_, endTime_);
    }

    function settleAirdrop(uint256 airdropId_, uint256 amount_, bytes32 merkleRoot_) external payable {
        Airdrop memory _airdrop = airdrops[airdropId_];
        require(_airdrop.creator == msg.sender, 'DAOAirdrop: not the creator.');
        require(_airdrop.merkleRoot == bytes32(0), 'DAOAirdrop: already settle.');

        if (amount_ > _airdrop.tokenStaked) {
            if (_airdrop.token == address(0)) {
                require(msg.value == amount_ - _airdrop.tokenStaked, 'DAOAirdrop: invalid amount.');
            } else {
                IERC20Upgradeable(_airdrop.token).safeTransferFrom(msg.sender, address(this), amount_ - _airdrop.tokenStaked);
            }
        }

        airdrops[airdropId_].tokenStaked = amount_;
        airdrops[airdropId_].merkleRoot = merkleRoot_;

        emit SettleAirdrop(airdropId_, amount_, merkleRoot_);
    }

    function isClaimed(uint256 airdropId_, address account_) public view returns (bool) {
        return claimedMap[airdropId_][account_];
    }

    function _setClaimed(uint256 airdropId_, address account_, uint256 amount_) private {
        claimedMap[airdropId_][account_] = true;
        airdrops[airdropId_].tokenClaimed += amount_;
    }

    function claimAirdrop(uint256 airdropId_, uint256 index_, address account_, uint256 amount_, bytes32[] calldata merkleProof_) external {
        Airdrop memory _airdrop = airdrops[airdropId_];
        require(_airdrop.creator != address(0), 'DAOAirdrop: not a valid airdrop id.');
        require(block.timestamp > _airdrop.startTime, 'DAOAirdrop: cannot claim yet.');
        require(block.timestamp <= _airdrop.endTime, 'DAOAirdrop: airdrop already done.');
        require(!isClaimed(airdropId_, account_), 'DAOAirdrop: drop already claimed.');
        require(_airdrop.merkleRoot != bytes32(0), 'DAOAirdrop: not settle.');
        require(_airdrop.tokenClaimed + amount_ <= _airdrop.tokenStaked, 'DAOAirdrop: insufficient funds.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index_, account_, amount_));
        require(MerkleProofUpgradeable.verify(merkleProof_, _airdrop.merkleRoot, node), 'DAOAirdrop: invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(airdropId_, account_, amount_);
        if (_airdrop.token == address(0)) {
            AddressUpgradeable.sendValue(payable(account_), amount_);
        } else {
            IERC20Upgradeable(_airdrop.token).safeTransfer(account_, amount_);
        }

        emit Claimed(airdropId_, index_, account_, amount_);
    }

    function recycleAirdrop(uint256 airdropId_) external {
        Airdrop memory _airdrop = airdrops[airdropId_];
        require(_airdrop.creator == msg.sender, 'DAOAirdrop: not the creator.');
        require(block.timestamp > _airdrop.endTime, 'DAOAirdrop: cannot recycle yet.');
        require(_airdrop.tokenStaked > _airdrop.tokenClaimed, 'DAOAirdrop: claimed out.');

        uint256 _reserve = _airdrop.tokenStaked - _airdrop.tokenClaimed;
        airdrops[airdropId_].tokenClaimed = _airdrop.tokenStaked;
        if (_airdrop.token == address(0)) {
            AddressUpgradeable.sendValue(payable(msg.sender), _reserve);
        } else {
            IERC20Upgradeable(_airdrop.token).safeTransfer(_airdrop.creator, _reserve);
        }
    }

}