// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/ERC721EnumerableMod.sol";
import "./lib/Operator.sol";
import "./lib/IRegistry.sol";

//      |||||\          |||||\               |||||\           |||||\
//      ||||| |         ||||| |              ||||| |          ||||| |
//       \__|||||\  |||||\___\|               \__|||||\   |||||\___\|
//          ||||| | ||||| |                      ||||| |  ||||| |
//           \__|||||\___\|       Y u g a         \__|||||\___\|
//              ||||| |             L a b s          ||||| |
//          |||||\___\|          Sewer Pass      |||||\___\|
//          ||||| |                              ||||| |
//           \__|||||||||||\                      \__|||||||||||\
//              ||||||||||| |                        ||||||||||| |
//               \_________\|                         \_________\|

error MintIsNotActive();
error BurnIsNotActive();
error UnauthorizedOwnerOfToken();
error NotAllowedToMint();
error ContractIsLocked();
error UnableToLockContract();
error MaxTokensMinted();
error TokenIdDoesNotExist();
error RegistryAddressIsNotSet();

/**
 * @title BAYC Sewer Pass ERC-721 Smart Contract
 */
contract BAYCSewerPass is ERC721EnumerableMod, Operator {
    uint64 private _totalSupply;
    uint64 public mintIndex;
    uint64 public constant MAX_TOKENS = 30000;
    address public registryAddress;
    bool public mintIsActive;
    bool public burnIsActive;
    bool public contractIsLocked;
    bool public isRegistryActive;
    string private baseURI;
    string public nftLicenseTerms = "https://mdvmm.xyz/license";
    bytes32 public metadataHash;
    mapping(address => bool) public minters;
    mapping(uint256 => uint256) public tokenIdtoMintData;

    constructor(
        string memory name,
        string memory symbol,
        address operator
    ) ERC721(name, symbol) Operator(operator) {}

    /**
     * @notice Mint a Sewer Pass
     * can only be called by approved contracts
     * @param to address of minting contract
     * @param mintData data from the token mint stored in uint256
     *  | dogTokenId | apeTokenId | tier |
     * 192          128           64     0
     */
    function mintSewerPass(
        address to,
        uint256 mintData
    ) external returns (uint256) {
        if (!mintIsActive) revert MintIsNotActive();
        if (_totalSupply >= MAX_TOKENS) revert MaxTokensMinted();
        if (!minters[_msgSender()]) revert NotAllowedToMint();

        uint256 _mintIndex = mintIndex;
        ++mintIndex;
        ++_totalSupply;
        tokenIdtoMintData[_mintIndex] = mintData;
        _safeMint(to, _mintIndex);

        return _mintIndex;
    }

    /**
     * @notice Get the data from token mint by token id
     * @param tokenId the token id
     * @return tier game pass tier
     * @return apeTokenId tier 1 & 2 mayc token id, tier 3 & 4 bayc token id
     * @return dogTokenId bakc token id, if 10000 dog was not used in claim
     */
    function getMintDataByTokenId(
        uint256 tokenId
    )
        external
        view
        returns (uint256 tier, uint256 apeTokenId, uint256 dogTokenId)
    {
        if (!_exists(tokenId)) revert TokenIdDoesNotExist();

        uint256 mintData = tokenIdtoMintData[tokenId];
        tier = uint256(uint64(mintData));
        apeTokenId = uint256(uint64(mintData >> 64));
        dogTokenId = uint256(uint64(mintData >> 128));
    }

    /**
     * @notice Get token ids by wallet
     * @param _owner the address of the owner
     */
    function tokenIdsByWallet(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
     * @notice Check if a token exists
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Get the total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // operator functions

    /**
     * @notice Flip mint state
     */
    function flipMintIsActiveState() external onlyOperator {
        if (contractIsLocked) revert ContractIsLocked();
        mintIsActive = !mintIsActive;
    }

    /**
     * @notice Flip burn state
     */
    function flipBurnIsActiveState() external onlyOperator {
        if (contractIsLocked) revert ContractIsLocked();
        burnIsActive = !burnIsActive;
    }

    /**
     * @notice Lock the contract - stops minting, contract burn,
     * flipping burn state, and adding minter contracts
     * KILL SWITCH - THIS CAN'T BE REVERSED
     */
    function lockContract() external onlyOperator {
        if (mintIsActive) revert UnableToLockContract();
        contractIsLocked = true;
    }

    /**
     * @notice Set base uri of metadata
     * @param uri the base uri of the metadata store
     */
    function setBaseURI(string memory uri) external onlyOperator {
        baseURI = uri;
    }

    /**
     * @notice Toggle the minting ability of a minter contract
     * @param _minterContract address of contract
     */
    function toggleMinterContract(
        address _minterContract
    ) external onlyOperator {
        if (contractIsLocked) revert ContractIsLocked();
        minters[_minterContract] = !minters[_minterContract];
    }

    /**
     * @notice Set the metadata provenance hash
     * @param _metadataHash hash of metadata
     */
    function setMetadataHash(bytes32 _metadataHash) external onlyOperator {
        metadataHash = _metadataHash;
    }

    /**
     * @notice Set NFT License URI
     * @param _nftLicenseUri the uri to license
     */
    function setNftLicenseTerms(
        string memory _nftLicenseUri
    ) external onlyOperator {
        nftLicenseTerms = _nftLicenseUri;
    }

    /**
     * @notice Withdraw erc-20 tokens sent to the contract by error
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOperator {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).transfer(operator, balance);
        }
    }

    /**
     * @notice Set the registry contract
     * @param _registryAddress Contract address for registry
     */
    function setRegistryAddress(
        address _registryAddress
    ) external onlyOperator {
        registryAddress = _registryAddress;
    }

    /**
     * @param isActive Enables or disables the registry
     */
    function setIsRegistryActive(bool isActive) external onlyOperator {
        if (registryAddress == address(0)) revert RegistryAddressIsNotSet();
        isRegistryActive = isActive;
    }

    // Internal function

    /**
     * @notice Checks whether caller is valid on the registry
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

    // Function overrides

    /**
     * @notice override _baseURI function
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Overrides beforeTokenTransfer and triggers before any transfer
     * @param from From address
     * @param to Address being transfered to
     * @param tokenId Token id being transferred
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

    // Token burning

    /**
     * @notice check if sender is approved to burn token
     *      includes token ownership and contract burn checks
     *  @param tokenId token id to check for burn approval
     */
    function _isApprovedToBurn(uint256 tokenId) private view returns (bool) {
        if (!contractIsLocked && minters[_msgSender()]) {
            return true;
        } else if (_isApprovedOrOwner(_msgSender(), tokenId)) {
            return true;
        }
        return false;
    }

    /**
     * @notice burn the token
     * @param tokenId token id to burn
     */
    function burn(uint256 tokenId) public virtual {
        if (!burnIsActive) revert BurnIsNotActive();
        if (!_isApprovedToBurn(tokenId)) revert UnauthorizedOwnerOfToken();
        --_totalSupply;
        _burn(tokenId);
    }
}