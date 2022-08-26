// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Pixelatarz is ERC721A, Ownable {
    using ECDSA for bytes32;
    string private _name = "Pixelatarz";
    string private _symbol = "PIX";

    string private _customBaseUri =
        "https://assets.chromaworld.io/pixelatarz/metadata/";
    string private _contractUri =
        "https://assets.chromaworld.io/pixelatarz/metadata/contract.json";

    uint256 public maxSupply = 3333;
    address public signerAddress;

    uint256 public priceWei;

    // Sale states:
    // 0: Closed
    // 1: Presale 1.
    // 2: Presale 2.
    // 3: Public sale.
    uint256 public saleState = 0;

    constructor() ERC721A(_name, _symbol) {}

    function presaleMint(
        uint256 numToMint,
        uint256 sigSaleState,
        bytes memory signature // Signed by signerAddress.
    ) public payable {
        require(saleState == 1 || saleState == 2, "Presale not open");
        require(
            sigSaleState <= saleState, // Users authorized for sale 1 can mint in sale 1 and sale 2.
            "Not authorized for this sale state"
        );
        require(
            isValidSignature(msg.sender, sigSaleState, signature),
            "Invalid signature"
        );
        _checkAndMint(numToMint);
    }

    function publicMint(uint256 numToMint) public payable {
        require(saleState == 3, "Public mint not open");
        _checkAndMint(numToMint);
    }

    function _checkAndMint(uint256 numToMint) internal {
        _requireWithinSupply(numToMint);
        _checkPayment(numToMint);
        _safeMint(msg.sender, numToMint);
    }

    function _checkPayment(uint256 numToMint) internal {
        uint256 amountRequired = priceWei * numToMint;
        require(msg.value >= amountRequired, "Not enough funds sent");
    }

    function isValidSignature(
        address addr,
        uint256 sigSaleState,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 inputHash = keccak256(abi.encodePacked(addr, sigSaleState));
        bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
        address recoveredAddress = ethSignedMessageHash.recover(signature);
        return recoveredAddress == signerAddress;
    }

    function _requireWithinSupply(uint256 numToMint) internal view {
        require(
            totalSupply() + numToMint <= maxSupply,
            "minting would exceed max supply"
        );
    }

    function ownerMint(uint256 numToMint) public onlyOwner {
        _requireWithinSupply(numToMint);
        _safeMint(msg.sender, numToMint);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _customBaseUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function setSalePrice(uint256 newPriceWei) public onlyOwner {
        priceWei = newPriceWei;
    }

    function setSaleState(uint256 newState) public onlyOwner {
        require(newState >= 0 && newState <= 3, "Invalid state");
        saleState = newState;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string calldata newURI) public onlyOwner {
        _customBaseUri = newURI;
    }

    function setContractUri(string calldata newUri) public onlyOwner {
        _contractUri = newUri;
    }

    function setSignerAddress(address newAddress) public onlyOwner {
        signerAddress = newAddress;
    }

    function reduceMaxSupply(uint newMaxSupply) public onlyOwner {
        require(newMaxSupply < maxSupply);
        maxSupply = newMaxSupply;
    }
}

library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return
            address(registry) != address(0) &&
            address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}