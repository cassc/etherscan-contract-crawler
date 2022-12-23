// SPDX-License-Identifier: MIT
/**
       ▄      ▄    
      ▐▒▀▄▄▄▄▀▒▌   
    ▄▀▒▒▒▒▒▒▒▒▓▀▄  
  ▄▀░█░░░░█░░▒▒▒▐  
  ▌░░░░░░░░░░░▒▒▐  
 ▐▒░██▒▒░░░░░░░▒▐  
 ▐▒░▓▓▒▒▒░░░░░░▄▀  
  ▀▄░▀▀▀▀░░░░▄▀    
    ▀▀▄▄▄▄▄▀▀                                                                                                                                                                                                                                                                  
*/

/** 
    Project: Dogeum NFTs
    Website: https://dogeum.io/

    Contract by RetroBoy (RetroBoy.dev)
*/

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract DogeumNFTs is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    uint256 public cost = 0.11 ether;
    uint256 public maxSupply = 5000;
    uint256 public tokenAmount;
    uint256 public tokenBalance;

    bool public paused = true;
    bool public revealed = true;

    address public token = 0xE83981C6E294881D92697FdC887D19Acd9A820E3;

    event TransferReceived(address _from, uint256 _amount);
    event TransferSent(address _from, address _to, uint256 _amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    //  Internal Functions

    receive() external payable {
        tokenBalance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Transfer Token Function

    function transferToken(address _to, uint256 _amount) private {
        uint256 erc20balance = IERC20(token).balanceOf(address(this));
        require(_amount <= erc20balance, "No tokens in contract");
        IERC20(token).transfer(_to, _amount);
        emit TransferSent(msg.sender, _to, _amount);
    }

    //  Public Functions

    // Mint NFT

    function mint(uint256 _amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid mint amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _amount, "Not enough funds");
        }

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        transferToken(msg.sender, _amount * tokenAmount);
    }

    // Mint for other Wallet

    function mintFor(address _to, uint256 _amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid mint amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");

        require(msg.value >= cost * _amount, "Not enough funds");

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, supply + i);
        }

        transferToken(_to, _amount * tokenAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //  Only Owner Functions

    // AirDrop NFT

    function airDrop(address _to, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_amount > 0);
        require(supply + _amount <= maxSupply);

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, supply + i);
        }

        transferToken(_to, _amount * tokenAmount);
    }

    // Reveal NFTs

    function reveal() public onlyOwner {
        revealed = true;
    }

    // Set Cost of Minting in BNB (WEI)

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    // Amount of Token will be send with each mint (WEI)

    function setTokenAmount(uint256 _newTokenAmount) public onlyOwner {
        tokenAmount = _newTokenAmount;
    }

    // Not Revealed URI

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // Base URI

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // Base Extension

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // Pause contract

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // Cut supply, only decrease

    function updateMaxSupply(uint256 _newSupply) private onlyOwner {
        require(
            _newSupply < maxSupply,
            "You tried to increase the suppply. Decrease only."
        );
        maxSupply = _newSupply;
    }

    // Withdrawing BNB from contract to Contract owner wallet

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // Emergency Dogeum Token Withdraw, this will Pause the contract

    function emergencyTokenWithdraw() external onlyOwner {
        IERC20(token).transfer(
            address(msg.sender),
            IERC20(token).balanceOf(address(this))
        );
        paused = true;
    }
}