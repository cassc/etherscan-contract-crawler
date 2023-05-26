// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract YgmeStakingDomain {
    struct StakingData {
        address owner;
        bool stakedState;
        uint128 startTime;
        uint128 endTime;
    }

    event Staking(
        address indexed account,
        uint256 indexed tokenId,
        address indexed nftContract,
        uint256 startTime,
        uint256 endTime,
        uint256 pledgeType
    );

    event WithdrawERC20(uint256 orderId, address account, uint256 amount);
}

contract YgmeStaking is
    YgmeStakingDomain,
    Pausable,
    Ownable,
    ERC721Holder,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    uint64 public constant ONE_CYCLE = 1 days;

    uint64[3] private stakingPeriods;

    IERC721 public immutable ygme;

    IERC20 public immutable ygio;

    address private withdrawSigner;

    mapping(uint256 => StakingData) public stakingDatas;

    mapping(address => uint256[]) private stakingTokenIds;

    mapping(uint256 => bool) public orderIsInvalid;

    uint128 public accountTotal;

    uint128 public ygmeTotal;

    constructor(address _ygme, address _ygio, address _withdrawSigner) {
        ygme = IERC721(_ygme);
        ygio = IERC20(_ygio);
        withdrawSigner = _withdrawSigner;
        stakingPeriods = [30 * ONE_CYCLE, 60 * ONE_CYCLE, 90 * ONE_CYCLE];
    }

    function setPause() external onlyOwner {
        if (!paused()) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setStakingPeriods(uint64[3] calldata _days) external onlyOwner {
        for (uint i = 0; i < _days.length; i++) {
            stakingPeriods[i] = _days[i] * ONE_CYCLE;
        }
    }

    function setWithdrawSigner(address _withdrawSigner) external onlyOwner {
        withdrawSigner = _withdrawSigner;
    }

    function getStakingTokenIds(
        address _account
    ) external view returns (uint256[] memory) {
        return stakingTokenIds[_account];
    }

    function getStakingPeriods()
        external
        view
        onlyOwner
        returns (uint64[3] memory)
    {
        return stakingPeriods;
    }

    function getWithdrawSigner() external view onlyOwner returns (address) {
        return withdrawSigner;
    }

    function staking(
        uint256[] calldata _tokenIds,
        uint256 _stakeDays
    ) external whenNotPaused nonReentrant returns (bool) {
        uint256 length = _tokenIds.length;
        uint256 _stakeTime = _stakeDays * ONE_CYCLE;
        address _account = _msgSender();

        require(length > 0, "Invalid tokenIds");

        require(
            _stakeTime == stakingPeriods[0] ||
                _stakeTime == stakingPeriods[1] ||
                _stakeTime == stakingPeriods[2],
            "Invalid stake time"
        );

        if (stakingTokenIds[_account].length == 0) {
            unchecked {
                accountTotal += 1;
            }
        }

        for (uint256 i = 0; i < length; ++i) {
            uint256 _tokenId = _tokenIds[i];

            require(!stakingDatas[_tokenId].stakedState, "Invalid stake state");

            require(ygme.ownerOf(_tokenId) == _account, "Invalid owner");

            StakingData memory _data = StakingData({
                owner: _account,
                stakedState: true,
                startTime: uint128(block.timestamp),
                endTime: uint128(block.timestamp + _stakeTime)
            });

            stakingDatas[_tokenId] = _data;

            if (stakingTokenIds[_account].length == 0) {
                stakingTokenIds[_account] = [_tokenId];
            } else {
                stakingTokenIds[_account].push(_tokenId);
            }

            ygme.safeTransferFrom(_account, address(this), _tokenId);

            emit Staking(
                _account,
                _tokenId,
                address(ygme),
                _data.startTime,
                _data.endTime,
                1
            );
        }

        unchecked {
            ygmeTotal += uint128(length);
        }

        return true;
    }

    function unStake(
        uint256[] calldata _tokenIds
    ) external whenNotPaused nonReentrant returns (bool) {
        uint256 length = _tokenIds.length;

        address _account = _msgSender();

        require(length > 0, "Invalid tokenIds");

        for (uint256 i = 0; i < length; ++i) {
            uint256 _tokenId = _tokenIds[i];

            StakingData memory _data = stakingDatas[_tokenId];

            require(_data.owner == _account, "Invalid account");

            require(_data.stakedState, "Invalid stake state");

            require(block.timestamp >= _data.endTime, "Too early to unStake");

            uint256 _len = stakingTokenIds[_account].length;

            for (uint256 j = 0; j < _len; ++j) {
                if (stakingTokenIds[_account][j] == _tokenId) {
                    stakingTokenIds[_account][j] = stakingTokenIds[_account][
                        _len - 1
                    ];
                    stakingTokenIds[_account].pop();
                    break;
                }
            }

            emit Staking(
                _account,
                _tokenId,
                address(ygme),
                _data.startTime,
                block.timestamp,
                2
            );

            delete stakingDatas[_tokenId];

            ygme.safeTransferFrom(address(this), _account, _tokenId);
        }

        if (stakingTokenIds[_account].length == 0) {
            accountTotal -= 1;
        }

        ygmeTotal -= uint128(length);

        return true;
    }

    function unStakeOnlyOwner(uint256[] calldata _tokenIds) external onlyOwner {
        uint256 length = _tokenIds.length;

        for (uint256 i = 0; i < length; ++i) {
            uint256 _tokenId = _tokenIds[i];

            StakingData memory _data = stakingDatas[_tokenId];

            address _account = _data.owner;

            require(_data.stakedState, "Invalid stake state");

            uint256 _len = stakingTokenIds[_account].length;

            for (uint256 j = 0; j < _len; ++j) {
                if (stakingTokenIds[_account][j] == _tokenId) {
                    stakingTokenIds[_account][j] = stakingTokenIds[_account][
                        _len - 1
                    ];

                    stakingTokenIds[_account].pop();

                    break;
                }
            }

            emit Staking(
                _account,
                _tokenId,
                address(ygme),
                _data.startTime,
                block.timestamp,
                3
            );

            delete stakingDatas[_tokenId];

            ygme.safeTransferFrom(address(this), _account, _tokenId);

            if (stakingTokenIds[_account].length == 0) {
                accountTotal -= 1;
            }
        }

        ygmeTotal -= uint128(length);
    }

    // TODO: data = abi.encode(orderId, account, amount)
    function withdrawERC20(
        bytes calldata data,
        bytes calldata signature
    ) external nonReentrant returns (bool) {
        require(data.length > 0, "Invalid data");

        bytes32 hash = keccak256(data);

        _verifySignature(hash, signature);

        (uint256 orderId, address account, uint256 amount) = abi.decode(
            data,
            (uint256, address, uint256)
        );

        require(!orderIsInvalid[orderId], "Invalid orderId");

        require(account == _msgSender(), "Invalid account");

        orderIsInvalid[orderId] = true;

        ygio.safeTransfer(account, amount);

        emit WithdrawERC20(orderId, account, amount);

        return true;
    }

    function _verifySignature(
        bytes32 hash,
        bytes calldata signature
    ) internal view {
        hash = hash.toEthSignedMessageHash();

        address signer = hash.recover(signature);

        require(signer == withdrawSigner, "Invalid signature");
    }
}