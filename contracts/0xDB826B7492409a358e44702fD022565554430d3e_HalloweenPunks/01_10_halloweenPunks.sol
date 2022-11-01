// SPDX-License-Identifier: None

pragma solidity ^0.8.16;

import "./erc721a/contracts/ERC721A.sol";
import "./erc721a/contracts/IERC721A.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./@openzeppelin/contracts/utils/Strings.sol";


// Made with <3 by @terncrypto & @real_senyai
//██╗░░██╗░█████╗░██╗░░░░░██╗░░░░░░█████╗░░██╗░░░░░░░██╗███████╗███████╗███╗░░██╗██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
//██║░░██║██╔══██╗██║░░░░░██║░░░░░██╔══██╗░██║░░██╗░░██║██╔════╝██╔════╝████╗░██║██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
//███████║███████║██║░░░░░██║░░░░░██║░░██║░╚██╗████╗██╔╝█████╗░░█████╗░░██╔██╗██║██████╔╝██║░░░██║██╔██╗██║█████═╝░╚█████╗░
//██╔══██║██╔══██║██║░░░░░██║░░░░░██║░░██║░░████╔═████║░██╔══╝░░██╔══╝░░██║╚████║██╔═══╝░██║░░░██║██║╚████║██╔═██╗░░╚═══██╗
//██║░░██║██║░░██║███████╗███████╗╚█████╔╝░░╚██╔╝░╚██╔╝░███████╗███████╗██║░╚███║██║░░░░░╚██████╔╝██║░╚███║██║░╚██╗██████╔╝
//╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝░░╚══════╝╚══════╝╚═╝░░╚══╝╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

error SaleInactive();
error SoldOut();
error InvalidPrice();
error WithdrawFailed();
error InvalidQuantity();
error InvalidProof();
error InvalidBatchMint();
error NotBlueChipHolder();
error AlreadyMintedBlueChip();
error NoContracts();
error InvalidSignature();


contract HalloweenPunks is
    ERC721A,
    ERC721AQueryable,
    Ownable
{
    enum SaleState {
        CLOSED,
        OPEN,
        PRESALE,
        AUTH
    }

    enum BlueChip {
        PUNK,
        BIRD,
        MAYC,
        BAYC,
        CLONE,
        DOODLE,
        UNDER,
        AZUKI,
        DIGI
    }

    using Strings for uint256;
    using ECDSA for bytes32;

    string public baseExtension = ".json";

    mapping(BlueChip => address) public blueChipContracts;
    mapping(address => BlueChip[]) public addressBlueChipMintBalance;
    mapping(address => uint256) public addressMintBalance;

    SaleState public saleState = SaleState.CLOSED;

    uint256 public presalePrice = 0;
    uint256 public price = 0;
    uint256 public maxPerTx = 1;
    uint256 public maxPerWallet = 1;
    uint256 public presaleMaxPerWallet = 1;
    uint256 public presaleMaxPerTx = 1;

    uint256 public maxSupply = 3333;
    uint256 public presaleSupply = 2333;
    uint256 public immutable teamSupply = 100;

    address public signer;

    string public _baseTokenURI;

    bytes32 public merkleRoot;

    constructor() ERC721A("Halloween Punks", "HWP") {
        teamMint();
    }

    modifier onlyBlueChip(BlueChip _blueChip) {
        address blueChipAddress = blueChipContracts[_blueChip];
        IERC721A blueChipContract = IERC721A(blueChipAddress);
        if (blueChipContract.balanceOf(msg.sender) < 1) revert NotBlueChipHolder();
        _;
    }

    modifier onlyUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function whitelistMint(uint256 qty, bytes32[] calldata merkleProof) external payable {
        if (saleState != SaleState.PRESALE) revert SaleInactive();
        if (totalSupply() + qty > presaleSupply) revert SoldOut();
        if (msg.value != presalePrice * qty) revert InvalidPrice();

        if (!MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert InvalidProof();
        }
        if (addressMintBalance[msg.sender] + qty > presaleMaxPerWallet) revert InvalidQuantity();
        if (qty > presaleMaxPerTx) revert InvalidQuantity();
        addressMintBalance[msg.sender] += qty;

        _safeMint(msg.sender, qty);
    }

    function bluechipMint(uint256 qty, BlueChip _bluechip) external onlyBlueChip(_bluechip) {
        if (saleState != SaleState.PRESALE) revert SaleInactive();
        if (totalSupply() + qty > presaleSupply) revert SoldOut();
        if (!canMintByBlueChip(_bluechip, msg.sender)) revert AlreadyMintedBlueChip();
        if (qty > presaleMaxPerTx) revert InvalidQuantity();

        addressBlueChipMintBalance[msg.sender].push(_bluechip);

        _safeMint(msg.sender, qty);
    }

    function publicMint(uint256 qty) external payable onlyUser() {
        if (saleState != SaleState.OPEN) revert SaleInactive();
        if (totalSupply() + qty > maxSupply) revert SoldOut();
        if (msg.value != price * qty) revert InvalidPrice();

        if (addressMintBalance[msg.sender] + qty > maxPerWallet) revert InvalidQuantity();
        if (qty > maxPerTx) revert InvalidQuantity();
        addressMintBalance[msg.sender] += qty;

        _safeMint(msg.sender, qty);
    }

    function canMintByBlueChip(BlueChip _blueChip, address sender) view public returns (bool) {
        for (uint256 i = 0; i < addressBlueChipMintBalance[sender].length; i++) {
            if (addressBlueChipMintBalance[sender][i] == _blueChip) {
                return false;
            }
        }
        return true;
    }

    function publicAuthMint(uint256 qty, bytes calldata signature) external payable onlyUser() {
        if (saleState != SaleState.AUTH) revert SaleInactive();
        if (totalSupply() + qty > maxSupply) revert SoldOut();
        if (!isValidSignature(msg.sender, qty, signature)) revert InvalidSignature();
        if (msg.value != price * qty) revert InvalidPrice();

        if (addressMintBalance[msg.sender] + qty > maxPerWallet) revert InvalidQuantity();
        if (qty > maxPerTx) revert InvalidQuantity();

        addressMintBalance[msg.sender] += qty;

        _safeMint(msg.sender, qty);

    }

    function isValidSignature(
        address _sender, uint256 qty,
        bytes memory signature
    ) view internal returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(_sender, qty));
        return signer == data.toEthSignedMessageHash().recover(signature);
    }

    function teamMint() public onlyOwner {
        if (totalSupply() != 0) revert InvalidQuantity();
        _mint(msg.sender, teamSupply);
    }

    function setBlueChipContracts(
        BlueChip[] memory _blueChips,
        address[] memory _contractAddresses
    ) external onlyOwner {
        require(_blueChips.length == _contractAddresses.length, "Invalid input");
        for (uint256 i = 0; i < _blueChips.length; ++i) {
            setBlueChipContract(_blueChips[i], _contractAddresses[i]);
        }
    }

    function setBlueChipContract(BlueChip _blueChip, address _contractAddress) private {
        blueChipContracts[_blueChip] = _contractAddress;
    }

    function setSaleState(uint8 _state) external onlyOwner {
        saleState = SaleState(_state);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function withdraw(address _address) public onlyOwner {
        (bool success, ) = _address.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setPresalePrice(uint256 newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setPresaleMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        presaleMaxPerWallet = _maxPerWallet;
    }

    function setPresaleMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        presaleMaxPerTx = _maxPerTx;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function batchTransfer(
        uint256[] calldata tokenIds,
        address[] calldata recipients
    ) external {
        require(tokenIds.length == recipients.length, "Invalid input");

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(IERC721A, ERC721A)
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }
}