//SPDX-License-Identifier: No License

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721A.sol";
import "./src/DefaultOperatorFilterer.sol";

contract Pengu is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;
    using SafeMath for uint256;

    error EmergencyNotActive();
    error NotTheDev();
    error MaxSupplyExceeded();
    error NotAllowlisted();
    error MaxPerWalletExceeded();
    error InsufficientValue();
    error PreSaleNotActive();
    error PublicSaleNotActive();
    error NoContracts();
    error CanNotExceedMaxSupply();
    error SupplyLocked();

    uint256 public presaleCost = 0.085 ether;
    uint256 public publicCost = 0.085 ether;
    uint256 public maxSupplyForPresale = 400;
    uint256 public maxSupply = 500;
    uint256 public maxSupplyForGuaranteed = 500;
    uint256 public preSaleCounter = 0;

    uint8 public maxMintAmount = 1;

    string private _baseTokenURI =
        "ipfs://QmVHJBxELQG2VCnBwgmvijqU5AGVbVYNam9eGtReDwqFJn/";

    bool public presaleActive;
    bool public publicSaleActive;
    bool public emergencyActive;

    bytes32 private presaleMerkleRoot = 0xa2188a1c08cb928286385dba3ece4526005686ce7477eeb8967967049ab11920;
    bytes32 private guaranteedMerkleRoot = 0x84ef14b129d2503eac596e95a23357ebae6f2fc5e5a582fb3ecb015e64e3912a;

    bool public supplyLocked;

    constructor() ERC721A("Pengu", "PENGU") {
        _mint(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671, 2);
        _mint(0xda2EF94C005BA429F5ac318a25d0d7689B3CC095, 1);
        _mint(0xA308F2979d9359BaBBfcdFb8F809D1Ed05eCC334, 1);
        _mint(0x4e711f04170dbbED6B5DD86720ecfFbc724b5322, 1);
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function freezeSupply() external onlyOwner {
        if (supplyLocked) revert SupplyLocked();
        supplyLocked = true;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (supplyLocked) revert SupplyLocked();
        maxSupply = _maxSupply;
    }

    function setMaxSupplyForGuaranteed(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply > maxSupply) revert CanNotExceedMaxSupply();
        maxSupplyForGuaranteed = _maxSupply;
    }

    function setMaxSupplyForPresale(uint256 _maxSupplyForPresale)
        external
        onlyOwner
    {
        if (_maxSupplyForPresale > maxSupply) revert CanNotExceedMaxSupply();
        maxSupplyForPresale = _maxSupplyForPresale;
    }

    function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot)
        external
        onlyOwner
    {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    function setGuaranteedMerkleRoot(bytes32 _guaranteedMerkleRoot)
        external
        onlyOwner
    {
        guaranteedMerkleRoot = _guaranteedMerkleRoot;
    }

    function setPreSaleCost(uint256 _newPreSaleCost) external onlyOwner {
        presaleCost = _newPreSaleCost;
    }

    function setPublicSaleCost(uint256 _newPublicCost) external onlyOwner {
        publicCost = _newPublicCost;
    }

    function guaranteedMint(uint8 _amount, bytes32[] calldata _proof)
        external
        payable
        callerIsUser
    {
        if (!presaleActive) revert PreSaleNotActive();
        if (totalSupply() + _amount > maxSupplyForGuaranteed)
            revert MaxSupplyExceeded();
        if (
            !MerkleProof.verify(
                _proof,
                guaranteedMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotAllowlisted();
        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();
        if (msg.value != presaleCost * _amount) revert InsufficientValue();

        _mint(msg.sender, _amount);
    }

    function presaleMint(uint8 _amount, bytes32[] calldata _proof)
        external
        payable
        callerIsUser
    {
        if (!presaleActive) revert PreSaleNotActive();
        if (preSaleCounter + _amount > maxSupplyForPresale)
            revert MaxSupplyExceeded();
        if (
            !MerkleProof.verify(
                _proof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotAllowlisted();
        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();
        if (msg.value != presaleCost * _amount) revert InsufficientValue();

        _mint(msg.sender, _amount);
        preSaleCounter += _amount;
    }

    function mint(uint8 _amount) external payable callerIsUser {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyExceeded();

        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();

        if (msg.value != publicCost * _amount) revert InsufficientValue();

        _mint(msg.sender, _amount);
    }

    function airDrop(address[] calldata targets) external onlyOwner {
        if (targets.length + totalSupply() > maxSupply)
            revert MaxSupplyExceeded();

        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], 1);
        }
    }

    function isValidGuaranteed(address _user, bytes32[] calldata _proof)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                guaranteedMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    function isValid(address _user, bytes32[] calldata _proof)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    function setMaxMintAmount(uint8 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
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

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        uint256 payoutDev = balance.mul(5).div(100);
        payable(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671).transfer(payoutDev);

        uint256 payoutA = balance.mul(15).div(100);
        payable(0x8c8ba6B887297ed525B31748B1A736AE83cbc0C1).transfer(payoutA);

        uint256 payoutB = balance.mul(15).div(100);
        payable(0xe0320EF76b242107B1ecDa0F6A848eD1125F905d).transfer(payoutB);

        uint256 payoutC = balance.mul(5).div(100);
        payable(0x54E6EDeA28AD21243C71eaC97d45BE97650Ff62D).transfer(payoutC);

        uint256 payoutD = balance.mul(20).div(100);
        payable(0xf30222609f3ba76b3Cb0ED9293078156997DFDc9).transfer(payoutD);

        balance = address(this).balance;
        payable(0xb00fbC64ea6632ee4A5DF6142a4753d7BD8562d8).transfer(balance);
    }

    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        uint256 payoutDev = balance.mul(5).div(100);
        payable(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671).transfer(payoutDev);

        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}