// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import { ERC721 } from "@rari-capital/solmate/src/tokens/ERC721.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Signable.sol";
import "../Helpers.sol";
import "./Errors.sol";

contract ForgottenRunes is ERC721, ReentrancyGuard, Signable, AccessControl {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Phase States: None - can't mint, Pre Sale - only mint with sign, Main Sale - only regular mint
    enum Phase {
        NONE,
        PRE_SALE,
        MAIN_SALE
    }

    struct WithdrawalAddress {
        address account;
        uint96 percentage;
    }

    // Current phase of the contract
    Phase private _phase;

    // Constants
    // Maximum number of NFTs can be allocated
    uint256 public orginalMaxSupply;
    uint256 public maxSupply;

    // ETH value should be sent with mint (owner mint is free)
    uint256 public mintPrice = 0.3 ether;

    // Number of mints account can do on the public sale
    uint256 public mintsPerAccountOnPublicSale = 5;

    // Addresses where money from the contract will go if the owner of the contract will call withdraw function
    WithdrawalAddress[] public withdrawalAddresses;

    // Counter used for token number in minting
    uint256 private _nextTokenCount = 1;

    // Base token and contract URI
    string private baseTokenURI;
    string private baseContractURI;

    // Number of tokens account has minted
    mapping(address => uint256) public minted;

    // Mapping from token ID to non transferable flag
    mapping(uint256 => uint256) private nonTransferableBitMap;

    // Modifier is used to check if the phase rule is met
    modifier phaseRequired(Phase phase_) {
        if (phase_ != _phase) revert Errors.MintNotAvailable();
        _;
    }

    // Modifier is used to check if at least a minimal amount of money was sent
    modifier costs(uint256 amount) {
        if (msg.value < mintPrice * amount) revert Errors.InsufficientFunds();
        _;
    }

    constructor(
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _baseContractURI,
        string memory _name,
        string memory _symbol,
        WithdrawalAddress[] memory _withdrawalAddresses
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        maxSupply = _maxSupply;
        orginalMaxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        baseContractURI = _baseContractURI;

        uint256 length = _withdrawalAddresses.length;
        if (length == 0) revert Errors.WithdrawalPercentageWrongSize();

        uint256 sum;
        for (uint256 i; i < length; ) {
            uint256 percentage = _withdrawalAddresses[i].percentage;
            if (percentage == 0) revert Errors.WithdrawalPercentageZero();
            sum += percentage;
            withdrawalAddresses.push(_withdrawalAddresses[i]);
            unchecked {
                ++i;
            }
        }
        if (sum != 100) revert Errors.WithdrawalPercentageNot100();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // Contract owner can call this function to mint `amount` of tokens into account with the address `to`
    function ownerMint(address to, uint256 amount) external onlyOwner lock {
        if (_nextTokenCount + amount - 1 > maxSupply)
            revert Errors.SupplyLimitReached();

        for (uint256 i; i < amount; ) {
            _safeMint(to, _nextTokenCount);

            unchecked {
                ++_nextTokenCount;
                ++i;
            }
        }
    }

    // Function used to do minting on pre-sale phase (with signature)
    function preSaleMint(
        uint256 amount,
        uint256 maxAmount,
        bytes calldata signature
    ) external payable costs(amount) phaseRequired(Phase.PRE_SALE) lock {
        if (!_verify(signer(), _hash(msg.sender, maxAmount), signature))
            revert Errors.InvalidSignature();

        if (minted[msg.sender] + amount > maxAmount)
            revert Errors.AccountAlreadyMintedMax();

        _mintLogic(amount);
    }

    // Function used to do minting on main-sale phase
    function mint(uint256 amount)
        external
        payable
        costs(amount)
        phaseRequired(Phase.MAIN_SALE)
        lock
    {
        if (minted[msg.sender] + amount > mintsPerAccountOnPublicSale)
            revert Errors.AccountAlreadyMintedMax();

        _mintLogic(amount);
    }

    function burn(uint256 id, address tokenOwner)
        external
        onlyRole(BURNER_ROLE)
    {
        _burnLogic(id, tokenOwner);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (this.isTransferable(id) == false)
            revert Errors.TokenNotTransferable();
        super.transferFrom(from, to, id);
    }

    function setIsTransferable(uint256 id, bool transferable)
        external
        onlyRole(BURNER_ROLE)
    {
        uint256 index = id / 256;
        uint256 bitIndex = id % 256;

        if (transferable == false) {
            nonTransferableBitMap[index] =
                nonTransferableBitMap[index] |
                (1 << bitIndex);
        } else {
            nonTransferableBitMap[index] =
                nonTransferableBitMap[index] &
                ~(1 << bitIndex);
        }
    }

    // Contract owner can call this function to withdraw all money from the contract into a defined wallet
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.NothingToWithdraw();

        uint256 length = withdrawalAddresses.length;
        for (uint256 i; i < length; ) {
            uint256 percentage = withdrawalAddresses[i].percentage;
            address withdrawalAddress = withdrawalAddresses[i].account;
            uint256 value = (balance * percentage) / 100;

            (withdrawalAddress.call{value: value}(""));

            unchecked {
                ++i;
            }
        }

        balance = address(this).balance;
        if (balance > 0) {
            (withdrawalAddresses[0].account.call{value: balance}(""));
        }
    }

    // Contract owner can call this function to set minting price on pre-sale and main-sale
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    // The contract owner can call this function to change the max supply. It can only be reduced but can't be smaller than the amount of already minted tokens
    function reduceMaxSupply(uint256 newMaxSupply) external onlyOwner {
        if (newMaxSupply < _nextTokenCount - 1)
            revert Errors.MaxSupplyTooSmall();

        if (newMaxSupply >= orginalMaxSupply)
            revert Errors.CanNotIncreaseMaxSupply();

        maxSupply = newMaxSupply;
    }

    // Contract owner can call this function to change the number of mints per account on public sale
    function setMintsPerAccountOnPublicSale(
        uint256 mintsPerAccountOnPublicSale_
    ) external onlyOwner {
        mintsPerAccountOnPublicSale = mintsPerAccountOnPublicSale_;
    }

    function setContractURI(string calldata baseContractURI_)
        external
        onlyOwner
    {
        baseContractURI = baseContractURI_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseTokenURI = baseURI_;
    }

    function setPhase(Phase phase_) external onlyOwner {
        _phase = phase_;
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenCount - 1;
    }

    function contractURI() external view returns (string memory) {
        return baseContractURI;
    }

    function phase() external view returns (Phase) {
        return _phase;
    }

    function isTransferable(uint256 id) external view returns (bool) {
        uint256 index = id / 256;
        uint256 bitIndex = id % 256;
        uint256 claimedWord = nonTransferableBitMap[index];
        uint256 mask = (1 << bitIndex);
        return claimedWord & mask != mask;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) revert Errors.TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, Helpers.uint2string(tokenId))
                )
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function _mintLogic(uint256 amount) private {
        if (_nextTokenCount + amount - 1 > maxSupply)
            revert Errors.SupplyLimitReached();

        for (uint256 i; i < amount; ) {
            _safeMint(msg.sender, _nextTokenCount);

            unchecked {
                ++_nextTokenCount;
                ++i;
            }
        }

        minted[msg.sender] += amount;
    }

    function _verify(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) private pure returns (bool) {
        return signer == ECDSA.recover(hash, signature);
    }

    function _hash(address account, uint256 amount)
        private
        pure
        returns (bytes32)
    {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(account, amount))
            );
    }

    function _burnLogic(uint256 id, address tokenOwner) private {
        address owner_ = ownerOf(id);

        if (tokenOwner != owner_) revert Errors.InvalidOwner();

        _burn(id);
    }
}