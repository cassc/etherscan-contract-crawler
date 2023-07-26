/**
SPDX-License-Identifier: MIT
██      ███████  █████   ██████  ██    ██ ███████      ██████  ███████      ██████  ██    ██  █████  ██████  ██████  ██  █████  ███    ██ ███████ 
██      ██      ██   ██ ██       ██    ██ ██          ██    ██ ██          ██       ██    ██ ██   ██ ██   ██ ██   ██ ██ ██   ██ ████   ██ ██      
██      █████   ███████ ██   ███ ██    ██ █████       ██    ██ █████       ██   ███ ██    ██ ███████ ██████  ██   ██ ██ ███████ ██ ██  ██ ███████ 
██      ██      ██   ██ ██    ██ ██    ██ ██          ██    ██ ██          ██    ██ ██    ██ ██   ██ ██   ██ ██   ██ ██ ██   ██ ██  ██ ██      ██ 
███████ ███████ ██   ██  ██████   ██████  ███████      ██████  ██           ██████   ██████  ██   ██ ██   ██ ██████  ██ ██   ██ ██   ████ ███████ 
*/
pragma solidity 0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error MintingPhaseClose();
error InvalidMintAmount();
error ExceedeedTokenClaiming();
error SupplyExceedeed();
error InsufficientFunds();
error AddressAlreadyClaimOrNotListed();
error NonExistToken();
error WrongInputPhase();
error InvalidProof();
error ContractNotAllowed();
error ProxyNotAllowed();

contract LOGverse is
    ERC721A,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    bool public toggleClaim;
    bool private _revealed;
    string private _hiddenMetadata;
    string private _uriPrefix;
    uint256 private constant MAX_SUPPLY = 6666;

    struct PhaseSpec {
        bytes32 merkleRoot;
        uint256 supply;
        uint256 cost;
        uint256 maxAmountPerAddress;
        uint256 minted;
        bool isOpen;
    }

    enum PhaseMint {
        publicSale,
        freeMint,
        guaranteed,
        fcfs
    }

    mapping(PhaseMint => PhaseSpec) public feature;
    mapping(address => mapping(PhaseMint => uint256)) private _addressClaim;

    constructor(
        string memory _hiddenMetadataUri
    ) ERC721A("League of Guardians", "LOG") {
        _hiddenMetadata = _hiddenMetadataUri;
        _setDefaultRoyalty(0x50940964eA7eF3E75Cf2929E0FBeE1b90Bd65F24, 500);

        feature[PhaseMint.publicSale] = PhaseSpec({
            merkleRoot: 0x00,
            supply: 2600,
            cost: 0.015 ether,
            maxAmountPerAddress: 3,
            isOpen: false,
            minted: 1
        });

        feature[PhaseMint.freeMint] = PhaseSpec({
            merkleRoot: 0x00,
            supply: 333,
            cost: 0,
            maxAmountPerAddress: 1,
            isOpen: false,
            minted: 1
        });

        feature[PhaseMint.guaranteed] = PhaseSpec({
            merkleRoot: 0x00,
            supply: 2000,
            cost: 0.015 ether,
            maxAmountPerAddress: 2,
            isOpen: false,
            minted: 1
        });

        feature[PhaseMint.fcfs] = PhaseSpec({
            merkleRoot: 0x00,
            supply: 2600,
            cost: 0.015 ether,
            maxAmountPerAddress: 2,
            isOpen: false,
            minted: 1
        });
    }

    // ===================================================================
    //                           PRIVATE FUNCTION
    // ===================================================================
    function _notContractAndCheckMintPhaseOpen(
        address _addr,
        PhaseMint _phase
    ) private view {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        if (size > 0) revert ContractNotAllowed();
        if (_msgSender() != tx.origin) revert ProxyNotAllowed();
        bool _isOpenPhase = feature[_phase].isOpen;
        if (!_isOpenPhase) {
            revert MintingPhaseClose();
        }
    }

    function _checkWhitelistEnum(PhaseMint _phase) private pure {
        if (_phase == PhaseMint.publicSale || _phase == PhaseMint.freeMint) {
            revert WrongInputPhase();
        }
    }

    function _verifying(
        PhaseMint _phase,
        bytes32[] calldata _merkleProof
    ) private view {
        bytes32 _leaf = keccak256(abi.encodePacked(_msgSender()));
        bytes32 _merkleRoot = feature[_phase].merkleRoot;
        if (!MerkleProof.verify(_merkleProof, _merkleRoot, _leaf)) {
            revert InvalidProof();
        }
    }

    function _checkAddressClaim(
        PhaseMint _phase,
        uint256 _mintAmount,
        uint256 _maxAmountPerAddress
    ) private view {
        uint256 _addressClaimed = _addressClaim[_msgSender()][_phase];
        if (_addressClaimed + _mintAmount > _maxAmountPerAddress) {
            revert ExceedeedTokenClaiming();
        }
    }

    function _checkSupplyPhase(
        PhaseMint _phase,
        uint256 _mintAmount
    ) private view {
        uint256 _alreadyMinted = feature[_phase].minted;
        uint256 _supplyPhase = feature[_phase].supply;
        if ((_alreadyMinted + _mintAmount) - 1 > _supplyPhase) {
            revert SupplyExceedeed();
        }
    }

    function _mintCompliance(
        PhaseMint _phase,
        uint256 _mintAmount
    ) private view {
        uint256 _maxAmountPerAddress = feature[_phase].maxAmountPerAddress;
        if (_mintAmount < 1 || _mintAmount > _maxAmountPerAddress) {
            revert InvalidMintAmount();
        }
        _checkAddressClaim(_phase, _mintAmount, _maxAmountPerAddress);
        uint256 _costPhase = feature[_phase].cost;
        if (msg.value < _mintAmount * _costPhase) {
            revert InsufficientFunds();
        }
        _checkSupplyPhase(_phase, _mintAmount);
    }

    function _checkClaimFreeMint() private view {
        if (!toggleClaim) revert MintingPhaseClose();
        uint256 _amount = _addressClaim[_msgSender()][PhaseMint.freeMint];
        if (_amount < 1) revert AddressAlreadyClaimOrNotListed();
    }

    function _getTotalMinted() private view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 _tokenFreeMint = feature[PhaseMint.freeMint].minted;
        return (_totalSupply + _tokenFreeMint) - 1;
    }

    // ===================================================================
    //                              MODIFIER
    // ===================================================================
    modifier mintComplianceFreeMint(bytes32[] calldata _merkleProof) {
        _notContractAndCheckMintPhaseOpen(_msgSender(), PhaseMint.freeMint);
        _verifying(PhaseMint.freeMint, _merkleProof);
        _checkAddressClaim(PhaseMint.freeMint, 1, 1);
        _checkSupplyPhase(PhaseMint.freeMint, 1);
        _;
    }

    modifier mintComplianceWhitelist(
        PhaseMint _phase,
        uint256 mintAmount,
        bytes32[] calldata _merkleProof
    ) {
        _checkWhitelistEnum(_phase);
        _notContractAndCheckMintPhaseOpen(_msgSender(), _phase);
        _verifying(_phase, _merkleProof);
        _mintCompliance(_phase, mintAmount);
        _;
    }

    modifier mintCompliancePublic(uint256 mintAmount) {
        _notContractAndCheckMintPhaseOpen(_msgSender(), PhaseMint.publicSale);
        _mintCompliance(PhaseMint.publicSale, mintAmount);
        _;
    }

    // ===================================================================
    //                                MINT
    // ===================================================================
    function freeMint(
        bytes32[] calldata _merkleProof
    ) external mintComplianceFreeMint(_merkleProof) {
        _addressClaim[_msgSender()][PhaseMint.freeMint]++;
        feature[PhaseMint.freeMint].minted++;
    }

    function whitelistMint(
        PhaseMint _phase,
        uint256 mintAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        mintComplianceWhitelist(_phase, mintAmount, _merkleProof)
    {
        _addressClaim[_msgSender()][_phase] += mintAmount;
        feature[_phase].minted += mintAmount;
        _safeMint(_msgSender(), mintAmount);
    }

    function mintPublic(
        uint256 mintAmount
    ) external payable mintCompliancePublic(mintAmount) {
        _addressClaim[_msgSender()][PhaseMint.publicSale] += mintAmount;
        feature[PhaseMint.publicSale].minted += mintAmount;
        _safeMint(_msgSender(), mintAmount);
    }

    function claimFreeToken() external {
        _checkClaimFreeMint();
        _addressClaim[_msgSender()][PhaseMint.freeMint]--;
        feature[PhaseMint.freeMint].minted--;
        _safeMint(_msgSender(), 1);
    }

    function airdropFreeMint(address[] calldata freeMintAddress) external onlyOwner {
        uint256 addressLength = freeMintAddress.length;
        uint256 _totalMintAirdrops;
        for (uint8 i = 0; i < addressLength; ) {
            address _freeMintAfddress = freeMintAddress[i];
            uint256 _amount = _addressClaim[_freeMintAfddress][PhaseMint.freeMint];
            if (_amount == 1) {
                _addressClaim[_freeMintAfddress][PhaseMint.freeMint]--;
                unchecked {
                    ++_totalMintAirdrops;
                }
                _safeMint(_freeMintAfddress, 1);
            }
            unchecked {
                ++i;
            }
        }
        feature[PhaseMint.freeMint].minted -= _totalMintAirdrops;
    }

    function airdrops(
        address[] calldata receiver,
        uint256[] calldata mintAmount
    ) external onlyOwner {
        uint256 _receiver = receiver.length;
        if (_receiver != mintAmount.length) revert WrongInputPhase();
        for (uint8 i = 0; i < _receiver; ) {
            _safeMint(receiver[i], mintAmount[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ===================================================================
    //                          OWNER FUNCTION
    // ===================================================================
    function setMerkleRoot(
        PhaseMint _phase,
        bytes32 merkleRoot
    ) external onlyOwner {
        if (_phase == PhaseMint.publicSale) {
            revert WrongInputPhase();
        }
        feature[_phase].merkleRoot = merkleRoot;
    }

    function toggleMintPhase(PhaseMint _phase, bool toggle) external onlyOwner {
        if (toggle) {
            if (_phase == PhaseMint.fcfs || _phase == PhaseMint.publicSale) {
                uint256 _nftAlreadyMinted = _getTotalMinted();
                uint256 _maxSupply = MAX_SUPPLY;
                feature[_phase].supply = _maxSupply - _nftAlreadyMinted;
            }
        }
        feature[_phase].isOpen = toggle;
    }

    function toggleClaimFreeMint(bool toggle) external onlyOwner {
        toggleClaim = toggle;
    }

    function setHiddenMetadata(
        string calldata _hiddenMetadataUri
    ) external onlyOwner {
        _hiddenMetadata = _hiddenMetadataUri;
    }

    function setBaseUri(string calldata _newUriPrefix) external onlyOwner {
        _uriPrefix = _newUriPrefix;
    }

    function setRevealed(bool _toggle) external onlyOwner {
        _revealed = _toggle;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert InsufficientFunds();
        (bool os, ) = payable(0x21d1E1577689550148722737aEB0aE6935941aaa).call{value: address(this).balance}("");
        require(os);
    }

    function setRoyalties(
        address _recipient,
        uint96 _amount
    ) external onlyOwner {
        _setDefaultRoyalty(_recipient, _amount);
    }

    // ===================================================================
    //                          FRONTEND FUNCTION
    // ===================================================================
    function getAddressAlreadyClaimed(
        PhaseMint _phase,
        address logHolder
    ) external view returns (uint256) {
        return _addressClaim[logHolder][_phase];
    }

    function totalMinted() external view returns (uint256) {
        return _getTotalMinted();
    }

    // ===================================================================
    //                           OPENSEA SUPPORT
    // ===================================================================
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(_tokenId)) revert NonExistToken();
        if (!_revealed) return _hiddenMetadata;
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(_tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ===================================================================
    //                         SUPPORT INTERFACE
    // ===================================================================
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}