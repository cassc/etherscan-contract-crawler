// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity 0.8.15;

contract LilHomies is
    ERC721ABurnable,
    ERC721AQueryable,
    IERC2981,
    ReentrancyGuard,
    Pausable,
    Ownable
{
    using Address for address;

    // MODIFIERS
    modifier onlyDevs() {
        require(isDeveloper[msg.sender], "Dev Only: caller is not the developer");
        _;
    }

    //EVENTS
    event WithdrawFees(address indexed devAddress, uint256 amount);
    event WithdrawWrongTokens(address indexed devAddress, address tokenAddress, uint256 amount);
    event WithdrawWrongNfts(address indexed devAddress, address tokenAddress, uint256 tokenId);

    // CONSTANTS
    uint256 private constant MAX_SUPPLY = 5555;

    string public baseURI;
    bytes32 public merkleRoot;
    // VARIABLES
    uint256 public maxSupply = MAX_SUPPLY;
    uint256 public maxPerTx = 1;
    uint256 public maxPerPerson = 5;
    bool public whitelistedOnly;
    address public royaltyAddress = 0xCD30e2F4c6aA0657465886B2B9Ee96cD42515bcC;
    uint256 public royalty = 750;

    // MAPPINGS
    mapping(address => bool) public whitelistMinted;
    mapping(address => bool) public isDeveloper;

    constructor(address[] memory _devList, bytes32 merkleRoot_) ERC721A("Lil Homies", "LILH") {
        for (uint8 i = 0; i < _devList.length; i++) {
            isDeveloper[_devList[i]] = true;
        }
        whitelistedOnly = true;
        merkleRoot = merkleRoot_;
        _pause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function whitelistedMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(whitelistedOnly,"Error: whitelisted mint turned off");
        uint256 supply = _totalMinted();
        require(supply < maxSupply, "Error: cannot mint more than total supply");
        require(!whitelistMinted[msg.sender], "Error: you already minted");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, quantity));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Error: you are not whitelisted or invalid quantity"
        );

        if (supply + quantity > maxSupply) {
            quantity = maxSupply - supply;
        }
        
        whitelistMinted[msg.sender] = true;
        _safeMint(msg.sender, quantity);
        
    }


    function mint(uint256 quantity)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(!whitelistedOnly,"Error: whitelisted only turned on");
        uint256 supply = _totalMinted();
        require(
            supply + quantity - 1 < maxSupply,
            "Error: cannot mint more than total supply"
        );
        require(quantity <= maxPerTx, "Error: max per tx limit");
        require(balanceOf(msg.sender) + 1 <= maxPerPerson, "Error: max per address limit");
        _safeMint(msg.sender, quantity);
    }
    

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function tokenExists(uint256 _id) external view returns (bool) {
        return (_exists(_id));
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override(IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyAddress, (_salePrice * royalty) / 10000);
    }

    function updateMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function updatePausedStatus() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function updateWhitelistedStatus() external onlyOwner {
        whitelistedOnly = !whitelistedOnly;
    }

    function setMaxPerPerson(uint256 newMaxBuy) external onlyOwner {
        maxPerPerson = newMaxBuy;
    }

    function setMaxPerTx(uint256 newMaxBuy) external onlyOwner {
        maxPerTx = newMaxBuy;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setRoyalty(uint16 _royalty) external onlyOwner {
        require(_royalty <= 750, "Royalty must be lower than or equal to 7,5%");
        royalty = _royalty;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    //Overrides

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function safeMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            ERC721A.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /// @dev emergency withdraw contract balance to the contract owner
    function emergencyWithdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Error: no fees :(");
        payable(msg.sender).transfer(amount);
        emit WithdrawFees(msg.sender, amount);
    }

    function airdropsToken(address[] memory _addr, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            _safeMint(_addr[i], amount);
        }
    }

    /// @dev withdraw ERC20 tokens
    function withdrawTokens(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), _amount);
        emit WithdrawWrongTokens(msg.sender, _tokenContract, _amount);
    }

    /// @dev withdraw ERC721 tokens to the contract owner
    function withdrawNFT(address _tokenContract, uint256[] memory _id) external onlyOwner {
        ERC721A tokenContract = ERC721A(_tokenContract);
        for (uint256 i = 0; i < _id.length; i++) {
            tokenContract.safeTransferFrom(address(this), owner(), _id[i]);
            emit WithdrawWrongNfts(msg.sender, _tokenContract, _id[i]);
        }
    }
}