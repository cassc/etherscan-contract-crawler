// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract TheNFTLeagueV2 is ERC721A, Pausable {
    using ECDSA for bytes32;

    bool public publicSale = true;
    bool public burnActive = false;
    uint256 public price = 0.08 ether;
    uint256 public pricePerPack = 0.4 ether;
    uint256 public playersPerPack = 6;
    address private signerAddress;
    // set to 1 higher than desired quantity
    uint256 public whitelistMintPerSignature = 6;
    address immutable safe = 0x8e90AFE9122D5BA34b60e56a8Bd9584F7bABb9aD;
    // set to 1 higher than desired quantity
    uint256 private maxSupply = 4151;

    // MAPPINGS
    mapping(bytes => uint256) public signatureMintedAmount;
    mapping(address => uint256) public freeMintClaim;

    constructor(address _signerAddress) ERC721A("NFT League", "TNLv2") {
        signerAddress = _signerAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function togglePublicSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function toggleBurn() public onlyOwner {
        burnActive = !burnActive;
    }

    function setWhitelistMintPerSignature(uint256 _whitelistMintPerSignature)
        public
        onlyOwner
    {
        whitelistMintPerSignature = _whitelistMintPerSignature;
    }

    function setSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPlayersPerPack(uint256 _playersPerPack) public onlyOwner {
        playersPerPack = _playersPerPack;
    }

    function setPricePerPack(uint256 _price) public onlyOwner {
        pricePerPack = _price;
    }

    // set single mapping
    function setFreeMint(address account, uint256 amount) public onlyOwner {
        freeMintClaim[account] += amount;
    }

    //batch set free mints
    function batchSetFreeMint(address[] memory accounts, uint256 amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            freeMintClaim[accounts[i]] += amount;
        }
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function publicMint(uint256 quantity) public payable whenNotPaused {
        require(publicSale, "Public sale is not open");
        require((_totalMinted() + quantity) < maxSupply, "Exceeded Max Supply");
        require(quantity * price == msg.value, "Invalid funds provided.");
        _mint(msg.sender, quantity);
    }

    function packMint(uint256 quantity) public payable whenNotPaused {
        uint256 totalPlayers = (quantity * playersPerPack);
        require(publicSale, "Public sale is not open");
        require(quantity * pricePerPack == msg.value, "Invalid funds provided");
        require(
            (_totalMinted() + totalPlayers) < maxSupply,
            "Exceeded Max Supply"
        );
        _mint(msg.sender, totalPlayers);
    }

    function whitelistMint(uint256 quantity, bytes calldata signature)
        public
        payable
        whenNotPaused
    {
        require(
            signerAddress ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Signer address mismatch."
        );
        require(
            (signatureMintedAmount[signature] + quantity) <
                whitelistMintPerSignature,
            "No whitelist mints remaining for this wallet"
        );
        require((_totalMinted() + quantity) < maxSupply, "Exceeded Max Supply");
        require(quantity * price == msg.value, "Invalid funds provided.");
        signatureMintedAmount[signature] += quantity;
        _mint(msg.sender, quantity);
    }

    function claimFreeMint() public whenNotPaused  {
        require(
            _totalMinted() + freeMintClaim[msg.sender] < maxSupply,
            "Exceeded Max Supply"
        );
        uint256 mintAmount = freeMintClaim[msg.sender];
        freeMintClaim[msg.sender] = 0;
        _mint(msg.sender, mintAmount);
        
    }

    function batchBurn(uint256[] calldata tokenIds)
        public
        virtual
        whenNotPaused
    {
        require(burnActive, "Burning is not active");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function burn(uint256 tokenID) public virtual whenNotPaused {
        require(burnActive, "Burning is not active");
        _burn(tokenID);
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function withdraw() public {
        (bool success, ) = safe.call{value: address(this).balance}("");
        require(success, "Failed to send to safe.");
    }
}