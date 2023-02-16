//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721A.sol";
import "./src/DefaultOperatorFilterer.sol";

contract Alfheim is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;
    using SafeMath for uint256;

    error MaxSupplyExceeded();
    error NotAllowlisted();
    error MaxPerWalletExceeded();
    error InsufficientValue();
    error PreSaleNotActive();
    error PublicSaleNotActive();
    error NoContracts();
    error NotAllowedToClaim();
    error InvalidOperation();
    error NothingToClaim();
    error NotAllowed();

    uint256 public presaleCost = 0.077 ether;
    uint256 public publicCost = 0.088 ether;
    uint256 public maxSupplyForPresale = 800;
    uint256 public amountOwedToDevOne = 0.75 ether;

    uint16 public maxSupply = 1000;

    uint8 public maxMintAmount = 1;

    string private _baseTokenURI = "";

    bool public presaleActive;
    bool public waitlistSaleActive;
    bool public publicSaleActive;

    bytes32 private presaleMerkleRoot;
    bytes32 private waitlistMerkleRoot;

    constructor() ERC721A("Alfheim", "Alfheim") {
        _mint(0x1Af83e32A6d96E1FE05923b844264cC45255D75d, 1);
        _mint(msg.sender, 1);
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function setMaxSupplyForPresale(uint256 _maxSupplyForPresale)
        external
        onlyOwner
    {
        maxSupplyForPresale = _maxSupplyForPresale;
    }

    function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot)
        external
        onlyOwner
    {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    function setWaitlistMerkleRoot(bytes32 _waitlistMerkleRoot)
        external
        onlyOwner
    {
        waitlistMerkleRoot = _waitlistMerkleRoot;
    }

    function setPreSaleCost(uint256 _newPreSaleCost) external onlyOwner {
        presaleCost = _newPreSaleCost;
    }

    function setPublicSaleCost(uint256 _newPublicCost) external onlyOwner {
        publicCost = _newPublicCost;
    }

    function presaleMint(uint8 _amount, bytes32[] calldata _proof)
        external
        payable
        callerIsUser
    {
        if (!presaleActive) revert PreSaleNotActive();
        if (totalSupply() + _amount > maxSupplyForPresale)
            revert MaxSupplyExceeded();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyExceeded();

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
    }

    function waitlistMint(uint8 _amount, bytes32[] calldata _proof) external payable callerIsUser {
        if (!waitlistSaleActive) revert PublicSaleNotActive();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyExceeded();
        if (
            !MerkleProof.verify(
                _proof,
                waitlistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotAllowlisted();
        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();

        if (msg.value != publicCost * _amount) revert InsufficientValue();

        _mint(msg.sender, _amount);
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

    function isValidWaitlist(address _user, bytes32[] calldata _proof)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                waitlistMerkleRoot,
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

    function toggleWaitlistSale() external onlyOwner {
        waitlistSaleActive = !waitlistSaleActive;
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

    function withdraw() external nonReentrant {
        if ((msg.sender != owner()) && (msg.sender != 0x6605AC1F5bC8c41a36d2c0710c5C7Fc35658418e)) revert NotAllowed();
        uint256 balance = address(this).balance;
        if (amountOwedToDevOne != 0) {
            if (balance < amountOwedToDevOne) {
                payable(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671).transfer(
                    balance
                );
                amountOwedToDevOne = amountOwedToDevOne - balance;
            } else {
                payable(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671).transfer(
                    amountOwedToDevOne
                );
                amountOwedToDevOne = 0;
            }
        }
        balance = address(this).balance;
        payable(0x6AD06Af8743f7DaDEc2C8e1474b472D7665F6676).transfer(balance);
    }

    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}