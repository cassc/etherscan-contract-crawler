// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "./Agreement.sol";
import "./Greenlist.sol";
import "./generated/impl/BaseCedarERC721PremintV1.sol";

/**
 * @title ERC721 Cedar contract
 * @notice The contract supports preminting and distribution. It supports user terms and checks the greenlist status before transfer
 * @author Monax Labs
 */
contract CedarERC721PremintV1 is
OwnableUpgradeable,
ERC721AUpgradeable,
ERC2981,
Greenlist,
Agreement,
Multicall,
BaseCedarERC721PremintV1
{
    using Address for address;
    using Strings for uint256;

    /* ========== STATE VARIABLES ========== */

    uint256 maxLimit;
    uint256 tokenId;
    uint64 maxMintPerBatch;
    uint64 preMintMaxPerBatch;
    string public baseURI;

    event TransferOwnership(address _address);
    event TokenMinted(uint256 tokenId, uint96 tierId, address receiver);
    event BaseURI(string baseURI);
    event MaxLimit(uint256 maxLimit);
    event PreMintMaxPerBatch(uint64 preMintMaxPerBatch);
    event Received(address sender, uint256 value);

    /* ========== Initializer ========== */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        address _greenlistManagerAddress,
        address _signatureVerifier,
        string memory _userAgreement,
        string memory baseURI_
    ) external initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __Agreement_init(_userAgreement, _signatureVerifier);
        __Greenlist_init(_greenlistManagerAddress);

        maxLimit = _maxLimit;
        baseURI = baseURI_;
    }

    /// @notice batch mints tokens for a specified tier and transfer to Owner
    /// @dev This function mints 200 tokens per batch up to maxLimit. It sets the tier ID for the token ID and returns an array of the token IDs.
    function mintBatch(uint256 _quantity, address _to) external override onlyOwner {
        require(
            _totalMinted() + _quantity <= maxLimit,
            "CedarERC721PremintV1: max limit exceeded, reverting batch call"
        );
        _mint(_to, _quantity);
        tokenId += _quantity;
    }

    function transferFromBatch(TransferRequest[] calldata transferRequests) external override onlyOwner {
        for (uint256 i; i < transferRequests.length; i++) {
            transferFrom(_msgSender(), transferRequests[i].to, transferRequests[i].tokenId);
        }
    }

    /// @dev this function sets the max limit in the collection
    function setMaxLimit(uint256 _maxLimit) external onlyOwner {
        maxLimit = _maxLimit;
        emit MaxLimit(_maxLimit);
    }

    function setRoyalties(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteRoyalties() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
    @dev _beforeTokenTransfer
    Hook that is called before any token transfer. This includes minting and burning.
    Hook will check transfers after mint.
    It checks whether the terms are activated, if yes check whether the caller is a contract.
    If yes, check the greenlist and if the greenlist is activated, check whether the caller is an approved caller.
    If yes, check whether the Transferee has accepted the terms.
    If terms are not activated, check the greenlist.
    */

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _quantity
    ) internal virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(_from, _to, _tokenId, _quantity);
        if (_to != owner()) {
            address caller = getCaller();
            if (termsActivated) {
                require(
                    termsAccepted[_to],
                    string(
                        abi.encodePacked(
                            "CedarERC721PremintV1: Receiver address has not accepted the collection's terms of use at ",
                            userAgreement
                        )
                    )
                );
            }
            checkGreenlist(caller);
        }
    }

    /// @dev this function returns the address for the *direct* caller of this contract.
    function getCaller() internal view returns (address _caller) {
        assembly {
            _caller := caller()
        }
    }

    /// @notice upgrades the baseURI
    /// @dev this function upgrades the baseURI. All token metadata is stored in the baseURI as a JSON
    function upgradeBaseURI(string calldata baseURI_) external override onlyOwner {
        baseURI = baseURI_;
    }

    /// @dev this function returns the baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice gets token URI
    /// @dev this function overrides the ERC721 tokenURI function. It returns the URI as `${baseURI}/${tokenId}`
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, "/", _tokenId.toString())) : "";
    }

    /* ========== VIEWS ========== */
    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(BaseCedarERC721PremintV1, ERC721AUpgradeable, ERC2981)
    returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    function multicall(bytes[] calldata data)
    external
    override(Multicall, IMulticallableV0)
    returns (bytes[] memory results)
    {
        return Multicall(this).multicall(data);
    }

    // Agreement

    /// @notice activates the terms
    /// @dev this function activates the user terms
    function setTermsStatus(bool _status) external virtual override onlyOwner {
        _setTermsStatus(_status);
    }

    /// @notice switch on / off the greenlist
    /// @dev this function will allow only Aspen's asset proxy to transfer tokens
    function setGreenlistStatus(bool _status) external virtual onlyOwner {
        _setGreenlistStatus(_status);
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function storeTermsAccepted(address _acceptor, bytes calldata _signature) external override virtual onlyOwner {
        _storeTermsAccepted(_acceptor, _signature);
    }
}