//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// _________________________ __ ___________________________________________
// 7     77     77      77  V  V  77  _  77  _  77     77     77     77    \
// |  _  ||  ___!!__  __!|  |  |  ||    _||  _  ||  -  ||  -  ||  ___!|  7  |
// |  7  ||  __|   7  7  |  !  !  ||  _ \ |  7  ||  ___!|  ___!|  __|_|  |  |
// |  |  ||  7     |  |  |        ||  7  ||  |  ||  7   |  7   |     7|  !  |
// !__!__!!__!     !__!  !________!!__!__!!__!__!!__!   !__!   !_____!!_____!

// Smart Contract by: @backseats_eth


contract NFTWrapped is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    uint256 public ethPrice = 0.05 ether;
    uint256 public sosPrice = 75000000000000000000000000; // 75,000,000 $SOS

    bool public mintEnabled;

    IERC20 public paymentToken = IERC20(0x3b484b82567a09e2588A13D54D032153f0c0aEe0);

    address public withdrawAddress = 0x8CD058f25BefF759239c9777D6fF4a5501bf145B;

    string baseURI = "https://nftwrapped.s3.us-west-2.amazonaws.com/minted/";

    mapping(uint => bool) internal takenTokenIds;

    // Events

    event WrappedMintedWithETH(address indexed _who);
    event WrappedMintedWithSOS(address indexed _who);
    event FundsWithdrawn(uint256 indexed _ethBalance, uint256 indexed _sosBalance, address indexed _to);

    // Modifiers

    modifier isNotPaused() {
        require(mintEnabled, "Mint Paused");
        _;
    }

    modifier tokenIdIsValid(uint256 _id) {
        require(_id > 0, "Invalid id");
        require(!takenTokenIds[_id], "Token id taken");
        _;
    }

    // Constructor

    constructor() ERC721("NFTWrapped", "NFTWRAP") {}

    // Public Functions

    // Mint with ETH
    function mint(uint256 _tokenId) public payable isNotPaused tokenIdIsValid(_tokenId) {
        require(msg.value == ethPrice, "Incorrect ETH Price");

        _tokenSupply.increment();
        _safeMint(msg.sender, _tokenId);
        takenTokenIds[_tokenId] = true;
        emit WrappedMintedWithETH(msg.sender);
    }

    function mintWithSOS(uint256 _tokenId) public isNotPaused tokenIdIsValid(_tokenId) {
        require(paymentToken.balanceOf(msg.sender) >= sosPrice, "Insufficient SOS balance");
        require(paymentToken.transferFrom(msg.sender, address(this), sosPrice));

        _tokenSupply.increment();
        _safeMint(msg.sender, _tokenId);
        takenTokenIds[_tokenId] = true;
        emit WrappedMintedWithSOS(msg.sender);
    }

    // Since we generate the ID on the site and pipe it into the mint functions, this function keeps the actual count of NFTs minted
    function mintedCount() public view returns (uint) {
        return _tokenSupply.current();
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(takenTokenIds[_tokenId], "Token doesn't exist");

        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".json"));
    }

    // Internal Function

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Ownable Functions

    function setMintEnabled(bool _val) public onlyOwner {
        mintEnabled = _val;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // Important: Set new price in wei (i.e. 80000000000000000 for 0.08 ETH)
    function setETHPrice(uint256 _newCost) public onlyOwner {
        ethPrice = _newCost;
    }

    // Important, similar to above. Use a tool like https://eth-converter.com/extended-converter.html to set the correct amount. Set the 'ether' value in the tool to the desired new price, and send the 'wei' amount into this function.
    function setSOSPrice(uint256 _newAmount) public onlyOwner {
        sosPrice = _newAmount;
    }

    function setWithdrawAddress(address _newAddress) public onlyOwner {
        withdrawAddress = _newAddress;
    }

    // Withdraw

    function withdraw() external onlyOwner {
        // Transfer ETH
        uint256 balance = address(this).balance;
        (bool success, ) = payable(withdrawAddress).call{value: balance}("");
        require(success);

        // Transfer SOS
        uint256 erc20Balance = paymentToken.balanceOf(address(this));
        paymentToken.transfer(withdrawAddress, erc20Balance);

        emit FundsWithdrawn(balance, erc20Balance, withdrawAddress);
    }

  }