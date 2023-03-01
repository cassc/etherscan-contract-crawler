// SPDX-License-Identifier: MIT
// Creator: deadbirbs.xyz

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Seller.sol";
import "./AttributeStore.sol";
import "./lib/IRegistry.sol";

/**
 * @title BaseContract contract
 * @dev Extends ERC721A
 */
contract DeadBirbs is ERC721A, Seller, AttributeStore, ReentrancyGuard, ERC2981 {
    using ECDSA for bytes32;

    /**
     @notice collection and contract meta data
     */
    string public baseURI;
    string private _contractURI;

    address public registryAddress;
    bool public isRegistryActive = false;

    mapping(uint256 => uint256) public backgrounds;
    uint256 backgroundOptions = 0;
    bool public addAttributesToTokenURI = true;

    constructor(
        string memory name,
        string memory symbol,
        string memory initBaseURI,
        string memory initContractURI,
        address payable _beneficiary
    ) ERC721A(name, symbol) {
        baseURI = initBaseURI;
        _contractURI = initContractURI;
        beneficiary = _beneficiary;
        _setDefaultRoyalty(_beneficiary, 0);

        // set sale
        setPublicSale(1677569753, 8035200, 9000000000000000, 1);

        setAttributeSigner(0xfCf023768266fD81AAC5a19D48c10697cE394CA1);
    }

    // mint functions

    /**
    @notice mints a deaDBirb on public sale without verifying any key
    */
    function deadBirbMint(string calldata attributes, bytes calldata signature) external payable nonReentrant {
        verifyPublicSale(1);
        verifyAttributes(attributes, signature);
        storeAttributes(attributes, msg.sender, totalSupply());
        _safeMint(msg.sender, 1);
    }

    /**
    @dev owner mint to fill up our treasury
    */
    function ownerMint(string calldata attributes, bytes calldata signature, address recipient) external onlyOwner nonReentrant {
        verifyAttributes(attributes, signature);
         storeAttributes(attributes, msg.sender, totalSupply());
        _safeMint(recipient, 1);
    }

    // metadata

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setAddAttributesToTokenURI(bool enabled) external onlyOwner {
        addAttributesToTokenURI = enabled;
    }

    // background options

    function setBackgroundOptions(uint256 options) external onlyOwner {
        backgroundOptions = options;
    }

    function setBackground(uint256 tokenId, uint256 backgroundId) external {
        require(backgroundOptions > 0, "this feature is disabled");
        require(backgroundOptions > backgroundId && 0 <= backgroundId, "invalid backgroundId");
        require(ownerOf(tokenId) == msg.sender, "invalid permission to modify this token");
        backgrounds[tokenId] = backgroundId;
    }

    /**
    @dev returns a list of the minted attributes variants
    */
    function getAllMinted() public view returns (string[] memory){
        string[] memory minted = new string[](totalSupply());
        for (uint256 i = 0; i < totalSupply(); i++) {
            minted[i] = tokenAttributes[i];
        }
        return minted;
    }

    /**
    @dev returns a list of the minters ordered by tokenId
    */
    function getAllMinters() public view returns (address[] memory){
        address[] memory minters = new address[](totalSupply());
        for (uint256 i = 0; i < totalSupply(); i++) {
            minters[i] = firstMinters[tokenAttributes[i]];
        }
        return minters;
    }

    /**
    @dev extended version of the tokenURI to pass the tokenAttributes as url params
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);

        if (!addAttributesToTokenURI) {
            return uri;
        }
        
        string memory extendedUri = bytes(uri).length > 0 ? string(abi.encodePacked(uri, "?attr=", tokenAttributes[tokenId])): "";
        if (backgroundOptions == 0) {
            return extendedUri;
        }

        return string(abi.encodePacked(extendedUri, "&bg=", Strings.toString(backgrounds[tokenId])));
    }

    /**
    @dev returns a list of the token uris which owned by the specified address
    */
    function tokenURIs(address owner) public view returns(string[] memory) {
        string[] memory URIs = new string[](balanceOf(owner));
        uint256 count = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == owner) {
                URIs[count] = tokenURI(i);
                count++;
            }
        }
        return URIs;
    }

    // transfer revenues

    /**
    @notice Recipient of revenues.
    */
    address payable public beneficiary;

    /**
    @notice Sets the recipient of revenues
    */
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    /**
    @notice Send revenues to beneficiary
    */
    function transferRevenues() external onlyOwner {
        require(beneficiary != address(0), "No beneficiary address defined");
        (bool success, ) = beneficiary.call{value: address(this).balance}("Sending revenues from cowlony");
        require(success, "Transfer failed.");
    }

    /**
    @notice Set the registry contract
    @param _registryAddress Contract address for registry
    */
    function setRegistryAddress(address _registryAddress) external onlyOwner {
        registryAddress = _registryAddress;
    }

    /**
    @param isActive Enables or disables the registry
    */
    function setIsRegistryActive(bool isActive) external onlyOwner {
        require(registryAddress != address(0));
        isRegistryActive = isActive;
    }

    /**
    @notice Checks whether caller is valid on the registry
    */
    function _isValidAgainstRegistry(address operator) internal view returns (bool) {
        if (isRegistryActive) {
            IRegistry registry = IRegistry(registryAddress);
            return registry.isAllowedOperator(operator);
        }
        return true;
    }

    /**
    @notice Overrides beforeTokenTransfers and triggers before any transfer
    */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        if (_isValidAgainstRegistry(msg.sender)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        } else {
            revert IRegistry.NotAllowed();
        }
    }

    /**
    @notice Sets the contract-wide royalty info.
    */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}