// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "ERC721A-Upgradeable/extensions/ERC721AQueryableUpgradeable.sol";

/**
 * @title NodeDao vNFT Contract
 */
contract VNFT is
    Initializable,
    OwnableUpgradeable,
    ERC721AQueryableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    address public liquidStakingContractAddress;

    uint256 public constant MAX_SUPPLY = 6942069420;

    struct Validator {
        uint256 operatorId;
        uint256 initHeight;
        bytes pubkey;
    }

    Validator[] public validators;

    // key is pubkey, value is operator_id
    mapping(bytes => uint256) public validatorRecords;
    // key is operator_id, value is token counts
    mapping(uint256 => uint256) public operatorRecords;

    // Empty nft belonging to operator, not yet filled with pubkey
    mapping(uint256 => uint256[]) public operatorEmptyNfts;
    mapping(uint256 => uint256) public operatorEmptyNftIndex;
    // empty nft counts
    uint256 internal emptyNftCounts;

    // Record the last owner when nft burned
    mapping(uint256 => address) public lastOwners;

    // v2 storage
    // key is tokenId, value is withdrawalCredentials
    mapping(uint256 => bytes) internal userNftWithdrawalCredentials;
    // key is tokenId, value is blockNumber
    mapping(uint256 => uint256) internal userNftExitBlockNumbers;
    // key is operatorId, value is nft ExitButNoBurn counts
    mapping(uint256 => uint256) internal operatorExitButNoBurnNftCounts;
    // key is tokenId, value is gasHeight
    mapping(uint256 => uint256) internal userNftGasHeights;
    // key is operatorId, value is nft counts
    mapping(uint256 => uint256) internal userActiceNftCounts;

    uint256 public totalExitButNoBurnNftCounts;

    event NFTMinted(uint256 _tokenId, bytes withdrawalCredentials);
    event NFTBurned(uint256 _tokenId);
    event BaseURIChanged(string _before, string _after);
    event LiquidStakingChanged(address _before, address _after);

    error PermissionDenied();
    error InvalidPubkey();
    error TokenNotExist();
    error TokenNotBurned();
    error ExceedMaxSupply();
    error PubkeyAlreadyUsed();
    error WithdrawalCredentialsEmpty();
    error WithdrawalCredentialsMismatch();
    error TokenAlreadyReport();
    error InvalidBlockHeight();
    error NotBelongUserNft();
    error InvalidAddr();

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer initializerERC721A {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __ERC721A_init("Validator NFT", "vNFT");
    }

    modifier onlyLiquidStaking() {
        if (liquidStakingContractAddress != msg.sender) revert PermissionDenied();
        _;
    }

    /**
     * @notice Returns the validators that are active (may contain validator that are yet active on beacon chain)
     */
    function activeValidatorOfUser() external view returns (bytes[] memory) {
        return _activeValidator(true);
    }

    /**
     * @notice Returns the validators that are active (may contain validator that are yet active on beacon chain)
     */
    function activeValidatorsOfStakingPool() external view returns (bytes[] memory) {
        return _activeValidator(false);
    }

    function _activeValidator(bool isUser) internal view returns (bytes[] memory) {
        uint256 total = _nextTokenId();
        uint256 activeCounts = 0;
        TokenOwnership memory ownership;

        for (uint256 i = _startTokenId(); i < total; ++i) {
            ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }

            if (keccak256(validators[i].pubkey) == keccak256(bytes(""))) {
                continue;
            }

            if (isUser) {
                if (userNftWithdrawalCredentials[i].length == 0) {
                    continue;
                }
            } else {
                if (userNftWithdrawalCredentials[i].length != 0) {
                    continue;
                }
            }

            activeCounts += 1;
        }

        uint256 tokenIdsIdx = 0;
        bytes[] memory _validators = new bytes[](activeCounts);
        for (uint256 i = _startTokenId(); i < total; ++i) {
            ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }

            if (keccak256(validators[i].pubkey) == keccak256(bytes(""))) {
                continue;
            }

            if (isUser) {
                if (userNftWithdrawalCredentials[i].length == 0) {
                    continue;
                }
            } else {
                if (userNftWithdrawalCredentials[i].length != 0) {
                    continue;
                }
            }

            _validators[tokenIdsIdx++] = validators[i].pubkey;
        }

        return _validators;
    }

    /**
     * @notice Returns the tokenId that are active (may contain validator that are yet active on beacon chain)
     */
    function activeNftsOfUser() external view returns (uint256[] memory) {
        return _activeNfts(true);
    }

    /**
     * @notice Returns the tokenId that are active (may contain validator that are yet active on beacon chain)
     */
    function activeNftsOfStakingPool() external view returns (uint256[] memory) {
        return _activeNfts(false);
    }

    function _activeNfts(bool isUser) internal view returns (uint256[] memory) {
        uint256 total = _nextTokenId();
        uint256 activeCounts = 0;
        TokenOwnership memory ownership;

        for (uint256 i = _startTokenId(); i < total; ++i) {
            ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }

            if (keccak256(validators[i].pubkey) == keccak256(bytes(""))) {
                continue;
            }
            if (isUser) {
                if (userNftWithdrawalCredentials[i].length == 0) {
                    continue;
                }
            } else {
                if (userNftWithdrawalCredentials[i].length != 0) {
                    continue;
                }
            }

            activeCounts += 1;
        }

        uint256 tokenIdsIdx = 0;
        uint256[] memory _nfts = new uint256[](activeCounts);
        for (uint256 i = _startTokenId(); i < total; ++i) {
            ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }

            if (keccak256(validators[i].pubkey) == keccak256(bytes(""))) {
                continue;
            }

            if (isUser) {
                if (userNftWithdrawalCredentials[i].length == 0) {
                    continue;
                }
            } else {
                if (userNftWithdrawalCredentials[i].length != 0) {
                    continue;
                }
            }

            _nfts[tokenIdsIdx++] = i;
        }

        return _nfts;
    }

    /**
     * @notice Get the number of total active nft counts
     */
    function getTotalActiveNftCounts() external view returns (uint256) {
        return totalSupply() - totalExitButNoBurnNftCounts - emptyNftCounts;
    }

    /**
     * @notice get empty nft counts
     */
    function getEmptyNftCounts() external view returns (uint256) {
        return emptyNftCounts;
    }

    /**
     * @notice Checks if a validator exists
     * @param _pubkey - A 48 bytes representing the validator's public key
     */
    function validatorExists(bytes calldata _pubkey) external view returns (bool) {
        return validatorRecords[_pubkey] != 0;
    }

    /**
     * @notice Finds the validator's public key of a nft
     * @param _tokenId - tokenId of the validator nft
     */
    function validatorOf(uint256 _tokenId) external view returns (bytes memory) {
        return validators[_tokenId].pubkey;
    }

    /**
     * @notice Finds the operator id of a nft
     * @param _tokenId - tokenId of the validator nft
     */
    function operatorOf(uint256 _tokenId) external view returns (uint256) {
        return validators[_tokenId].operatorId;
    }

    /**
     * @notice Finds all the validator's public key of a particular address
     * @param _owner - The particular address
     */
    function validatorsOfOwner(address _owner) external view returns (bytes[] memory) {
        unchecked {
            //slither-disable-next-line uninitialized-local
            uint256 tokenIdsIdx;
            //slither-disable-next-line uninitialized-local
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(_owner);
            bytes[] memory pubkeys = new bytes[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == _owner) {
                    pubkeys[tokenIdsIdx++] = validators[i].pubkey;
                }
            }
            return pubkeys;
        }
    }

    /**
     * @notice Finds the tokenId of a validator
     * @dev Returns MAX_SUPPLY if not found
     * @param _pubkey - A 48 bytes representing the validator's public key
     */

    function tokenOfValidator(bytes calldata _pubkey) external view returns (uint256) {
        if (_pubkey.length == 0) revert InvalidPubkey();
        for (uint256 i = 0; i < validators.length; ++i) {
            if (keccak256(validators[i].pubkey) == keccak256(_pubkey) && _exists(i)) {
                return i;
            }
        }
        return MAX_SUPPLY;
    }

    /**
     * @notice Finds all the validator's public key of a particular operator
     * @param _operatorId - The particular address of the operator
     */
    function validatorsOfOperator(uint256 _operatorId) external view returns (bytes[] memory) {
        uint256 total = _nextTokenId();
        uint256 tokenIdsIdx;
        bytes[] memory _validators = new bytes[](total);
        TokenOwnership memory ownership;

        for (uint256 i = _startTokenId(); i < total; ++i) {
            ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (validatorRecords[validators[i].pubkey] == _operatorId) {
                _validators[tokenIdsIdx++] = validators[i].pubkey;
            }
        }

        return _validators;
    }

    /**
     * @notice Returns the init height of the tokenId
     * @param _tokenId - tokenId of the validator nft
     */
    function initHeightOf(uint256 _tokenId) external view returns (uint256) {
        if (!_exists(_tokenId)) revert TokenNotExist();

        return validators[_tokenId].initHeight;
    }

    /**
     * @notice Returns the last owner before the nft is burned
     * @param _tokenId - tokenId of the validator nft
     */

    function lastOwnerOf(uint256 _tokenId) external view returns (address) {
        if (!_ownershipAt(_tokenId).burned) revert TokenNotBurned();

        return lastOwners[_tokenId];
    }

    /**
     * @notice Mints a Validator nft (vNFT)
     * @param _pubkey -  A 48 bytes representing the validator's public key
     * @param _to - The recipient of the nft
     * @param _operatorId - The operator repsonsible for operating the physical node
     */

    function whiteListMint(
        bytes calldata _pubkey,
        bytes calldata _withdrawalCredentials,
        address _to,
        uint256 _operatorId
    ) external onlyLiquidStaking returns (uint256) {
        if (totalSupply() + 1 > MAX_SUPPLY) revert ExceedMaxSupply();

        uint256 nextTokenId = _nextTokenId();
        if (_pubkey.length == 0) {
            emptyNftCounts += 1;
            operatorEmptyNfts[_operatorId].push(nextTokenId);

            if (_withdrawalCredentials.length == 0) revert WithdrawalCredentialsEmpty();
            userNftWithdrawalCredentials[nextTokenId] = _withdrawalCredentials;
        } else {
            if (validatorRecords[_pubkey] != 0) revert PubkeyAlreadyUsed();
            validatorRecords[_pubkey] = _operatorId;

            uint256[] memory emptyNfts = operatorEmptyNfts[_operatorId];
            for (uint256 i = operatorEmptyNftIndex[_operatorId]; i < emptyNfts.length; ++i) {
                uint256 tokenId = emptyNfts[i];
                if (_ownershipAt(tokenId).burned) {
                    // When the nft has not been filled, it is unstaked by the user
                    continue;
                }
                // check withdrawal credentials before filling
                if (keccak256(userNftWithdrawalCredentials[tokenId]) != keccak256(_withdrawalCredentials)) {
                    revert WithdrawalCredentialsMismatch();
                }

                operatorEmptyNftIndex[_operatorId] = i + 1;
                validators[tokenId].pubkey = _pubkey;
                emptyNftCounts -= 1;
                userNftGasHeights[tokenId] = block.number;
                userActiceNftCounts[_operatorId] += 1;

                return tokenId;
            }
        }

        validators.push(Validator({operatorId: _operatorId, initHeight: block.number, pubkey: _pubkey}));
        operatorRecords[_operatorId] += 1;

        _safeMint(_to, 1);
        emit NFTMinted(nextTokenId, _withdrawalCredentials);

        return nextTokenId;
    }

    /**
     * @notice Burns a Validator nft (vNFT)
     * @param _tokenId - tokenId of the validator nft
     */
    function whiteListBurn(uint256 _tokenId) external onlyLiquidStaking {
        lastOwners[_tokenId] = ownerOf(_tokenId);
        _burn(_tokenId);
        emit NFTBurned(_tokenId);
        operatorRecords[validators[_tokenId].operatorId] -= 1;

        if (keccak256(validators[_tokenId].pubkey) == keccak256(bytes(""))) {
            emptyNftCounts -= 1;
        }

        if (userNftExitBlockNumbers[_tokenId] != 0) {
            operatorExitButNoBurnNftCounts[validators[_tokenId].operatorId] -= 1;
            totalExitButNoBurnNftCounts -= 1;
        }
    }

    /**
     * @notice Obtain the withdrawal voucher used by tokenid,
     * if it is bytes(""), it means it is not the user's nft, and the voucher will be the withdrawal contract address of the nodedao protocol
     * @param _tokenId - tokenId
     */
    function getUserNftWithdrawalCredentialOfTokenId(uint256 _tokenId) external view returns (bytes memory) {
        return userNftWithdrawalCredentials[_tokenId];
    }

    /**
     * @notice The operator obtains the withdrawal voucher to be used for the next registration of the validator.
     *  // If it is bytes (""), it means that it is not the user's NFT, and the voucher will be the withdrawal contract address of the nodedao protocol.
     * @param _operatorId - operatorId
     */
    function getNextValidatorWithdrawalCredential(uint256 _operatorId) external view returns (bytes memory) {
        uint256[] memory emptyNfts = operatorEmptyNfts[_operatorId];
        for (uint256 i = operatorEmptyNftIndex[_operatorId]; i < emptyNfts.length; ++i) {
            uint256 tokenId = emptyNfts[i];
            if (_ownershipAt(tokenId).burned) {
                continue;
            }

            return userNftWithdrawalCredentials[tokenId];
        }

        return bytes("");
    }

    function getMultipleValidatorWithdrawalCredentials(uint256 _operatorId, uint256 _number)
        external
        view
        returns (bytes[] memory)
    {
        bytes[] memory withdrawalCredentials = new bytes[] (_number);
        uint256 i = 0;
        uint256[] memory emptyNfts = operatorEmptyNfts[_operatorId];
        for (uint256 j = operatorEmptyNftIndex[_operatorId]; j < emptyNfts.length; ++j) {
            uint256 tokenId = emptyNfts[j];
            if (_ownershipAt(tokenId).burned) {
                continue;
            }

            withdrawalCredentials[i++] = userNftWithdrawalCredentials[tokenId];
            if (i == _number - 1) {
                break;
            }
        }

        for (i; i < _number - 1; ++i) {
            withdrawalCredentials[i] = bytes("");
        }

        return withdrawalCredentials;
    }

    /**
     * @notice set nft exit height
     * @param _tokenIds - tokenIds
     * @param _exitBlockNumbers - tokenIds
     */

    function setNftExitBlockNumbers(uint256[] memory _tokenIds, uint256[] memory _exitBlockNumbers)
        external
        onlyLiquidStaking
    {
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            if (userNftExitBlockNumbers[tokenId] != 0) revert TokenAlreadyReport();
            uint256 number = _exitBlockNumbers[i];
            if (number > block.number) revert InvalidBlockHeight();
            userNftExitBlockNumbers[tokenId] = number;
            operatorExitButNoBurnNftCounts[validators[tokenId].operatorId] += 1;
            totalExitButNoBurnNftCounts += 1;

            if (userNftWithdrawalCredentials[tokenId].length != 0) {
                // The user's nft has exited, but there is no claim, userActiceNftCounts needs to be updated
                userActiceNftCounts[validators[tokenId].operatorId] -= 1;
            }
        }
    }

    /**
     * @notice Get the number of nft exit height
     * @param _tokenIds - tokenIds
     */
    function getNftExitBlockNumbers(uint256[] memory _tokenIds) external view returns (uint256[] memory) {
        uint256[] memory numbers = new uint256[] (_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            numbers[i] = userNftExitBlockNumbers[tokenId];
        }

        return numbers;
    }

    /**
     * @notice set nft gas height
     * @param _tokenId - tokenId
     * @param _number - gas height
     */

    function setUserNftGasHeight(uint256 _tokenId, uint256 _number) external onlyLiquidStaking {
        if (userNftGasHeights[_tokenId] == 0) revert NotBelongUserNft();
        userNftGasHeights[_tokenId] = _number;
    }

    /**
     * @notice Get the number of user's nft gas height
     * @param _tokenIds - tokenIds
     */
    function getUserNftGasHeight(uint256[] memory _tokenIds) external view returns (uint256[] memory) {
        uint256[] memory gasHeights = new uint256[] (_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            if (userNftGasHeights[_tokenIds[i]] == 0) {
                gasHeights[i] = validators[_tokenIds[i]].initHeight;
            } else {
                gasHeights[i] = userNftGasHeights[_tokenIds[i]];
            }
        }

        return gasHeights;
    }

    /**
     * @notice Get the number of operator's nft
     * @param _operatorId - operator id
     */
    function getActiveNftCountsOfOperator(uint256 _operatorId) external view returns (uint256) {
        return operatorRecords[_operatorId] - operatorExitButNoBurnNftCounts[_operatorId]
            - (operatorEmptyNfts[_operatorId].length - operatorEmptyNftIndex[_operatorId]);
    }

    function getEmptyNftCountsOfOperator(uint256 _operatorId) external view returns (uint256) {
        return operatorEmptyNfts[_operatorId].length - operatorEmptyNftIndex[_operatorId];
    }

    /**
     * @notice Get the number of user's active nft
     * @param _operatorId - operator id
     */
    function getUserActiveNftCountsOfOperator(uint256 _operatorId) external view returns (uint256) {
        return userActiceNftCounts[_operatorId];
    }

    // // metadata URI
    string internal _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice set nft baseURI
     * @param _baseURI baseURI
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        emit BaseURIChanged(_baseTokenURI, _baseURI);
        _baseTokenURI = _baseURI;
    }

    /**
     * @notice set LiquidStaking contract address
     * @param _liquidStakingContractAddress contract address
     */
    function setLiquidStaking(address _liquidStakingContractAddress) external onlyOwner {
        if (_liquidStakingContractAddress == address(0)) revert InvalidAddr();
        emit LiquidStakingChanged(liquidStakingContractAddress, _liquidStakingContractAddress);
        liquidStakingContractAddress = _liquidStakingContractAddress;
    }

    /**
     * @notice Returns the number of tokens minted by `owner`.
     * @param _owner nft owner address
     */
    function numberMinted(address _owner) external view returns (uint256) {
        return _numberMinted(_owner);
    }

    ////////below is the new code//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.

        if (_operator == liquidStakingContractAddress) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}