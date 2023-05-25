// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PPADealers is ERC721A, Ownable {
    using ECDSA for bytes32;
    string private _name = "PPADealers";
    string private _symbol = "DLR";

    string private _customBaseUri =
        "https://assets.jointheppa.com/dealers/metadata/";
    string private _contractUri =
        "https://assets.jointheppa.com/dealers/metadata/contract.json";

    uint256 public MAX_SUPPLY = 10000;
    address public signerAddress;

    mapping(address => bool) public mintedInSale1;
    mapping(address => uint256) public numMintedInSale2;
    mapping(address => uint256) public numMintedInSale3;

    uint256 public publicPriceWei;

    uint256 public constant MAX_PRESALE_MINTS = 500;

    // Sale states:
    // 0: Closed
    // 1: WL minting in presale (max 1 per address)
    // 2: Public minting in (max 5 per address)
    // 3: Shuttlepass holder minting
    // 4: Open to Public, purchase with ETH, no max.
    uint256 public saleState = 0;

    address public stakingAddress;

    constructor() ERC721A(_name, _symbol) {}

    // WL mint, max 1 per address.
    function whitelistMint(
        bytes memory signature // Signed by signerAddress.
    ) public payable {
        require(saleState == 1, "Whitelist mint not open");
        _requireWithinSupply(1, MAX_PRESALE_MINTS);
        require(!mintedInSale1[msg.sender], "Already minted in whitelist sale");
        require(isValidSignature(msg.sender, 1, 1, signature), "Invalid signature");
        mintedInSale1[msg.sender] = true;
        _checkPayment(1);
        _safeMint(msg.sender, 1);
    }

    // Public minting before main sale, max 5 per address.
    function publicEarlyMint(uint256 amount) public payable {
        require(saleState == 2, "Public early mint not open");
        _requireWithinSupply(amount, MAX_PRESALE_MINTS);
        numMintedInSale2[msg.sender] += amount;
        require(
            numMintedInSale2[msg.sender] <= 5,
            "Cannot mint more than 5 total in public pre-sale"
        );
        _checkPayment(amount);
        _safeMint(msg.sender, amount);
    }

    // Minting for shuttlepass holders. Number of mints allowed is determined by how many shuttlepassees they own.
    function shuttlepassMint(
        uint256 amount,
        uint256 totalMintsAllowed,
        bytes memory signature
    ) public {
        require(saleState == 3, "Shuttlepass minting not open");
        _requireWithinSupply(amount, MAX_SUPPLY);
        numMintedInSale3[msg.sender] += amount;
        require(
            numMintedInSale3[msg.sender] <= totalMintsAllowed,
            "Not authorized for this many mints"
        );
        require(
            isValidSignature(msg.sender, totalMintsAllowed, 3, signature),
            "Invalid Signature"
        );

        _safeMint(msg.sender, amount);
    }

    // Public mint (if needed), open to all with no limits.
    function publicMint(uint256 amount) public payable {
        require(saleState == 4, "Public mint not open");
        _requireWithinSupply(amount, MAX_SUPPLY);
        _checkPayment(amount);
        _safeMint(msg.sender, amount);
    }

    function _checkPayment(uint256 numMinted) internal {
        uint256 amountRequired = publicPriceWei * numMinted;
        require(msg.value >= amountRequired, "Not enough funds sent");
    }

    function isValidSignature(
        address addr,
        uint256 totalMintsAllowed,
        uint256 targetSaleState,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 inputHash = keccak256(
            abi.encodePacked(addr, totalMintsAllowed, targetSaleState)
        );
        bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
        address recoveredAddress = ethSignedMessageHash.recover(signature);
        return recoveredAddress == signerAddress;
    }

    function _requireWithinSupply(uint256 numToMint, uint256 supply) internal view {
        require(
            totalSupply() + numToMint <= supply,
            "minting would exceed allowed supply for this sale phase"
        );
    }

    function ownerMint(uint256 numToMint) public onlyOwner {
        _requireWithinSupply(numToMint, MAX_SUPPLY);
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
            operator == stakingAddress || // NOTE: the staking address is approved to move dealers.
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function setSalePrice(uint256 newPriceWei) public onlyOwner {
        publicPriceWei = newPriceWei;
    }

    function setSaleState(uint256 newState) public onlyOwner {
        require(newState >= 0 && newState <= 4, "Invalid state");
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

    function setStakingAddress(address _stakingAddress) public onlyOwner {
        stakingAddress = _stakingAddress;
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