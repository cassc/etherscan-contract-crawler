// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";


pragma solidity ^0.8.10;

contract SwolStarlas is ERC721A, ERC721ABurnable,ERC721AQueryable, ERC2981, ReentrancyGuard, Pausable, Ownable {
    
    using SafeMath for uint;
    using Address for address;

    // MODIFIERS
    modifier onlyDevs() {
        require(devFees[msg.sender].percent > 0, "Dev Only: caller is not the developer");
        _;
    }

    // STRUCTS
    struct DevFee {
        uint percent;
        uint amount;
    }

    struct WhiteListedUser {
        uint64 spots;
        bool isWhitelisted;
    }

    //EVENTS
    event WithdrawFees(address indexed devAddress, uint amount);
    event WithdrawWrongTokens(address indexed devAddress, address tokenAddress, uint amount);
    event WithdrawWrongNfts(address indexed devAddress, address tokenAddress, uint tokenId);

    // CONSTANTS
    uint private constant MAX_SUPPLY = 1500;

    string public baseURI;
    // VARIABLES
    uint public maxSupply = MAX_SUPPLY;
    uint public maxPerTx = 5;
    uint public maxPerPerson = 1500;
    uint public price = 30000000000000000;
    bool public whitelistedOnly;
    address public royaltyAddress = 0x1c55168497E67E9383105c20417B53Afe9baabbb;
    uint public royalty = 750;
    uint private gasForDestinationLzReceive = 350000;
    address[] private devList;
    

    // MAPPINGS
    mapping(address => WhiteListedUser) public whiteListed;
    mapping(address => DevFee) public devFees;

    constructor(
        address[] memory _devList,
        uint[] memory _fees
    ) ERC721A("SwolStarlas", "SWST") {
        require(_devList.length == _fees.length, "Error: invalid data");
        uint totalFee = 0;
        for (uint8 i = 0; i < _devList.length; i++) {
            devList.push(_devList[i]);
            devFees[_devList[i]] = DevFee(_fees[i], 0);
            totalFee += _fees[i];
        }
        require(totalFee == 10000, "Error: invalid total fee");
        whitelistedOnly = true;
        _pause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function splitFees(uint sentAmount) internal {
        for (uint8 i = 0; i < devList.length; i++) {
            address devAddress = devList[i];
            uint devFee = devFees[devAddress].percent;
            uint devFeeAmount = sentAmount.mul(devFee).div(10000);
            devFees[devAddress].amount += devFeeAmount;
        }
    }


    function mint(uint amount) public payable whenNotPaused nonReentrant {
        uint supply = _totalMinted();
        require(supply + amount - 1 < maxSupply, "Error: cannot mint more than total supply");
        require(amount <= maxPerTx, "Error: max par tx limit");
        require(balanceOf(msg.sender) + 1 <= maxPerPerson, "Error: max per address limit");
        if(whiteListed[msg.sender].spots > 0) {
            _safeMint(msg.sender, whiteListed[msg.sender].spots);
            whiteListed[msg.sender].spots = 0;
            return;
        }
        if(whitelistedOnly) {
            require(whiteListed[msg.sender].isWhitelisted,"You are not whitelisted");
        }
        if (price > 0) require(msg.value == price * amount, "Error: invalid price");
        _safeMint(msg.sender,amount);
        if (price > 0 && msg.value > 0) splitFees(msg.value);
    }

    function tokenURI(uint tokenId) public view override(ERC721A) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function tokenExists(uint _id) external view returns (bool) {
        return (_exists(_id));
    }

    function royaltyInfo(uint, uint _salePrice) external view override returns (address receiver, uint royaltyAmount) {
        return (royaltyAddress, (_salePrice * royalty) / 10000);
    }

    //dev

    function whiteList(address[] calldata _addressList,uint64[] calldata countList) external onlyOwner {
        require(_addressList.length > 0, "Error: list is empty");
        require(countList.length == _addressList.length, "Error: invalid list");
        for (uint i = 0; i < _addressList.length; ++i) {
            whiteListed[_addressList[i]] = WhiteListedUser({
                spots: countList[i],
                isWhitelisted: true
            });
        }
    }

    function removeWhiteList(address[] calldata addressList) external onlyOwner {
        require(addressList.length > 0, "Error: list is empty");
        for (uint i = 0; i < addressList.length; ++i) delete whiteListed[addressList[i]];
    }

    function updatePausedStatus() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function updateWhitelistedStatus() external onlyOwner {
        whitelistedOnly = !whitelistedOnly;
    }

    function setMaxPerPerson(uint newMaxBuy) external onlyOwner {
        maxPerPerson = newMaxBuy;
    }

    function setMaxPerTx(uint newMaxBuy) external onlyOwner {
        maxPerTx = newMaxBuy;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
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

    function safeMint(address to,uint256 count) public onlyOwner {
        _safeMint(to,count);
    }

    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(ERC721A,ERC2981) returns (bool) {
    return 
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
    }

    /// @dev withdraw fees
    function withdraw() external onlyDevs {
        uint amount = devFees[msg.sender].amount;
        require(amount > 0, "Error: no fees :(");
        devFees[msg.sender].amount = 0;
        payable(msg.sender).transfer(amount);
        emit WithdrawFees(msg.sender, amount);
    }

    /// @dev emergency withdraw contract balance to the contract owner
    function emergencyWithdraw() external onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "Error: no fees :(");
        for (uint8 i = 0; i < devList.length; i++) {
            address devAddress = devList[i];
            devFees[devAddress].amount = 0;
        }
        payable(msg.sender).transfer(amount);
        emit WithdrawFees(msg.sender, amount);
    }

    function airdropsToken(address[] memory _addr, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            _safeMint(_addr[i],amount);
        }
    }

    /// @dev withdraw ERC20 tokens
    function withdrawTokens(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), _amount);
        emit WithdrawWrongTokens(msg.sender, _tokenContract, _amount);
    }

    /// @dev withdraw ERC721 tokens to the contract owner
    function withdrawNFT(address _tokenContract, uint[] memory _id) external onlyOwner {
        ERC721A tokenContract = ERC721A(_tokenContract);
        for (uint i = 0; i < _id.length; i++) {
            tokenContract.safeTransferFrom(address(this), owner(), _id[i]);
            emit WithdrawWrongNfts(msg.sender, _tokenContract, _id[i]);
        }
    }
}