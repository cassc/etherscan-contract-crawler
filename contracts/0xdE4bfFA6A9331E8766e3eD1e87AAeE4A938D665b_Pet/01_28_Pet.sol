// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//                    ityvusnkqpoooggoopppqkncuvyrl
//              tvsohdmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmaepsvt
//          lfoammmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbkvj
//        xgmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmhnz
//      yhmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmwsl
//    ipmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmqj
//   ibmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmn
//   ommmmmmmmmmmmmmmmmmabokcfnmmdyjjljjttramwcnpgwmmmmmmmmmmmmmmmmmmmmmht
//  xmmmmmmmmmmmmmmbkfri      rmaz         hdz      ummbammmmmmmmmmmmmmmmdz
//  emmmmmmmmmmdqyi           zbj          wy       fmwi tuwmmmmmmmmmmmmmmdr
// immmmmmmmmmmr              j           iz        kdt    kmmmmmmmmmmmmmmmwi
// rmmmmmmmmmmmn              iyukogggpqnuyj        gy     smmgsmmmmmmmmmmmmn
// tmmmmmmmmmmmms         jvqhmmmmmmmmmmmmmmapvi    y      nmdj rammmmmmmmmmdi
//  dmmmmmmmmmmmmk     znhmmmmmdcrtttrzxukbmmmmdsi         qmy   rmmmmmmmmmmmy
//  nmmmmmmmmmmmmmhuvqammmmmmmmr           lqmmmmhl        gv     kmmmmmmmmmms
//  ihmmmmmmmmmmmmmmmmmmmmmmmmg             fmmmmme        y      xmmmmmmmmmmk
//   lhmmmmmmmmmmmmmmmmmmmmmmmecufuuxl      wmmmmmmt              xmmmmmmmmmmn
//    iqmmmmmmmmmmmmmmmmmmmmmmmmwqfl       ummmmmmmz              kmmmmmmmmmmf
//    jwmmmmmmmmmmmmmmmmmmmmmovj          iammmmmmmi             iammmmmmmmmmj
//    hmmmmmmmmmmmmmmmmmmmmmw             smmmmmmmp              qmmmmmmmmmmg
//   ummmmmmmmmmmmmmmmmmmmmmc            ldmmmmmmhi             cmmmmmmmmmmmz
//   hmmmmmmmmmmmmgbmmmmmmmmqnqczi       kmmmmmmol             nmmmmmmmmmmmq
//  lmmmmmmmmmmmmy  juemmmmmeul         jmmmmmgy             jgmmmmmmmmmmmbi
//  zmmmmmmmmmmmk      iycnl            qmhpfl             icdmmmmmmmmmmmwl
//  ymmmmmmmmmmmx                       j                iuwmmmmmmmmmmmmwj
//  zmmmmmmmmmmmc                                      zqdmmmmmmmmmmmmmbl
//  immmmmmmmmmmar                                 lxqammmmmmmmmmmmmmmq
//   gmmmmmmmmmmmmgsyj                        jycqhmmmmmmmmmmmmmmmmmax
//   zmmmmmmmmmmmmmmmmmwc             nqqogbammmmmmmmmmmmmmmmmmmmmmql
//    nmmmmmmmmmmmmmmmmmt            vmmmmmmmmmmmmmmmmmmmmmmmmmmmot
//     kmmmmmmmmmmmmmmmmdwhhgczi     emmmmmmmmmmmmmmmmmmmmmmmmmpt
//      yemmmmmmmmmmmmmmwpfj        rmmmmmmmmmmmmmmmmmmmmmmmbcl
//       iammmmmmmmmmmgl            qmmmmmmmmmmmmmmmmmmmdguj
//       cmmmmmmmmmmmmr             lammmmmmmmmmmbegqsvt
//       bmmmmmmmmmmmmgkcz          ymmmmmmmmmmmd
//       mmmmmmmmmmmmdgct           gmmmmmmmmmmme
//      immmmmmmmmmmd              zmmmmmmmmmmmms
//       ammmmmmmmmmmwpuzi         emmmmmmmmmmmmt
//       qmmmmmmmmmmmmmmmmwgnfrl  fmmmmmmmmmmmmg
//       lammmmmmmmmmmmmmmmmmmmmddmmmmmmmmmmmmmt
//        rdmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmc
//         jemmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmk
//           xbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmc
//             rnhmmmmmmmmmmmmmmmmmmmmmmmmgt
//                lxngwmmmmmmmmmmmmmmmmwkr
//                      jzxfcnkqppqkcxj

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "operator-filter-registry/src/upgradeable/UpdatableOperatorFiltererUpgradeable.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS, CANONICAL_CORI_SUBSCRIPTION} from "operator-filter-registry/src/lib/Constants.sol";

import "@imtbl/imx-contracts/contracts/IMintable.sol";
import "@imtbl/imx-contracts/contracts/utils/Minting.sol";

import "./interfaces/IPet.sol";

contract Pet is
    Initializable,
    ERC721RoyaltyUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721HolderUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UpdatableOperatorFiltererUpgradeable,
    IMintable,
    IPet
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CLONER_ROLE = keccak256("CLONER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    string public baseURI;

    uint256 public totalSupply;

    mapping(uint256 => bool) clones;
    mapping(address => bool) custodials;

    address public imx;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @param _uri Base URI
    function initialize(string calldata _uri) public initializer {
        __ERC721_init("Pet", "PET");
        __Ownable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        __UpdatableOperatorFiltererUpgradeable_init(
            CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS,
            CANONICAL_CORI_SUBSCRIPTION,
            true
        );

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(CLONER_ROLE, _msgSender());
        _grantRole(CUSTODIAN_ROLE, _msgSender());

        baseURI = _uri;
        emit BaseURISet(_msgSender());
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Sets a base URI
    /// @param _uri Base URI
    function setBaseURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
        emit BaseURISet(_msgSender());
    }

    function _setClone(uint256 _tokenId, bool _clone) internal returns (bool) {
        if (_clone == clones[_tokenId]) {
            return false;
        }

        clones[_tokenId] = _clone;
        emit CloneSet(_tokenId, _clone, _msgSender());
        return true;
    }

    /// @notice Set clone flag for a specific token
    /// @param _tokenId Token ID
    /// @param _clone Clone status
    function setClone(uint256 _tokenId, bool _clone) public onlyRole(CLONER_ROLE) {
        require(_setClone(_tokenId, _clone), "clone value is unchanged");
    }

    /// @notice Check if the token is cloned
    /// @param _tokenId Token ID
    /// @return clone_ Cloned falg
    function isClone(uint256 _tokenId) public view returns (bool) {
        return clones[_tokenId];
    }

    function _setCustodial(address _account, bool _status) internal returns (bool) {
        require(
            _account != address(0) && _account != address(this),
            "unsupported address for custodial"
        );

        if (_status == custodials[_account]) {
            return false;
        }

        custodials[_account] = _status;
        emit CustodialSet(_account, _status, _msgSender());
        return true;
    }

    /// @notice Set a custodial
    /// @param _account Custodial account
    /// @param _status Account status
    function setCustodial(address _account, bool _status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_setCustodial(_account, _status), "custodial value is unchanged");
    }

    /// @notice Check if the account is cusotodial
    /// @param _account Account to be checked
    /// @return status_ Account status
    function isCustodial(address _account) public view returns (bool) {
        return custodials[_account];
    }

    function _mintTo(
        address _to,
        uint256 _tokenId,
        bool _clone
    ) internal onlyRole(MINTER_ROLE) {
        require(_to != address(0), "invalid receiver account");

        _safeMint(_to, _tokenId);
        _setClone(_tokenId, _clone);
    }

    /// @notice Mints a signle pet to a specific address
    /// @param _to Receiver address
    /// @param _tokenId Token ID
    /// @param _custodial Custodial flag
    /// @param _clone Clone flag
    function mintTo(
        address _to,
        uint256 _tokenId,
        bool _custodial,
        bool _clone
    ) public onlyRole(MINTER_ROLE) {
        _setCustodial(_to, _custodial);
        _mintTo(_to, _tokenId, _clone);
    }

    /// @notice Mints multiple pets to a list of addresses
    /// @param _tos List of receiver addresses
    /// @param _tokenIds Token IDs
    /// @param _custodial Custodial flag
    /// @param _clone Clone flag
    function multiMintTo(
        address[] memory _tos,
        uint256[] memory _tokenIds,
        bool _custodial,
        bool _clone
    ) public onlyRole(MINTER_ROLE) {
        require(
            _tos.length == _tokenIds.length,
            "length of receivers and token IDs are different"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            mintTo(_tos[i], _tokenIds[i], _custodial, _clone);
        }
    }

    /// @notice Mints a single pet to this contract
    /// @param _tokenId Token ID
    function mintToContract(uint256 _tokenId) external onlyRole(MINTER_ROLE) {
        _mintTo(address(this), _tokenId, false);
    }

    /// @notice Mints multiple pets to this contract
    /// @param _tokenIds Token IDs
    function multiMintToContract(uint256[] memory _tokenIds) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _mintTo(address(this), _tokenIds[i], false);
        }
    }

    function _custodialAndCustodianRole(uint256 _tokenId) private view returns (bool) {
        return isCustodial(ownerOf(_tokenId)) && hasRole(CUSTODIAN_ROLE, _msgSender());
    }

    function _cloneAndClonerRole(uint256 _tokenId) private view returns (bool) {
        return isClone(_tokenId) && hasRole(CLONER_ROLE, _msgSender());
    }

    function _contractOwnedAndMinterRole(uint256 _tokenId) private view returns (bool) {
        return ownerOf(_tokenId) == address(this) && hasRole(MINTER_ROLE, _msgSender());
    }

    function _checkTokenId(uint256 tokenId) private view returns (bool) {
        return
            _custodialAndCustodianRole(tokenId) ||
            _cloneAndClonerRole(tokenId) ||
            _contractOwnedAndMinterRole(tokenId);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        if (_checkTokenId(tokenId)) {
            super._approve(operator, tokenId);
        } else {
            require(!isClone(tokenId), "cannot freely approve clones");
            super.approve(operator, tokenId);
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        require(
            !isCustodial(_msgSender()),
            "setApprovalForAllCustodial must be used for custodial wallets"
        );
        super.setApprovalForAll(operator, approved);
    }

    function setApprovalForAllCustodial(
        address owner,
        address operator,
        bool approved
    ) public onlyRole(CUSTODIAN_ROLE) onlyAllowedOperatorApproval(operator) {
        require(isCustodial(owner), "owner is not custodial");
        super._setApprovalForAll(owner, operator, approved);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        if (_checkTokenId(tokenId)) {
            return true;
        }
        return !isClone(tokenId) && super._isApprovedOrOwner(spender, tokenId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        if (_from == address(0)) {
            totalSupply++;
        }
        if (_to == address(0)) {
            totalSupply--;
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @notice Transfers multiple pets at once
    /// @param _froms Token owners
    /// @param _tos Token receivers
    /// @param _tokenIds Token IDs
    function bulkTransferFrom(
        address[] memory _froms,
        address[] memory _tos,
        uint256[] memory _tokenIds
    ) public {
        require(
            _froms.length == _tos.length && _tos.length == _tokenIds.length,
            "lengths of arguments are not identical"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_froms[i], _tos[i], _tokenIds[i]);
        }
    }

    /// @notice Transfers multiple pets at once
    /// @param _froms Token owners
    /// @param _tos Token receivers
    /// @param _tokenIds Token IDs
    /// @param _custodials Custodial flags for destination addresses
    function bulkTransferFromCustodials(
        address[] memory _froms,
        address[] memory _tos,
        uint256[] memory _tokenIds,
        bool[] memory _custodials
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _froms.length == _tos.length &&
                _tos.length == _tokenIds.length &&
                _tokenIds.length == _custodials.length,
            "lengths of arguments are not identical"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_froms[i], _tos[i], _tokenIds[i]);
            _setCustodial(_tos[i], _custodials[i]);
        }
    }

    // ERC721 Holder
    // ===========================================================================

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public view override returns (bytes4) {
        require(_msgSender() == address(this), "unsupported ERC721 contract");

        return this.onERC721Received.selector;
    }

    // ERC2981 Secondary sale royalties
    // ===========================================================================

    /// @notice Set the royalty info for all tokens
    /// @param _royaltyReceiver Account to receive sale royalties
    /// @param _royaltyNumerator Fraction relative to ROYALTY_DENOMINATOR (which is <= 10000)
    function setRoyaltyInfo(address _royaltyReceiver, uint96 _royaltyNumerator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(_royaltyReceiver, _royaltyNumerator);
        emit RoyaltyInfoSet(_royaltyReceiver, _royaltyNumerator);
    }

    // Immutable X
    // ===========================================================================

    /// @notice Sets the Immutable X address
    /// @param _imx New Immutable X
    function setIMX(address _imx) external onlyRole(DEFAULT_ADMIN_ROLE) {
        imx = _imx;
        emit IMXSet(_msgSender(), imx);
    }

    /// @notice Mints a new token from a blob
    /// @param _to Owner of the newly minted token
    /// @param _quantity Token quantity, only 1 is supported
    /// @param _blob Blob of the format {token_id}:{blueprint}
    function mintFor(
        address _to,
        uint256 _quantity,
        bytes calldata _blob
    ) external override nonReentrant {
        require(_msgSender() == imx, "function can only be called by IMX");
        require(_quantity == 1, "invalid quantity");
        (uint256 tokenId, bool clone) = abi.decode(_blob, (uint256, bool));
        _mintTo(_to, tokenId, clone);
    }

    // Required by Solidity.
    // ===========================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721RoyaltyUpgradeable, ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, UpdatableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function _burn(uint256 _tokenId)
        internal
        override(ERC721RoyaltyUpgradeable, ERC721Upgradeable)
    {
        super._burn(_tokenId);
    }
}