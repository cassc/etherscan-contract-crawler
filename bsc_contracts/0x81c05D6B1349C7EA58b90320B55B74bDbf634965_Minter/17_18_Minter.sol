// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AutuniteNFT.sol";
import "./Ownable.sol";

contract Minter is Ownable {

    IERC20 public BUSD;
    AutuniteNFT public AUT;
    uint256 public minValue;
    uint256 public totalEntered;
    address public mainWallet;
    bool public topUpActive;
    
    mapping(address => uint256) public userLastToken;

    mapping(uint256 => TokenUpdate[]) _tokenDetails;
    struct TokenUpdate {
        uint256 value;
        uint256 time;
    }

    event Deposit(address indexed from, uint256 indexed tokenId, uint256 indexed amount);
    event TopUp(address indexed from, uint256 indexed tokenId, uint256 indexed amount);

    constructor(
        string memory baseURI,
        string memory name,
        string memory symbol,
        uint256 _minValue,
        address _BUSD,
        address minterOwner,
        address nftOwner,
        address _mainWallet,
        bool singleNFT
    ) Ownable(minterOwner) {
        AUT = new AutuniteNFT(baseURI, name, symbol, nftOwner, singleNFT);
        BUSD = IERC20(_BUSD);
        minValue = _minValue;
        mainWallet = _mainWallet;
    }

    function tokenDetails(uint256 tokenId) public view returns(TokenUpdate[] memory) {
        return _tokenDetails[tokenId];
    }

    function deposit(uint256 amount) public {
        address userAddr = msg.sender;
        require(amount >= minValue, "insufficient value");
        BUSD.transferFrom(userAddr, mainWallet, amount);
        totalEntered += amount;
        uint256 tokenId = AUT.safeMint(userAddr);
        _tokenDetails[tokenId].push(TokenUpdate(amount, block.timestamp));
        userLastToken[userAddr] = tokenId;
        emit Deposit(userAddr, tokenId, amount);
    }

    function topUp(uint256 tokenId, uint256 amount) public {
        address userAddr = msg.sender;
        require(topUpActive, "topUp is not active");
        require(amount >= minValue, "insufficient value");
        require(userAddr == AUT.ownerOf(tokenId), "only owner of tokenId can topUp");
        BUSD.transferFrom(userAddr, mainWallet, amount);
        totalEntered += amount;
        _tokenDetails[tokenId].push(TokenUpdate(amount, block.timestamp));
        emit TopUp(userAddr, tokenId, amount);
    }

    function ownerMint(address userAddr) public onlyOwner {
        uint256 tokenId = AUT.safeMint(userAddr);
        _tokenDetails[tokenId].push(TokenUpdate(0, block.timestamp));
        userLastToken[userAddr] = tokenId;
    }

    function changeBaseURI(string memory baseURI) public onlyOwner {
        AUT.changeBaseURI(baseURI);
    }

    function changeSingleNFT() public onlyOwner {
        AUT.changeSingleNFT();
    }

    function changeTopUpActivation() public onlyOwner {
        if(topUpActive){
            topUpActive = false;
        } else {
            topUpActive = true;
        }
    }
    
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner { 
        AUT.setDefaultRoyalty(receiver, feeNumerator);
    }
    
    function deleteDefaultRoyalty() public onlyOwner { 
        AUT.deleteDefaultRoyalty();
    }

    function changeMinValue(uint256 _minValue) public onlyOwner {
        minValue = _minValue;
    }

    function changeMainWallet(address _mainWallet) public onlyOwner {
        mainWallet = _mainWallet;
    }
}