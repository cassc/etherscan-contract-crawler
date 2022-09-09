// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EndangeredArkNFT is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        //PROJECT FOUNDING
        // =============================================================================
        (bool psa, ) = payable(0x723345cd25f514a46B91684a2a2f01c47759728b).call{
            value: (address(this).balance * 5) / 100
        }("");
        require(psa);
        //Pasa and Project Gorille Fernan Vaz will receive funds directly to this wallet.
        // =============================================================================
        // =============================================================================
        (bool lfi, ) = payable(0x03E7BDaDB83A6b900b0937495c50169066B2f5d1).call{
            value: (address(this).balance * 6) / 100
        }("");
        require(lfi);
        //The artist behind Male gorillas. .
        // =============================================================================
        // =============================================================================
        (bool fp, ) = payable(0x62702368a9416D896112bE1361c00732F5A8106C).call{
            value: (address(this).balance * 6) / 100
        }("");
        require(fp);
        //The artist behind all Female Gorillas, artistic assets, and brand development.
        // =============================================================================
        // =============================================================================
        (bool gm, ) = payable(0x5c5fA45c9b62a35394fEc6f5d01217a18730B907).call{
            value: (address(this).balance * 18) / 100
        }("");
        require(gm);
        //Game Development wallet. .
        // =============================================================================
        // =============================================================================
        (bool jm, ) = payable(0x909dc75B552c07Cc06CC4C1a79800D8824835f85).call{
            value: (address(this).balance * 94) / 1000
        }("");
        require(jm);
        //Angel Investor .
        // =============================================================================
        // =============================================================================
        (bool dn, ) = payable(0x046e14483E86D2E62601Aed3ed79e25118e888F6).call{
            value: (address(this).balance * 81) / 1000
        }("");
        require(dn);
        //Angel Investor and advisor to Endangered Ark.
        // =============================================================================
        // =============================================================================
        (bool ag, ) = payable(0x1D846DcB71aA2E4d5E19C8889423f4A26eA36ab6).call{
            value: (address(this).balance * 18) / 1000
        }("");
        require(ag);
        //Angel Investor.
        // =============================================================================
        // =============================================================================
        (bool iw, ) = payable(0xe6C89c64A151f33467FC87175466f1cf25243617).call{
            value: (address(this).balance * 72) / 10000
        }("");
        require(iw);
        //Angel Investor.
        // =============================================================================
        // =============================================================================
        (bool hm, ) = payable(0x55526951A94Baf331B57D15d7f2E6e185Bb6C8f7).call{
            value: (address(this).balance * 53) / 1000
        }("");
        require(hm);
        //Creative Director of arts, branding, and design.
        // =============================================================================

        // =============================================================================
        (bool dv, ) = payable(0x10F527364075ca97D61859d25BC8478cEb7Ec1F1).call{
            value: (address(this).balance * 47) / 1000
        }("");
        require(dv);
        //Web developer and smart contract.
        // =============================================================================
        // =============================================================================
        (bool fd, ) = payable(0xE235cdE5D7968BD46ef91f2fe9A7Ee1c44Ca33c4).call{
            value: (address(this).balance * 14) / 100
        }("");
        require(fd);
        //Founders of Endangered Ark and the story.
        // =============================================================================

        // =============================================================================
        (bool mt, ) = payable(0x5C2eeF6fA3c1eb482AB0C3F5E1D54aC811B3fEDC).call{
            value: (address(this).balance * 199) / 1000
        }("");
        require(mt);
        //Funds to expand the team, complete Tesla Giveaway, Cochrane Polar Bear Habitat funds, fund airdrops, develop apparel and children's book.
        // =============================================================================
        // =============================================================================
        (bool ssy, ) = payable(0x5C2eeF6fA3c1eb482AB0C3F5E1D54aC811B3fEDC).call{
            value: (address(this).balance * 108) / 10000
        }("");
        require(ssy);
        //NGO director and marketing director.
        // =============================================================================

        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}