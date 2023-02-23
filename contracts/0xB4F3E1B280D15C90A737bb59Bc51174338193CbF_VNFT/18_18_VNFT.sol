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

    event NFTMinted(uint256 _tokenId);
    event NFTBurned(uint256 _tokenId);
    event BaseURIChanged(string _before, string _after);
    event LiquidStakingChanged(address _before, address _after);

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer initializerERC721A {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __ERC721A_init("Validator NFT", "vNFT");
    }

    modifier onlyLiquidStaking() {
        require(liquidStakingContractAddress == msg.sender, "Not allowed to mint/burn nft");
        _;
    }

    /**
     * @notice Returns the validators that are active (may contain validator that are yet active on beacon chain)
     */
    function activeValidators() external view returns (bytes[] memory) {
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

            _validators[tokenIdsIdx++] = validators[i].pubkey;
        }

        return _validators;
    }

    /**
     * @notice Returns the tokenId that are active (may contain validator that are yet active on beacon chain)
     */
    function activeNfts() external view returns (uint256[] memory) {
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

            _nfts[tokenIdsIdx++] = i;
        }

        return _nfts;
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
        require(_pubkey.length != 0, "Invalid pubkey");
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
        require(_exists(_tokenId), "Token does not exist");

        return validators[_tokenId].initHeight;
    }

    /**
     * @notice Returns the last owner before the nft is burned
     * @param _tokenId - tokenId of the validator nft
     */
    function lastOwnerOf(uint256 _tokenId) external view returns (address) {
        require(_ownershipAt(_tokenId).burned, "Token not burned yet");

        return lastOwners[_tokenId];
    }

    /**
     * @notice Mints a Validator nft (vNFT)
     * @param _pubkey -  A 48 bytes representing the validator's public key
     * @param _to - The recipient of the nft
     * @param _operatorId - The operator repsonsible for operating the physical node
     */
    function whiteListMint(bytes calldata _pubkey, address _to, uint256 _operatorId)
        external
        onlyLiquidStaking
        returns (uint256)
    {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceed MAX_SUPPLY");

        uint256 nextTokenId = _nextTokenId();
        if (_pubkey.length == 0) {
            emptyNftCounts += 1;
            operatorEmptyNfts[_operatorId].push(nextTokenId);
        } else {
            require(validatorRecords[_pubkey] == 0, "Pub key already in used");
            validatorRecords[_pubkey] = _operatorId;

            if (operatorEmptyNfts[_operatorId].length != operatorEmptyNftIndex[_operatorId]) {
                uint256 tokenId = operatorEmptyNfts[_operatorId][operatorEmptyNftIndex[_operatorId]];
                operatorEmptyNftIndex[_operatorId] += 1;
                validators[tokenId].pubkey = _pubkey;
                emptyNftCounts -= 1;
                return tokenId;
            }
        }

        validators.push(Validator({operatorId: _operatorId, initHeight: block.number, pubkey: _pubkey}));
        operatorRecords[_operatorId] += 1;

        _safeMint(_to, 1);
        emit NFTMinted(nextTokenId);

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
    }

    /**
     * @notice Get the number of operator's nft
     * @param _operatorId - operator id
     */
    function getNftCountsOfOperator(uint256 _operatorId) external view returns (uint256) {
        return operatorRecords[_operatorId];
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
        require(_liquidStakingContractAddress != address(0), "LiquidStaking address invalid");
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