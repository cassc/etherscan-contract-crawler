// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../interfaces/IERC721PortalFacet.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibGovernance.sol";
import "../libraries/LibFeeCalculator.sol";
import "../libraries/LibPayment.sol";
import "../libraries/LibRouter.sol";
import "../libraries/LibERC721.sol";
import "../WrappedERC721.sol";

contract ERC721PortalFacet is IERC721PortalFacet, ERC721Holder {
    using SafeERC20 for IERC20;

    /// @notice Mints wrapped `_tokenId` to the `receiver` address.
    ///         Must be authorised by the configured supermajority threshold of `signatures` from the `members` set.
    /// @param _sourceChain ID of the source chain
    /// @param _transactionId The source transaction ID + log index
    /// @param _wrappedToken The address of the wrapped ERC-721 token on the current chain
    /// @param _tokenId The target token ID
    /// @param _metadata The tokenID's metadata, used to be queried as ERC-721.tokenURI
    /// @param _receiver The address of the receiver on this chain
    /// @param _signatures The array of signatures from the members, authorising the operation
    function mintERC721(
        uint256 _sourceChain,
        bytes memory _transactionId,
        address _wrappedToken,
        uint256 _tokenId,
        string memory _metadata,
        address _receiver,
        bytes[] calldata _signatures
    ) external override whenNotPaused {
        LibGovernance.validateSignaturesLength(_signatures.length);
        bytes32 ethHash = computeMessage(
            _sourceChain,
            block.chainid,
            _transactionId,
            _wrappedToken,
            _tokenId,
            _metadata,
            _receiver
        );

        LibRouter.Storage storage rs = LibRouter.routerStorage();
        require(
            !rs.hashesUsed[ethHash],
            "ERC721PortalFacet: transaction already submitted"
        );
        validateAndStoreTx(ethHash, _signatures);

        WrappedERC721(_wrappedToken).safeMint(_receiver, _tokenId, _metadata);

        emit MintERC721(
            _sourceChain,
            _transactionId,
            _wrappedToken,
            _tokenId,
            _metadata,
            _receiver
        );
    }

    /// @notice Burns `_tokenId` of `wrappedToken` and initializes a portal transaction to the target chain
    ///         The wrappedToken's fee payment is transferred to the contract upon execution.
    /// @param _targetChain The target chain to which the wrapped asset will be transferred
    /// @param _wrappedToken The address of the wrapped token
    /// @param _tokenId The tokenID of `wrappedToken` to burn
    /// @param _paymentToken The current payment token
    /// @param _fee The fee amount for the wrapped token's payment token
    /// @param _receiver The address of the receiver on the target chain
    function burnERC721(
        uint256 _targetChain,
        address _wrappedToken,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _fee,
        bytes memory _receiver
    ) public override whenNotPaused {
        require(
            msg.sender == WrappedERC721(_wrappedToken).ownerOf(_tokenId),
            "ERC721PortalFacet: caller is not owner"
        );

        address payment = LibERC721.erc721Payment(_wrappedToken);
        require(
            LibPayment.containsPaymentToken(payment),
            "ERC721PortalFacet: payment token not supported"
        );
        require(
            _paymentToken == payment,
            "ERC721PortalFacet: _paymentToken does not match the current set payment token"
        );
        uint256 currentFee = LibERC721.erc721Fee(_wrappedToken);
        require(
            _fee == currentFee,
            "ERC721PortalFacet: _fee does not match current set payment token fee"
        );

        IERC20(payment).safeTransferFrom(msg.sender, address(this), _fee);
        LibFeeCalculator.accrueFee(payment, _fee);

        WrappedERC721(_wrappedToken).burn(_tokenId);
        emit BurnERC721(
            _targetChain,
            _wrappedToken,
            _tokenId,
            _receiver,
            payment,
            _fee
        );
    }

    /// @notice Sets ERC-721 contract payment token and fee amount
    /// @param _erc721 The target ERC-721 contract
    /// @param _payment The target payment token
    /// @param _fee The fee required upon every portal transfer
    function setERC721Payment(
        address _erc721,
        address _payment,
        uint256 _fee
    ) external override {
        LibDiamond.enforceIsContractOwner();

        require(
            LibPayment.containsPaymentToken(_payment),
            "ERC721PortalFacet: payment token not supported"
        );

        LibERC721.setERC721PaymentFee(_erc721, _payment, _fee);

        emit SetERC721Payment(_erc721, _payment, _fee);
    }

    /// @notice Returns the payment token for an ERC-721
    /// @param _erc721 The address of the ERC-721 Token
    function erc721Payment(
        address _erc721
    ) external view override returns (address) {
        return LibERC721.erc721Payment(_erc721);
    }

    /// @notice Returns the payment fee for an ERC-721
    /// @param _erc721 The address of the ERC-721 Token
    function erc721Fee(
        address _erc721
    ) external view override returns (uint256) {
        return LibERC721.erc721Fee(_erc721);
    }

    /// @notice Computes the bytes32 ethereum signed message hash for signatures
    /// @param _sourceChain The chain where the bridge transaction was initiated from
    /// @param _targetChain The target chain of the bridge transaction.
    ///                     Should always be the current chainId.
    /// @param _transactionId The transaction ID of the bridge transaction
    /// @param _token The address of the token on this chain
    /// @param _tokenId The token ID for the _token
    /// @param _metadata The metadata for the token ID
    /// @param _receiver The receiving address on the current chain
    function computeMessage(
        uint256 _sourceChain,
        uint256 _targetChain,
        bytes memory _transactionId,
        address _token,
        uint256 _tokenId,
        string memory _metadata,
        address _receiver
    ) internal pure returns (bytes32) {
        bytes32 hashedData = keccak256(
            abi.encode(
                _sourceChain,
                _targetChain,
                _transactionId,
                _token,
                _tokenId,
                _metadata,
                _receiver
            )
        );
        return ECDSA.toEthSignedMessageHash(hashedData);
    }

    /// @notice Validates the signatures and the data and saves the transaction
    /// @param _ethHash The hashed data
    /// @param _signatures The array of signatures from the members, authorising the operation
    function validateAndStoreTx(
        bytes32 _ethHash,
        bytes[] calldata _signatures
    ) internal {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        LibGovernance.validateSignatures(_ethHash, _signatures);
        rs.hashesUsed[_ethHash] = true;
    }

    /// Modifier to make a function callable only when the contract is not paused
    modifier whenNotPaused() {
        LibGovernance.enforceNotPaused();
        _;
    }
}