// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/* -----------------------------*/ /*
 .   .  .
 |\_/\_/|             ._.
 |______|             |_|
  _ __ ___ _   _ _ __  _  ___  _ __  
 | '__/ _ \ | | | '_ \| |/ _ \| '_ \ 
 | | |  __/ |_| | | | | | (_) | | | |
 |_|  \___|\__,_|_| |_|_|\___/|_| |_|

 ~ species ~

*/ /*------------------------------*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IDelegationRegistry.sol";
import "./NES.sol";

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NotTokenOwner();
error WrongClaimMultiple();
error MaxSupplyReached();
error TokenAlreadyClaimed();
error MissingParameters();
error NotEnoughEth();
error Claim3NotLive();
error Claim2NotLive();
error Claim1NotLive();
error PublicSaleNotLive();
error MaxPerWalletReached();
error AddressNotSet();
error SenderNotDelegated();
error TransferLocked();
error InvalidAddress();
error InvalidStakingController();
error TicketsNotEnabled();
error NotOnAllowlist();
error StakingNotEnabled();
error AirdropFrozen();

interface LegacyRSP {
    function isTokenClaimed(uint256 tokenId) external view returns (bool);
}

contract ReunionSpecies is
    ERC721AQueryable,
    ERC721ABurnable,
    ERC2981,
    NES,
    ReentrancyGuard,
    OperatorFilterer,
    Ownable
{
    using Strings for uint256;

    mapping(uint256 => bool) private claimedTokenIds;
    mapping(address => uint256) public allowlist;

    address public delegationRegistryAddress;
    address private AR;
    address private legacyRSP;

    string private _baseTokenURI;

    uint256 private maxSupply;
    uint256 private maxPerWallet = 3;

    bool public operatorFilteringEnabled;
    bool public claim3Live = false;
    bool public claim2Live = false;
    bool public claim1Live = false;
    bool public publicSaleLive = false;
    bool public revealLive = false;
    bool public ticketsEnabled = false;
    bool public batchTicketsEnabled = false;
    bool public stakingEnabled = false;
    bool private maxSupplyFrozen = false;
    bool private airdropFrozen = false;

    uint256 public claim2Price = 0.049 ether;
    uint256 public claim1Price = 0.059 ether;
    uint256 public publicSalePrice = 0.09 ether;
    uint256 public ticketPrice = 0.02 ether;
    uint256 public allowListPrice = 0.069 ether;

    event ApeClaimed(uint256 indexed tokenId);
    event TicketReceipt(address indexed owner, bytes32 hash);
    event BatchTicketReceipt(
        address indexed owner,
        bytes32 hash,
        uint256 quantity
    );

    constructor(
        address _delegationRegistryAddress,
        address _devAddress,
        uint256 _reserveAmount,
        uint256 _maxSupply
    ) ERC721A("ReunionSpecies", "RSP") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 8% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 800);

        _mintERC2309(_devAddress, _reserveAmount);
        // set ownership in batches of 5
        for (uint256 i; i < (_reserveAmount / 5); ++i) {
            _initializeOwnershipAt(i * 5);
        }
        maxSupply = _maxSupply;

        delegationRegistryAddress = _delegationRegistryAddress;
    }

    function setApeReunionAddress(address _AR) external onlyOwner {
        AR = _AR;
    }

    function setLegacyRSPAddress(address _legacyRSP) external onlyOwner {
        legacyRSP = _legacyRSP;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setClaim1(bool _claim1Live) external onlyOwner {
        claim1Live = _claim1Live;
    }

    function setClaim2(bool _claim2Live) external onlyOwner {
        claim2Live = _claim2Live;
    }

    function setClaim3(bool _claim3Live) external onlyOwner {
        claim3Live = _claim3Live;
    }

    function setPublicSale(bool _publicSaleLive) external onlyOwner {
        publicSaleLive = _publicSaleLive;
    }

    function setTicketsEnabled(bool _ticketsEnabled) external onlyOwner {
        ticketsEnabled = _ticketsEnabled;
    }

    function setBatchTicketsEnabled(
        bool _batchTicketsEnabled
    ) external onlyOwner {
        batchTicketsEnabled = _batchTicketsEnabled;
    }

    function setStakingController(address _controller) external onlyOwner {
        _setStakingController(_controller);
    }

    function setClaim2Price(uint256 _claim2Price) external onlyOwner {
        claim2Price = _claim2Price;
    }

    function setClaim1Price(uint256 _claim1Price) external onlyOwner {
        claim1Price = _claim1Price;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setTicketPrice(uint256 _ticketPrice) external onlyOwner {
        ticketPrice = _ticketPrice;
    }

    function setAllowListPrice(uint256 _allowListPrice) external onlyOwner {
        allowListPrice = _allowListPrice;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setStakingEnabled(bool _stakingEnabled) external onlyOwner {
        stakingEnabled = _stakingEnabled;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (maxSupplyFrozen) revert MaxSupplyReached();
        if (_maxSupply < _totalMinted()) revert MaxSupplyReached();
        maxSupply = _maxSupply;
    }

    function freezeMaxSupply() external onlyOwner {
        maxSupplyFrozen = true;
    }

    function setReveal(bool _revealLive) external onlyOwner {
        revealLive = _revealLive;
    }

    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "Addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function airdrop(
        address[] calldata owners,
        uint256[] calldata quantities
    ) external onlyOwner {
        if (airdropFrozen) revert AirdropFrozen();
        if (owners.length != quantities.length) revert MissingParameters();

        for (uint256 i = 0; i < owners.length; ) {
            _mint(owners[i], quantities[i]);

            unchecked {
                i++;
            }
        }
    }

    function freezeAirdrop() external onlyOwner {
        airdropFrozen = true;
    }

    function setDelegationRegistry(
        address _delegationRegistryAddress
    ) external onlyOwner {
        delegationRegistryAddress = _delegationRegistryAddress;
    }

    function withdrawEth() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function claimWith3(uint256[] calldata _tokenIds, address _to) external {
        if (!claim3Live) revert Claim3NotLive();
        uint256 claimMultiple = 3;
        _claim(_to, _tokenIds, claimMultiple, false);
    }

    function claimWith2PlusEth(
        uint256[] calldata _tokenIds,
        address _to
    ) external payable nonReentrant {
        if (!claim2Live) revert Claim2NotLive();

        uint256 claimMultiple = 2;
        if (_tokenIds.length != claimMultiple) revert WrongClaimMultiple();
        if (msg.value != claim2Price) revert NotEnoughEth();

        _claim(_to, _tokenIds, claimMultiple, false);
    }

    function claimWith1PlusEth(
        uint256[] calldata _tokenIds,
        address _to
    ) external payable nonReentrant {
        if (!claim1Live) revert Claim1NotLive();

        uint256 claimMultiple = 1;
        if (_tokenIds.length != claimMultiple) revert WrongClaimMultiple();
        if (msg.value != claim1Price) revert NotEnoughEth();

        _claim(_to, _tokenIds, claimMultiple, false);
    }

    function delegateClaimWith3(
        uint256[] calldata _tokenIds,
        address _to
    ) external {
        if (!claim3Live) revert Claim3NotLive();
        uint256 claimMultiple = 3;
        _claim(_to, _tokenIds, claimMultiple, true);
    }

    function delegateClaimWith2PlusEth(
        uint256[] calldata _tokenIds,
        address _to
    ) external payable nonReentrant {
        if (!claim2Live) revert Claim2NotLive();
        if (msg.value != claim2Price) revert NotEnoughEth();

        uint256 claimMultiple = 2;
        if (_tokenIds.length != claimMultiple) revert WrongClaimMultiple();
        if (msg.value != claim2Price) revert NotEnoughEth();

        _claim(_to, _tokenIds, claimMultiple, true);
    }

    function delegateClaimWith1PlusEth(
        uint256[] calldata _tokenIds,
        address _to
    ) external payable nonReentrant {
        if (!claim1Live) revert Claim1NotLive();

        uint256 claimMultiple = 1;
        if (_tokenIds.length != claimMultiple) revert WrongClaimMultiple();
        if (msg.value != claim1Price) revert NotEnoughEth();

        _claim(_to, _tokenIds, claimMultiple, true);
    }

    function publicSale(uint256 quantity) external payable nonReentrant {
        if (quantity == 0) revert MissingParameters();
        if (!publicSaleLive) revert PublicSaleNotLive();
        if (msg.value != quantity * publicSalePrice) revert NotEnoughEth();

        if (_numberMinted(_msgSender()) + quantity > maxPerWallet)
            revert MaxPerWalletReached();
        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyReached();

        _mint(_msgSender(), quantity);
    }

    function stakeFromController(uint256 _tokenId) external {
        if (!stakingEnabled) revert StakingNotEnabled();
        if (_msgSender() != stakingController)
            revert InvalidStakingController();

        _stake(_tokenId);
    }

    function unstakeFromController(uint256 _tokenId) external {
        if (!stakingEnabled) revert StakingNotEnabled();
        if (_msgSender() != stakingController)
            revert InvalidStakingController();

        _unstake(_tokenId);
    }

    function _claim(
        address _to,
        uint256[] calldata _tokenIds,
        uint256 _claimMultiple,
        bool delegated
    ) internal {
        if (_tokenIds.length == 0) revert MissingParameters();
        if (address(AR) == address(0)) revert AddressNotSet();
        if (address(legacyRSP) == address(0)) revert AddressNotSet();
        if (_to == address(0)) revert InvalidAddress();

        uint256 claimQuantity = _tokenIds.length / _claimMultiple;
        if (_tokenIds.length % _claimMultiple != 0) revert WrongClaimMultiple();
        if (_totalMinted() + claimQuantity > maxSupply)
            revert MaxSupplyReached();

        for (uint256 i = 0; i < _tokenIds.length; ) {
            uint256 tokenId = _tokenIds[i];
            address tokenOwnerAddress = IERC721(AR).ownerOf(tokenId);

            if (claimedTokenIds[tokenId]) revert TokenAlreadyClaimed();
            if (LegacyRSP(legacyRSP).isTokenClaimed(tokenId))
                revert TokenAlreadyClaimed();

            if (delegated) {
                bool isDelegateValid = IDelegationRegistry(
                    delegationRegistryAddress
                ).checkDelegateForAll(_msgSender(), tokenOwnerAddress);
                if (!isDelegateValid) revert SenderNotDelegated();
            } else {
                if (tokenOwnerAddress != _msgSender()) revert NotTokenOwner();
            }

            claimedTokenIds[tokenId] = true;
            emit ApeClaimed(tokenId);

            unchecked {
                i++;
            }
        }

        _mint(_to, claimQuantity);
    }

    function allowlistMint(uint256 quantity) external payable nonReentrant {
        if (quantity == 0) revert MissingParameters();
        if (allowlist[msg.sender] < quantity) revert NotOnAllowlist();
        if (msg.value != quantity * allowListPrice) revert NotEnoughEth();

        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyReached();

        allowlist[msg.sender] = allowlist[msg.sender] - quantity;
        _mint(msg.sender, quantity);
    }

    function buyTicket(uint256 quantity) external payable nonReentrant {
        if (quantity == 0) revert MissingParameters();
        if (!ticketsEnabled) revert TicketsNotEnabled();
        if (msg.value != quantity * ticketPrice) revert NotEnoughEth();

        for (uint256 i = 0; i < quantity; i++) {
            bytes32 hash = keccak256(
                abi.encodePacked(block.timestamp, msg.sender, i)
            );
            emit TicketReceipt(_msgSender(), hash);
        }
    }

    function buyTicketBatch(uint256 quantity) external payable nonReentrant {
        if (quantity == 0) revert MissingParameters();
        if (!batchTicketsEnabled) revert TicketsNotEnabled();
        if (msg.value != quantity * ticketPrice) revert NotEnoughEth();

        bytes32 hash = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, quantity)
        );
        emit BatchTicketReceipt(_msgSender(), hash, quantity);
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function isTokenClaimed(uint256 tokenId) external view returns (bool) {
        return claimedTokenIds[tokenId];
    }

    function isAllowlisted(address owner) external view returns (bool) {
        return allowlist[owner] > 0;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Both safeTransferFrom functions in ERC721A call this function
     * so we don't need to override them.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        if (isStaked(tokenId)) revert TransferLocked();

        super.transferFrom(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}