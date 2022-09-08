//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
import "./IClokies.sol";

/*
 ██████╗██╗      ██████╗ ██╗  ██╗██╗███████╗███████╗   
██╔════╝██║     ██╔═══██╗██║ ██╔╝██║██╔════╝██╔════╝██╗
██║     ██║     ██║   ██║█████╔╝ ██║█████╗  ███████╗╚═╝
██║     ██║     ██║   ██║██╔═██╗ ██║██╔══╝  ╚════██║██╗
╚██████╗███████╗╚██████╔╝██║  ██╗██║███████╗███████║╚═╝
 ╚═════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝   
████████╗██╗  ██╗███████╗     ██████╗██╗  ██╗██████╗  ██████╗ ███╗   ██╗ ██████╗     ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██║  ██║██╔══██╗██╔═══██╗████╗  ██║██╔═══██╗    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝
   ██║   ███████║█████╗      ██║     ███████║██████╔╝██║   ██║██╔██╗ ██║██║   ██║    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝███████╗
   ██║   ██╔══██║██╔══╝      ██║     ██╔══██║██╔══██╗██║   ██║██║╚██╗██║██║   ██║    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗╚════██║
   ██║   ██║  ██║███████╗    ╚██████╗██║  ██║██║  ██║╚██████╔╝██║ ╚████║╚██████╔╝    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║███████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝     ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝
*/

/// @title ERC721 for Clokies: The Chrono Masters
/// @author @FLGRNT
/// @dev Credit to: @IsekaiMeta (@ItsCuzzo / @frankied_eth) && @cygaar
/// @dev Audited by: @cygaar


contract Clokies is IClokies, Ownable, ERC721A {
    using ECDSA for bytes32;

    enum SaleStates {
        CLOSED,
        TIMELIST,
        PUBLIC
    }

    SaleStates public saleState;

    uint256 public maxClokies = 8888;
    uint256 public timelistPrice = 0.049 ether;
    uint256 public publicPrice = 0.059 ether;

    uint256 public constant RESERVED_CLOKIES = 50;
    uint64 public constant TIMELIST_MINT_MAX = 2;
    uint64 public constant PUBLIC_MINT_MAX = 2;

    string private _baseTokenURI;
    string private _contractURI;

    address private _signer;

    address private constant artistAddress = 0xBFD76f31c622932dB4CC5F8CA658711f798064f2;
    address private constant devAddress = 0xcEB1E4f830b54e2BAA7E852922D0EacCe5172133;
    address private constant founderAddress = 0xaFf8516ad2EecF942AD4425f67135667cb0f55ff;
    address private constant vaultAddress = 0xe39E169F4C3B2a293EE7f1f50AD01c8312ad9D08;

    bool public revealed = false;

    event Minted(address indexed receiver, uint256 quantity);
    event SaleStateChanged(SaleStates saleState);

    constructor(address receiver) ERC721A("Clokies", "CLOKIES") {
        _mintERC2309(receiver, RESERVED_CLOKIES);
    }

    /// @notice Function used during the timelist mint. 
    /// @param signature Signature to verify TIMELIST membership.
    /// @param quantity Amount to mint.
    /// @dev checkState to check sale state.
    function timelistMint(uint64 quantity, bytes calldata signature) 
        external
        payable 
        checkState(SaleStates.TIMELIST)
    {
        if (quantity > TIMELIST_MINT_MAX) revert InvalidQuantity();
        if (msg.value != quantity * timelistPrice) revert InvalidEtherAmount();
        if (_totalMinted() + quantity > maxClokies) revert SupplyExceeded();
        uint64 userAuxilary = _getAux(msg.sender);
        if (userAuxilary > 1) revert TokenClaimed();
        if (!_verifySignature(signature, "TIMELIST")) revert InvalidSignature();

        /// @dev Set non-zero auxilary value to acknowledge that the caller has claimed their token.
        _setAux(msg.sender, userAuxilary + quantity);

        _mint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used during the public mint - just in case ;)
    /// @param signature Signature to verify mints originate from website.
    /// @param quantity Amount to mint.
    /// @dev checkState to check sale state.
    function publicMint(uint64 quantity, bytes calldata signature)
        external
        payable
        checkState(SaleStates.PUBLIC)
    {
        if (msg.value != quantity * publicPrice) revert InvalidEtherAmount();
        if ((_numberMinted(msg.sender) - _getAux(msg.sender)) + quantity > PUBLIC_MINT_MAX)
            revert WalletLimitExceeded();
        if (_totalMinted() + quantity > maxClokies) revert SupplyExceeded();
        if (!_verifySignature(signature, "PUBLIC")) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint free tokens to any address.
    /// @param receiver address to mint to.
    /// @param quantity number to mint.
    function ownerMint(address receiver, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > maxClokies) revert SupplyExceeded();
        _mint(receiver, quantity);
    }

    /// @notice Withdraws funds to team and community vault. 
    function withdraw() public onlyOwner {
        uint teamSplit = address(this).balance / 10;

        (bool artistWithdrawalSuccess, ) = payable(artistAddress).call{value: teamSplit}("");
        if (!artistWithdrawalSuccess) revert WithdrawFailedArtist();

        (bool devWithdrawalSuccess, ) = payable(devAddress).call{value: teamSplit}("");
        if (!devWithdrawalSuccess) revert WithdrawFailedDev();

        (bool founderWithdrawalSuccess, ) = payable(founderAddress).call{value: teamSplit}("");
        if (!founderWithdrawalSuccess) revert WithdrawFailedFounder();
        
        (bool vaultWithdrawalSuccess, ) = payable(vaultAddress).call{value: address(this).balance}("");
        if (!vaultWithdrawalSuccess) revert WithdrawFailedVault();
    }

    /// @notice Fail-safe withdraw function, incase withdraw() causes any issue.
    /// @param receiver address to withdraw to.
    function withdrawTo(address receiver) public onlyOwner {        
        (bool withdrawalSuccess, ) = payable(receiver).call{value: address(this).balance}("");
        if (!withdrawalSuccess) revert WithdrawFailedVault();
    }

    /// @notice Function used to set a new `maxSupply` value.
    /// @param newMaxSupply Newly intended `maxSupply` value.
    /// @dev Max supply will never exceed 8,888 tokens.
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        if (newMaxSupply > 8888) revert InvalidTokenCap();
        maxClokies = newMaxSupply;
    }

    /// @notice Function used to change mint timelist price.
    /// @param newTimelistPrice Newly intended `timelistPrice` value.
    /// @dev Price can never exceed the initially set mint timelist price (0.05E), and can never be increased over it's current value.
    function changeTimelistPrice(uint256 newTimelistPrice) external onlyOwner {
        if (newTimelistPrice > timelistPrice) revert InvalidNewPrice();
        timelistPrice = newTimelistPrice;
    }

    /// @notice Function used to change mint public price.
    /// @param newPublicPrice Newly intended `publicPrice` value.
    /// @dev Price can never exceed the initially set mint public price (0.069E), and can never be increased over it's current value.
    function changePublicPrice(uint256 newPublicPrice) external onlyOwner {
        if (newPublicPrice > publicPrice) revert InvalidNewPrice();
        publicPrice = newPublicPrice;
    }

    /// @notice Function used to check the number of tokens `account` has minted.
    /// @param account Account to check balance for.
    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    /// @notice Contract URI getter for OS collection.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Contract URI setter for OS collection.
    function setContractURI(string calldata newContractUri) external onlyOwner {
        _contractURI = newContractUri;
    }

    /// @notice Function used to view the current `_baseTokenURI` value.
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Sets base token metadata URI.
    /// @param baseURI New base token URI.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice Function used to set a new `_signer` value.
    /// @param newSigner Newly desired `_signer` value.
    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    /// @notice Function used to view the current `_signer` value.
    function signer() external view returns (address) {
        return _signer;
    }

    /// @notice Function used to change the current `saleState` value.
    /// @param newSaleState The new `saleState` value.
    /// @dev 0 = CLOSED, 1 = TIMELIST, 2 = PUBLIC
    function setSaleState(uint256 newSaleState) external onlyOwner {
        if (newSaleState > uint256(SaleStates.PUBLIC))
            revert InvalidSaleState();

        saleState = SaleStates(newSaleState);

        emit SaleStateChanged(saleState);
    }

    /// @notice Verifies a TIMELIST or PUBLIC mint signature.
    /// @param signature The signature to verify. 
    /// @param phase The phase to verify signature against. 
    function _verifySignature(bytes memory signature, string memory phase)
        internal
        view
        returns (bool)
    {
        return
            _signer ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(abi.encodePacked(msg.sender, phase))
                )
            ).recover(signature);
    }

    /// @notice Verifies the current state.
    /// @param saleState_ Sale state to verify. 
    modifier checkState(SaleStates saleState_) {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != saleState_) revert InvalidSaleState();
        _;
    }

    /// @notice Sets the revealed flag and updates token base URI.
    /// @param baseURI New base token URI.
    function reveal(string calldata baseURI) external onlyOwner {
        revealed = true;
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (revealed){
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : ''; 
        } else {
            return _baseURI();
        }
    }
}