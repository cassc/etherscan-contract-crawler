// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "erc721a/contracts/ERC721A.sol";

contract RUMBLEBIRDS is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;

    enum State {
        Setup,
        PreSale,
        PublicSale, 
        Finished
    }

    State private _state;
    uint256 private publicSaleMintingPrice = 0.025 ether;
    uint256 private presaleMintingPrice = 0 ether;
    uint256 private maxSupply = 5000;
    uint256 private mintLimit = 20;
    string private baseTokenUri;
    string private unRevealUri;
    bool private revealed = false;
    mapping(address => bool) private whitelistedUsers;

    ERC20 private coinAddress;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory unRevealUri_,
        string memory revealedUri_,
        ERC20 coinAddress_
    ) ERC721A (
        name_,
        symbol_
    ) {
        _state = State.Setup;
        unRevealUri = unRevealUri_;
        baseTokenUri = revealedUri_;
        coinAddress = coinAddress_;
    } 

    function setbaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setUnRevealUrl(string calldata unRevealUri_) external onlyOwner {
        unRevealUri = unRevealUri_;
    }

    function tokenURI(uint256 tokenId_) public view override(ERC721A) returns (string memory ) {
     if (!_exists(tokenId_)) revert URIQueryForNonexistentToken();
     
       if (revealed == true) {
            return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
       } else {
           return unRevealUri;
       }
    }

    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
    }

    function revealCollection() public onlyOwner {
        revealed = true;
    }

    function setStateToSetup() public onlyOwner {
        _state = State.Setup;
    }
    
    function startPreSale() public onlyOwner {
        _state = State.PreSale;
    }

    function startPublicSale() public onlyOwner {
        _state = State.PublicSale;
    }
    
    function finishSale() public onlyOwner {
        _state = State.Finished;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
    }

    function getMaxSupply() public view returns(uint256) {
        return maxSupply;
    }

    function setMintLimit(uint256 limit) public onlyOwner {
        mintLimit = limit;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        if (_totalMinted() > 2000) {
            publicSaleMintingPrice = price;
        } else {
            presaleMintingPrice = price;
        }
    }

    function getMintPrice() public view returns(uint256) {
        if (_totalMinted() > 2000) {
            return publicSaleMintingPrice;
        } else {
            return presaleMintingPrice;
        }
    }

    function isWhitelisted(address __user) public view virtual returns (bool) {
        return whitelistedUsers[__user];
    }

    function whitelistUser(address __user) public onlyOwner {
        whitelistedUsers[__user] = true;
    }

    function setCoin(uint256 limit) public onlyOwner {
        mintLimit = limit;
    }

    function getMintLimit() public view returns(uint256) {
        return mintLimit;
    }

    function mint(
        uint256 amount
    ) external payable nonReentrant {
        require(_state != State.Setup, "Minting hasn't started yet.");
        require(_state != State.Finished, "Minting is closed.");
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint."
        );
        require(
            balanceOf(msg.sender) <= mintLimit,
            "Mint limit exceeded."
        );
        require(
            _totalMinted() + amount <= maxSupply,
            "Amount should not exceed max supply."
        );
        if (_state == State.PreSale) {
            require(
                whitelistedUsers[msg.sender] == true,
                "You're not whitelisted."
            );
        }
        if (_totalMinted() > 2000) {
            require(
                amount * publicSaleMintingPrice <= msg.value,
                "Insuficient ETH to mint."
            );
        }

        uint _decimals = coinAddress.decimals();
        coinAddress.transferFrom(owner(), msg.sender, amount * (10 ** _decimals));
        _safeMint(msg.sender, amount);
    }

    function airDrop(address[] memory recipients, uint256[] memory numberOfTokensPerWallet, uint256 numberOfTokensToAirdrop) public onlyOwner {
        require(
            recipients.length == numberOfTokensPerWallet.length,
            "Different array sizes"
        );

        require(
            _totalMinted() + numberOfTokensToAirdrop <= maxSupply,
            "Exceeded max supply"
        );

        for (uint256 i=0; i<recipients.length; i++) {
            address recipient = recipients[i];
            _safeMint(recipient, numberOfTokensPerWallet[i]);
        }
    }
 }