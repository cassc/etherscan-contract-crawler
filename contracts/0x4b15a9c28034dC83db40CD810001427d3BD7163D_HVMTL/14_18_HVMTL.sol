// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/ERC721Lockable.sol";
import "./lib/Operator.sol";
import "./lib/IRegistry.sol";

//      |||||\          |||||\               |||||\          |||||\
//      ||||| |         ||||| |              ||||| |         ||||| |
//       \__|||||\  |||||\___\|               \__|||||\  |||||\___\|
//          ||||| | ||||| |                      ||||| | ||||| |
//           \__|||||\___\|       Y u g a         \__|||||\___\|
//              ||||| |             L a b s          ||||| |
//          |||||\___\|           H V M T L      |||||\___\|
//          ||||| |                              ||||| |
//           \__|||||||||||\                      \__|||||||||||\
//              ||||||||||| |                        ||||||||||| |
//               \_________\|                         \_________\|

error MintIsNotEnabled();
error NotAllowedToMint();
error NotAllowedToBurn();
error ContractIsLocked();
error UnableToLockContract();
error MaxTokensMinted();
error RegistryAddressIsNotSet();

/**
 * @title HV-MTL ERC-721 Smart Contract
 */
contract HVMTL is ERC721Lockable, Operator {
    using SafeERC20 for IERC20;

    uint128 public constant MAX_TOKENS = 30_000;
    uint128 private _totalSupply;
    uint256 public mintedSupply;
    address public registryAddress;
    bool public isMintEnabled;
    bool public isMintBatchEnabled;
    bool public isOwnerBurnEnabled;
    bool public isContractBurnEnabled;
    bool public isContractLocked;
    bool public isRegistryActive;
    string private baseURI;
    string public nftLicenseTerms = "mdvmm.xyz/hvmtl-license";
    bytes32 public metadataHash;
    mapping(address => bool) public minters;

    constructor(
        string memory name,
        string memory symbol,
        address operator
    ) ERC721(name, symbol) Operator(operator) {}

    modifier allowedToMint() {
        if (minters[msg.sender] == false) {
            revert NotAllowedToMint();
        }
        _;
    }

    /**
     * @notice mint one
     * can only be called by approved contracts
     * @param to address being minted to
     * @param tokenId id of the token
     */
    function mintOne(address to, uint256 tokenId) external allowedToMint {
        if (!isMintEnabled) revert MintIsNotEnabled();
        if (mintedSupply >= MAX_TOKENS) revert MaxTokensMinted();

        unchecked {
            ++_totalSupply;
            ++mintedSupply;
        }
        _safeMint(to, tokenId);
    }

    /**
     * @notice mint many
     * can only be called by approved contracts
     * @param to address being minted to
     * @param startTokenId id of the first token
     * @param quantity amount to mint
     */
    function mintBatch(
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) external allowedToMint {
        if (!isMintBatchEnabled) revert MintIsNotEnabled();
        if (mintedSupply + quantity > MAX_TOKENS) revert MaxTokensMinted();

        uint256 endTokenId = startTokenId + quantity;
        for (startTokenId; startTokenId < endTokenId; ) {
            uint256 tempIndex = startTokenId;

            unchecked {
                ++startTokenId;
                ++mintedSupply;
                ++_totalSupply;
            }
            _safeMint(to, tempIndex);
        }
    }

    /**
     * @notice check if token id exists
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice get the total supply of tokens
     */
    function totalSupply() external view returns (uint128) {
        return _totalSupply;
    }

    // operator functions

    /**
     * @notice turn mint on or off
     */
    function setIsMintEnabled(bool isEnabled) external onlyOperator {
        if (isContractLocked) revert ContractIsLocked();
        isMintEnabled = isEnabled;
    }

    /**
     * @notice turn batch mint on or off
     */
    function setIsMintBatchEnabled(bool isEnabled) external onlyOperator {
        if (isContractLocked) revert ContractIsLocked();
        isMintBatchEnabled = isEnabled;
    }

    /**
     * @notice turn token burning by owner on or off
     */
    function setIsOwnerBurnEnabled(bool isEnabled) external onlyOperator {
        if (isContractLocked) revert ContractIsLocked();
        isOwnerBurnEnabled = isEnabled;
    }

    /**
     * @notice turn token burning by contract on or off
     */
    function setIsContractBurnEnabled(bool isEnabled) external onlyOperator {
        if (isContractLocked) revert ContractIsLocked();
        isContractBurnEnabled = isEnabled;
    }

    /**
     * @notice lock the contract - stops minting, contract burn,
     *   setting burn states, and adding minters.
     * KILL SWITCH - THIS CAN'T BE REVERSED
     */
    function lockContract() external onlyOperator {
        if (isMintEnabled || isMintBatchEnabled) revert UnableToLockContract();
        isContractLocked = true;
    }

    /**
     * @notice set the token lock contract
     * @param _tokenLockContract address of contract
     * @param isEnabled enables or disables token locking
     */
    function setTokenLockContract(
        address _tokenLockContract,
        bool isEnabled
    ) external onlyOperator {
        if (isContractLocked) revert ContractIsLocked();
        _addContractAllowedToLock(_tokenLockContract, isEnabled);
    }

    /**
     * @notice set base uri of metadata
     * @param uri the base uri
     */
    function setBaseURI(string memory uri) external onlyOperator {
        baseURI = uri;
    }

    /**
     * @notice set the metadata provenance hash
     * @param _metadataHash the provenance hash
     */
    function setMetadataHash(bytes32 _metadataHash) external onlyOperator {
        metadataHash = _metadataHash;
    }

    /**
     * @notice set NFT License URI
     * @param _nftLicenseUri the uri of the license
     */
    function setNftLicenseTerms(
        string memory _nftLicenseUri
    ) external onlyOperator {
        nftLicenseTerms = _nftLicenseUri;
    }

    /**
     * @notice toggle the minting ability of a minter or burner contract
     * @param _minterContract address of contract
     */
    function toggleMinterContract(
        address _minterContract
    ) external onlyOperator {
        if (isContractLocked) revert ContractIsLocked();
        minters[_minterContract] = !minters[_minterContract];
    }

    /**
     * @notice set the registry contract
     * @param _registryAddress contract address for registry
     */
    function setRegistryAddress(
        address _registryAddress
    ) external onlyOperator {
        registryAddress = _registryAddress;
    }

    /**
     * @notice enables or disables the registry
     */
    function setIsRegistryActive(bool isActive) external onlyOperator {
        if (registryAddress == address(0)) revert RegistryAddressIsNotSet();
        isRegistryActive = isActive;
    }

    /**
     * @notice withdraw erc-20 tokens
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOperator {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).safeTransfer(operator, balance);
        }
    }

    // internal function

    /**
     * @notice checks whether caller is valid on the registry
     */
    function _isValidAgainstRegistry(
        address operator
    ) internal view returns (bool) {
        if (isRegistryActive) {
            IRegistry registry = IRegistry(registryAddress);

            return registry.isAllowedOperator(operator);
        }
        return true;
    }

    // function overrides

    /**
     * @notice override _baseURI function
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice overrides beforeTokenTransfer and triggers before any transfer
     * @param from from address
     * @param to address being transfered to
     * @param tokenId token id being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (_isValidAgainstRegistry(msg.sender)) {
            super._beforeTokenTransfer(from, to, tokenId);
        } else {
            revert IRegistry.NotAllowed();
        }
    }

    // token burning

    /**
     * @notice checks if the sender or contract is approved to burn the token
     * @param tokenId token id to check for burn approval
     */
    function _isApprovedToBurn(uint256 tokenId) private view returns (bool) {
        if (isContractBurnEnabled && minters[_msgSender()]) {
            return true;
        } else if (
            isOwnerBurnEnabled && _isApprovedOrOwner(_msgSender(), tokenId)
        ) {
            return true;
        }
        return false;
    }

    /**
     * @notice burn the token
     * @param tokenId token id to burn
     */
    function burn(uint256 tokenId) public virtual {
        if (!_isApprovedToBurn(tokenId)) revert NotAllowedToBurn();
        unchecked {
            --_totalSupply;
        }
        _burn(tokenId);
    }
}