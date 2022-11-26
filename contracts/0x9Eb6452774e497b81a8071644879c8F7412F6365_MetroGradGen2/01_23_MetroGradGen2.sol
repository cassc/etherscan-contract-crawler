//SPDX-License-Identifier: No License

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721A.sol";
import "./MetroVault.sol";
import "./MetroGradStaked.sol";
import "./src/DefaultOperatorFilterer.sol";

contract MetroGradGen2 is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
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
    error FinalPhaseInactive();

    MetroVault staked = MetroVault(0xaBEB2295f6c1857b76e41b760a8669FF0cddef91);
    MetroGradStaked stakedMetro =
        MetroGradStaked(0xE8F9616bD9f606D24c54c8135d1E667749398538);

    uint256 public presaleCost = 0.035 ether;
    uint256 public publicCost = 0.035 ether;
    uint256 public reserved = 433;
    uint256 public maxSupplyForPresale = 2900;
    uint256 public reservedCounter = 0;

    uint16 public maxSupply = 3333;

    uint8 public maxMintAmount = 2;

    string private _baseTokenURI = "ipfs://QmPdXciRnC9Fev9c9bNFkGV8hwPsJssQ4YCF8SFAHLVRUm/";

    bool public presaleActive;
    bool public publicSaleActive;
    bool public finalPhase;

    bytes32 private presaleMerkleRoot;

    mapping(address => bool) private _allowList;
    mapping(uint256 => bool) private _idClaimed;

    constructor() ERC721A("MetroGrad Gen.2", "Survivor") {
        _mint(0x1Af83e32A6d96E1FE05923b844264cC45255D75d, 1);
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

    function setReserveAmount(uint256 _reserved) external onlyOwner {
        if (_reserved > reserved) revert InvalidOperation();
        reserved = _reserved;
    }

    function claimAllRemainingFree() external onlyOwner {
        if (reservedCounter == reserved) revert NothingToClaim();
        if (reservedCounter > reserved) revert InvalidOperation();
        uint256 claim = reserved - reservedCounter;
        reservedCounter = reserved;
        if (totalSupply() + claim > maxSupply) revert MaxSupplyExceeded();
        finalPhase = false;
        _mint(msg.sender, claim);
    }

    function isIdClaimed(uint256 _id) external view returns (bool) {
        return _idClaimed[_id];
    }

    function isAllowlisted(address _user) external view returns (bool) {
        return _allowList[_user];
    }

    function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot)
        external
        onlyOwner
    {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    function setMetroVault(MetroVault _staked) external onlyOwner {
        staked = _staked;
    }

    function setMetroGradStaked(MetroGradStaked _stakedMetro)
        external
        onlyOwner
    {
        stakedMetro = _stakedMetro;
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

    function stakerClaim(uint256[] calldata _tokensToClaim)
        external
        callerIsUser
    {
        if (!finalPhase) revert FinalPhaseInactive();
        if (totalSupply() + _tokensToClaim.length > maxSupply)
            revert MaxSupplyExceeded();
        for (uint256 i = 0; i < _tokensToClaim.length; i++) {
            if (_idClaimed[_tokensToClaim[i]] == true)
                revert NotAllowedToClaim();
            if (
                msg.sender != stakedMetro.ownerOf(_tokensToClaim[i]) &&
                msg.sender !=
                staked.getMintingWalletOf(
                    stakedMetro.ownerOf(_tokensToClaim[i])
                )
            ) revert NotAllowedToClaim();
            _idClaimed[_tokensToClaim[i]] = true;
        }
        reservedCounter += _tokensToClaim.length;
        _mint(msg.sender, _tokensToClaim.length);
    }

    function freeClaim() external callerIsUser {
        if (!finalPhase) revert FinalPhaseInactive();
        if (!_allowList[msg.sender]) revert NotAllowedToClaim();
        _allowList[msg.sender] = false;
        if (1 + totalSupply() > maxSupply) revert MaxSupplyExceeded();
        reservedCounter += 1;
        _mint(msg.sender, 1);
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

    function toggleFinalPhase() external onlyOwner {
        finalPhase = !finalPhase;
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

        uint256 payoutDev = balance.mul(7 * 1 ether).div(100 * 1 ether);
        payable(0x42b9d28EB31Caf51442Fb5cD7297a70dE3f45cc9).transfer(payoutDev);

        uint256 payoutA = balance.mul(0.5 * 1 ether).div(100 * 1 ether);
        payable(0x00a9af07EC12C73A846cedDAa981D3554D8A2D08).transfer(payoutA);

        uint256 payoutB = balance.mul(0.5 * 1 ether).div(100 * 1 ether);
        payable(0xac159fDADA150667Add4f2B1671a015400209687).transfer(payoutB);

        uint256 payoutC = balance.mul(6 * 1 ether).div(100 * 1 ether);
        payable(0x2d80ed642E5ACdEF9780dc3f4172399E71F5c85C).transfer(payoutC);

        uint256 payoutD = balance.mul(20 * 1 ether).div(100 * 1 ether);
        payable(0xaE2999C250B6D9e76C483062Cf9731058178964B).transfer(payoutD);

        uint256 payoutE = balance.mul(10 * 1 ether).div(100 * 1 ether);
        payable(0xE96F870A5578fBC95e35362536BF9db655DAEB18).transfer(payoutE);

        uint256 payoutF = balance.mul(20 * 1 ether).div(100 * 1 ether);
        payable(0xe0320EF76b242107B1ecDa0F6A848eD1125F905d).transfer(payoutF);

        uint256 payoutG = balance.mul(3 * 1 ether).div(100 * 1 ether);
        payable(0xe5716A93b16b2cE95361FadF0479F34fb3Bc712b).transfer(payoutG);

        uint256 payoutH = balance.mul(2 * 1 ether).div(100 * 1 ether);
        payable(0x205b41068805f8289aEd04c17a6b02438000D679).transfer(payoutH);

        uint256 payoutI = balance.mul(5 * 1 ether).div(100 * 1 ether);
        payable(0xa5890c58c100D386E184425420928e109b0C9fEe).transfer(payoutI);

        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function emergencyWithdraw() external onlyOwner nonReentrant{
        uint256 balance = address(this).balance;

        uint256 payoutDev = balance.mul(7).div(100);
        payable(0x42b9d28EB31Caf51442Fb5cD7297a70dE3f45cc9).transfer(payoutDev);

        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}