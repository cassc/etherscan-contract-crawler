// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {NFTReceiver} from "src/utils/NFTReceiver.sol";
import {Protoform} from "src/protoforms/Protoform.sol";

import {ICheckpoint, Stage} from "src/checks/interfaces/ICheckpoint.sol";
import {IChecks} from "src/checks/interfaces/IChecks.sol";
import {IERC721} from "src/interfaces/IERC721.sol";
import {IERC1155} from "src/interfaces/IERC1155.sol";
import {ISupply} from "src/interfaces/ISupply.sol";
import {IVaultRegistry, InitInfo} from "src/interfaces/IVaultRegistry.sol";

/// @title Checkpoint
/// @author Tessera
/// @notice Checks Protoform contract for reaching infinity
contract Checkpoint is ICheckpoint, Protoform, NFTReceiver {
    uint256 public constant MAX_SUPPLY = 4096;
    address public immutable registry;
    address public immutable checks;
    address public vault;
    uint88 public totalPoints;
    Stage public currentStage;
    mapping(address => uint256) public ownerToPoints;
    mapping(uint256 => address) public tokenIdToOwner;

    constructor(
        address _registry,
        address _supply,
        address _checks,
        address[] memory _modules
    ) {
        registry = _registry;
        checks = _checks;
        _deployVault(_supply, _modules);
    }

    function deposit(uint256[] calldata _tokenIds) external {
        if (currentStage != Stage.COLLECTING) revert InvalidStage(Stage.COLLECTING, currentStage);
        uint256 length = _tokenIds.length;

        unchecked {
            for (uint256 i; i < length; ++i) {
                uint256 tokenId = _tokenIds[i];
                IERC721(checks).transferFrom(msg.sender, address(this), tokenId);
                tokenIdToOwner[tokenId] = msg.sender;
                uint256 checkValue = getCheckValue(tokenId);
                ownerToPoints[msg.sender] += checkValue;
                totalPoints += uint88(checkValue);

                emit Deposit(msg.sender, tokenId, checkValue, totalPoints);
            }
        }

        if (totalPoints > MAX_SUPPLY) {
            revert TooManyPoints();
        } else if (totalPoints == MAX_SUPPLY) {
            currentStage = Stage.BURNING;
        }
    }

    function withdraw(uint256[] calldata _tokenIds) external {
        if (currentStage != Stage.COLLECTING) revert InvalidStage(Stage.COLLECTING, currentStage);
        uint256 length = _tokenIds.length;

        unchecked {
            for (uint256 i; i < length; ++i) {
                uint256 tokenId = _tokenIds[i];
                if (tokenIdToOwner[tokenId] != msg.sender) revert NotOwner();
                delete tokenIdToOwner[tokenId];
                IERC721(checks).transferFrom(address(this), msg.sender, tokenId);
                uint256 checkValue = getCheckValue(tokenId);
                ownerToPoints[msg.sender] -= checkValue;
                totalPoints -= uint88(checkValue);

                emit Withdraw(msg.sender, tokenId, checkValue, totalPoints);
            }
        }
    }

    function compositeMany(uint256[] calldata _tokenIds, uint256[] calldata _burnIds) external {
        if (currentStage != Stage.BURNING) revert InvalidStage(Stage.BURNING, currentStage);
        IChecks(checks).compositeMany(_tokenIds, _burnIds);

        emit CompositeMany(_tokenIds, _burnIds);
    }

    function infinity(uint256[] calldata _tokenIds) external {
        if (currentStage != Stage.BURNING) revert InvalidStage(Stage.BURNING, currentStage);
        uint256[] memory tokenIds = sort(_tokenIds, 0, _tokenIds.length);
        uint256 lowestId = tokenIds[0];

        IChecks(checks).infinity(tokenIds);
        IERC721(checks).transferFrom(address(this), vault, lowestId);
        currentStage = Stage.CLAIMING;

        emit Infinity(_tokenIds, lowestId);
    }

    function claim(address _owner) external {
        if (currentStage != Stage.CLAIMING) revert InvalidStage(Stage.CLAIMING, currentStage);
        uint256 points = ownerToPoints[_owner];
        delete ownerToPoints[_owner];

        (address rae, uint256 id) = IVaultRegistry(registry).vaultToToken(vault);
        IERC1155(rae).safeTransferFrom(address(this), _owner, id, points, "");

        emit Claim(msg.sender, points);
    }

    function getTotalValue(uint256[] calldata _tokenIds) external view returns (uint256 total) {
        uint256 length = _tokenIds.length;
        unchecked {
            for (uint256 i; i < length; ++i) {
                total += getCheckValue(_tokenIds[i]);
            }
        }
    }

    function getCheckValue(uint256 _tokenId) public view returns (uint256 value) {
        IChecks.Check memory check = IChecks(checks).getCheck(_tokenId);
        value = 2**check.stored.divisorIndex;
    }

    function sort(
        uint256[] memory _array,
        uint256 _begin,
        uint256 _last
    ) public pure returns (uint256[] memory) {
        if (_begin < _last) {
            uint256 j = _begin;
            uint256 pivot = _array[j];
            for (uint256 i = _begin + 1; i < _last; ) {
                if (_array[i] < pivot) _swap(_array, i, ++j);

                unchecked {
                    ++i;
                }
            }

            _swap(_array, _begin, j);
            sort(_array, _begin, j);
            sort(_array, j + 1, _last);
        }

        return _array;
    }

    function _swap(
        uint256[] memory _array,
        uint256 i,
        uint256 j
    ) internal pure {
        (_array[i], _array[j]) = (_array[j], _array[i]);
    }

    function _deployVault(address _supply, address[] memory _modules) private {
        bytes32[] memory leafNodes = generateMerkleTree(_modules);
        bytes32 merkleRoot = getRoot(leafNodes);

        InitInfo[] memory initInfo = new InitInfo[](1);
        initInfo[0] = InitInfo({
            target: _supply,
            data: abi.encodeCall(ISupply.mint, (address(this), MAX_SUPPLY)),
            proof: new bytes32[](0)
        });

        vault = IVaultRegistry(registry).create(merkleRoot, initInfo);

        emit ActiveModules(vault, _modules);
    }
}