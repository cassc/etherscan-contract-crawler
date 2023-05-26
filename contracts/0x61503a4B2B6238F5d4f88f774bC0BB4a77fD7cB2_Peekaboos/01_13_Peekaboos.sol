// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Peekaboos is ERC721A, Ownable {
    
    using Strings for uint256;
    address breedingContract;
    address peekaboosWallet = 0x323A0C6d5B6d6A466ddEc1a6C5fC723C66e127dF;

    string public baseApiURI;
    bytes32 private whitelistRoot;
    bytes32 private ogbooRoot;
    bytes32 private fanbooRoot;

    //General Settings
    uint16 public maxMintAmountPerTransaction = 10;
    uint16 public maxMintAmountPerWallet = 10;

    //whitelisting Settings
    uint16 public maxMintAmountPerWhitelist = 2;
    uint16 public maxMintAmountPerOgboo = 6;
    uint16 public maxMintAmountPerFanBoo = 4;

    //Inventory
    uint256 public maxSupply = 10000;

    //Prices
    uint256 public cost = 0.1 ether;
    uint256 public ogbooCost = 0.06 ether;
    uint256 public fanbooCost = 0.07 ether;
    uint256 public whitelistCost = 0.08 ether;

    //Utility
    bool public paused = true;
    bool public whiteListingSale = true;

    //mapping
    mapping(address => uint256) private ogboodMints;
    mapping(address => uint256) private fanbooMints;
    mapping(address => uint256) private whitelistedMints;

    constructor(string memory _baseUrl) ERC721A("Peekaboos", "PKB") {
        baseApiURI = _baseUrl;
    }

    function setBreedingContractAddress(address _bAddress) public onlyOwner {
        breedingContract = _bAddress;
    }

    function setPeekaboosWallet(address _pk) public onlyOwner{
        peekaboosWallet = _pk;
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

    function mintExternal(address _address, uint256 _mintAmount) external {
        require(
            msg.sender == breedingContract,
            "Sorry you dont have permission to mint"
        );
        _safeMint(_address, _mintAmount);
    }

    function setWhitelistingRoot(bytes32 _root) public onlyOwner {
        whitelistRoot = _root;
    }

    function setogbooRoot(bytes32 _root) public onlyOwner {
        ogbooRoot = _root;
    }

    function setfanbooRoot(bytes32 _root) public onlyOwner {
        fanbooRoot = _root;
    }

    function setAllWlRoot(
        bytes32 _fanbooRoot,
        bytes32 _ogbooRoot,
        bytes32 _wlroot
    ) public onlyOwner {
        whitelistRoot = _wlroot;
        ogbooRoot = _ogbooRoot;
        fanbooRoot = _fanbooRoot;
    }

    // Verify that a given leaf is in the tree.
    function _verify(
        uint256 _verifyIndex,
        bytes32 _leafNode,
        bytes32[] memory proof
    ) internal view returns (bool) {
        //indexes
        //0 - ogboo
        //1 - fanboo
        //2 - whitelist
        if (_verifyIndex == 0) {
            return MerkleProof.verify(proof, ogbooRoot, _leafNode);
        } else if (_verifyIndex == 1) {
            return MerkleProof.verify(proof, fanbooRoot, _leafNode);
        } else {
            return MerkleProof.verify(proof, whitelistRoot, _leafNode);
        }
    }

    // Generate the leaf node (just the hash of tokenID concatenated with the account address)
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    //whitelist mint
    function mintWhitelist(
        uint256 _verifyIndex,
        bytes32[] calldata proof,
        uint256 _mintAmount
    ) public payable {
        //indexes
        //0 - ogboo
        //1 - fanboo
        //2 - whitelist

        if (msg.sender != owner()) {
            require(!paused);
            require(whiteListingSale, "Whitelisting not enabled");

            if (_verifyIndex == 0) {
                //OgBoo Verifications
                require(
                    _verify(_verifyIndex, _leaf(msg.sender), proof),
                    "Invalid proof"
                );

                require(
                    (ogboodMints[msg.sender] + _mintAmount) <=
                        maxMintAmountPerOgboo,
                    "Exceeds Max Mint amount for OGBOO"
                );

                require(
                    msg.value >= (ogbooCost * _mintAmount),
                    "Insuffient funds"
                );

                //End OGBOO Verification
                //Mint
                _mintLoop(msg.sender, _mintAmount);
                ogboodMints[msg.sender] =
                    ogboodMints[msg.sender] +
                    _mintAmount;


            } else if (_verifyIndex == 1) {
                //Fanboo Verifications
                require(
                    _verify(_verifyIndex, _leaf(msg.sender), proof),
                    "Invalid proof"
                );

                require(
                    (fanbooMints[msg.sender] + _mintAmount) <=
                        maxMintAmountPerFanBoo,
                    "Exceeds Max Mint amount for Fanboo"
                );

                require(
                    msg.value >= (fanbooCost * _mintAmount),
                    "Insuffient funds"
                );
                //End Fanboo Verification
                //Mint
                _mintLoop(msg.sender, _mintAmount);
                fanbooMints[msg.sender] =
                    fanbooMints[msg.sender] +
                    _mintAmount;

            } else {
                //Normal WL Verifications
                require(
                    _verify(_verifyIndex, _leaf(msg.sender), proof),
                    "Invalid proof"
                );
                require(
                    (whitelistedMints[msg.sender] + _mintAmount) <=
                        maxMintAmountPerWhitelist,
                    "Exceeds Max Mint amount"
                );

                require(
                    msg.value >= (whitelistCost * _mintAmount),
                    "Insuffient funds"
                );

                //END WL Verifications

                //Mint
                _mintLoop(msg.sender, _mintAmount);
                whitelistedMints[msg.sender] =
                    whitelistedMints[msg.sender] +
                    _mintAmount;
            }
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        if (msg.sender != owner()) {
            uint256 ownerTokenCount = balanceOf(msg.sender);

            require(!paused);
            require(!whiteListingSale, "You cant mint on Presale");
            require(_mintAmount > 0, "Mint amount should be greater than 0");
            require(
                _mintAmount <= maxMintAmountPerTransaction,
                "Sorry you cant mint this amount at once"
            );
            require(
                totalSupply() + _mintAmount <= maxSupply,
                "Exceeds Max Supply"
            );
            require(
                (ownerTokenCount + _mintAmount) <= maxMintAmountPerWallet,
                "Sorry you cant mint more"
            );

            require(msg.value >= cost * _mintAmount, "Insuffient funds");
        }

        _mintLoop(msg.sender, _mintAmount);
    }

    function gift(address _to, uint256 _mintAmount) public onlyOwner {
        _mintLoop(_to, _mintAmount);
    }

    function airdrop(address[] memory _airdropAddresses) public onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            _mintLoop(to, 1);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseApiURI;
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
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistingCost(uint256 _newCost) public onlyOwner {
        whitelistCost = _newCost;
    }

    function setogbooCost(uint256 _newCost) public onlyOwner {
        ogbooCost = _newCost;
    }

    function setfanbooCost(uint256 _newCost) public onlyOwner {
        fanbooCost = _newCost;
    }

    function setmaxMintAmountPerTransaction(uint16 _amount) public onlyOwner {
        maxMintAmountPerTransaction = _amount;
    }

    function setMaxMintAmountPerWallet(uint16 _amount) public onlyOwner {
        maxMintAmountPerWallet = _amount;
    }

    function setMaxMintAmountPerWhitelist(uint16 _amount) public onlyOwner {
        maxMintAmountPerWhitelist = _amount;
    }

    function setMaxMintAmountPerOgboo(uint16 _amount) public onlyOwner {
        maxMintAmountPerOgboo = _amount;
    }

    function setMaxMintAmountPerFanboo(uint16 _amount) public onlyOwner {
        maxMintAmountPerFanBoo = _amount;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseApiURI = _newBaseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function toggleWhiteSale() public onlyOwner {
        whiteListingSale = !whiteListingSale;
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        _safeMint(_receiver, _mintAmount);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        (bool pkw, ) = payable(peekaboosWallet).call{value: balance}("");
        require(pkw);
    }
}