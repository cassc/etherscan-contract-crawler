// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ERC721A } from "erc721a/contracts/ERC721A.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { IReceiverVerifier } from "./interfaces/IReceiverVerifier.sol";

import { RouterEndpoint } from "../nfts/Structs.sol";

import { Ownable2StepOmitted } from "../access/Ownable2StepOmitted.sol";

import { IParallelAvatarInvoke } from "./interfaces/IParallelAvatarInvoke.sol";

/**
 * @title  ParallelAvatarInvoke
 * @notice ParallelAvatarInvoke is a token contract that extends ERC721A
 *         with additional metadata, ownership capabilities and supports the echelon protocol.
 */
contract ParallelAvatarInvoke is
    ERC721A,
    Ownable2StepOmitted,
    IParallelAvatarInvoke,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /// @notice Address of PRIME contract.
    IERC20 public _prime = IERC20(0xb23d80f5FefcDDaa212212F028021B41DEd428CF);

    /// @notice Track the max supply.
    uint256 public _maxSupply;

    /// @notice Track the base URI for token metadata.
    string public _tokenBaseURI;

    /// @notice Track the contract URI for contract metadata.
    string public _contractURI;

    /// @notice Track the provenance hash for guaranteeing metadata order
    ///         for random reveals.
    bytes32 public _provenanceHash;

    /// @notice Track the disabled state of the contract.
    bool public _disabled;

    /// @notice Track the locked state for baseURI.
    bool public _baseURILocked;

    /// @notice Track the Router mapping
    mapping(uint256 => RouterEndpoint) public _routerEndpoints;

    /// @notice Track the royalty info: address to receive royalties, and
    ///         royalty basis points.
    RoyaltyInfo public _royaltyInfo;

    /**
     * @dev Reverts if the sender is not the owner or the contract itself.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     */
    function _onlyOwnerOrSelf() internal view {
        if (
            _cast(msg.sender == owner()) | _cast(msg.sender == address(this)) ==
            0
        ) {
            revert OnlyOwner();
        }
    }

    /**
     * @notice Deploy the token contract with its name and symbol.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 newMaxSupply
    ) ERC721A(name, symbol) {
        setMaxSupply(newMaxSupply);
    }

    /**
     * @notice Allow the caller to send PRIME and/or ETH to the Echelon Ecosystem of smart contracts
     *         PRIME and ETH are collected to the destination address, handler is invoked to trigger downstream logic and events
     * @param _id - The id of the deployed and registered InvokeEchelonHandler contract
     * @param _primeValue - The amount of PRIME that was sent to the invokeEchelon function (and was collected to _destination)
     * @param _data - Catch-all param to allow the caller to pass additional data to the handler
     */
    function invoke(
        uint256 _id,
        uint256[] calldata _tokenIds,
        uint256 _primeValue,
        bytes calldata _data
    ) external payable nonReentrant {
        if (_disabled) {
            revert ContractDisabled();
        }

        // Require type to be setup
        RouterEndpoint memory routerEndpoint = _routerEndpoints[_id];
        if (routerEndpoint.verifier == address(0)) {
            revert VerifierNotSet();
        }

        // pull the eth to ethReceiverAddress
        if (msg.value != 0) {
            (bool success, ) = payable(routerEndpoint.ethReceiver).call{
                value: msg.value
            }("");
            if (!success) {
                revert EthTransferFailed();
            }
        }

        // pull the PRIME to primeReceiverAddress
        if (_primeValue != 0) {
            _prime.safeTransferFrom(
                msg.sender,
                routerEndpoint.primeReceiver,
                _primeValue
            );
        }

        // pull the Nfts to nftReceiverAddress
        if (_tokenIds.length != 0) {
            for (uint256 i = 0; i < _tokenIds.length; ) {
                safeTransferFrom(
                    msg.sender,
                    routerEndpoint.nftReceiver,
                    _tokenIds[i]
                );
                unchecked {
                    ++i;
                }
            }
        }

        // Invoke handler
        IReceiverVerifier(routerEndpoint.verifier).handleInvoke(
            msg.sender,
            routerEndpoint,
            msg.value,
            _primeValue,
            _tokenIds,
            _data
        );
    }

    /**
     * @notice Allow an address with minter role to add a handler contract for invoke
     * @param _id - The id of the newly added handler contracts
     * @param _nftReceiver - The address to which the nfts are collected
     * @param _ethReceiver - The address to which ETH is collected
     * @param _primeReceiver - The address to which PRIME is collected
     * @param _verifier - The address of the new invoke handler contract to be registered
     */
    function setReceiver(
        uint256 _id,
        address _nftReceiver,
        address _ethReceiver,
        address _primeReceiver,
        address _verifier
    ) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        if (
            _cast(_nftReceiver == address(0)) |
                _cast(_ethReceiver == address(0)) |
                _cast(_primeReceiver == address(0)) |
                _cast(_verifier == address(0)) ==
            1
        ) {
            revert ZeroAddress();
        }

        RouterEndpoint memory receiverInfo;
        receiverInfo.nftReceiver = _nftReceiver;
        receiverInfo.ethReceiver = _ethReceiver;
        receiverInfo.primeReceiver = _primeReceiver;
        receiverInfo.verifier = _verifier;

        // Effect
        _routerEndpoints[_id] = receiverInfo;
    }

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param newBaseURI The new base URI to set.
     */
    function setBaseURI(string calldata newBaseURI) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        if (_baseURILocked) {
            revert LockedBaseURI();
        }

        // Set the new base URI.
        _tokenBaseURI = newBaseURI;

        // Emit an event with the update.
        if (totalSupply() != 0) {
            emit BatchMetadataUpdate(1, _nextTokenId() - 1);
        }
    }

    /**
     * @notice Lock baseURI so it can no longer be updated.
     *
     */
    function lockBaseURI() external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Set the new base URI.
        _baseURILocked = true;

        // Emit an event with the update.
        emit BaseURILocked();
    }

    /**
     * @notice Updated prime contract address.
     *
     * @param prime New prime contract address.
     */
    function setPrime(address prime) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        _prime = IERC20(prime);

        // Emit an event with the update.
        emit PrimeAddressSet(prime);
    }

    /**
     * @notice Sets the contract URI for contract metadata.
     *
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string calldata newContractURI) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Set the new contract URI.
        _contractURI = newContractURI;

        // Emit an event with the update.
        emit ContractURIUpdated(newContractURI);
    }

    /**
     * @notice Sets the contract disabled state.
     *
     * @param disabled The new disabled state.
     */
    function setDisabled(bool disabled) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Set the disabled state.
        _disabled = disabled;

        // Emit an event with the update.
        emit IsDisabledSet(disabled);
    }

    /**
     * @notice Emit an event notifying metadata updates for
     *         a range of token ids, according to EIP-4906.
     *
     * @param fromTokenId The start token id.
     * @param toTokenId   The end token id.
     */
    function emitBatchMetadataUpdate(
        uint256 fromTokenId,
        uint256 toTokenId
    ) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Emit an event with the update.
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) internal {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the max supply does not exceed the maximum value of uint64.
        if (newMaxSupply > 2 ** 64 - 1) {
            revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        }

        // Set the new max supply.
        _maxSupply = newMaxSupply;

        // Emit an event with the update.
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @notice Sets the provenance hash and emits an event.
     *
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it has not been
     *         modified after mint started.
     *
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Revert if any items have been minted.
        if (_totalMinted() > 0) {
            revert ProvenanceHashCannotBeSetAfterMintStarted();
        }

        // Keep track of the old provenance hash for emitting with the event.
        bytes32 oldProvenanceHash = _provenanceHash;

        // Set the new provenance hash.
        _provenanceHash = newProvenanceHash;

        // Emit an event with the update.
        emit ProvenanceHashUpdated(oldProvenanceHash, newProvenanceHash);
    }

    /**
     * @notice Sets the address and basis points for royalties.
     *
     * @param newInfo The struct to configure royalties.
     */
    function setRoyaltyInfo(RoyaltyInfo calldata newInfo) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Revert if the new royalty address is the zero address.
        if (newInfo.royaltyAddress == address(0)) {
            revert RoyaltyAddressCannotBeZeroAddress();
        }

        // Revert if the new basis points is greater than 10_000.
        if (newInfo.royaltyBps > 10_000) {
            revert InvalidRoyaltyBasisPoints(newInfo.royaltyBps);
        }

        // Set the new royalty info.
        _royaltyInfo = newInfo;

        // Emit an event with the updated params.
        emit RoyaltyInfoUpdated(newInfo.royaltyAddress, newInfo.royaltyBps);
    }

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view override returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Returns the base URI for the contract, which ERC721A uses
     *         to return tokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    /**
     * @notice Returns the contract URI for contract metadata.
     */
    function contractURI() external view override returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view override returns (bytes32) {
        return _provenanceHash;
    }

    /**
     * @notice Returns the address that receives royalties.
     */
    function royaltyAddress() external view returns (address) {
        return _royaltyInfo.royaltyAddress;
    }

    /**
     * @notice Returns the royalty basis points out of 10_000.
     */
    function royaltyBasisPoints() external view returns (uint256) {
        return _royaltyInfo.royaltyBps;
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     *
     * @ param  _tokenId     The NFT asset queried for royalty information.
     * @param  _salePrice    The sale price of the NFT asset specified by
     *                       _tokenId.
     *
     * @return receiver      Address of who should be sent the royalty payment.
     * @return royaltyAmount The royalty payment amount for _salePrice.
     */
    function royaltyInfo(
        uint256 /* _tokenId */,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        // Put the royalty info on the stack for more efficient access.
        RoyaltyInfo storage info = _royaltyInfo;

        // Set the royalty amount to the sale price times the royalty basis
        // points divided by 10_000.
        royaltyAmount = (_salePrice * info.royaltyBps) / 10_000;

        // Set the receiver of the royalty.
        receiver = info.royaltyAddress;
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == 0x49064906 || // ERC-4906
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}