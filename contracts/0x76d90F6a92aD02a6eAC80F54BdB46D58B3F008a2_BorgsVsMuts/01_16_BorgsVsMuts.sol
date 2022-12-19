// SPDX-License-Identifier: MIT
//                                                                          ___
//  /'\_/`\                                            /'\_/`\            /'___\ __
// /\      \     __       __   _ __   ___     ____    /\      \     __   /\ \__//\_\     __
// \ \ \__\ \  /'__`\   /'_ `\/\`'__\/ __`\  /',__\   \ \ \__\ \  /'__`\ \ \ ,__\/\ \  /'__`\
//  \ \ \_/\ \/\ \L\.\_/\ \L\ \ \ \//\ \L\ \/\__, `\   \ \ \_/\ \/\ \L\.\_\ \ \_/\ \ \/\ \L\.\_
//   \ \_\\ \_\ \__/.\_\ \____ \ \_\\ \____/\/\____/    \ \_\\ \_\ \__/.\_\\ \_\  \ \_\ \__/.\_\
//    \/_/ \/_/\/__/\/_/\/___L\ \/_/ \/___/  \/___/      \/_/ \/_/\/__/\/_/ \/_/   \/_/\/__/\/_/
//                        /\____/
//                        \_/__/
//                  __              __                  ____        __   ___    __
//                 /\ \            /\ \                /\  _`\    /'__`\/\_ \  /\ \__
//   ___    ___    \_\ \     __    \ \ \____  __  __   \ \ \L\ \ /\ \/\ \//\ \ \ \ ,_\
//  /'___\ / __`\  /'_` \  /'__`\   \ \ '__`\/\ \/\ \   \ \  _ <'\ \ \ \ \\ \ \ \ \ \/
// /\ \__//\ \L\ \/\ \L\ \/\  __/    \ \ \L\ \ \ \_\ \   \ \ \L\ \\ \ \_\ \\_\ \_\ \ \_
// \ \____\ \____/\ \___,_\ \____\    \ \_,__/\/`____ \   \ \____/ \ \____//\____\\ \__\
//  \/____/\/___/  \/__,_ /\/____/     \/___/  `/___/> \   \/___/   \/___/ \/____/ \/__/
//                                                /\___/

pragma solidity ^0.8.17;

import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";
import "MerkleProof.sol";
import {DefaultOperatorFilterer} from "DefaultOperatorFilterer.sol";

contract BorgsVsMuts is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    uint256 public cost = 0.0069 ether;
    uint256 public maxSupply = 999;
    uint256 public maxMintAmountPerTx = 2;
    bytes32 public whitelistMerkleRoot;
    bool public pausedPublic = true;
    bool public pausedWL = true;
    bool public revealed = false;
    bool public walletPerTransaction = true;
    address[] private addrThatTransacted;

    constructor() ERC721("Borgs vs Muts", "BVM") {
        setHiddenMetadataUri(
            "ipfs://bafkreifklev5wxm6xi6fhgnwnzruotvme4ahlhdczh3e4ihu4jyzwexpiu"
        );
        mintOwner(99, owner());
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Mint amount cant be zero!");
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }
    modifier notOwnerMintModifiers(uint256 _mintAmount) {
        require(_mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        if (walletPerTransaction) {
            require(
                didCallerTrasactedBefore(),
                "Only one transaction per wallet is allowed"
            );
        }
        _;
    }
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mintPublic(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        notOwnerMintModifiers(_mintAmount)
    {
        require(!pausedPublic, "The contract is not open to the public!");
        _mintLoop(msg.sender, _mintAmount);
        addAddrTransacted();
    }

    function mintWL(bytes32[] calldata merkleProof, uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        notOwnerMintModifiers(_mintAmount)
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    {
        require(!pausedWL, "Presale is not activated!");
        _mintLoop(msg.sender, _mintAmount);
        addAddrTransacted();
    }

    function mintOwner(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _mintLoop(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
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

    function setRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
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

    function setPauseForPublic(bool _state) public onlyOwner {
        pausedPublic = _state;
    }

    function setPauseForWL(bool _state) public onlyOwner {
        pausedWL = _state;
    }

    function setWalletPerTransaction(bool _state) public onlyOwner {
        walletPerTransaction = _state;
    }

    function resgate() public onlyOwner {
        uint256 balanco = address(this).balance;
        (bool magro, ) = payable(0x9Cf547d2063A96DF36F44591E77d4F2b8abBcdCD)
            .call{value: (balanco * 40) / 100}("");
        require(magro);
        (bool eu, ) = payable(0x682575665500B067BB4D2B2EF3F0f0Cb89D48C27).call{
            value: (balanco * 40) / 100
        }("");
        require(eu);
        (bool proximo_projeto, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(proximo_projeto);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function didCallerTrasactedBefore() internal view virtual returns (bool) {
        for (uint256 i = 0; i < addrThatTransacted.length; i++) {
            if (addrThatTransacted[i] == msg.sender) {
                return false;
            }
        }
        return true;
    }

    function addAddrTransacted() internal virtual {
        addrThatTransacted.push(msg.sender);
    }
}