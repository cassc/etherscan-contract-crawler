//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC721A.sol";

contract MetroGrad is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    error MaxSupplyExceeded();
    error NotAllowlisted();
    error MaxPerWalletExceeded();
    error InsufficientValue();
    error PreSaleNotActive();
    error PublicSaleNotActive();
    error CannotIncreaseCost();
    error NoContracts();

    uint256 public presaleCost = 0.025 ether;
    uint256 public publicCost = 0.05 ether;
    uint256 private reserveLimit = 0;

    uint16 public maxSupply = 333;

    uint8 public maxMintAmount = 2;

    string private _baseTokenURI =
        "ipfs://QmTzANCLC54prBsNEg4SiPWM1xW8eVrFTXoRtrHwcrkzum/";

    bool public presaleActive;
    bool public publicSaleActive;

    mapping(address => bool) private _allowList;

    constructor() ERC721A("MetroGrad Gen.1", "Survivor") {
        _mint(0x1Af83e32A6d96E1FE05923b844264cC45255D75d, 1);
        _mint(0xd346F04605cf0c65CDcc6368ABf82Bc1B646d381, 1);
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function isAllowlisted(address _user) external view returns (bool) {
        return _allowList[_user];
    }

    function setPreSaleCost(uint256 _newPreSaleCost) external onlyOwner {
        if (_newPreSaleCost > 0.05 ether) revert CannotIncreaseCost();
        presaleCost = _newPreSaleCost;
    }

    function setPublicSaleCost(uint256 _newPublicCost) external onlyOwner {
        if (_newPublicCost > 0.05 ether) revert CannotIncreaseCost();
        publicCost = _newPublicCost;
    }

    function togglePreSalePhase() external onlyOwner {
        if (presaleCost == 0.025 ether) {
            presaleCost = 0.05 ether;
        } else {
            presaleCost = 0.025 ether;
        }
    }

    function presaleMint(uint8 _amount) external payable callerIsUser {
        if (!presaleActive) revert PreSaleNotActive();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyExceeded();
        if (!_allowList[msg.sender]) revert NotAllowlisted();
        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();
        if (msg.value != presaleCost * _amount) revert InsufficientValue();

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

    function airDrop(address[] memory targets) external onlyOwner {
        if (targets.length + reserveLimit > 25) revert MaxSupplyExceeded();

        reserveLimit += targets.length;

        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], 1);
        }
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

    function setAllowlistAddresses(address[] calldata _users)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _users.length; i++) {
            _allowList[_users[i]] = true;
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 payoutDev = balance.mul(5).div(100);
        uint256 payoutSelHelp = balance.mul(4).div(100);
        payable(0xEAa13156a5D2651832164EcC8302C40fD2C401A1).transfer(payoutDev);
        payable(0xd346F04605cf0c65CDcc6368ABf82Bc1B646d381).transfer(
            payoutSelHelp
        );
        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}