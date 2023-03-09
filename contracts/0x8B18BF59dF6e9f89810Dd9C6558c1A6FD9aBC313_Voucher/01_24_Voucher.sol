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

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS, CANONICAL_CORI_SUBSCRIPTION} from "operator-filter-registry/src/lib/Constants.sol";
import "./interfaces/IPet.sol";

contract Voucher is
    ERC721URIStorage,
    ERC721Burnable,
    AccessControl,
    Ownable,
    ERC2981,
    UpdatableOperatorFilterer
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    string public baseURI;

    uint256 public totalSupply;

    struct VoucherToken {
        address to; // The recipient of the voucher
        uint256 tokenId; // The token ID of the voucher
        uint256 price; // The price, in wei, of one voucher
        uint256 expiry; // The time after which the attestation is no longer valid, where zero indicates no expiry
    }
    mapping(bytes32 => bool) public vouchersUsed;

    address public pet;

    /// @notice Emitted when the new base URI is set
    /// @param who Admin that set the base URI
    event BaseURISet(address indexed who);

    /// @notice Emitted when the new Pet address is set
    /// @param pet Address of a new Pet contract
    /// @param who Admin that set the Pet
    event PetSet(address indexed pet, address indexed who);

    /// @notice Emitted when setRoyaltyInfo is called
    /// @param royaltyReceiver Account to receive sale royalties
    /// @param royaltyNumerator Fraction relative to ROYALTY_DENOMINATOR
    event RoyaltyInfoSet(address royaltyReceiver, uint256 royaltyNumerator);

    /// @notice Emitted when withdraw
    /// @param to Account who receive the amount
    /// @param amount Amount of witdhrawal
    /// @param who Admin that withdraw
    event Withdraw(address indexed to, uint256 amount, address indexed who);

    constructor(string memory _uri, address _pet)
        ERC721("Voucher", "VOU")
        UpdatableOperatorFilterer(
            CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS,
            CANONICAL_CORI_SUBSCRIPTION,
            true
        )
    {
        require(_pet != address(0), "cannot set pet to zero address");

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(REDEEMER_ROLE, _msgSender());

        baseURI = _uri;
        pet = _pet;
        emit BaseURISet(_msgSender());
        emit PetSet(_pet, _msgSender());
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

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice Sets a Pet contract address
    /// @param _pet Pet contract address
    function setPet(address _pet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_pet != address(0), "cannot set pet to zero address");
        require(_pet != pet, "pet should be different from the current");

        pet = _pet;
        emit PetSet(_pet, _msgSender());
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        if (_from == address(0)) {
            totalSupply++;
        }
        if (_to == address(0)) {
            totalSupply--;
        }
    }

    /// @notice Returns the hash of a voucher
    /// @param _voucher The voucher contains to, tokenId, price, expiry
    /// @return The hash of the voucher
    function hashVoucher(VoucherToken calldata _voucher) public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, _voucher));
    }

    /// @notice Mint (purchase) a new voucher
    /// @param _voucher The voucher contains to, tokenId, price, expiry
    /// @param _signature The signed by an address with the Minter role
    /// @param _signer The signer of the signature
    function mintTo(
        VoucherToken calldata _voucher,
        bytes calldata _signature,
        address _signer
    ) external payable {
        bytes32 voucherHashed = hashVoucher(_voucher);
        bool signatureValid = SignatureChecker.isValidSignatureNow(
            _signer,
            ECDSA.toEthSignedMessageHash(voucherHashed),
            _signature
        );

        require(hasRole(MINTER_ROLE, _signer), "invalid signer");
        require(signatureValid, "invalid signature");
        require(msg.value == _voucher.price, "payment mismatch");
        require(_voucher.expiry > block.timestamp, "voucher has been expired");
        require(!vouchersUsed[voucherHashed], "voucher has been already used");
        require(IERC721(pet).balanceOf(pet) > totalSupply, "insufficient pet supply");
        vouchersUsed[voucherHashed] = true;

        require(_voucher.to != address(0), "cannot mint to zero address");
        _safeMint(_voucher.to, _voucher.tokenId);
    }

    /// @notice Redeem a voucher
    /// @param _voucherTokenId The voucher token ID to be redeemed
    /// @param _petTokenId The pet token ID
    function redeemVoucher(uint256 _voucherTokenId, uint256 _petTokenId)
        external
        onlyRole(REDEEMER_ROLE)
    {
        address owner = ownerOf(_voucherTokenId);
        _burn(_voucherTokenId);

        // Pet is a pre-minted token
        IERC721(pet).transferFrom(address(pet), owner, _petTokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _withdraw(address _to, uint256 _amount) internal onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_to != address(0), "cannot withdraw to zero address");

        uint256 balance = address(this).balance;
        require(balance > 0, "no balance");
        require(balance >= _amount, "insufficient balance");

        // This forwards all available gas. Be sure to check the return value!
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "withdraw failed");

        emit Withdraw(_to, _amount, _msgSender());
    }

    /// @notice Withdraw amount of native coins to a specific account
    /// @param _to Recipient address
    /// @param _amount Native coins amount
    function withdraw(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdraw(_to, _amount);
    }

    /// @notice Withdraw all amount of native coints to a specific account
    /// @param _to Recipient address
    function withdrawAll(address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdraw(_to, address(this).balance);
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

    // UpdatableOperatorFilterer
    // ===========================================================================

    // The following function overrides are specific to OpenSea's UpdatableOperatorFilterer

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
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

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    // Required by Solidity.
    // ===========================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981, ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}