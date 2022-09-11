// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721AGuardable.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract HybridHumans is ERC721AGuardable, Ownable {
    // errors
    error NotEnoughTokens();
    error ExceedMaxMint();
    error WrongValueSent();
    error SaleIsPaused();

    /*
    * MAX_SUPPLY can be lowered one time by calling `burnExcess`, which will lower
    * it to match the current totalSupply(), preventing the possibility of any
    * future mints (by the team or otherwise).
    */
    uint256 public MAX_SUPPLY = 1111;

    // constants
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_PER_PUBLIC_WALLET = 10;

    string private baseTokenURI;
    bool private isRevealed;
    address private HYBRID_HUMANS_TREASURY = 0xc9Bfb7a0607a5670bb77c5fc2D72c86941ED2EF9;

    bool public publicSaleStarted;

    constructor(string memory _baseTokenURI) ERC721AGuardable("Hybrid Humans", "HyHu") {
        baseTokenURI = _baseTokenURI;
        _mint(HYBRID_HUMANS_TREASURY, 200);
    }

    function mint(uint256 amount) external payable {
        if (!publicSaleStarted) revert SaleIsPaused();
        if (_numberMinted(msg.sender) + amount > MAX_PER_PUBLIC_WALLET) revert ExceedMaxMint();
        if (totalSupply() + amount > MAX_SUPPLY) revert NotEnoughTokens();

        if (msg.value != MINT_PRICE * amount) revert WrongValueSent();

        _mint(msg.sender, amount);
    }

    function airdrop(address[] calldata owners, uint[] calldata amounts) external onlyOwner {
        if (owners.length != amounts.length) revert();

        for (uint256 i = 0; i < owners.length; i++) {
            uint256 amount = amounts[i];
            if (totalSupply() + amount > MAX_SUPPLY) revert NotEnoughTokens();

            _mint(owners[i], amount);
        }
    }

    function flipPublicSale(bool _state) external onlyOwner {
        publicSaleStarted = _state;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!isRevealed) return _baseURI();

        return super.tokenURI(tokenId);
    }

    function setRevealed(string calldata _baseTokenURI) external onlyOwner {
        setBaseTokenURI(_baseTokenURI);
        isRevealed = true;
    }

    function burnExcess() external onlyOwner {
        MAX_SUPPLY = totalSupply();
    }

    function setBaseTokenURI(string calldata _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}