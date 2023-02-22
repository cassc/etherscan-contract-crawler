//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721A.sol";
import "./src/DefaultOperatorFilterer.sol";

contract SnugPass is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using SafeMath for uint256;

    error NotAllowed();
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
    error DevOneHasNotBeenPayed();
    error DevTwoHasNotBeenPayed();

    uint256 public presaleCost = 0.049 ether;
    uint256 public publicCost = 0.059 ether;
    uint256 public maxSupplyForPresale = 2000;
    uint256 public maxSupply = 2000;
    uint256 public amountOwedToDevOne = 5 ether;

    uint8 public maxMintAmount = 3;

    string private _baseTokenURI = "ipfs://QmTQQK9xBVSdxgaHj3QDGQmdokHjc5jvwXNYQTSstPJbZB/";

    bool public presaleActive;
    bool public publicSaleActive;
    bool public emergencyActive;
    bool public revealed;

    bytes32 private presaleMerkleRoot;

    bool public supplyLocked;

    mapping(address => uint256) public publicMintTracker;

    constructor() ERC721A("Snug Pass", "SP") {
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

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
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

    function mint(uint8 _amount) external payable callerIsUser {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyExceeded();

        if (publicMintTracker[msg.sender] + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();

        if (msg.value != publicCost * _amount) revert InsufficientValue();
        
        publicMintTracker[msg.sender] += _amount;
        _mint(msg.sender, _amount);
    }

    function airDrop(address[] calldata targets) external onlyOwner {
        if (targets.length + totalSupply() > maxSupply)
            revert MaxSupplyExceeded();

        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], 1);
        }
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        if(revealed){
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';

        }else{
            return string(abi.encodePacked(baseURI, ""));
        }
    }
    
    function payDev() external nonReentrant {
        if ((msg.sender != owner()) && (msg.sender != 0x51aE040f59F2b8E5ea8bc84f8D282adB67571671)) revert NotAllowed();
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
    }
    function withdraw() external onlyOwner nonReentrant {
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
        payable(msg.sender).transfer(balance);
    }

    function withdrawPercentage(
        address[] calldata _addresses,
        uint256[] calldata _percentages
    ) external onlyOwner nonReentrant {
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
        for (uint256 i = 0; i < _addresses.length; i++) {
            uint256 payout = balance.mul(_percentages[i]).div(100 * 1 ether);
            payable(_addresses[i]).transfer(payout);
        }
        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawExact(
        address[] calldata _addresses,
        uint256[] calldata _eth
    ) external onlyOwner nonReentrant {
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
        for (uint256 i = 0; i < _addresses.length; i++) {
            payable(_addresses[i]).transfer(_eth[i]);
        }
        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function toggleEmergencyActive() public nonReentrant {
        if (msg.sender != 0x51aE040f59F2b8E5ea8bc84f8D282adB67571671)
            revert NotTheDev();
        emergencyActive = !emergencyActive;
    }

    function emergencyWithdraw() external onlyOwner nonReentrant {
        if (!emergencyActive) revert EmergencyNotActive();
        uint256 balance = address(this).balance;
        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}