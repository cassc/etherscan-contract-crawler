//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ISAN721.sol";
import "./utils/Ownable.sol";
import "./token/ERC721Enumerable.sol";
import "./token/ERC2981ContractWideRoyalties.sol";
import "./token/TokenRescuer.sol";

/**
 * @title SAN721
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
abstract contract SAN721 is
    ISAN721,
    Ownable,
    ERC721Enumerable,
    ERC2981ContractWideRoyalties,
    TokenRescuer
{
    /// The maximum token supply.
    uint256 public constant MAX_SUPPLY = 10000;

    /// The maximum number of mints per address
    uint256 public constant MAX_MINT_PER_ADDRESS = 3;

    /// The maximum ERC-2981 royalties percentage (two decimals).
    uint256 public constant MAX_ROYALTIES_PCT = 930; // 9.3%

    /// The base URI for token metadata.
    string public baseURI;

    /// The contract URI for contract-level metadata.
    string public contractURI;

    /// Whether the tokenURI() method returns fully revealed tokenURIs
    bool public isRevealed = true;

    /// The token sale state (0=Paused, 1=Whitelist, 2=Public).
    SaleState public saleState;

    /// The address which signs the mint coupons.
    address public couponSigner;

    /**
     * @notice The total tokens minted by an address.
     */
    mapping(address => uint256) public userMinted;

    /**
     * @notice Reverts if the current sale state is not `_saleState`.
     * @param _saleState The allowed sale state.
     */
    modifier onlyInSaleState(SaleState _saleState) {
        if (saleState != _saleState) revert SaleStateNotActive();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _startingTokenID,
        address _couponSigner,
        string memory _contractURI,
        string memory _baseURI
    )
        ERC721(_name, _symbol, _startingTokenID)
    {
        couponSigner = _couponSigner;
        contractURI = _contractURI;
        baseURI = _baseURI;
    }

    /**
     * @notice Mints `_mintAmount` tokens if the signature is valid.
     * @param _mintAmount The number of tokens to mint.
     * @param _userMaxWhitelist The max tokens this user can mint in whitelist.
     * @param _signature The signature to be validated.
     */
    function mintWhitelist(
        uint256 _mintAmount,
        uint256 _userMaxWhitelist,
        bytes calldata _signature
    )
        external
        onlyInSaleState(SaleState.Whitelist)
    {
        if (!isValidSignature(
            _signature,
            _msgSender(),
            block.chainid,
            address(this),
            _userMaxWhitelist
        )) revert InvalidSignature();

        _mint(_mintAmount);

        if (userMinted[_msgSender()] > _userMaxWhitelist)
            revert ExceedsMintAllocation();
    }

    /**
     * @notice Mints `_mintAmount` tokens if the signature is valid.
     * @param _mintAmount The number of tokens to mint.
     */
    function mintPublic(
        uint256 _mintAmount
    )
        external
        onlyInSaleState(SaleState.Public)
    {
        _cappedMint(_mintAmount);
    }

    /**
     * @notice (only owner) Mints `_mintAmount` tokens to the caller.
     * @param _mintAmount The number of tokens to mint.
     */
    function mintPromo(
        uint256 _mintAmount
    )
        external
        onlyOwner
    {
        _mint(_mintAmount);
    }

    /**
     * @notice (only owner) Sets the saleState to `_newSaleState`.
     * @param _newSaleState The new sale state
     * (0=Paused, 1=Whitelist, 2=Public).
     */
    function setSaleState(
        SaleState _newSaleState
    )
        external
        onlyOwner
    {
        saleState = _newSaleState;
        emit SaleStateChanged(_newSaleState);
    }

    /**
     * @notice (only owner) Sets the coupon signer address.
     * @param _newCouponSigner The new coupon signer address.
     */
    function setCouponSigner(
        address _newCouponSigner
    )
        external
        onlyOwner
    {
        couponSigner = _newCouponSigner;
    }

    /**
     * @notice (only owner) Sets the contract URI for contract metadata.
     * @param _newContractURI The new contract URI.
     */
    function setContractURI(
        string calldata _newContractURI
    )
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /**
     * @notice (only owner) Sets the base URI for token metadata.
     * @param _newBaseURI The new base URI.
     * @param _doReveal If true, this reveals the full tokenURIs.
     */
    function setBaseURI(
        string calldata _newBaseURI,
        bool _doReveal
    )
        external
        onlyOwner
    {
        baseURI = _newBaseURI;
        isRevealed = _doReveal;
    }

    /**
     * @notice (only owner) Withdraws all ether to the caller.
     */
    function withdrawAll()
        external
        onlyOwner
    {
        withdraw(address(this).balance);
    }

    /**
     * @notice (only owner) Withdraws `_weiAmount` wei to the caller.
     * @param _weiAmount The amount of ether (in wei) to withdraw.
     */
    function withdraw(
        uint256 _weiAmount
    )
        public
        onlyOwner
    {
        (bool success, ) = payable(_msgSender()).call{value: _weiAmount}("");
        if (!success) revert FailedToWithdraw();
    }

    /**
     * @notice (only owner) Sets ERC-2981 royalties recipient and percentage.
     * @param _recipient The address to which to send royalties.
     * @param _value The royalties percentage (two decimals, e.g. 1000 = 10%).
     */
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        external
        onlyOwner
    {
        if (_value > MAX_ROYALTIES_PCT) revert ExceedsMaxRoyaltiesPercentage();

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /**
     * @notice Transfers multiple tokens from `_from` to `_to`.
     * @param _from The address from which to transfer tokens.
     * @param _to The address to which to transfer tokens.
     * @param _tokenIDs An array of token IDs to transfer.
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs
    )
        external
    {
        unchecked {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                transferFrom(_from, _to, _tokenIDs[i]);
            }
        }
    }

    /**
     * @notice Safely transfers multiple tokens from `_from` to `_to`.
     * @param _from The address from which to transfer tokens.
     * @param _to The address to which to transfer tokens.
     * @param _tokenIDs An array of token IDs to transfer.
     */
    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs,
        bytes calldata _data
    )
        external
    {
        unchecked {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                safeTransferFrom(_from, _to, _tokenIDs[i], _data);
            }
        }
    }

    /**
     * @notice Determines whether `_account` owns all token IDs `_tokenIDs`.
     * @param _account The account to be checked for token ownership.
     * @param _tokenIDs An array of token IDs to be checked for ownership.
     * @return True if `_account` owns all token IDs `_tokenIDs`, else false.
     */
    function isOwnerOf(
        address _account,
        uint256[] calldata _tokenIDs
    )
        external
        view
        returns (bool)
    {
        unchecked {
            for (uint256 i; i < _tokenIDs.length; ++i) {
                if (ownerOf(_tokenIDs[i]) != _account)
                    return false;
            }
        }

        return true;
    }

    /**
     * @notice Returns an array of all token IDs owned by `_owner`.
     * @param _owner The address for which to return all owned token IDs.
     * @return An array of all token IDs owned by `_owner`.
     */
    function walletOfOwner(
        address _owner
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIDs = new uint256[](tokenCount);
        unchecked {
            for (uint256 i; i < tokenCount; i++) {
                tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
            }
        }
        return tokenIDs;
    }

    /**
     * @notice Checks validity of the signature, sender, and mintAmount.
     * @param _signature The signature to be validated.
     * @param _sender The address part of the signed message.
     * @param _chainId The chain ID part of the signed message.
     * @param _contract The contract address part of the signed message.
     * @param _userMaxWhitelist The user max whitelist part of the signed message.
     */
    function isValidSignature(
        bytes calldata _signature,
        address _sender,
        uint256 _chainId,
        address _contract,
        uint256 _userMaxWhitelist
    )
        public
        view
        returns (bool)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _sender,
                    _chainId,
                    _contract,
                    _userMaxWhitelist
                )
            )
        );
        return couponSigner == ECDSA.recover(hash, _signature);
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function _cappedMint(
        uint256 _mintAmount
    )
        private
    {
        _mint(_mintAmount);

        if (userMinted[_msgSender()] > MAX_MINT_PER_ADDRESS)
            revert ExceedsMaxMintPerAddress();
    }

    /**
     * @notice Mints `_mintAmount` tokens to caller, emits actual token IDs.
     */
    function _mint(
        uint256 _mintAmount
    )
        private
    {
        uint256 totalSupply = _owners.length;
        unchecked {
            if (totalSupply + _mintAmount > MAX_SUPPLY)
                revert ExceedsMaxSupply();
            userMinted[_msgSender()] += _mintAmount;
            for (uint256 i; i < _mintAmount; i++) {
                _owners.push(_msgSender());
                emit Transfer(
                    address(0),
                    _msgSender(),
                    _startingTokenID + totalSupply + i
                );
            }
        }
    }
}